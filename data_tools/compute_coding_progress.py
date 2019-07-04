import firebase_client_wrapper as fcw

import json
import sys
from time import gmtime, strftime


def compute_coding_progress(dataset_id, force_recount=False):
    """Compute and return the progress metrics for a given dataset.
    This method will initialise the counts in Firestore if they do
    not already exist."""
    messages = []
    messages_with_labels = 0
    wrong_scheme_messages = 0
    not_coded_messages = 0

    # New scheme
    metrics = fcw.get_dataset_metrics(dataset_id)
    if not force_recount and metrics is not None:
        return metrics

    metrics = {}

    schemes = {scheme["SchemeID"]: scheme for scheme in fcw.get_all_code_schemes(dataset_id)}

    for message in fcw.get_all_messages(dataset_id):
        messages.append(message)
        if len(message["Labels"]) > 0:
            messages_with_labels += 1

        # Get the latest label from each scheme
        latest_labels = dict()  # of scheme id -> label
        for label in message["Labels"]:
            if label["SchemeID"] not in latest_labels:
                latest_labels["SchemeID"] = label

        # Test if any of the latest labels are either WS or NC
        message_has_ws = False
        message_has_nc = False
        for label in latest_labels.values():
            scheme_for_label = schemes[label["SchemeID"]]
            code_for_label = None
            for code in scheme_for_label["Codes"]:
                if label["CodeID"] == code["CodeID"]:
                    code_for_label = code

            if code_for_label["CodeType"] == "Control":
                if code_for_label["ControlCode"] == "WS":
                    message_has_ws = True
                if code_for_label["ControlCode"] == "NC":
                    message_has_nc = True

        # Update counts appropriately
        if message_has_ws:
            wrong_scheme_messages += 1
        if message_has_nc:
            not_coded_messages += 1

    metrics['messages_count'] = len(messages)
    metrics['messages_with_label'] = messages_with_labels
    metrics['wrong_scheme_messages'] = wrong_scheme_messages
    metrics['not_coded_messages'] = not_coded_messages

    # Write the metrics back if they weren't stored
    fcw.set_dataset_metrics(dataset_id, metrics)
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
    for dataset_id in ids:
        data['coding_progress'][dataset_id] = compute_coding_progress(dataset_id)

    data["last_update"] = strftime("%Y-%m-%d %H:%M:%S", gmtime())
    print (json.dumps(data, indent=2))
