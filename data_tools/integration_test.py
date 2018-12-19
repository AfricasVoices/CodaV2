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

USERS_FILE = 'test_data/users.json'
BINARY_SCHEME_FILE = 'test_data/binary_scheme.json'
MESSAGES_FILE = 'test_data/messages.json'

def printProcessOutput(stdout, stderr):
    print('Output:')
    print (stdout.decode('UTF-8'))
    print('Error output:')
    print (stderr.decode('UTF-8'))

# Testing add users

print ('\nTesting add.py users...')
completedProcess = subprocess.run(["python3", "add.py", CRYPTO_TOKEN_PATH, DATASET_ID, "users", USERS_FILE], capture_output=True)

if (completedProcess.returncode == 0):
    print('FAIL: add.py succeeded in adding users. Is this implemented now?')
    print('      If so, please update the integration test.')
    exit(1)

print('PASS: No users added, as adding users is not yet implemented in add.py.')


# Testing add scheme

print ('\nTesting add.py schemes...')
completedProcess = subprocess.run(["python3", "add.py", CRYPTO_TOKEN_PATH, DATASET_ID, "schemes", BINARY_SCHEME_FILE], capture_output=True)

if (completedProcess.returncode != 0):
    print('FAIL: add.py failed in adding a scheme. Please check the error output below:')
    printProcessOutput(completedProcess.stdout, completedProcess.stderr)
    exit(1)

print('PASS: Scheme added successfully.')

print ('Verifying that add.py added the right things...')
completedProcess = subprocess.run(["python3", "get.py", CRYPTO_TOKEN_PATH, DATASET_ID, "schemes"], capture_output=True)

if (completedProcess.returncode != 0):
    print('FAIL: get.py failed in getting scheme. Please check the error output below:')
    printProcessOutput(completedProcess.stdout, completedProcess.stderr)
    exit(1)

print('PASS: Got schemes successfully.')

scheme = json.load(open(BINARY_SCHEME_FILE, 'r'))
if ([scheme] != json.loads(completedProcess.stdout)):
    print('FAIL: scheme wasn\'t added correctly, see diff:')
    print('      original scheme: {}'.format(json.dumps([scheme], indent=2).encode('UTF-8')))
    print('      firebase scheme: {}'.format(completedProcess.stdout))
    exit(1)

print('PASS: verified scheme added successfully and correctly')

# Testing add message

print ('\nTesting add.py messages...')
completedProcess = subprocess.run(["python3", "add.py", CRYPTO_TOKEN_PATH, DATASET_ID, "messages", MESSAGES_FILE], capture_output=True)

if (completedProcess.returncode != 0):
    print('FAIL: add.py failed in adding messages. Please check the error output below:')
    printProcessOutput(completedProcess.stdout, completedProcess.stderr)
    exit(1)

print('PASS: Adding messages successful.')

print ('Verifying that add.py added the right things...')
completedProcess = subprocess.run(["python3", "get.py", CRYPTO_TOKEN_PATH, DATASET_ID, "messages"], capture_output=True)

if (completedProcess.returncode != 0):
    print('FAIL: get.py failed in getting messages. Please check the error output below:')
    printProcessOutput(completedProcess.stdout, completedProcess.stderr)
    exit(1)

print('PASS: Got messages successfully.')

firebase_messages = json.loads(completedProcess.stdout)
firebase_messages.sort(key=lambda message: message['MessageID'])
local_messages = json.load(open(MESSAGES_FILE, 'r'))

if ('SequenceNumber' not in firebase_messages[4]):
    print('FAIL: add.py failed to add missing sequence number')
    exit(1)

print('PASS: Successfully added missing sequence number')
local_messages[4]['SequenceNumber'] = firebase_messages[4]['SequenceNumber']

if (local_messages != firebase_messages):
    print('FAIL: messages weren\'t added correctly, see diff:')
    print('      original messages: {}'.format(json.dumps(MESSAGES_FILE, indent=2).encode('UTF-8')))
    print('      firebase messages: {}'.format(completedProcess.stdout))
    exit(1)

print('PASS: messages added successfully and correctly')






