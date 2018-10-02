/**
 * The main UI of the application.
 */
library coda.ui;

import 'dart:html';

import 'data_model.dart';
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

  CodaUI() {
    firebase.initializeApp(
      apiKey: "AIzaSyAVM9wsuKG0ANdKnkJjNN6lTmmH0fD_v68",
      authDomain: "fir-test-b0eb7.firebaseapp.com",
      databaseURL: "https://fir-test-b0eb7.firebaseio.com",
      projectId: "fir-test-b0eb7",
      storageBucket: "fir-test-b0eb7.appspot.com",
      messagingSenderId: "587699758467");

    initFirebaseAuth();
  }

  displayDataset(Dataset dataset) {
    clearMessageCodingTable(); // Clear up the table before loading the new dataset.
    this.dataset = dataset;

    messageCodingTable.append(createTableHeader(dataset));

    TableSectionElement body = new Element.tag('tbody');
    dataset.messages.forEach((message) {
      MessageViewModel messageViewModel = new MessageViewModel(message, dataset);
      messages.add(messageViewModel);
      body.append(messageViewModel.viewElement);
    });
    messageCodingTable.append(body);
  }

  createTableHeader(Dataset dataset) {
    TableSectionElement header = new Element.tag('thead');
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
    // TODO: Implement clearing up the table
  }
}
