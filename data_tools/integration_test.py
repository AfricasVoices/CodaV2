import json
import subprocess

import firebase_client_wrapper as fcw

import sys

if (len(sys.argv) != 2):
    print("Usage python integration_test.py crypto_token")
    cleanupFirebaseTestEnvironment()
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

FIREBASE_PROJECT = 'coda-integration-test'
DATASET_ID = 'integration-test-dataset'

USERS_TO_SET_FILE = 'test_data/users_to_set.json'
SCHEME_TO_ADD_FIRST_FILE = 'test_data/scheme_to_add_first.json'
SCHEME_TO_ADD_SECOND_FILE = 'test_data/scheme_to_add_second.json'
SCHEMES_TO_SET_FILE = 'test_data/schemes_to_set.json'
MESSAGES_TO_ADD_FILE = 'test_data/messages_to_add.json'
MESSAGES_TO_ADD_NO_SEQ_FILE = 'test_data/messages_to_add_no_seq.json'

def printProcessOutput(stdout, stderr):
    print('Output:')
    print(stdout.decode('UTF-8'))
    print('Error output:')
    print(stderr.decode('UTF-8'))

def runScript(script, content_type, data_file, expected_to_fail=False):
    completedProcess = subprocess.run(["python3", script, CRYPTO_TOKEN_PATH, DATASET_ID, content_type, data_file], capture_output=True)

    if (expected_to_fail == True):
        if (completedProcess.returncode != 0):
            return

        print('FAIL: {} for {} was expected to fail but succeeded. Please check the error output below:'.format(script, content_type))
        printProcessOutput(completedProcess.stdout, completedProcess.stderr)
        cleanupFirebaseTestEnvironment()
        exit(1)

    if (completedProcess.returncode == 0):
        return

    print('FAIL: {} failed for {}. Please check the error output below:'.format(script, content_type))
    printProcessOutput(completedProcess.stdout, completedProcess.stderr)
    cleanupFirebaseTestEnvironment()
    exit(1)


def checkFirebaseAgainstExpected(content_type, expected):
    print('Verifying that firebase has the expected changes...')
    completedProcess = subprocess.run(["python3", 'get.py', CRYPTO_TOKEN_PATH, DATASET_ID, content_type], capture_output=True)

    if (completedProcess.returncode != 0):
        print('FAIL: get.py failed for {}. Please check the error output below:'.format(content_type))
        printProcessOutput(completedProcess.stdout, completedProcess.stderr)
        cleanupFirebaseTestEnvironment()
        exit(1)

    print('PASS: Got {} successfully.'.format(content_type))

    actual = json.loads(completedProcess.stdout)
    if (isinstance(expected, list)):
        expected = {json.dumps(key, sort_keys=True) : 1 for key in expected}
        actual = {json.dumps(key, sort_keys=True) : 1 for key in actual}
    if (expected != actual):
        print('FAIL: {} doesn\'t match expected, see diff:'.format(content_type))
        print('      expected: {}'.format(json.dumps(expected, indent=2)))
        print('      firebase: {}'.format(json.dumps(actual, indent=2)))
        cleanupFirebaseTestEnvironment()
        exit(1)

    print('PASS: firebase has the expected changes')

def cleanupFirebaseTestEnvironment():
    print('\nCleaning up...')
    fcw.delete_dataset(DATASET_ID)



# Preparing for testing

print('\nPreparing for testing...')
cleanupFirebaseTestEnvironment()


# Testing add.py users

print('\nTesting add.py users...')
runScript('add.py', 'users', USERS_TO_SET_FILE, expected_to_fail=True)
print('PASS: No users added, as adding users is not yet implemented in add.py.')

checkFirebaseAgainstExpected('users', None)

# Testing add.py scheme

print('\nadd.py schemes - adding first scheme')
runScript('add.py', 'schemes', SCHEME_TO_ADD_FIRST_FILE)
print('PASS: Scheme added successfully.')

checkFirebaseAgainstExpected('schemes', [json.load(open(SCHEME_TO_ADD_FIRST_FILE, 'r'))])


# Testing add.py second scheme

print('\nadd.py schemes - adding second scheme')
runScript('add.py', 'schemes', SCHEME_TO_ADD_SECOND_FILE)
print('PASS: Scheme added successfully.')

checkFirebaseAgainstExpected('schemes', [json.load(open(SCHEME_TO_ADD_FIRST_FILE, 'r')), json.load(open(SCHEME_TO_ADD_SECOND_FILE, 'r'))])


# Testing add.py messages

print('\nadd.py messages - adding 5 messages')
runScript('add.py', 'messages', MESSAGES_TO_ADD_FILE)
print('PASS: Adding messages successful.')

checkFirebaseAgainstExpected('messages', json.load(open(MESSAGES_TO_ADD_FILE, 'r')))


# Testing add.py messages without sequence number

print('\nadd.py messages - adding 5 messages without sequence number')
runScript('add.py', 'messages', MESSAGES_TO_ADD_NO_SEQ_FILE)
print('PASS: Adding messages successful.')

expected_messages = json.load(open(MESSAGES_TO_ADD_FILE, 'r'))
sequence_number = 5
for message in json.load(open(MESSAGES_TO_ADD_NO_SEQ_FILE, 'r')):
    message['SequenceNumber'] = sequence_number
    expected_messages.append(message)
    sequence_number += 1
checkFirebaseAgainstExpected('messages', expected_messages)


# Testing set.py users

print('\nset.py users - setting users')
runScript('set.py', 'users', USERS_TO_SET_FILE)
print('PASS: Users set successfully.')

checkFirebaseAgainstExpected('users', json.load(open(USERS_TO_SET_FILE, 'r')))


# Testing set.py modify first scheme

print('\nset.py schemes - modify first scheme')
runScript('set.py', 'schemes', SCHEMES_TO_SET_FILE)
print('PASS: Scheme set successfully.')

expected_schemes = json.load(open(SCHEMES_TO_SET_FILE, 'r'))
expected_schemes.append(json.load(open(SCHEME_TO_ADD_SECOND_FILE, 'r')))
checkFirebaseAgainstExpected('schemes', expected_schemes)


# Cleanup
cleanupFirebaseTestEnvironment()