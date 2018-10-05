import 'package:firebase/firebase.dart' as firebase;
// import 'package:firebase/firestore.dart' as firestore;
import 'firebase_constants.dart' as firebase_constants;
import 'data_model.dart';
import 'config.dart';


init() {
  firebase.initializeApp(
      apiKey: firebase_constants.apiKey,
      authDomain: firebase_constants.authDomain,
      databaseURL: firebase_constants.databaseURL,
      projectId: firebase_constants.projectId,
      storageBucket: firebase_constants.storageBucket,
      messagingSenderId: firebase_constants.messagingSenderId);
   
    // firestore.Firestore firestoreInstance = firebase.firestore();
    // firestore.CollectionReference datasetsCollection = firestoreInstance.collection('datasets');
    // datasetsCollection.add({
    //   "id": "msg 1",
    //   "text": "this is a message text",
    //   "label": "label 1",
}

updateMessage(Message msg) {
  if (VERBOSE) print("Updating: $msg");

  // TODO: Implement writeback
}