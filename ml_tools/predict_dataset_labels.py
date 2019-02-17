import firebase_client_wrapper as fcw

from datetime import datetime

from logger import log
import json
from core_data_modules.data_models import Scheme
from core_data_modules.data_models import Message
from core_data_modules.data_models import Label
from core_data_modules.data_models import Origin
import model_utils
import pytz


def predict_labels_for_dataset(dataset_id):
    DATASET_ID = dataset_id
    fcw.set_dataset_autolabel_complete(DATASET_ID, 0.0)

    log(f"Predicting labels for: {DATASET_ID}")

    code_scheme_ids = fcw.get_code_scheme_ids(DATASET_ID)

    log(f"Code_Scheme_IDs for: {code_scheme_ids}")

    code_schemes = {}
    for code_scheme_id in code_scheme_ids:
        fb_map_scheme = fcw.get_code_scheme(DATASET_ID, code_scheme_id)
        code_schemes[code_scheme_id] = Scheme.from_firebase_map(fb_map_scheme)

    log(f"Code_schemes: {len(code_schemes)}")

    messages_fb = fcw.get_all_messages(DATASET_ID)
    messages = []

    seq_num_map = {}


    for message_fb in messages_fb:
        seq_num_map[message_fb["MessageID"]] = message_fb["SequenceNumber"]
        # Work around interpretation with firebase rewriting '1.0' to '1'
        for label_map in message_fb["Labels"]:
            label_map["Confidence"] = float(label_map["Confidence"])

        messages.append(Message.from_firebase_map(message_fb))

    log(f"Messages: {len(messages)}")

    for scheme_id in code_scheme_ids:
        log(f"Processing scheme: {scheme_id}")

        messages_for_model = []
        labels_for_model = []
        for message in messages:
            for label in message.labels:
                if label.scheme_id != scheme_id:
                    continue
                if label.code_id == "SPECIAL-MANUALLY_UNCODED":
                    continue
                if not label.checked:
                    continue
                
                messages_for_model.append(message.text)
                labels_for_model.append(label.code_id)
                break

        log(f"Messages for model: {len(labels_for_model)}")

        model, scores = model_utils.build_and_evaluate(messages_for_model, labels_for_model)

        log(f"Model built")
        log(f"Scores: {str(scores)}")

        dt_time = pytz.utc.localize(datetime.utcnow()).isoformat(timespec="microseconds")
        origin = Origin("label_predictor", "Label Predictor", "Automatic")

        messages_to_predict = []
        message_update_batch = []
        i = 0
        for message in messages:
            i = i + 1
            if i % 100 == 0:
                fcw.set_dataset_autolabel_complete(DATASET_ID, i / len(messages))
                # print (f"{i} messages / {len(messages)} processed")

            if len(message.labels) != 0:
                continue
            msg = message.text

            pred_label = model.predict([msg])[0]
            pred_distance = model.decision_function([msg])[0]

            max_distance = max(pred_distance)
            max_confidence = (max_distance + 100) / 200
            if (max_confidence > 0.6):
                label = Label(scheme_id, pred_label, dt_time, origin, confidence=max_confidence)
                message.labels = [label]
                firebase_map = message.to_firebase_map()
                firebase_map["SequenceNumber"] = seq_num_map[message.message_id]
                message_update_batch.append(firebase_map)

                if (len(message_update_batch) > 100):
                    fcw.set_messages_content_batch(DATASET_ID, message_update_batch)
                    log (f"Messages updated {len(message_update_batch)}")
                    message_update_batch.clear()

                # fcw.set_messages_content(DATASET_ID, [firebase_map])

        fcw.set_messages_content_batch(DATASET_ID, message_update_batch)
        log (f"Messages updated {len(message_update_batch)}")
        fcw.set_dataset_autolabel_complete(DATASET_ID, 1.0)

