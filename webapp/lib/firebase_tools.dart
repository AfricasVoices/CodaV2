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

typedef MessageUpdatesListener(List<Message> messages, ChangeType changeType);
enum ChangeType {
  added,
  modified
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

void setupListenerForFirebaseMessageUpdates(Dataset dataset, MessageUpdatesListener listener) {
  log.verbose("setupListenerForFirebaseMessageUpdates: Loading messages for: ${dataset.id}");

  var messagesCollectionRoot = "/datasets/${dataset.id}/messages";
  log.verbose("setupListenerForFirebaseMessageUpdates: Root of query: $messagesCollectionRoot");

  _firestoreInstance.collection(messagesCollectionRoot).onSnapshot.listen((querySnapshot) {
    // No need to process local writes to Firebase
    if (querySnapshot.metadata.hasPendingWrites) {
      log.verbose("setupListenerForFirebaseMessageUpdates: Skipping processing of local messages");
      return;
    }

    log.verbose("setupListenerForFirebaseMessageUpdates: Starting processing ${querySnapshot.docChanges().length} messages.");
    List<Message> added = [];
    List<Message> modified = [];
    querySnapshot.docChanges().forEach((documentChange) {
      Message message = new Message.fromFirebaseMap(documentChange.doc.data());
      if (documentChange.type == "added") {
        added.add(message);
      } else if (documentChange.type == "modified") {
        modified.add(message);
      } else {
        log.log("setupListenerForFirebaseMessageUpdates: Warning! Skip processing ${documentChange.type} message ${message.id}");
      }
    });
    log.verbose("setupListenerForFirebaseMessageUpdates: Finished processing ${querySnapshot.docChanges().length} messages.");

    listener(added, ChangeType.added);
    listener(modified, ChangeType.modified);
  });
}

Future<Dataset> loadDatasetWithOnlyCodeSchemes(String datasetId) async {
  log.verbose("Loading dataset: $datasetId");

  // TODO handle non-datasets for demo usage
  if (datasetId == null) {
    throw new DatasetLoadException('Sorry, you need to specify a dataset to load.');
  }

  if (TEST_MODE) {
    log.logFirestoreCall('loadDataset', '$datasetId', jsonDatasetTwoSchemes);
    return new Dataset('two schemes', [], jsonDatasetTwoSchemes['CodeSchemes']);
  }

  List<Scheme> schemes = await loadSchemes(datasetId);

  return new Dataset(datasetId, [], schemes);
}
