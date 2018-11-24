import json
import sys

DATA_PATH = sys.argv[1]
OUT_PATH = sys.argv[1]
print ("Processing {}".format(DATA_PATH))
json_data = json.load(open(DATA_PATH))

for dataset_name in json_data.keys():
    dataset = json_data[dataset_name]

    messages_to_export = {}

    for message in dataset["messages"]:
        text = message['Text']
        labels = message['Labels']
        if len(labels) > 0:
            scheme_label_map = {}
            for label in reversed(labels):
                scheme_label_map[label['SchemeID']] = label['CodeID']
            
            for k in scheme_label_map.keys():
                if k not in messages_to_export.keys():
                    messages_to_export[k] = []
                
                messages_to_export[k].append({
                    "message": text,
                    "label": scheme_label_map[k]
                })
    
    for scheme_id in messages_to_export.keys():
        f = open (OUT_PATH + "_{}_{}.json".format(dataset_name, scheme_id), 'w')
        json.dump(messages_to_export[scheme_id], f, indent=2)

    
            