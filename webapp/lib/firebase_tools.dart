import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as firebase_constants;
import 'data_model.dart';
import 'config.dart';
import 'sample_data/sample_json_datasets.dart';

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

Dataset loadDataset(String datasetName) {
  if (VERBOSE) print("Loading dataset: $datasetName");

  // Temporary code
  if (datasetName == null) {
    throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
  }

  String msgCountDatasetPrefix = 'dataset-msg-';
  if (datasetName.startsWith(msgCountDatasetPrefix)) {
    try {
      int count = int.parse(datasetName.replaceFirst(msgCountDatasetPrefix, ''));
      return generateEmptyDataset(datasetName, 3, count);
    } catch (e) {
      throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
    }
  }
  if (datasetName == 'test-dataset') {
    return new Dataset.fromJson(jsonDatasetTwoSchemesNoCodes);
  }
  throw new DatasetLoadException('Sorry, dataset "$datasetName" not available to load.');
}

Dataset generateEmptyDataset(String name, int schemeCount, int messageCount) {
  Dataset dataset = new Dataset(name);
  for (int i = 0; i < schemeCount; i++) {
    Scheme scheme = new Scheme('scheme $i');
    for (int c = 0; c < 5; c++) {
      scheme.codes.add({
        'name': 'Code $c',
        'valueID': 'code $c',
        'shortcut': '$c'
      });
    }
    dataset.codeSchemes.add(scheme);
  }

  for (int i = 0; i < messageCount; i++) {
    dataset.messages.add(new Message('msg_$i', 'message', new DateTime.now()));
  }

  return dataset;
}
