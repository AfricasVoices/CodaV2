import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as firebase_constants;
import 'data_model.dart';
import 'config.dart';
import 'sample_data/sample_json_datasets.dart';

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
  return new Dataset.fromJson(jsonDatasetTwoSchemesNoCodes);
}
