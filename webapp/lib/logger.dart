import 'package:http/browser_client.dart';
import 'dart:convert';

import "config.dart";
import "firebase_constants.dart" as firebase_constants;
import "authentication.dart" as auth;


log(String s) => _write(s);
logMap(Map m) => _writeMap(m);

perf(String name, int ms) {
  _writeMap({
    "perf" : name,
    "time" : ms
    });
}

verbose(String s) {
  if (VERBOSE) {
    _write(s);
  }
}

trace(String f, String s) {
  if (VERBOSE) {
    _writeMap({
      "function" : f,
      "msg" : s
    });
  }
}

severe(String s) {
  // TODO: Implement a leaky bucket system for writing the logs (issue #146)
  _write(s);
}

_write(String s) {
  var m = {
    "DateTime" : DateTime.now().toUtc().toIso8601String(),
    "Email" : auth.getUserEmail(),
    "msg" : s
  };

  String logString = "${m['DateTime']}: ${m['Email']}: $s";
  print (logString);
  _logToServer(m);
} 

_writeMap(Map m) {
  m["DateTime"] = DateTime.now().toUtc().toIso8601String();
  m["Email"] = auth.getUserEmail();
  print (m);
  _logToServer(m);
}

_logToServer(Map m) async {
  var client = new BrowserClient();
  await firebase_constants.init();
  client.post(firebase_constants.logUrl, body: json.encode(m));
}


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
