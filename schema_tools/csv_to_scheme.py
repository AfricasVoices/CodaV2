# Take CSV containing colums for each coding scheme and generate a scheme

# Format to the csv

# Scheme name  | Scheme name  | ...
# Scheme value | Scheme value | ...
# Scheme value | Scheme value | ...
# Scheme value | Scheme value | ...

import argparse
import json
import csv
import uuid
import os
import re

def short_uuid():
    return str(uuid.uuid4()).split('-')[-1]

def code_to_string_value(display_text):
    txt = re.sub(' +', '_', display_text)
    txt = re.sub('[^0-9a-zA-Z_]+', '', txt)
    txt = txt.lower()
    return txt

def generate_scheme(header_name, codes):
    codes_list = []
    i = 0
    for code in codes:
        codes_list.append(
            {
                "CodeID" : "code-{}".format(short_uuid()),
                "DisplayText"    : code,
                "NumericValue"   : i,
                "StringValue"    : code_to_string_value(code),
                "VisibleInCoda"  : True,
                "CodeType"       : "Normal"
            }
        )
        i += 1

    for code in SPECIAL_CODES:
        codes_list.append(code)

    scheme = {
        "SchemeID"      :  "Scheme-{}".format(short_uuid()),
        "Name"          :  header_name,
        "Version"       :  "0.0.0.1",
        "Codes"         :  codes_list
    }

    return scheme

SPECIAL_CODES = [
    {
        "CodeID": "code-NA-f93d3eb7",
        "CodeType": "Control",
        "ControlCode": "NA",
        "DisplayText": "NA (missing)",
        "NumericValue": -10,
        "StringValue": "NA",
        "VisibleInCoda": False
    },
    {
        "CodeID": "code-NS-2c11b7c9",
        "CodeType": "Control",
        "ControlCode": "NS",
        "DisplayText": "NS (skip)",
        "NumericValue": -20,
        "StringValue": "NS",
        "VisibleInCoda": False
    },
    {
        "CodeID": "code-NC-42f1d983",
        "CodeType": "Control",
        "ControlCode": "NC",
        "DisplayText": "NC (not coded)",
        "NumericValue": -30,
        "StringValue": "NC",
        "VisibleInCoda": True
    },
    {
        "CodeID": "code-NR-5e3eee23",
        "CodeType": "Control",
        "ControlCode": "NR",
        "DisplayText": "NR (not reviewed)",
        "NumericValue": -40,
        "StringValue": "NR",
        "VisibleInCoda": False
    },
    {
        "CodeID": "code-NIC-99631cb8",
        "CodeType": "Control",
        "ControlCode": "NIC",
        "DisplayText": "NIC (not internally consistent)",
        "NumericValue": -50,
        "StringValue": "NIC",
        "VisibleInCoda": False
    },
    {
        "CodeID": "code-NOC-e38423ed",
        "CodeType": "Control",
        "ControlCode": "NOC",
        "DisplayText": "NOC (Noise Other Channel)",
        "NumericValue": -70,
        "StringValue": "NOC",
        "VisibleInCoda": True
    },
    {
        "CodeID": "code-STOP-08b832a8",
        "CodeType": "Control",
        "ControlCode": "STOP",
        "DisplayText": "STOP",
        "NumericValue": -90,
        "StringValue": "STOP",
        "VisibleInCoda": True
    },
    {
        "CodeID": "code-WS-adb25603b7af",
        "CodeType": "Control",
        "ControlCode": "WS",
        "DisplayText": "WS (wrong scheme)",
        "NumericValue": -100,
        "StringValue": "WS",
        "VisibleInCoda": True
    },
    {
        "CodeID": "code-CE-016c1e22",
        "CodeType": "Control",
        "ControlCode": "CE",
        "DisplayText": "CE (coding error)",
        "NumericValue": -110,
        "StringValue": "CE",
        "VisibleInCoda": False
    },
    {
        "CodeID": "code-PB-a434a800",
        "DisplayText": "push back",
        "NumericValue": -100000,
        "StringValue": "push_back",
        "VisibleInCoda": True,
        "CodeType": "Meta"
    },
    {
        "CodeID": "code-Q-a5d3700d",
        "DisplayText": "question",
        "NumericValue": -100010,
        "StringValue": "question",
        "VisibleInCoda": True,
        "CodeType": "Meta"
    },
    {
        "CodeID": "code-SQ-5e8f0122",
        "DisplayText": "showtime question",
        "NumericValue": -100030,
        "StringValue": "showtime_question",
        "VisibleInCoda": True,
        "CodeType": "Meta"
    },
    {
        "CodeID": "code-G-97cb3199",
        "DisplayText": "greeting",
        "NumericValue": -100020,
        "StringValue": "greeting",
        "VisibleInCoda": True,
        "CodeType": "Meta"
    },
]

parser = argparse.ArgumentParser(description="Generate schema files")
parser.add_argument("csv_file_path", help="Path to input file")
parser.add_argument("output_folder", help="Path to the output")

args = parser.parse_args()

INPUT_PATH = args.csv_file_path
OUTPUT_PATH = args.output_folder

print ("{} => {}".format(INPUT_PATH, OUTPUT_PATH))

scheme_map = {}
headers = []

line_count = 0
with open(INPUT_PATH) as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    for row in csv_reader:
        if line_count == 0:
            headers = row
            line_count += 1
            for header in headers:
                scheme_map[header] = []
            print (scheme_map.keys())
        else:
            col = 0
            for item in row:
                header_item = headers[col]
                if item != "":
                    scheme_map[header_item].append(item)
                col += 1
            line_count += 1
    print('Processed {} lines.'.format(line_count))

print ('Scheme: {}'.format(scheme_map))

for k in scheme_map.keys():
    v = scheme_map[k]
    scheme = generate_scheme(k, v)

    scheme_path = os.path.join(OUTPUT_PATH, k) + ".json"
    open (scheme_path, 'w').write(
        json.dumps(scheme, indent=2, sort_keys=True) + "\n"
    )

    print ("Written {} => {}".format(k, scheme_path))
