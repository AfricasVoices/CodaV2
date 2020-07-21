import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) != 3):
    print ("Usage python restore.py crypto_token backup_file")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
BACKUP_PATH = sys.argv[2]

fcw.init_client(CRYPTO_TOKEN_PATH)
project_id = json.load(open(CRYPTO_TOKEN_PATH, 'r'))["project_id"]

existing_segmented_dataset_ids = fcw.get_segmented_dataset_ids()
if len(existing_segmented_dataset_ids) > 0:
    print("Target Firestore still has segment_counts, can't restore. Please delete all existing data first:")
    print("Run:")
    print("firebase -P {} firestore:delete -r segment_counts".format(project_id))
    print("")
    exit(1)

existing_ids = fcw.get_dataset_ids()
if len(existing_ids) > 0:
    print ("Target Firestore still has datasets, can't restore. Please delete all existing data first:")
    print ("Run:")
    print ("firebase -P {} firestore:delete -r datasets".format(project_id))
    print ("")
    exit (1)

with open(BACKUP_PATH, 'r') as f:
    for line in f:
        dataset = json.loads(line)
        dataset_id = dataset["dataset_id"]
        print(f"Restoring dataset {dataset_id}")

        for segment_id, segment in dataset["segments"].items():
            print(f"Starting to restore segment {segment_id}")
            fcw.set_user_ids(segment_id, segment["users"])
            for scheme in segment["schemes"]:
                fcw.set_code_scheme(segment_id, scheme)
            fcw.restore_segment_messages_content_batch(segment_id, segment["messages"])
            fcw.set_segment_metrics(segment_id, segment["metrics"])
            print(f"Restore complete: segment {segment_id}")

        print(f"Starting to restore segment_counts for dataset {dataset_id}")
        segment_count = len(dataset["segments"])
        if segment_count > 1:
            fcw.set_segment_count(dataset_id, segment_count)
        print(f"Restore complete: segment_counts for dataset {dataset_id}")
        print(f"Restored dataset {dataset_id}")
