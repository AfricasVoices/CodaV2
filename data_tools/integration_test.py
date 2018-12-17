import json
import subprocess

import firebase_client_wrapper as fcw

import sys

if (len(sys.argv) != 2):
    print ("Usage python integration_test.py crypto_token")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

FIREBASE_PROJECT = 'coda-integration-test'
DATASET_ID = 'integration-test-dataset'


BINARY_SCHEME = {
    "SchemeID"      :  "Scheme-c9b1a1d8",
    "Name"          :  "Binary Scheme",
    "Version"       :  "0.0.0.1",
    "Codes"        :  [
    {
        "CodeID"        : "code-8f1c2c4d",
        "DisplayText"    : "Option 1",
        "Shortcut"       : "1",	
        "CodeType"       : "Normal",
        "NumericValue"   : 1,
        "VisibleInCoda"  : True
    },
    {
        "CodeID"        : "code-298abe95",
        "DisplayText"    : "Option 2",	
        "Shortcut"       : "2",	
        "CodeType"       : "Normal",
        "NumericValue"   : 2,
        "VisibleInCoda"  : True
    },
    {
        "CodeID"        : "code-NA-c459eda1",
        "DisplayText"    : "NA (missing)",
        "ControlCode"    : "NA",
        "CodeType"       : "Control",
        "NumericValue"   : -10,
        "VisibleInCoda"  : True
    },
    {
        "CodeID"        : "code-NC-08ffb18",
        "DisplayText"    : "NC (not coded)",	
        "ControlCode"    : "NC",
        "CodeType"       : "Control",
        "NumericValue"   : -30,
        "VisibleInCoda"  : True
    }
    ]
}

MESSAGES = [
    {
        "MessageID": "m-1",
        "SequenceNumber": 0,
        "Text": "First message text",
        "CreationDateTimeUTC": "2018-10-19T21:36:17.133956",
        "Labels": []
    },
    {
        "MessageID": "m-2",
        "SequenceNumber": 1,
        "Text": "Second message text",
        "CreationDateTimeUTC": "2018-10-19T21:36:17.133980",
        "Labels": []
    },
    {
        "MessageID": "m-3",
        "SequenceNumber": 2,
        "Text": "Third message text",
        "CreationDateTimeUTC": "2018-10-19T21:36:17.133984",
        "Labels": []
    },
    {
        "MessageID": "m-4",
        "SequenceNumber": 3,
        "Text": "Fourth message text",
        "CreationDateTimeUTC": "2018-10-19T21:36:17.133988",
        "Labels": []
    },
    {
        "MessageID": "m-5",
        "Text": "Fifth message text",
        "CreationDateTimeUTC": "2018-10-19T21:36:17.133991",
        "Labels": []
    }
]

print ('\nTesting add.py users...')
with open('users.json', 'w') as f:
    f.write(json.dumps({
        'users': [
            'a@test.com',
            'b@test.com',
            'c@test.com',
        ]
    }))
completedProcess = subprocess.run(["python3", "add.py", CRYPTO_TOKEN_PATH, DATASET_ID, "users", 'users.json'], capture_output=True)

if (completedProcess.returncode == 1):
    print('PASS: Adding users is not yet implemented in add.py.')
else:
    print('FAIL: add.py succeeded in adding users. Is this implemented now?')
    print('      If so, please update the integration test.')

completedProcess = subprocess.run(["rm", "users.json"], capture_output=True)
if (completedProcess.returncode != 0):
    print(completedProcess.stderr.decode('UTF-8'))


print ('\nTesting add.py schemes...')
with open('schemes.json', 'w') as f:
    f.write(json.dumps(BINARY_SCHEME))
completedProcess = subprocess.run(["python3", "add.py", CRYPTO_TOKEN_PATH, DATASET_ID, "schemes", 'schemes.json'], capture_output=True)

if (completedProcess.returncode == 0):
    print('PASS: Adding scheme successful.')
else:
    print('FAIL: add.py failed in adding a scheme. Please check the error output below:')
    print('Output:')
    print (completedProcess.stdout.decode('UTF-8'))
    print('Error output:')
    print (completedProcess.stderr.decode('UTF-8'))


print ('Verifying that add.py added the right things...')
completedProcess = subprocess.run(["python3", "get.py", CRYPTO_TOKEN_PATH, DATASET_ID, "schemes"], capture_output=True)

if (completedProcess.returncode == 0):
    print('PASS: Got schemes successfully.')
else:
    print('FAIL: get.py failed in getting scheme. Please check the error output below:')
    print('Output:')
    print (completedProcess.stdout.decode('UTF-8'))
    print('Error output:')
    print (completedProcess.stderr.decode('UTF-8'))

if ([BINARY_SCHEME] == json.loads(completedProcess.stdout)):
    print('PASS: scheme added successfully and correctly')
else :
    print('FAIL: scheme wasn\'t added correctly, see diff:')
    print('      original scheme: {}'.format(json.dumps([BINARY_SCHEME], indent=2).encode('UTF-8')))
    print('      firebase scheme: {}'.format(completedProcess.stdout))

completedProcess = subprocess.run(["rm", "schemes.json"], capture_output=True)
if (completedProcess.returncode != 0):
    print(completedProcess.stderr.decode('UTF-8'))



print ('\nTesting add.py messages...')
with open('messages.json', 'w') as f:
    f.write(json.dumps(MESSAGES))
completedProcess = subprocess.run(["python3", "add.py", CRYPTO_TOKEN_PATH, DATASET_ID, "messages", 'messages.json'], capture_output=True)

if (completedProcess.returncode == 0):
    print('PASS: Adding messages successful.')
else:
    print('FAIL: add.py failed in adding messages. Please check the error output below:')
    print('Output:')
    print (completedProcess.stdout.decode('UTF-8'))
    print('Error output:')
    print (completedProcess.stderr.decode('UTF-8'))


print ('Verifying that add.py added the right things...')
completedProcess = subprocess.run(["python3", "get.py", CRYPTO_TOKEN_PATH, DATASET_ID, "messages"], capture_output=True)

if (completedProcess.returncode == 0):
    print('PASS: Got messages successfully.')
else:
    print('FAIL: get.py failed in getting messages. Please check the error output below:')
    print('Output:')
    print (completedProcess.stdout.decode('UTF-8'))
    print('Error output:')
    print (completedProcess.stderr.decode('UTF-8'))


firebase_messages = json.loads(completedProcess.stdout)
firebase_messages.sort(key=lambda message: message['MessageID'])

if ('SequenceNumber' in firebase_messages[4]):
    print('PASS: Successfully added missing sequence number')
    MESSAGES[4]['SequenceNumber'] = firebase_messages[4]['SequenceNumber']
else:
    print('FAIL: add.py failed to add missing sequence number')

if (MESSAGES == firebase_messages):
    print('PASS: messages added successfully and correctly')
else :
    print('FAIL: messages weren\'t added correctly, see diff:')
    print('      original messages: {}'.format(json.dumps(MESSAGES, indent=2).encode('UTF-8')))
    print('      firebase messages: {}'.format(completedProcess.stdout))

completedProcess = subprocess.run(["rm", "messages.json"], capture_output=True)
if (completedProcess.returncode != 0):
    print(completedProcess.stderr.decode('UTF-8'))





