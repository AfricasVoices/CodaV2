import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

client = None

MAX_SHARD_SIZE = 4000

def init_client(crypto_token_path):
    global client
    cred = credentials.Certificate(crypto_token_path)
    firebase_admin.initialize_app(cred)
    client = firestore.client()

def get_dataset_ids():
    ids = []
    for dataset in client.collection(u'datasets').get():
        ids.append(dataset.id)
    return ids

def get_dataset(id):
    return client.document(u'datasets/{}'.format(id)).get()

def get_dataset_ref(id):
    return client.document(u'datasets/{}'.format(id))


def get_user_ids(dataset_id):
    return get_dataset(dataset_id).get("users")

def get_code_scheme_ids(dataset_id):
    ids = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(dataset_id)).get():
        ids.append(scheme.id)
    return ids

def get_all_code_schemes(dataset_id):
    schemes = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(dataset_id)).get():
        schemes.append(scheme.to_dict())
    return schemes

def get_code_scheme(dataset_id, scheme_id):
    return client.document(u'datasets/{}/code_schemes/{}'.format(dataset_id, scheme_id)).get().to_dict()

def get_code_scheme_ref(dataset_id, scheme_id):
    return client.document(u'datasets/{}/code_schemes/{}'.format(dataset_id, scheme_id))

def get_message_ids(dataset_id):
    ids = []
    for message in client.collection(u'datasets/{}/messages'.format(dataset_id)).get():
        ids.append(message.id)
    return ids

# This is a much faster way of reading an entire dataset rather than repeated get_message calls
def get_shard_messages(dataset_id, shard_index=None):
    if shard_index is not None:
        dataset_id += f'_{shard_index}'

    messages = []
    for message in client.collection(u'datasets/{}/messages'.format(dataset_id)).get():
        messages.append(message.to_dict())
    return messages

def get_all_messages(dataset_id):
    shard_count = get_shard_count(dataset_id)
    if shard_count is None or shard_count == 1:
        return get_shard_messages(dataset_id)
    else:
        messages = []
        for shard_index in range(1, shard_count + 1):
            messages.extend(get_shard_messages(dataset_id, shard_index))
        return messages

def get_message(dataset_id, message_id):
    return client.document(u'datasets/{}/messages/{}'.format(dataset_id, message_id)).get().to_dict()

def get_message_ref(dataset_id, message_id):
    return client.document(u'datasets/{}/messages/{}'.format(dataset_id, message_id))

def push_coding_status(coding_status):
    client.document(u'metrics/coda').set(coding_status)

def get_dataset_metrics(dataset_id):
    return client.document(u'datasets/{}/metrics/messages'.format(dataset_id)).get().to_dict()

def set_dataset_metrics(dataset_id, metrics_map):
    message_metrics_ref = client.document(u'datasets/{}/metrics/messages'.format(dataset_id))
    message_metrics_ref.set(metrics_map)

def set_users(dataset_id, users_list):
    dataset_ref = get_dataset_ref(dataset_id)
    dataset_ref.set({
        'users': users_list
    })
    print ("Written users")

def set_scheme(dataset_id, scheme):
    scheme_id = scheme["SchemeID"]
    get_code_scheme_ref(dataset_id, scheme_id).set(scheme)
    print ("Written scheme: {}".format(scheme_id))

def set_all_code_schemes(dataset_id, schemes):
    # TODO: Implement more efficiently:
    for scheme in schemes:
        set_scheme(dataset_id, scheme)


def set_messages_content(dataset_id, messages):
    for message in messages:
        message_id = message["MessageID"]
        get_message_ref(dataset_id, message_id).set(message)
        print ("Written message: {}".format(message_id))


def set_shard_messages_content_batch(dataset_id, messages, shard_index=None, batch_size=500):
    if shard_index is not None:
        dataset_id += f'_{shard_index}'

    total_messages_count = len(messages)
    i = 0
    batch_counter = 0
    batch = client.batch()
    for message in messages:
        i += 1
        id = message["MessageID"]
        batch.set(get_message_ref(dataset_id, id), message)
        batch_counter += 1
        if batch_counter >= batch_size:
            batch.commit()
            print ("Batch of {} messages committed, progress: {} / {}".format(batch_counter, i, total_messages_count))
            batch_counter = 0
            batch = client.batch()
    
    if batch_counter > 0:
        batch.commit()
        print ("Final batch of {} messages committed".format(batch_counter))

    print ("Written {} messages".format(i))

def set_dataset_messages_content_batch(dataset_id, messages, batch_size=500):
    next_batch_to_write = []
    current_shard_size = len(get_shard_messages(dataset_id, get_shard_count(dataset_id)))
    for message in messages:
        if current_shard_size >= MAX_SHARD_SIZE:
            set_shard_messages_content_batch(
                dataset_id, next_batch_to_write, shard_index=get_shard_count(dataset_id), batch_size=batch_size)
            next_batch_to_write = []
            create_next_dataset_shard(dataset_id)
            current_shard_size = 0
        next_batch_to_write.append(message)
        current_shard_size += 1

    set_shard_messages_content_batch(
        dataset_id, next_batch_to_write, shard_index=get_shard_count(dataset_id), batch_size=batch_size)

def delete_dataset(dataset_id):
    # Delete Code schemes
    _delete_collection(
        client.collection("datasets/{}/code_schemes".format(dataset_id)), 10)
    
    # Delete Messages
    _delete_collection(
        client.collection("datasets/{}/messages".format(dataset_id)), 10)

    # Delete dataset
    get_dataset_ref(dataset_id).delete()


def _delete_collection(coll_ref, batch_size):
    docs = coll_ref.limit(batch_size).get()
    deleted = 0
    for doc in docs:
        print(u'Deleting doc {} => {}'.format(doc.id, doc.to_dict()))
        doc.reference.delete()
        deleted = deleted + 1

    if deleted >= batch_size:
        return _delete_collection(coll_ref, batch_size)

def get_shard_count(dataset_id):
    shard_count_doc = client.document(f'shard_counts/{dataset_id}').get().to_dict()
    if shard_count_doc is None:
        return None
    return shard_count_doc["shard_count"]

def set_shard_count(dataset_id, shard_count):
    client.document(f'shard_counts/{dataset_id}').set({"shard_count": shard_count})

def create_next_dataset_shard(dataset_id):
    shard_count = get_shard_count(dataset_id)

    if shard_count is None:
        current_shard_id = f"{dataset_id}"
        next_shard_id = f"{dataset_id}_2"
        next_shard_count = 2
    else:
        current_shard_id = f"{dataset_id}_{shard_count}"
        next_shard_id = f"{dataset_id}_{shard_count + 1}"
        next_shard_count = shard_count + 1

    print(f"Creating next dataset shard with id {next_shard_id}")

    code_schemes = get_all_code_schemes(current_shard_id)
    set_all_code_schemes(next_shard_id, code_schemes)

    users = get_user_ids(current_shard_id)
    set_users(next_shard_id, users)

    set_shard_count(dataset_id, next_shard_count)


