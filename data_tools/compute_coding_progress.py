import firebase_client_wrapper as fcw

import json
import sys
from time import gmtime, strftime

if (len(sys.argv) != 2):
    print ("Usage python compute_coding_progress.py coda_crypto_token")
    exit(1)

CODA_CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CODA_CRYPTO_TOKEN_PATH)

def compute_coding_progress(dataset_ids, messages, metrics):
    """
    Computes no. of messages,labelled messages and last data update time
    params dataset_id: dataset unique identifiers
    params messages: dataset messages 
    params metrics: dataset message metrics(Messages,Labelled messages,Not Coded messages,Wrong Schemes)
    """
    data = {}
    data['coding_progress'] = {}
    for id in dataset_ids:
        data['coding_progress'][id] = {}  
        messages_with_labels = 0
        # New scheme
        if metrics != None:
            data['coding_progress'][id] = metrics   
            continue
        for message in messages:
            if len(message["Labels"]) > 0:
                messages_with_labels += 1
        data['coding_progress'][id]['messages_count'] = len(messages)
        data['coding_progress'][id]['messages_with_label'] = messages_with_labels
    data["last_update"] = strftime("%Y-%m-%d %H:%M:%S", gmtime())
    return data

def get_messages_ids_metrics(): 
    """ 
    Fetches dataset ids, messages and metrics for individual datasets and
    computes coding progress through the compute_coding_progress() function.
    params dataset_id: dataset unique identifiers.
    params messages: dataset messages. 
    params metrics: dataset message metrics(Messages,Labelled messages, Not Coded messages, Wrong Schemes)
    """
    dataset_ids = []
    for dataset_id in fcw.get_dataset_ids():
        dataset_ids.append(dataset_id)

    metrics = []
    for metric in fcw.get_dataset_metrics(dataset_ids):
        metrics.append(metric)

    messages = []
    for message in fcw.get_all_messages(dataset_ids):
        messages.append(message)

    progress = compute_coding_progress(dataset_ids, messages, metrics)
    return progress

if __name__ == "__main__":
    get_messages_ids_metrics()
    print (json.dumps(data, indent=2))
    