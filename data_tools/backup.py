import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) != 2):
    print ("Usage python backup.py crypto_token")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

data = {}

ids = fcw.get_dataset_ids()

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

