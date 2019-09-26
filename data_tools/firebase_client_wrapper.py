import json
import time

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

client = None

# TODO: Set from a program argument
MAX_SEGMENT_SIZE = 2500


def init_client(crypto_token_path):
    global client
    cred = credentials.Certificate(crypto_token_path)
    firebase_admin.initialize_app(cred)
    client = firestore.client()


def id_for_segment(dataset_id, segment_index=None):
    if segment_index is None or segment_index == 1:
        return dataset_id
    return dataset_id + f'_{segment_index}'


def get_segment_ids():
    ids = []
    for segment in client.collection(u'datasets').get():
        ids.append(segment.id)
    return ids


def get_dataset_ids():
    # Get the dataset ids by retrieving all the segment ids then removing those that are not the first segment.
    segment_ids = get_segment_ids()
    assert len(segment_ids) == len(set(segment_ids)), "Segment ids not unique"

    dataset_ids = set(segment_ids)
    for dataset_id in get_segmented_dataset_ids():
        segment_count = get_segment_count(dataset_id)
        if segment_count is not None and segment_count > 1:
            for segment_index in range(2, segment_count + 1):
                dataset_ids.remove(id_for_segment(dataset_id, segment_index))

    return dataset_ids


def get_segment_ref(segment_id):
    return client.document(u'datasets/{}'.format(segment_id))


def get_segment(segment_id):
    return get_segment_ref(segment_id).get()


def get_segment_user_ids(segment_id):
    return get_segment(segment_id).get("users")


def get_user_ids(dataset_id):
    users = get_segment(dataset_id).get("users")

    # Perform a consistency check on the other segments if they exist
    segment_count = get_segment_count(dataset_id)
    if segment_count is not None and segment_count > 1:
        for segment_index in range(2, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            assert set(get_segment_user_ids(segment_id)) == set(users), \
                f"Segment {segment_id} has different users to the first segment {dataset_id}"

    return users


def get_code_scheme_ids(dataset_id):
    return [scheme["SchemeID"] for scheme in get_all_code_schemes(dataset_id)]


def get_all_code_schemes(dataset_id):
    schemes = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(dataset_id)).get():
        schemes.append(scheme.to_dict())

    # Perform a consistency check on the other segments if they exist
    segment_count = get_segment_count(dataset_id)
    if segment_count is not None and segment_count > 1:
        for segment_index in range(2, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)

            segment_schemes = []
            for scheme in client.collection(u'datasets/{}/code_schemes'.format(segment_id)).get():
                segment_schemes.append(scheme.to_dict())

            assert len(schemes) == len(segment_schemes), \
                f"Segment {segment_id} has a different number of schemes to the first segment {dataset_id}"

            schemes.sort(key=lambda s: s["SchemeID"])
            segment_schemes.sort(key=lambda s: s["SchemeID"])
            for x, y in zip(schemes, segment_schemes):
                assert json.dumps(x, sort_keys=True) == json.dumps(y, sort_keys=True), \
                    f"Segment {segment_id} has different schemes to the first segment {dataset_id}"

    return schemes


def get_code_scheme(dataset_id, scheme_id):
    scheme = client.document(u'datasets/{}/code_schemes/{}'.format(dataset_id, scheme_id)).get().to_dict()

    # Perform a consistency check on the other segments if they exist
    segment_count = get_segment_count(dataset_id)
    if segment_count is not None and segment_count > 1:
        for segment_index in range(2, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            segment_scheme = client.document(u'datasets/{}/code_schemes/{}'.format(segment_id, scheme_id)).get().to_dict()

            assert json.dumps(scheme, sort_keys=True) == json.dumps(segment_scheme, sort_keys=True), \
                f"Segment {segment_id} has a different scheme {scheme['SchemeID']} to the first segment {dataset_id}"

    return scheme


def get_segment_code_scheme_ref(segment_id, scheme_id):
    return client.document(u'datasets/{}/code_schemes/{}'.format(segment_id, scheme_id))


def get_segment_message_ids(segment_id):
    ids = []
    for message in client.collection(u'datasets/{}/messages'.format(segment_id)).get():
        ids.append(message.id)
    return ids


def get_message_ids(dataset_id):
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        return get_segment_message_ids(dataset_id)
    else:
        message_ids = set()
        for segment_index in range(1, segment_count + 1):
            segment_ids = get_segment_messages(id_for_segment(dataset_id, segment_index))
            for segment_id in segment_ids:
                assert segment_id not in message_ids, "Duplicate message id found"
            message_ids.update(segment_ids)
        return message_ids


# This is a much faster way of reading an entire dataset rather than repeated get_message calls
def get_segment_messages(segment_id):
    messages = []
    for message in client.collection(u'datasets/{}/messages'.format(segment_id)).get():
        messages.append(message.to_dict())
    return messages


def get_all_messages(dataset_id):
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        return get_segment_messages(dataset_id)
    else:
        messages = []
        for segment_index in range(1, segment_count + 1):
            messages.extend(get_segment_messages(id_for_segment(dataset_id, segment_index)))

        message_ids = set()
        for message in messages:
            assert message["MessageID"] not in message_ids, "Duplicate message found"
            message_ids.add(message["MessageID"])

        return messages


def get_message_ref(segment_id, message_id):
    return client.document(u'datasets/{}/messages/{}'.format(segment_id, message_id))


def push_coding_status(coding_status):
    client.document(u'metrics/coda').set(coding_status)


def get_segment_metrics(segment_id):
    return client.document(u'datasets/{}/metrics/messages'.format(segment_id)).get().to_dict()


def set_segment_metrics(dataset_id, metrics_map):
    message_metrics_ref = client.document(u'datasets/{}/metrics/messages'.format(dataset_id))
    message_metrics_ref.set(metrics_map)


def set_user_ids(dataset_id, user_ids):
    segment_count = get_segment_count(dataset_id)
    batch = client.batch()
    if segment_count is None or segment_count == 1:
        batch.set(get_segment_ref(dataset_id), {"users": user_ids})
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            batch.set(get_segment_ref(segment_id), {"users": user_ids})
    batch.commit()
    print(f"Wrote users to dataset {dataset_id}")


def set_code_scheme(dataset_id, scheme):
    scheme_id = scheme["SchemeID"]
    segment_count = get_segment_count(dataset_id)
    batch = client.batch()
    if segment_count is None or segment_count == 1:
        batch.set(get_segment_code_scheme_ref(dataset_id, scheme_id), scheme)
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            batch.set(get_segment_code_scheme_ref(segment_id, scheme_id), scheme)
    batch.commit()
    print("Wrote scheme: {}".format(scheme_id))


def set_all_code_schemes(dataset_id, schemes):
    # TODO: Implement more efficiently
    # TODO: Rename this (and all other set functions that don't really set) to add_and_update...
    for scheme in schemes:
        set_code_scheme(dataset_id, scheme)


def set_segment_messages_content_batch(dataset_id, messages, segment_index=None, batch_size=500):
    dataset_id = id_for_segment(dataset_id, segment_index)

    total_messages_count = len(messages)
    i = 0
    batch_counter = 0
    batch = client.batch()
    for message in messages:
        i += 1
        id = message["MessageID"]
        batch.set(get_message_ref(dataset_id, id), message)
        batch_counter += 1
        if batch_counter >= batch_size:
            batch.commit()
            print("Batch of {} messages committed, progress: {} / {}".format(batch_counter, i, total_messages_count))
            batch_counter = 0
            batch = client.batch()

    if batch_counter > 0:
        batch.commit()
        print("Final batch of {} messages committed".format(batch_counter))

    print("Written {} messages".format(i))


def set_dataset_messages_content_batch(dataset_id, messages, batch_size=500):
    next_batch_to_write = []
    latest_segment_index = get_segment_count(dataset_id)
    latest_segment_size = len(get_segment_messages(id_for_segment(dataset_id, latest_segment_index)))
    for message in messages:
        if latest_segment_size >= MAX_SEGMENT_SIZE:
            set_segment_messages_content_batch(
                dataset_id, next_batch_to_write, segment_index=get_segment_count(dataset_id), batch_size=batch_size)
            next_batch_to_write = []
            create_next_segment(dataset_id)
            latest_segment_size = 0
        next_batch_to_write.append(message)
        latest_segment_size += 1

    set_segment_messages_content_batch(
        dataset_id, next_batch_to_write, segment_index=get_segment_count(dataset_id), batch_size=batch_size)


def delete_segment(segment_id):
    # Delete code schemes
    segment_code_schemes_path = f"datasets/{segment_id}/code_schemes"
    print(f"Deleting {segment_code_schemes_path}...")
    _delete_collection(client.collection(segment_code_schemes_path), 10)

    # Delete messages
    segment_messages_path = f"datasets/{segment_id}/messages"
    print(f"Deleting {segment_messages_path}...")
    _delete_collection(client.collection(segment_messages_path), 10)

    # Delete metrics
    segment_metrics_path = f"datasets/{segment_id}/metrics"
    print(f"Deleting {segment_metrics_path}...")
    _delete_collection(client.collection(segment_metrics_path), 10)

    # Delete segment
    get_segment_ref(segment_id).delete()

    print(f"Deleted segment {segment_id}")


def delete_dataset(dataset_id):
    # Delete segments
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        delete_segment(dataset_id)
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            delete_segment(segment_id)

    # Delete segment count record if it exists
    client.document(f"segment_counts/{dataset_id}").delete()

    print(f"Deleted dataset {dataset_id}")


def _delete_collection(coll_ref, batch_size):
    docs = coll_ref.limit(batch_size).get()
    deleted = 0
    for doc in docs:
        print(u'Deleting doc {} => {}'.format(doc.id, doc.to_dict()))
        doc.reference.delete()
        deleted = deleted + 1

    if deleted >= batch_size:
        return _delete_collection(coll_ref, batch_size)


def delete_unchecked_messages_in_segment(segment_id):
    messages = get_segment_messages(segment_id)
    messages.sort(key=lambda msg: msg["SequenceNumber"])
    
    deleted_count = 0
    for msg in messages:
        # Get the latest label from each scheme
        latest_labels = dict()  # of scheme id -> label
        for label in msg["Labels"]:
            if label["SchemeID"] not in latest_labels:
                latest_labels[label["SchemeID"]] = label

        manually_coded = False
        for label in latest_labels.values():
            if label["Checked"]:
                manually_coded = True
                break

        if not manually_coded:
            print(f"Deleting message with sequence number: {msg['SequenceNumber']}")
            client.document(f"datasets/{segment_id}/messages/{msg['MessageID']}").delete()
            deleted_count += 1
    print(f"Deleted {deleted_count} messages from segment {segment_id}")


def delete_unchecked_messages(dataset_id):
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        delete_unchecked_messages_in_segment(dataset_id)
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            delete_unchecked_messages_in_segment(segment_id)


def get_segmented_dataset_ids():
    # Return the ids of datasets which have been segmented i.e. which have a definition
    # in the /segment_counts collection
    segmented_dataset_ids = []
    for x in client.collection("segment_counts").get():
        segmented_dataset_ids.append(x.id)
    return segmented_dataset_ids


def get_segment_count(dataset_id):
    segment_count_doc = client.document(f'segment_counts/{dataset_id}').get().to_dict()
    if segment_count_doc is None:
        return None
    return segment_count_doc["segment_count"]


def set_segment_count(dataset_id, segment_count):
    client.document(f'segment_counts/{dataset_id}').set({"segment_count": segment_count})


def create_next_segment(dataset_id):
    segment_count = get_segment_count(dataset_id)

    if segment_count is None:
        current_segment_id = f"{dataset_id}"
        next_segment_id = f"{dataset_id}_2"
        next_segment_count = 2
    else:
        current_segment_id = f"{dataset_id}_{segment_count}"
        next_segment_id = f"{dataset_id}_{segment_count + 1}"
        next_segment_count = segment_count + 1

    print(f"Creating next dataset segment with id {next_segment_id}")

    code_schemes = get_all_code_schemes(current_segment_id)
    set_all_code_schemes(next_segment_id, code_schemes)

    users = get_user_ids(current_segment_id)
    set_user_ids(next_segment_id, users)

    set_segment_count(dataset_id, next_segment_count)

    for x in range(0, 10):
        if get_segment_count(dataset_id) == next_segment_count:
            return
        print("New segment count not yet committed, waiting 1s before retrying")
        time.sleep(1)
    assert False, "Server segment count did not update to the newest count fast enough"
