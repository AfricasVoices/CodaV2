import argparse
import warnings

from dateutil.parser import isoparse

import firebase_client_wrapper as fcw

import json

parser = argparse.ArgumentParser(description="Gets data from Coda's Firestore")

parser.add_argument("--previous-export-file-path",
                    help="Path to a previous export of messages data. If provided, only messages changed since this "
                         "export was created will be downloaded from Firestore, and the output data will be the "
                         "contents of the previous export, updated with the latest data from Firestore")
parser.add_argument("crypto_token_path", metavar="crypto-token-path",
                    help="Path to the Firestore credentials file")
parser.add_argument("dataset_id", metavar="dataset-id", help="Dataset to get data from")
parser.add_argument("content_type", metavar="content-type", choices=["all", "users", "schemes", "messages"],
                    help="Type of data to download")

args = parser.parse_args()

previous_export_file_path = args.previous_export_file_path
crypto_token_path = args.crypto_token_path
dataset_id = args.dataset_id
content_type = args.content_type

assert previous_export_file_path is None or content_type not in {"users", "schemes"}, \
    "Cannot use previous-export-file-path with content-type 'users' or 'schemes'"

fcw.init_client(crypto_token_path)

if content_type in ["all", "users"]:
    if content_type == "all":
        print("Users:")
    print(json.dumps(fcw.get_user_ids(dataset_id), indent=2))

if content_type in ["all", "schemes"]:
    if content_type == "all":
        print("Schemes:")
    schemes = fcw.get_all_code_schemes(dataset_id)
    print(json.dumps(schemes, indent=2))

if content_type in ["all", "messages"]:
    if content_type == "all":
        print("Messages:")

    previous_export = []
    last_updated = None
    if previous_export_file_path is not None:
        with open(previous_export_file_path) as f:
            previous_export = json.load(f)
        for msg in previous_export:
            if "LastUpdated" in msg and (last_updated is None or isoparse(msg["LastUpdated"]) > last_updated):
                last_updated = isoparse(msg["LastUpdated"])
        if last_updated is None:
            warnings.warn(f"Previous export file {previous_export_file_path} does not contain a message with a "
                          f"'LastUpdated' field; performing a full download of the entire dataset...")

    messages_dict = {msg["MessageID"]: msg for msg in previous_export}
    new_messages_dict = {msg["MessageID"]: msg for msg in fcw.get_all_messages(dataset_id, last_updated_after=last_updated)}
    messages_dict.update(new_messages_dict)

    messages = list(messages_dict.values())
    messages.sort(key=lambda msg: msg["SequenceNumber"])
    print(json.dumps(messages, indent=2))
