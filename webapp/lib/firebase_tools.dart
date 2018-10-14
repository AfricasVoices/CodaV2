import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as firebase_constants;
import 'data_model.dart';
import 'dataset_tools.dart' as dataset_tools;
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

  firebase.initializeApp(
      apiKey: firebase_constants.apiKey,
      authDomain: firebase_constants.authDomain,
      databaseURL: firebase_constants.databaseURL,
      projectId: firebase_constants.projectId,
      storageBucket: firebase_constants.storageBucket,
      messagingSenderId: firebase_constants.messagingSenderId);
}

updateMessage(Dataset dataset, Message msg) {
  if (VERBOSE) print("Updating: $msg");

  var docPath = "datasets/${dataset.id}/msgs/${msg.id}";

  _firestoreInstance.doc(docPath).set(msg.toMap()).then((_) {
    if (VERBOSE) print("Store complete: ${msg.id}");
  });
}

Future<List<Scheme>> loadSchemes(String datasetId) async {
  List<Scheme> ret = <Scheme>[];

  if (VERBOSE) print("loadSchemes: Loading schemes for: $datasetId");

  var schemeCollectionRoot = "/datasets/$datasetId/code_schemes";
  if (VERBOSE) print("loadSchemes: Root of query: $schemeCollectionRoot");

  var schemesQuery = await _firestoreInstance.collection(schemeCollectionRoot).get();
  if (VERBOSE) print("loadSchemes: Query constructed");
  
  schemesQuery.forEach((scheme) {
    if (VERBOSE) print("loadSchemes: Processing ${scheme.id}");

    ret.add(
      new Scheme.fromFirebaseMap(scheme.data())
    );
  });

  if (VERBOSE) print("loadSchemes: ${ret.length} schemes loaded");
  return ret;
}

Dataset loadDataset(String datasetName) {
  if (VERBOSE) print("Loading coding schemes for: reach_demo");
  loadSchemes("reach_demo");

  if (VERBOSE) print("Loading dataset: $datasetName");

  // Temporary code
  if (datasetName == null) {
    throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
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
    return new Dataset.fromJson(jsonDatasetTwoSchemesNoCodes);
  }
  throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
}
