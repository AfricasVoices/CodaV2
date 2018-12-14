import firebase_client_wrapper as fcw

import json
import sys
from time import gmtime, strftime

if (len(sys.argv) != 2):
    print ("Usage python compute_coding_progress.py coda_crypto_token")
    exit(1)

CODA_CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CODA_CRYPTO_TOKEN_PATH)

def compute_coding_progress(ids, messages, metrics):
    """
    Computes no of messages,labelled messages and last data update time
    params ids: dataset unique identifiers
    params messages: project messages 
    params metrics: project message metrics(Messages,Labelled messages,Not Coded messages,Wrong Schemes)
    """
    data = {}
    data['coding_progress'] = {}
    for id in ids:
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
    Fetches messages, ids and metrics from firebase and computes
    coding progess using compute_coding_progress().
    """
    ids = fcw.get_dataset_ids()

    metrics = fcw.get_dataset_metrics(id)

    messages = []
    for message in fcw.get_all_messages(id):
        messages.append(message)

    progress = compute_coding_progress(ids, messages, metrics)
    return progress

if __name__ == "__main__":
    get_messages_ids_metrics()
    






    
