import "config.dart";

log(String s) => write(s);

verbose(String s) {
  write(s);
}

write(String s) => print ("${DateTime.now().toIso8601String()}: $s");

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
