import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as firebase_constants;
import 'data_model.dart';
import 'dataset_tools.dart' as dataset_tools;
import 'logger.dart' as log;
import 'config.dart';
import 'sample_data/sample_json_datasets.dart';
import 'dart:async';

class DatasetLoadException implements Exception {
  final String _message;
  const DatasetLoadException(this._message);
  String toString() => _message;
}

firestore.Firestore _firestoreInstance = firebase.firestore();

init() {
  if (TEST_MODE) return;

  firebase.initializeApp(
      apiKey: firebase_constants.apiKey,
      authDomain: firebase_constants.authDomain,
      databaseURL: firebase_constants.databaseURL,
      projectId: firebase_constants.projectId,
      storageBucket: firebase_constants.storageBucket,
      messagingSenderId: firebase_constants.messagingSenderId);
}

updateMessage(Dataset dataset, Message msg) {
  log.verbose("Updating: $msg");

  var docPath = "datasets/${dataset.id}/messages/${msg.id}";

  if (TEST_MODE) {
    log.logFirestoreCall('updateMessage', '$docPath', msg.toFirebaseMap());
    return;
  }

  _firestoreInstance.doc(docPath).set(msg.toFirebaseMap()).then((_) {
    log.verbose("Store complete: ${msg.id}");
  });
}

Future<List<Scheme>> loadSchemes(String datasetId) async {
  List<Scheme> ret = <Scheme>[];

  log.verbose("loadSchemes: Loading schemes for: $datasetId");

  var schemeCollectionRoot = "/datasets/$datasetId/code_schemes";
  log.verbose("loadSchemes: Root of query: $schemeCollectionRoot");

  var schemesQuery = await _firestoreInstance.collection(schemeCollectionRoot).get();
  log.verbose("loadSchemes: Query constructed");

  schemesQuery.forEach((scheme) {
    log.verbose("loadSchemes: Processing ${scheme.id}");

    ret.add(new Scheme.fromFirebaseMap(scheme.data()));
  });

  log.verbose("loadSchemes: ${ret.length} schemes loaded");
  return ret;
}

Future<List<Message>> loadMessages(String datasetId) async {
  List<Message> ret = <Message>[];

  log.verbose("loadMessages: Loading messages for: $datasetId");

  var messagesCollectionRoot = "/datasets/$datasetId/messages";
  log.verbose("loadMessages: Root of query: $messagesCollectionRoot");

  var messagesQuery = await _firestoreInstance.collection(messagesCollectionRoot).get();
  log.verbose("loadMessages: Query constructed");

  messagesQuery.forEach((message) {
    log.verbose('loadMessages: Processing ${message.id}');
    ret.add(new Message.fromFirebaseMap(message.data()));
  });

  log.verbose("loadMessages: ${ret.length} messages loaded");
  return ret;
}

Future<Dataset> loadDataset(String datasetId) async {
  log.verbose("Loading dataset: $datasetId");

  // TODO handle non-datasets for demo usage
  if (datasetId == null) {
    throw new DatasetLoadException('Sorry, you need to specify a dataset to load.');
  }

  if (TEST_MODE) {
    log.logFirestoreCall('loadDataset', '$datasetId', jsonDatasetTwoSchemes);
    return new Dataset('two schemes',
      jsonDatasetTwoSchemes['Documents'],
      jsonDatasetTwoSchemes['CodeSchemes']);
  }

  List<Scheme> schemes = await loadSchemes(datasetId);
  List<Message> messages = await loadMessages(datasetId);

  return new Dataset(datasetId, messages, schemes);
}
