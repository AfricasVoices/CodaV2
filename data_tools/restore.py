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

data = json.load(open(BACKUP_PATH, 'r'))

existing_ids = fcw.get_dataset_ids()

if len(existing_ids) > 0:
    print ("Target Firestore still has datasets, can't restore. Please delete all existing data first:")
    print ("Run:")
    print ("firebase -P {} firestore:delete -r datasets".format(project_id))
    print ("")
    exit (1)

for dataset_id in data.keys():
    print ("Starting to restore {}".format(dataset_id))
    fcw.set_user_ids(dataset_id, data[dataset_id]["users"])
    for scheme in data[dataset_id]["schemes"]:
        fcw.set_code_scheme(dataset_id, scheme)
    fcw.add_and_update_dataset_messages_content_batch(dataset_id, data[dataset_id]["messages"])
    print ("Restore complete: {}".format(dataset_id))

