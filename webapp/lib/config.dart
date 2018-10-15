bool VERBOSE = true;

/// Whether the connection to Firestore should be mocked.
bool TEST_MODE = false;

/// Stores calls to Firestore if in [TEST_MODE].
List<Map> firestoreCallLog = <Map>[];

/// Logs calls to Firestore if in [TEST_MODE].
logFirestoreCall(var callType, var target, var content) {
  firestoreCallLog.add({
    'callType': callType,
    'target': target,
    'content': content
  });
}
