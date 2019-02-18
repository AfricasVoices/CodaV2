import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

client = None

def init_client(crypto_token_path):
    global client
    cred = credentials.Certificate(crypto_token_path)
    firebase_admin.initialize_app(cred)
    client = firestore.client()

def get_code_scheme_ids(dataset_id):
    ids = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(dataset_id)).get():
        ids.append(scheme.id)
    return ids

def get_code_scheme(dataset_id, scheme_id):
    return client.document(u'datasets/{}/code_schemes/{}'.format(dataset_id, scheme_id)).get().to_dict()

# This is a much faster way of reading an entire dataset rather than repeated get_message calls
def get_all_messages(dataset_id):
    messages = []
    for message in client.collection(u'datasets/{}/messages'.format(dataset_id)).get():
        messages.append(message.to_dict())
    return messages

def get_message_ref(dataset_id, message_id):	
    return client.document(u'datasets/{}/messages/{}'.format(dataset_id, message_id))

def set_dataset_autolabel_complete(dataset_id, fraction_complete):
    message_metrics_ref = client.document(u'datasets/{}/metrics/autolabel'.format(dataset_id))
    message_metrics_ref.set(
        {
            "fractionComplete" : fraction_complete
        }
    )

def set_messages_content_batch(dataset_id, messages, batch_size=500):
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
