/**
 * The main UI of the application.
 */
library coda.ui;

import 'dart:html';

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firestore.dart' as firestore;

import 'data_model.dart';
import 'firebase_constants.dart' as firebase_constants;
import 'view_model.dart';
import 'sample_data/sample_json_datasets.dart';

import 'authentication.dart';

import 'package:firebase/firebase.dart' as firebase;

void init() {
  CodaUI codaUI = new CodaUI();
  // TODO: This is just for prototyping, the json dataset will come from a server
  codaUI.displayDataset(new Dataset.fromJson(jsonDatasetTwoSchemes));
}

class CodaUI {
  ButtonElement get saveButton => querySelector('#save-all-button');
  TableElement get messageCodingTable => querySelector('#message-coding-table');

  Dataset dataset;
  List<MessageViewModel> messages = [];
  
  // Cache main elemetns of the UI
  Element tableHead = null;
  Element tableBody = null;

  CodaUI() {
    firebase.initializeApp(
      apiKey: firebase_constants.apiKey,
      authDomain: firebase_constants.authDomain,
      databaseURL: firebase_constants.databaseURL,
      projectId: firebase_constants.projectId,
      storageBucket: firebase_constants.storageBucket,
      messagingSenderId: firebase_constants.messagingSenderId);
    initFirebaseAuth();
    firestore.Firestore firestoreInstance = firebase.firestore();
    firestore.CollectionReference datasetsCollection = firestoreInstance.collection('datasets');
    datasetsCollection.add({
      "id": "msg 1",
      "text": "this is a message text",
      "label": "label 1",
    });
  }

  displayDataset(Dataset dataset) {
    clearMessageCodingTable(); // Clear up the table before loading the new dataset.
    this.dataset = dataset;

    messageCodingTable.append(createTableHeader(dataset));

    TableSectionElement body = new Element.tag('tbody');
    this.tableBody = body;

    dataset.messages.forEach((message) {
      MessageViewModel messageViewModel = new MessageViewModel(message, dataset);
      messages.add(messageViewModel);
      body.append(messageViewModel.viewElement);
    });
    messageCodingTable.append(body);
  }

  createTableHeader(Dataset dataset) {
    TableSectionElement header = new Element.tag('thead');
    this.tableHead = header;

    TableRowElement headerRow = header.addRow();
    headerRow.addCell()
      ..classes.add('message-id')
      ..text = 'ID';
    headerRow.addCell()
      ..classes.add('message-text')
      ..text = 'Message';
    dataset.codeSchemes.forEach((codeScheme) {
      headerRow.addCell()
        ..classes.add('message-code')
        ..text = codeScheme.schemeID;
    });
    return header;
  }

  void clearMessageCodingTable() {
    this.tableHead?.remove();
    this.tableBody?.remove();
  }
}
