import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) < 2 or len(sys.argv) > 3):
    print ("Usage python backup.py crypto_token [dataset_id]")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

dataset_ids = fcw.get_dataset_ids()

if len(sys.argv) == 3:
    id = sys.argv[2]
    if id not in dataset_ids:
        sys.exit("Dataset: {} not found".format(id))
    dataset_ids = [id]

for dataset_id in dataset_ids:
    dataset = {
        "dataset_id": dataset_id,
        "segments": {}
    }

    segment_count = fcw.get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        segment_id = dataset_id
        dataset["segments"][segment_id] = {
            "users": fcw.get_segment_user_ids(dataset_id),
            "schemes": fcw.get_segment_code_schemes(segment_id),
            "messages": fcw.get_segment_messages(segment_id),
            "metrics": fcw.get_segment_metrics(segment_id)
        }
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = fcw.id_for_segment(dataset_id, segment_index)
            dataset["segments"][segment_id] = {
                "users": fcw.get_segment_user_ids(dataset_id),
                "schemes": fcw.get_segment_code_schemes(segment_id),
                "messages": fcw.get_segment_messages(segment_id),
                "metrics": fcw.get_segment_metrics(segment_id)
            }

    print(json.dumps(dataset, sort_keys=True))
