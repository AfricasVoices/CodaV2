import firebase_client_wrapper as fcw
import predict_dataset_labels
import sys

if (len(sys.argv) != 3):
    print ("Usage python get.py crypto_token datasetid")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATASET_ID = sys.argv[2]

predict_dataset_labels.predict_labels_for_dataset(DATASET_ID)
