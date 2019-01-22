import firebase_client_wrapper as fcw

import json
import sys

if (len(sys.argv) != 3):
    print ("Usage python push_coding_progress.py dashboard_crypto_token progress_file")
    exit(1)

DASHBOARD_CRYPTO_TOKEN_PATH = sys.argv[1]
PROGRESS_FILE = sys.argv[2]

fcw.init_client(DASHBOARD_CRYPTO_TOKEN_PATH)
data = json.load(open(PROGRESS_FILE, 'r'))
fcw.push_coding_status(data)
