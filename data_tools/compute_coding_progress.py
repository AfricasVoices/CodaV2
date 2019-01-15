import firebase_client_wrapper as fcw

import json
import sys
from time import gmtime, strftime

def compute_coding_progress(DATASET_ID, force_recount=False):
    """Compute and return the progress metrics for a given dataset.
    This method will initialise the counts in Firestore if they do
    not already exist."""
    messages = []
    messages_with_labels = 0

    # New scheme
    metrics = fcw.get_dataset_metrics(DATASET_ID)
    if force_recount == False and metrics != None:
        return metrics 
    
    metrics = {}

    for message in fcw.get_all_messages(DATASET_ID):
        messages.append(message)
        if len(message["Labels"]) > 0:
            messages_with_labels += 1

    metrics['messages_count'] = len(messages)
    metrics['messages_with_label'] = messages_with_labels
        
    # Write the metrics back if they weren't stored
    fcw.set_dataset_metrics(DATASET_ID, metrics)
    return metrics

if __name__ == "__main__":
    if (len(sys.argv) != 2):
        print ("Usage python compute_coding_progress.py coda_crypto_token")
        exit(1)

    CODA_CRYPTO_TOKEN_PATH = sys.argv[1]
    fcw.init_client(CODA_CRYPTO_TOKEN_PATH)

    data = {}
    ids = fcw.get_dataset_ids()
    data['coding_progress'] = {}
    for DATASET_ID in ids:
        data['coding_progress'][DATASET_ID] = compute_coding_progress(DATASET_ID)

    data["last_update"] = strftime("%Y-%m-%d %H:%M:%S", gmtime())
    print (json.dumps(data, indent=2))
