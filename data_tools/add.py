import argparse
import json

import firebase_client_wrapper as fcw
import validate_code_scheme
import validate_message_structure

parser = argparse.ArgumentParser(description="Adds data items that don't currently exist, by id. "
                                             "Existing data items are untouched, even if they differ in content.")

parser.add_argument("firestore_credentials_file_path", metavar="firestore-credentials-file-path",
                    help="Path to the Firestore credentials file")
parser.add_argument("dataset_id", metavar="dataset-id", help="Id of dataset to add data to")
parser.add_argument("content_type", choices=["schemes", "messages"], help="Type of data to add")
parser.add_argument("path", help="Path to a JSON file containing the data to add")

args = parser.parse_args()

firestore_credentials_file_path = args.firestore_credentials_file_path
dataset_id = args.dataset_id
content_type = args.content_type
path = args.path

fcw.init_client(firestore_credentials_file_path)

dataset_ids = fcw.get_dataset_ids()

if dataset_id not in dataset_ids:
    print(f"WARNING: dataset {dataset_id} does not exist, this will create a new dataset")

json_data = json.loads(open(path).read())

if content_type == "users":
    pass  # Not implemented
elif content_type == "schemes":
    added = 0
    skipped_existing = 0

    existing_ids = fcw.get_code_scheme_ids(dataset_id)
    print(f"Existing Ids: {len(existing_ids)}")
    if json_data is list:
        schemes = json_data
    else:
        assert isinstance(json_data, dict)
        schemes = [json_data]
    
    for scheme in schemes:
        validate_code_scheme.verify_scheme(scheme)
        id = scheme["SchemeID"]
    
        if id in existing_ids:
            skipped_existing += 1
            continue

        fcw.set_code_scheme(dataset_id, scheme)
        print(f"Written: {id}")
        added += 1
    
    print(f"Added: {added}, Skipped: {skipped_existing}")
elif content_type == "messages":
    added = 0
    skipped_existing = 0
    all_messages = fcw.get_all_messages(dataset_id)

    existing_ids = set()
    highest_seq_no = -1
    for message in all_messages:
        existing_ids.add(message["MessageID"])
        if message["SequenceNumber"] > highest_seq_no:
            highest_seq_no = message["SequenceNumber"]

    messages_to_write = []
    for message in json_data:
        validate_message_structure.verify_message(message)
        id = message["MessageID"]
        if id in existing_ids:
            skipped_existing += 1
            continue
        if "SequenceNumber" not in message:
            highest_seq_no += 1
            message["SequenceNumber"] = highest_seq_no

        messages_to_write.append(message)
        added += 1
    
    print(f"To add: {added}, Skipping: {skipped_existing}")

    fcw.add_messages_content_batch(dataset_id, messages_to_write)
