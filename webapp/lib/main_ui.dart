/**
 * The main UI of the application.
 */
library coda.ui;

import 'dart:html';

import 'data_model.dart';
import 'view_model.dart';
import 'sample_data/sample_json_datasets.dart';

import 'authentication.dart' as auth;
import 'firebase_tools.dart' as fb;

void init() {
  CodaUI codaUI = new CodaUI();
  String datasetName = Uri.base.queryParameters["dataset"];
  codaUI.displayDataset(fb.loadDataset(datasetName));
}

class CodaUI {
  ButtonElement get saveButton => querySelector('#save-all-button');
  TableElement get messageCodingTable => querySelector('#message-coding-table');
  
  Dataset dataset;
  List<MessageViewModel> messages = [];

  CodaUI() {
    fb.init();
    auth.init();
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
