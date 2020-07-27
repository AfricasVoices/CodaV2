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


def ensure_user_ids_consistent(dataset_id):
    # Perform a consistency check on the other segments if they exist
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        return

    first_segment_users = get_segment(dataset_id).get("users")
    for segment_index in range(2, segment_count + 1):
        segment_id = id_for_segment(dataset_id, segment_index)
        assert set(get_segment_user_ids(segment_id)) == set(first_segment_users), \
            f"Segment {segment_id} has different users to the first segment {dataset_id}"


def get_segment_user_ids(segment_id):
    return get_segment(segment_id).get("users")


def get_user_ids(dataset_id):
    ensure_user_ids_consistent(dataset_id)

    users = get_segment(dataset_id).get("users")
    return users


def get_code_scheme_ids(dataset_id):
    return [scheme["SchemeID"] for scheme in get_all_code_schemes(dataset_id)]


def ensure_code_schemes_consistent(dataset_id):
    # Checks that the code schemes are the same in all segments
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        return

    first_segment_schemes = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(dataset_id)).get():
        first_segment_schemes.append(scheme.to_dict())

    for segment_index in range(2, segment_count + 1):
        segment_id = id_for_segment(dataset_id, segment_index)

        current_segment_schemes = []
        for scheme in client.collection(u'datasets/{}/code_schemes'.format(segment_id)).get():
            current_segment_schemes.append(scheme.to_dict())

        assert len(first_segment_schemes) == len(current_segment_schemes), \
            f"Segment {segment_id} has a different number of schemes to the first segment {dataset_id}"

        first_segment_schemes.sort(key=lambda s: s["SchemeID"])
        current_segment_schemes.sort(key=lambda s: s["SchemeID"])
        for x, y in zip(first_segment_schemes, current_segment_schemes):
            assert json.dumps(x, sort_keys=True) == json.dumps(y, sort_keys=True), \
                f"Segment {segment_id} has different schemes to the first segment {dataset_id}"


def get_segment_code_schemes(segment_id):
    schemes = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(segment_id)).get():
        schemes.append(scheme.to_dict())
    return schemes


def get_all_code_schemes(dataset_id):
    ensure_code_schemes_consistent(dataset_id)

    schemes = []
    for scheme in client.collection(u'datasets/{}/code_schemes'.format(dataset_id)).get():
        schemes.append(scheme.to_dict())
    return schemes


def get_code_scheme(dataset_id, scheme_id):
    ensure_code_schemes_consistent(dataset_id)

    scheme = get_segment_code_scheme_ref(dataset_id, scheme_id).get().to_dict()
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
        msg = message.to_dict()
        if "LastUpdated" in msg:
            msg["LastUpdated"] = msg["LastUpdated"].isoformat(timespec="microseconds")
        messages.append(msg)

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


def set_segment_metrics(segment_id, metrics_map):
    message_metrics_ref = client.document(u'datasets/{}/metrics/messages'.format(segment_id))
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


def add_and_update_code_schemes(dataset_id, schemes):
    # TODO: Implement more efficiently
    for scheme in schemes:
        set_code_scheme(dataset_id, scheme)


def restore_segment_messages_content_batch(dataset_id, messages, segment_index=None, batch_size=500):
    # Note: restore uploads its inputs unchanged, so does not update the 'LastUpdated' field.
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


def add_and_update_dataset_messages_content_batch(dataset_id, messages, batch_size=500):
    # Get existing messages by segment, so we then find:
    #   - The location and sequence number of existing messages.
    #   - The highest existing sequence number, for tagging new messages that don't have sequence numbers.
    existing_segment_messages = dict()  # of segment id -> list of Message
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        existing_segment_messages[dataset_id] = get_segment_messages(dataset_id)
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            existing_segment_messages[segment_id] = get_segment_messages(segment_id)
            
    # Search the existing messages for the highest seen sequence number, and create a dictionary of
    # message id -> segment for existing messages.
    highest_seq_no = -1
    message_id_to_segment_id = dict()
    message_id_to_sequence_number = dict()
    for segment_id, segment_messages in existing_segment_messages.items():
        for msg in segment_messages:
            message_id_to_segment_id[msg["MessageID"]] = segment_id
            message_id_to_sequence_number[msg["MessageID"]] = msg["SequenceNumber"]
            if msg["SequenceNumber"] > highest_seq_no:
                highest_seq_no = msg["SequenceNumber"]
    print(f"Existing Ids: {len(message_id_to_segment_id)}")
    print(f"Highest seen sequence number: {highest_seq_no}")

    # Categorise the changed messages into updated and new messages.
    updated_messages = []
    new_messages = []
    for msg in messages:
        if msg["MessageID"] in message_id_to_segment_id:
            updated_messages.append(msg)
        else:
            new_messages.append(msg)
    print(f"Updating {len(updated_messages)} existing messages; adding {len(new_messages)} new messages...")

    # Commit the updated messages.
    batch = client.batch()
    batch_counter = 0
    for i, msg in enumerate(updated_messages):
        msg = msg.copy()
        if "SequenceNumber" not in msg:
            msg["SequenceNumber"] = message_id_to_sequence_number[msg["MessageID"]]
        assert msg["SequenceNumber"] == message_id_to_sequence_number[msg["MessageID"]]
        msg["LastUpdated"] = firestore.firestore.SERVER_TIMESTAMP

        batch.set(get_message_ref(message_id_to_segment_id[msg["MessageID"]], msg["MessageID"]), msg)

        batch_counter += 1
        if batch_counter >= batch_size / 2:  # Each document costs 2 writes due to the additional write needed by the server to set LastUpdated
            batch.commit()
            print(f"Batch of {batch_counter} updated messages committed, progress: {i + 1} / {len(updated_messages)}")
            batch_counter = 0
            batch = client.batch()
    if batch_counter > 0:
        batch.commit()
        print(f"Final batch of {batch_counter} updated messages committed")

    # Commit the new messages.
    batch = client.batch()
    batch_counter = 0
    next_seq_no = highest_seq_no + 1
    latest_segment_index = segment_count
    latest_segment_size = len(existing_segment_messages[id_for_segment(dataset_id, latest_segment_index)])
    for i, msg in enumerate(new_messages):
        msg = msg.copy()
        msg["LastUpdated"] = firestore.firestore.SERVER_TIMESTAMP

        if latest_segment_size >= MAX_SEGMENT_SIZE:
            create_next_segment(dataset_id)
            latest_segment_index = get_segment_count(dataset_id)
            latest_segment_size = 0
            existing_segment_messages[id_for_segment(dataset_id, latest_segment_index)] = []

        if "SequenceNumber" not in msg:
            msg["SequenceNumber"] = next_seq_no
            next_seq_no += 1

        segment_id = id_for_segment(dataset_id, latest_segment_index)
        batch.set(get_message_ref(segment_id, msg["MessageID"]), msg)
        existing_segment_messages[segment_id].append(msg)
        latest_segment_size += 1

        batch_counter += 1
        if batch_counter >= batch_size / 2:  # Each document costs 2 writes due to the additional write needed by the server to set LastUpdated
            batch.commit()
            print(f"Batch of {batch_counter} new messages committed, progress: {i + 1} / {len(new_messages)}")
            batch_counter = 0
            batch = client.batch()
    if batch_counter > 0:
        batch.commit()
        print(f"Final batch of {batch_counter} new messages committed")

    if segment_count is None or segment_count == 1:
        compute_segment_coding_progress(dataset_id, existing_segment_messages[dataset_id], True)
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            compute_segment_coding_progress(segment_id, existing_segment_messages[segment_id], True)


def compute_segment_coding_progress(segment_id, messages=None, force_recount=False):
    """Compute and return the progress metrics for a given dataset.
    This method will initialise the counts in Firestore if they do
    not already exist."""
    if not force_recount:
        segment_metrics = get_segment_metrics(segment_id)
        if segment_metrics is not None:
            return segment_metrics

    print(f"Performing a full recount of the metrics for segment {segment_id}...")
    if messages is None:
        messages = get_segment_messages(segment_id)
    messages_with_labels = 0
    wrong_scheme_messages = 0
    not_coded_messages = 0

    schemes = {scheme["SchemeID"]: scheme for scheme in get_all_code_schemes(segment_id)}

    for message in messages:
        # Get the latest label from each scheme
        latest_labels = dict()  # of scheme id -> label
        for label in message["Labels"]:
            if label["SchemeID"] not in latest_labels:
                latest_labels[label["SchemeID"]] = label

        # Test if the message has a label (that isn't SPECIAL-MANUALLY_UNCODED), and
        # if any of the latest labels are either WS or NC
        message_has_label = False
        message_has_ws = False
        message_has_nc = False
        for label in latest_labels.values():
            if label["CodeID"] == "SPECIAL-MANUALLY_UNCODED":
                continue

            if not label["Checked"]:
                continue

            message_has_label = True
            scheme_for_label = schemes[label["SchemeID"]]
            code_for_label = None
            for code in scheme_for_label["Codes"]:
                if label["CodeID"] == code["CodeID"]:
                    code_for_label = code
            assert code_for_label is not None

            if code_for_label["CodeType"] == "Control":
                if code_for_label["ControlCode"] == "WS":
                    message_has_ws = True
                if code_for_label["ControlCode"] == "NC":
                    message_has_nc = True

        # Update counts appropriately
        if message_has_label:
            messages_with_labels += 1
        if message_has_ws:
            wrong_scheme_messages += 1
        if message_has_nc:
            not_coded_messages += 1

    metrics = {
        "messages_count": len(messages),
        "messages_with_label": messages_with_labels,
        "wrong_scheme_messages": wrong_scheme_messages,
        "not_coded_messages": not_coded_messages
    }

    # Write the metrics back if they weren't stored
    set_segment_metrics(segment_id, metrics)
    return metrics


def compute_coding_progress(dataset_id, force_recount=False):
    segment_count = get_segment_count(dataset_id)
    if segment_count is None or segment_count == 1:
        compute_segment_coding_progress(dataset_id, force_recount=force_recount)
    else:
        for segment_index in range(1, segment_count + 1):
            segment_id = id_for_segment(dataset_id, segment_index)
            compute_segment_coding_progress(segment_id, force_recount=force_recount)


def delete_segment(segment_id):
    # Delete code schemes
    segment_code_schemes_path = f"datasets/{segment_id}/code_schemes"
    print(f"Deleting {segment_code_schemes_path}...")
    _delete_collection(client.collection(segment_code_schemes_path), 500)

    # Delete messages
    segment_messages_path = f"datasets/{segment_id}/messages"
    print(f"Deleting {segment_messages_path}...")
    _delete_collection(client.collection(segment_messages_path), 500)

    # Delete metrics
    segment_metrics_path = f"datasets/{segment_id}/metrics"
    print(f"Deleting {segment_metrics_path}...")
    _delete_collection(client.collection(segment_metrics_path), 500)

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
    add_and_update_code_schemes(next_segment_id, code_schemes)

    users = get_user_ids(current_segment_id)
    set_user_ids(next_segment_id, users)

    set_segment_count(dataset_id, next_segment_count)

    for x in range(0, 10):
        if get_segment_count(dataset_id) == next_segment_count:
            return
        print("New segment count not yet committed, waiting 1s before retrying")
        time.sleep(1)
    assert False, "Server segment count did not update to the newest count fast enough"
