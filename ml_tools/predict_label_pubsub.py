import firebase_client_wrapper as fcw
import predict_dataset_labels
import sys
import os
import json
from google.cloud import pubsub_v1

if (len(sys.argv) != 2):
    print ("Usage python get.py crypto_token")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

project_id = json.load(open(CRYPTO_TOKEN_PATH))["project_id"]
TOPIC= project_id + "-test-topic"
SUBSCRIPTION= project_id + "-test-subscription"



subscriber = pubsub_v1.SubscriberClient.from_service_account_json(CRYPTO_TOKEN_PATH)
topic_name = 'projects/{project_id}/topics/{topic}'.format(
    project_id=project_id,
    topic=TOPIC,
)
subscription_name = 'projects/{project_id}/subscriptions/{sub}'.format(
    project_id=project_id,
    sub=SUBSCRIPTION, 
)

# Setup

publisher = pubsub_v1.PublisherClient.from_service_account_json(CRYPTO_TOKEN_PATH)

try:
    response = client.create_topic(topic_name)
    print (f"topic created: {topic_name}")
except:
    print (f"Error on topic creation for {topic_name}: {sys.exc_info()[0]}")

try:
    subscriber.create_subscription(name=subscription_name, topic=topic_name)
    print (f"Subscription created: {subscription_name}")
except:
    print (f"Error on subscription creation for {subscription_name}: {sys.exc_info()[0]}")
    
print ("Setup complete")
    
def callback(message):
    print (f"Processing: {message}")

    # Processing: Message {
    #     data: b'{"data":{"message":"books2"}}'
    #     attributes: {}
    # }

    dataset_id = json.loads(message.data.decode('utf-8'))["data"]["message"]

    print (f"About to predict labels for {dataset_id}")
    predict_dataset_labels.predict_labels_for_dataset(dataset_id)
    message.ack()

future = subscriber.subscribe(subscription_name, callback)

try:
    r = future.result()
    print (r)
except KeyboardInterrupt:
    future.cancel()

