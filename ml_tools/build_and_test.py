# Builds a topic classifier and computes precision and recall
# (scores.json +) labelled_dataset.json -> model.pkl

import pickle
import json
import argparse
import random

from logger import log
import model_utils

MINIMUM_MESSAGES = 100      # Minimum number of messages required for training (when reporting scores on partial data)

parser = argparse.ArgumentParser(description="Trains a relatedness classifier")

# parser.add_argument("--report_partial_scores", dest="report_partial_scores", help="Report partial results every n messages", nargs="?", type=int, default=0)
# parser.add_argument("--repeats", dest="repeats", help="Number of models to train", nargs="?", type=int, default=1)
# parser.add_argument("--output_path", dest="output_path", help="Path where script will create .json file containing evaluation scores", nargs="?", default=None)
parser.add_argument("labelled_data_path", help="Path to labelled data file", nargs=1)
# parser.add_argument("model_output_path", help="Path to cache the model to", nargs=1)

args = parser.parse_args()
REPORT_PARTIAL_SCORES = 0
REPEATS = 1
# OUTPUT_PATH = args.output_path
LABELLED_DATA_PATH = args.labelled_data_path[0]
# MODEL_OUTPUT_PATH = args.model_output_path[0]

with open(LABELLED_DATA_PATH, "r") as labelled_data_file:
    labelled_data = json.load(labelled_data_file)

log(f"Loaded data: {LABELLED_DATA_PATH}")

all_scores = []
model = None

for repeat in range(REPEATS):
    random.shuffle(labelled_data)

    single_run_scores = []     # All precision/recall scores from a single run

    messages = []
    labels = []
    seen_labels = []

    for i, message_dict in enumerate(labelled_data):

        message = message_dict["message"]
        label = message_dict["label"]

        messages.append(message)
        labels.append(label)

        if label not in seen_labels:
            seen_labels.append(label)

        assert len(messages) == len(labels)
        assert len(messages) > 0 and len(labels) > 0

        # if (REPORT_PARTIAL_SCORES
        #     and i >= MINIMUM_MESSAGES
        #     and len(seen_labels) > 1             # Ensures multiple labels available for classification
        #     and i % REPORT_PARTIAL_SCORES == 0):

        #     log("{} messages added".format(i))
        #     model, scores = model_utils.build_and_evaluate(messages, labels)

        #     for score in scores:
        #         score["training-size"] = len(messages)

        #     single_run_scores.extend(scores)

    # assert len(messages) == len(labels)
    assert len(messages) > 1 and len(labels) > 1
    assert len(seen_labels) > 1

    model, scores = model_utils.build_and_evaluate(messages, labels)
    log("Model built")

    for model_scores in scores:
        log (f"{model_scores}")
        for code_id in model_scores:
            scores = model_scores[code_id]
            log (f"{code_id} :\t {scores['precision']} {scores['recall']} {scores['support']}")

    # for score in scores:
        # score["training-size"] = len(messages)
    # single_run_scores.extend(scores)

    # for score_set in single_run_scores:
        # score_set["run"] = repeat
 
    # all_scores.extend(single_run_scores)



# with open(MODEL_OUTPUT_PATH, 'wb') as model_file:
#     pickle.dump(model, model_file)
# log("Model written out to {}".format(MODEL_OUTPUT_PATH))

# if OUTPUT_PATH:
#     with open(OUTPUT_PATH, 'w') as output_file:
#         json.dump(all_scores, output_file, indent=4)
#     log("Model scores written out to {}".format(OUTPUT_PATH))

