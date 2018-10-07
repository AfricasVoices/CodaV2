/**
 * The main UI of the application.
 */
library coda.ui;

import 'dart:html';

import 'config.dart';
import 'data_model.dart';

import 'authentication.dart' as auth;
import 'firebase_tools.dart' as fbt;

part 'view_model.dart';

void init() {
  CodaUI codaUI = new CodaUI();
  String datasetName = Uri.base.queryParameters["dataset"];
  codaUI.displayDataset(fbt.loadDataset(datasetName));
}

class CodaUI {
  ButtonElement get saveButton => querySelector('#save-all-button');
  TableElement get messageCodingTable => querySelector('#message-coding-table');

  static InputElement horizontalCodingToggle = querySelector('#horizontal-coding');
  static bool get horizontalCoding => horizontalCodingToggle.checked;

  Dataset dataset;
  List<MessageViewModel> messages;
  Map<String, MessageViewModel> messageMap;

  // Cache main elements of the UI
  Element tableHead = null;
  Element tableBody = null;

  CodaUI() {
    fbt.init();
    auth.init();
  }

  displayDataset(Dataset dataset) {
    clearMessageCodingTable(); // Clear up the table before loading the new dataset.
    this.dataset = dataset;
    this.messages = [];
    this.messageMap = {};

    messageCodingTable.append(createTableHeader(dataset));

    TableSectionElement body = new Element.tag('tbody');
    this.tableBody = body;

    dataset.messages.forEach((message) {
      MessageViewModel messageViewModel = new MessageViewModel(message, dataset);
      messages.add(messageViewModel);
      messageMap[message.messageID] = messageViewModel;
      body.append(messageViewModel.viewElement);
    });
    messageCodingTable.append(body);

    messageCodingTable.onChange.listen((event) {
      var target = event.target;
      if (target is InputElement || target is SelectElement) {
        TableRowElement row = parentOfClass(target, 'message-row');
        DivElement inputGroup = parentOfClass(target, 'input-group');
        String messageID = row.attributes['message-id'];
        MessageViewModel message = messageMap[messageID];
        String schemeID = inputGroup.attributes['scheme-id'];

        if (target is InputElement) { // change on checkbox element
          message.schemeCheckChanged(schemeID, target.checked);
        }
        if (target is SelectElement) { // change on dropdown select element
          CodeSelector codeSelector = message.codeSelectors.singleWhere((codeSelector) => codeSelector.scheme.schemeID == schemeID);
          CodeSelector.activeCodeSelector = codeSelector;
          message.schemeCodeChanged(schemeID, codeSelector.selectedOption);
          codeSelector.hideWarning();
          selectNextEmptyCodeSelector(messageID, schemeID);
        }
      }
    });

    window.onKeyDown.listen((event) {
      if (event.key == 'Tab') {
        TableRowElement row = parentOfClass(CodeSelector.activeCodeSelector.viewElement, 'message-row');
        String messageID = row.attributes['message-id'];
        selectNextEmptyCodeSelector(messageID, CodeSelector.activeCodeSelector.scheme.schemeID);
        event.preventDefault();
        event.stopPropagation();
        return;
      }

      Map activeShortcuts = {};
      CodeSelector.activeCodeSelector.scheme.codes.forEach((code) {
        activeShortcuts[code['shortcut']] = code['valueID'];
      });
      activeShortcuts[' '] = CodeSelector.emptyCodeValue; // add space as shortcut for unassigning a code

      if (activeShortcuts.keys.contains(event.key)) {
        CodeSelector.activeCodeSelector.selectedOption = activeShortcuts[event.key];
        CodeSelector.activeCodeSelector.hideWarning();
        TableRowElement row = parentOfClass(CodeSelector.activeCodeSelector.viewElement, 'message-row');
        String messageID = row.attributes['message-id'];
        messageMap[messageID].schemeCodeChanged(CodeSelector.activeCodeSelector.scheme.schemeID, CodeSelector.activeCodeSelector.selectedOption);
        selectNextEmptyCodeSelector(messageID, CodeSelector.activeCodeSelector.scheme.schemeID);
        event.preventDefault();
        event.stopPropagation();
        return;
      }
    });
    CodeSelector.activeCodeSelector = messages[0].codeSelectors[0];
  }

  selectNextEmptyCodeSelector(String messageID, String schemeID) {
    MessageViewModel message = messageMap[messageID];
    int codeSelectorIndex = message.codeSelectors.indexWhere((codeSelector) => codeSelector.scheme.schemeID == schemeID);
    if (horizontalCoding) {
      if (codeSelectorIndex < message.codeSelectors.length - 1) { // it's not the code selector in the last column
        CodeSelector.activeCodeSelector = message.codeSelectors[codeSelectorIndex + 1];
        if (CodeSelector.activeCodeSelector.selectedOption != CodeSelector.emptyCodeValue) {
          selectNextEmptyCodeSelector(messageID, CodeSelector.activeCodeSelector.scheme.schemeID);
        }
      } else { // it's the code selector in the last column, move to the next message
        int messageIndex = messages.indexOf(message);
        if (messageIndex < messages.length - 1) { // it's not the last message
          CodeSelector.activeCodeSelector = messages[messageIndex + 1].codeSelectors[0];
          if (CodeSelector.activeCodeSelector.selectedOption != CodeSelector.emptyCodeValue) {
            selectNextEmptyCodeSelector(messages[messageIndex + 1].message.messageID, CodeSelector.activeCodeSelector.scheme.schemeID);
          }
        } else {} // it's the last message, stop
      }
    } else {
      int messageIndex = messages.indexOf(message);
      if (messageIndex < messages.length - 1) { // it's not the last message
        CodeSelector.activeCodeSelector = messages[messageIndex + 1].codeSelectors[codeSelectorIndex];
      } else {} // it's the last message, stop
    }
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

parentOfClass(Element element, String parentClass) {
 Element parent = element;
  while (parent != null) {
    if (parent.classes.contains(parentClass)) {
      return parent;
    } else {
      parent = parent.parent;
    }
  }
  return null; // no parent with the given class.
}
