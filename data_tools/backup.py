import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) < 2 or len(sys.argv) > 3):
    print ("Usage python backup.py crypto_token [dataset_id]")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

ids = fcw.get_segment_ids()

if len(sys.argv) == 3:
    id = sys.argv[2]
    if id not in ids:
        sys.exit("Dataset: {} not found".format(id))
    ids = []
    for segment_index in range(0, fcw.get_segment_count(id)):
        ids.append(fcw.id_for_segment(id, segment_index))

data = {
    "segments": {},
    "segment_counts": {}
}

for segment_id in ids:
    data["segments"][segment_id] = {
        "users": fcw.get_user_ids(segment_id),
        "schemes": fcw.get_all_code_schemes(segment_id),
        "messages": fcw.get_all_messages(segment_id)
    }

for dataset_id in fcw.get_segmented_dataset_ids():
    data["segment_counts"][dataset_id] = fcw.get_segment_count(dataset_id)

print(json.dumps(data, indent=2, sort_keys=True))

