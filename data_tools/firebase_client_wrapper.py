import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

client = None

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
def get_all_messages(dataset_id):
    messages = []
    for message in client.collection(u'datasets/{}/messages'.format(dataset_id)).get():
        messages.append(message.to_dict())
    return messages

def get_message(dataset_id, message_id):
    return client.document(u'datasets/{}/messages/{}'.format(dataset_id, message_id)).get().to_dict()

def get_message_ref(dataset_id, message_id):
    return client.document(u'datasets/{}/messages/{}'.format(dataset_id, message_id))

def push_coding_status(coding_status):
    client.document(u'metrics/coda').set(coding_status)

def get_dataset_metrics(dataset_id):
    return client.document(u'datasets/{}/metrics/messages'.format(dataset_id)).get().to_dict()