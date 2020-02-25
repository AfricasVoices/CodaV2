import argparse
import json

from core_data_modules.data_models import Message, Label, Origin
from core_data_modules.logging import Logger
from core_data_modules.traced_data import Metadata
from core_data_modules.util import TimeUtils

Logger.set_project_name("CodeMerge")
log = Logger(__name__)

parser = argparse.ArgumentParser(description="Performs a code merge on a local dataset. "
                                             "To use with Coda, use get.py, code_merge.py, then set.py")
parser.add_argument("messages_input_file_path", metavar="messages-input-file-path",
                    help="Path to the Coda messages file to perform the code merge on")
parser.add_argument("code_ids_to_merge", metavar="code-ids-to-merge", nargs="+",
                    help="Ids of the codes to merge")
parser.add_argument("merged_code_id", metavar="merged-code-id",
                    help="Id of the code to merge the source codes to")
parser.add_argument("messages_output_file_path", metavar="messages-output-file-path",
                    help="Path to the Coda messages file to write the messages to after performing the code merge")

args = parser.parse_args()
messages_input_file_path = args.messages_input_file_path
code_ids_to_merge = args.code_ids_to_merge
merged_code_id = args.merged_code_id
messages_output_file_path = args.messages_output_file_path

log.info(f"Loading Coda messages from '{messages_input_file_path}'...")
with open(messages_input_file_path) as f:
    messages = [Message.from_firebase_map(d) for d in json.load(f)]
log.info(f"Loaded {len(messages)} messages")

log.info(f"Performing merge ({code_ids_to_merge} -> '{merged_code_id}')...")
merged_count = 0  # A count of the number of labels that were remapped to the merged value, for sense-check logging
for msg in messages:
    processed_scheme_ids = set()
    for label in list(msg.labels):
        if label.scheme_id in processed_scheme_ids:
            continue

        processed_scheme_ids.add(label.scheme_id)

        if label.code_id in code_ids_to_merge:
            msg.labels.insert(
                0,
                Label(label.scheme_id, merged_code_id, TimeUtils.utc_now_as_iso_string(),
                      Origin(Metadata.get_call_location(), "Auto Code-Merge", "External"), checked=label.checked)
            )
            merged_count += 1
log.info(f"Merged {merged_count} labels to '{merged_code_id}'")

log.info(f"Exporting code-merged Coda messages to '{messages_output_file_path}'...")
with open(messages_output_file_path, "w") as f:
    json.dump([msg.to_firebase_map() for msg in messages], f, indent=2)
log.info("Done")
