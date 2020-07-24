import firebase_client_wrapper as fcw

import json
import sys
from time import gmtime, strftime


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage python compute_coding_progress.py coda_crypto_token")
        exit(1)

    CODA_CRYPTO_TOKEN_PATH = sys.argv[1]
    fcw.init_client(CODA_CRYPTO_TOKEN_PATH)

    data = {}
    ids = fcw.get_segment_ids()
    data['coding_progress'] = {}
    for segment_id in ids:
        data['coding_progress'][segment_id] = fcw.compute_segment_coding_progress(segment_id)

    data["last_update"] = strftime("%Y-%m-%d %H:%M:%S", gmtime())
    print(json.dumps(data, indent=2))
