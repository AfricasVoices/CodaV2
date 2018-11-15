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

def short_uuid():
    return str(uuid.uuid4()).split('-')[-1]

def generate_scheme(header_name, codes):
    codes_list = []
    i = 0
    for code in codes:
        codes_list.append(
            {
                "CodeID" : "code-{}".format(short_uuid()),
                "DisplayText"    : code,
                "NumericValue"   : i,
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
        "CodeID"        : "code-NA-f93d3eb7",
        "DisplayText"    : "NA (missing)",
        "ControlCode"    : "NA",
        "CodeType"       : "Control",
        "NumericValue"   : -10,
        "VisibleInCoda"  : True
      },
      {
        "CodeID"        : "code-NC-42f1d983",
        "DisplayText"    : "NC (not coded)",	
        "ControlCode"    : "NC",
        "CodeType"       : "Control",
        "NumericValue"   : -30,
        "VisibleInCoda"  : True
      },
      {
        "CodeID"        : "code-WS-adb25603b7af",
        "DisplayText"    : "WS (wrong scheme)",	
        "ControlCode"    : "WS",
        "CodeType"       : "Control",
        "NumericValue"   : -100,
        "VisibleInCoda"  : True
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
        json.dumps(scheme, indent=2, sort_keys=True)
    )

    print ("Written {} => {}".format(k, scheme_path))
