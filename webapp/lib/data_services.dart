import 'logger.dart' as log;
import 'package:http/browser_client.dart';
import 'firebase_constants.dart';
import 'dart:convert';
import 'dart:async';

const _AUTOCODE_CONTROL_TOPIC_POSTFIX = "-autocode-topic";

Future triggerAutoLabelling(String datasetId) async {
  log.trace("triggerAutoLabelling", "triggering labelling for $datasetId");

  var topicName = projectId + _AUTOCODE_CONTROL_TOPIC_POSTFIX;

  var client = new BrowserClient();
  var response = await client.post(publishUrl, body: json.encode({"topic":topicName,"message": datasetId }));
  log.trace("triggerAutoLabelling", "response ${response.statusCode}, ${response.body}");
}


