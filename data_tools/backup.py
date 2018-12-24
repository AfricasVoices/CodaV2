import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) < 2 or len(sys.argv) > 3):
    print ("Usage python backup.py crypto_token [dataset_id]")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

if len(sys.argv) == 3:
    ids = [sys.argv[2]]
else:
    ids = fcw.get_dataset_ids()

data = {}

for id in ids:
    data[id] = {}
    data[id]["users"] = fcw.get_user_ids(id)
    schemes = []
    for scheme in fcw.get_code_scheme_ids(id):
        schemes.append(fcw.get_code_scheme(id, scheme))
    data[id]["schemes"] = schemes
    
    messages = []
    for message in fcw.get_all_messages(id):
        messages.append(message)

    data[id]["messages"] = messages

print (json.dumps(data, indent=2))

