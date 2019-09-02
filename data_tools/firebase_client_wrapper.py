import time

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

client = None

# TODO: Set from a program argument
MAX_SEGMENT_SIZE = 2500

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
def get_segment_messages(dataset_id, segment_index=None):
    if segment_index is not None and segment_index != 1:
        dataset_id += f'_{segment_index}'

    messages = []
    for message in client.collection(u'datasets/{}/messages'.format(dataset_id)).get():
        messages.append(message.to_dict())
    return messages

def get_all_messages(dataset_id):
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        return get_segment_messages(dataset_id)
    else:
        messages = []
        for segment_index in range(1, segment_count + 1):
            messages.extend(get_segment_messages(dataset_id, segment_index))

        message_ids = set()
        for message in messages:
            assert message["MessageID"] not in message_ids, "Duplicate message found"
            message_ids.add(message["MessageID"])

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

def set_segment_user_ids(dataset_id, user_ids, segment_index=None):
    if segment_index is not None and segment_index != 1:
        dataset_id += f'_{segment_index}'

    print(f"Writing users to segment {dataset_id}...")
    dataset_ref = get_dataset_ref(dataset_id)
    dataset_ref.set({
        "users": user_ids
    })

def set_dataset_user_ids(dataset_id, user_ids):
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        set_segment_user_ids(dataset_id, user_ids)
    else:
        for segment_index in range(1, segment_count + 1):
            set_segment_user_ids(dataset_id, user_ids, segment_index=segment_index)
    print(f"Wrote users to dataset {dataset_id}")

def set_scheme(dataset_id, scheme):
    scheme_id = scheme["SchemeID"]
    get_code_scheme_ref(dataset_id, scheme_id).set(scheme)
    print ("Written scheme: {}".format(scheme_id))

def set_all_code_schemes(dataset_id, schemes):
    # TODO: Implement more efficiently
    # TODO: Rename this (and all other set functions that don't really set) to add_and_update...
    for scheme in schemes:
        set_scheme(dataset_id, scheme)


def set_messages_content(dataset_id, messages):
    for message in messages:
        message_id = message["MessageID"]
        get_message_ref(dataset_id, message_id).set(message)
        print ("Written message: {}".format(message_id))


def set_segment_messages_content_batch(dataset_id, messages, segment_index=None, batch_size=500):
    if segment_index is not None and segment_index != 1:
        dataset_id += f'_{segment_index}'

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
    latest_segment_index = get_segment_count(dataset_id)
    latest_segment_size = len(get_segment_messages(dataset_id, latest_segment_index))
    for message in messages:
        if latest_segment_size >= MAX_SEGMENT_SIZE:
            set_segment_messages_content_batch(
                dataset_id, next_batch_to_write, segment_index=get_segment_count(dataset_id), batch_size=batch_size)
            next_batch_to_write = []
            create_next_dataset_segment(dataset_id)
            latest_segment_size = 0
        next_batch_to_write.append(message)
        latest_segment_size += 1

    set_segment_messages_content_batch(
        dataset_id, next_batch_to_write, segment_index=get_segment_count(dataset_id), batch_size=batch_size)

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

def get_segment_count(dataset_id):
    segment_count_doc = client.document(f'segment_counts/{dataset_id}').get().to_dict()
    if segment_count_doc is None:
        return None
    return segment_count_doc["segment_count"]

def set_segment_count(dataset_id, segment_count):
    client.document(f'segment_counts/{dataset_id}').set({"segment_count": segment_count})

def create_next_dataset_segment(dataset_id):
    segment_count = get_segment_count(dataset_id)

    if segment_count is None:
        current_segment_id = f"{dataset_id}"
        next_segment_id = f"{dataset_id}_2"
        next_segment_count = 2
    else:
        current_segment_id = f"{dataset_id}_{segment_count}"
        next_segment_id = f"{dataset_id}_{segment_count + 1}"
        next_segment_count = segment_count + 1

    print(f"Creating next dataset segment with id {next_segment_id}")

    code_schemes = get_all_code_schemes(current_segment_id)
    set_all_code_schemes(next_segment_id, code_schemes)

    users = get_user_ids(current_segment_id)
    set_dataset_user_ids(next_segment_id, users)

    set_segment_count(dataset_id, next_segment_count)

    for x in range(0, 10):
        if get_segment_count(dataset_id) == next_segment_count:
            return
        print("New segment count not yet committed, waiting 1s before retrying")
        time.sleep(1)
    assert False, "Server segment count did not update to the newest count fast enough"
