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

CodaUI _codaUI;
CodaUI get codaUI => _codaUI;

void init() {
  _codaUI = new CodaUI();
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
      messageMap[message.id] = messageViewModel;
      body.append(messageViewModel.viewElement);
    });
    messageCodingTable.append(body);

    messageCodingTable.onChange.listen((event) {
      var target = event.target;
      if (target is! InputElement && target is! SelectElement) return;

      TableRowElement row = getAncestors(target).firstWhere((e) => e.classes.contains('message-row'));
      DivElement inputGroup = getAncestors(target).firstWhere((e) => e.classes.contains('input-group'));
      String messageID = row.attributes['message-id'];
      MessageViewModel message = messageMap[messageID];
      String schemeID = inputGroup.attributes['scheme-id'];

      if (target is InputElement) { // change on checkbox element
        message.schemeCheckChanged(dataset, schemeID, target.checked);
        return;
      }
      if (target is SelectElement) { // change on dropdown select element
        CodeSelector codeSelector = message.codeSelectors.singleWhere((codeSelector) => codeSelector.scheme.id == schemeID);
        CodeSelector.activeCodeSelector = codeSelector;
        message.schemeCodeChanged(dataset, schemeID, codeSelector.selectedOption);
        codeSelector.hideWarning();
        selectNextEmptyCodeSelector(messageID, schemeID);
      }
    });

    // When clicking on a row, select the first dropdown from that row
    // When clicking around a checkbox or dropdown, select that dropdown
    messageCodingTable.onMouseDown.listen((event) {
      var target = event.target;
      TableRowElement clickedRow = getAncestors(target).firstWhere((e) => e.classes.contains('message-row'), orElse: () => null);
      TableCellElement messageCodeCell = getAncestors(target).firstWhere((e) => e.classes.contains('message-code'), orElse: () => null);

       // User clicked on the message text or id
      if (clickedRow != null && messageCodeCell == null) {
        // If the row clicked is the same as the row with the already selected dropdown, don't do anything
        TableRowElement activeSelectorRow = getAncestors(CodeSelector.activeCodeSelector.viewElement).firstWhere((e) => e.classes.contains('message-row'));
        if (clickedRow == activeSelectorRow) return;

        // Select the first code selector in the clicked row
        String messageID = clickedRow.attributes['message-id'];
        MessageViewModel message = messageMap[messageID];
        CodeSelector.activeCodeSelector = message.codeSelectors[0];

        return;
      }

      // User clicked on or around a checkbox or dropdown
      if (messageCodeCell != null) {
        var inputGroupOrText = messageCodeCell.firstChild;
        // There is text instead of the correct div.input-group element only for the header, so we exit earlier in this case.
        if (inputGroupOrText is Text) return;
        DivElement inputGroup = inputGroupOrText;

        // Select the dropdown in the clicked table cell
        String messageID = clickedRow.attributes['message-id'];
        MessageViewModel message = messageMap[messageID];
        String schemeID = inputGroup.attributes['scheme-id'];
        CodeSelector codeSelector = message.codeSelectors.singleWhere((codeSelector) => codeSelector.scheme.id == schemeID);
        CodeSelector.activeCodeSelector = codeSelector;
      }

    });

    window.onKeyDown.listen((event) {
      if (event.key == 'Tab') {
        TableRowElement row = getAncestors(CodeSelector.activeCodeSelector.viewElement).firstWhere((e) => e.classes.contains('message-row'));
        String messageID = row.attributes['message-id'];
        selectNextEmptyCodeSelector(messageID, CodeSelector.activeCodeSelector.scheme.id);
        event.preventDefault();
        event.stopPropagation();
        return;
      }

      Map activeShortcuts = {};
      CodeSelector.activeCodeSelector.scheme.codes.forEach((code) {
        activeShortcuts[code['shortcut']] = code['valueID'];
      });
      activeShortcuts[' '] = CodeSelector.EMPTY_CODE_VALUE; // add space as shortcut for unassigning a code

      if (activeShortcuts.keys.contains(event.key)) {
        CodeSelector.activeCodeSelector.selectedOption = activeShortcuts[event.key];
        CodeSelector.activeCodeSelector.hideWarning();
        TableRowElement row = getAncestors(CodeSelector.activeCodeSelector.viewElement).firstWhere((e) => e.classes.contains('message-row'));
        String messageId = row.attributes['message-id'];
        messageMap[messageId].schemeCodeChanged(dataset, CodeSelector.activeCodeSelector.scheme.id, CodeSelector.activeCodeSelector.selectedOption);
        selectNextEmptyCodeSelector(messageId, CodeSelector.activeCodeSelector.scheme.id);
        event.preventDefault();
        event.stopPropagation();
        return;
      }
    });
    CodeSelector.activeCodeSelector = messages[0].codeSelectors[0];
  }

  selectNextEmptyCodeSelector(String messageID, String schemeID) {
    if (horizontalCoding) {
      selectNextEmptyCodeSelectorHorizontal(messageID, schemeID);
    } else {
      selectNextEmptyCodeSelectorVertical(messageID, schemeID);
    }

    // TODO: scroll into view if needed
  }

  selectNextEmptyCodeSelectorHorizontal(String messageID, String schemeID) {
    MessageViewModel message = messageMap[messageID];
    int codeSelectorIndex = message.codeSelectors.indexWhere((codeSelector) => codeSelector.scheme.id == schemeID);

    if (codeSelectorIndex < message.codeSelectors.length - 1) { // it's not the code selector in the last column, move to the next column
      CodeSelector.activeCodeSelector = message.codeSelectors[codeSelectorIndex + 1];
      if (CodeSelector.activeCodeSelector.selectedOption != CodeSelector.EMPTY_CODE_VALUE) {
        selectNextEmptyCodeSelectorHorizontal(messageID, CodeSelector.activeCodeSelector.scheme.id);
      }
    } else { // it's the code selector in the last column, move to the next message
      int messageIndex = messages.indexOf(message);
      if (messageIndex < messages.length - 1) { // it's not the last message
        CodeSelector.activeCodeSelector = messages[messageIndex + 1].codeSelectors[0];
        if (CodeSelector.activeCodeSelector.selectedOption != CodeSelector.EMPTY_CODE_VALUE) {
          selectNextEmptyCodeSelectorHorizontal(messages[messageIndex + 1].message.id, CodeSelector.activeCodeSelector.scheme.id);
        }
      } // else, it's the last message, stop
    }
  }

  selectNextEmptyCodeSelectorVertical(String messageID, String schemeID) {
    MessageViewModel message = messageMap[messageID];
    int codeSelectorIndex = message.codeSelectors.indexWhere((codeSelector) => codeSelector.scheme.id == schemeID);
    int messageIndex = messages.indexOf(message);
    if (messageIndex < messages.length - 1) { // it's not the last message
      CodeSelector.activeCodeSelector = messages[messageIndex + 1].codeSelectors[codeSelectorIndex];
    } // else, it's the last message, stop
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
        ..text = codeScheme.id;
    });
    return header;
  }

  void clearMessageCodingTable() {
    this.tableHead?.remove();
    this.tableBody?.remove();
  }
}

List<Element> getAncestors(Element element) {
  List<Element> ancestors = [element];
  while (element != null) {
    ancestors.add(element);
    element = element.parent;
  }
  return ancestors;
}
