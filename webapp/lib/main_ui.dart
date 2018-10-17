/**
 * The main UI of the application.
 */
library coda.ui;

import 'dart:html';

import 'logger.dart' as log;
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
  DivElement get loaderAnimation => querySelector('#loader');
  Element get messageCodingNavButtons => querySelector('nav #coding-nav');
  DivElement get otherContent => querySelector('#other-content');

  static InputElement horizontalCodingToggle = querySelector('#horizontal-coding');
  static bool get horizontalCoding => horizontalCodingToggle.checked;

  Dataset dataset;
  List<MessageViewModel> messages;
  Map<String, MessageViewModel> messageMap;

  // Cache main elements of the UI
  TableElement messageCodingTable;

  CodaUI() {
    fbt.init();
    auth.init();
  }

  displaySignedOutView() {
    clearMessageCodingTable(); // Clear up the table.
    otherContent.innerHtml = ''; // Clear out any of the other content, like error messages.
    messageCodingNavButtons.setAttribute('hidden', 'true'); // Hide coding buttons.
  }

  displayUrlErrorView(String text) {
    clearMessageCodingTable(); // Clear up the table.
    otherContent.innerHtml = ''; // Clear out any of the other content, like error messages.
    messageCodingNavButtons.setAttribute('hidden', 'true'); // Hide coding buttons.
    otherContent.text = text;
  }

  displayDatasetView() async {
    showLoader();

    // Load the dataset
    String datasetId = Uri.base.queryParameters["dataset"];
    try {
      dataset = await fbt.loadDatasetWithOnlyCodeSchemes(datasetId);
      displayDatasetHeadersView(dataset);
    } catch (e, s) {
      displayUrlErrorView(e.toString());
      log.verbose(e.toString());
      log.verbose(s.toString());
      hideLoader();
      return;
    }

    fbt.setupListenerForFirebaseMessageUpdates(dataset, (List<Message> messages, fbt.ChangeType changeType) {
      switch(changeType) {
        case fbt.ChangeType.added:
          addMessagesToView(messages);
          break;
        case fbt.ChangeType.modified:
          updateMessagesInView(messages);
          break;
        default:
          throw "Change type '$changeType' not supported.";
      }
      hideLoader();
    });
  }

  displayDatasetHeadersView(Dataset dataset) {
    // Prepare for displaying the dataset view by clearing up the DOM.
    clearMessageCodingTable(); // Clear up the table before loading the new dataset.
    otherContent.innerHtml = ''; // Clear out any of the other content, like error messages.
    messageCodingNavButtons.attributes.remove('hidden'); // Show coding buttons

    // (Re)initialise objects
    this.dataset = dataset;
    this.messages = [];
    this.messageMap = {};

    messageCodingTable.append(createTableHeader(dataset));
    messageCodingTable.append(createEmptyTableBody(dataset));
    addListenersToMessageCodingTable();
  }

  TableSectionElement createTableHeader(Dataset dataset) {
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
        ..text = codeScheme.id;
    });
    return header;
  }

  TableSectionElement createEmptyTableBody(Dataset dataset) {
    return new Element.tag('tbody');
  }

  void addMessagesToView(List<Message> newMessages) {
    TableSectionElement body = messageCodingTable.tBodies.first;

    newMessages.forEach((message) {
      MessageViewModel messageViewModel = new MessageViewModel(message, dataset);
      messages.add(messageViewModel);
      messageMap[message.id] = messageViewModel;
      dataset.messages.add(message);
      body.append(messageViewModel.viewElement);
    });

    // It's the first time we're adding messages to the table, select the first code selector
    if (CodeSelector.activeCodeSelector == null) {
      CodeSelector.activeCodeSelector = messages.first.codeSelectors.first;
    }
  }

  void updateMessagesInView(List<Message> changedMessages) {
    changedMessages.forEach((message) {
      messageMap[message.id].update(message);
      int index = dataset.messages.indexWhere((m) => m.id == message.id);
      dataset.messages[index] = message;
    });
  }

  addListenersToMessageCodingTable() {
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

    messageCodingTable.onKeyDown.listen((event) {
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
        activeShortcuts[code.shortcut] = code.id;
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

  void clearMessageCodingTable() {
    messageCodingTable?.remove();
    messageCodingTable = new TableElement();
    messageCodingTable.id = 'message-coding-table';
    Element main = querySelector('main');
    main.insertBefore(messageCodingTable, main.firstChild);
  }

  void showLoader() {
    loaderAnimation.attributes.remove('hidden');
  }

  void hideLoader() {
    loaderAnimation.setAttribute('hidden', 'true');
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
