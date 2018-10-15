import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as firebase_constants;
import 'data_model.dart';
import 'dataset_tools.dart' as dataset_tools;
import 'logger.dart' as log;
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

  var docPath = "datasets/${dataset.id}/msgs/${msg.id}";

  if (TEST_MODE) {
    firestoreCallLog.add({
      'callType': 'updateMessage',
      'target': '$docPath',
      'content': msg.toMap()
    });
    return;
  }

  _firestoreInstance.doc(docPath).set(msg.toMap()).then((_) {
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

    ret.add(
      new Scheme.fromFirebaseMap(scheme.data())
    );
  });

  log.verbose("loadSchemes: ${ret.length} schemes loaded");
  return ret;
}

Dataset loadDataset(String datasetName) {
  log.verbose("Loading coding schemes for: reach_demo");
  loadSchemes("reach_demo");

  log.verbose("Loading dataset: $datasetName");

  // Temporary code
  if (datasetName == null) {
    throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
  }

  if (TEST_MODE) {
    firestoreCallLog.add({
      'callType': 'loadDataset',
      'target': '$datasetName',
      'content': jsonDatasetTwoSchemes
    });
    return new Dataset.fromJson(jsonDatasetTwoSchemes);
  }

  const msgCountDatasetPrefix = 'dataset-msg-';
  if (datasetName.startsWith(msgCountDatasetPrefix)) {
    try {
      int count = int.parse(datasetName.replaceFirst(msgCountDatasetPrefix, ''));
      return dataset_tools.generateEmptyDataset(datasetName, 3, count);
    } catch (e) {
      throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
    }
  }
  if (datasetName == 'test-dataset') {
    return new Dataset.fromJson(jsonDatasetTwoSchemes);
  }
  throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
}
