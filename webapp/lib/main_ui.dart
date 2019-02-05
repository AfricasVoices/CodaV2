/**
 * The main UI of the application.
 */
library coda.ui;

import 'dart:convert';
import 'dart:html';
import 'dart:math' as math;

import 'logger.dart' as log;
import 'data_model.dart';
import 'snackbar_ui.dart' as snackbar;
import 'loader_ui.dart' as loader;
import 'authentication.dart' as auth;
import 'firebase_tools.dart' as fbt;

part 'view_model.dart';

CodaUI _codaUI;
CodaUI get codaUI => _codaUI;

void init() async {
  _codaUI = new CodaUI();
  await _codaUI.init();
}

class CodaUI {
  ButtonElement get saveButton => querySelector('#save-all-button');
  Element get messageCodingNavButtons => querySelector('nav #coding-nav');
  DivElement get otherContent => querySelector('#other-content');

  static InputElement horizontalCodingToggle = querySelector('#horizontal-coding');
  static bool get horizontalCoding => horizontalCodingToggle.checked;

  static InputElement continuousSortingCheckbox = querySelector('#continuous-sorting');
  static bool get continuousSorting => continuousSortingCheckbox.checked;

  static InputElement jumpToNextUncodedCheckbox = querySelector('#jump-to-next-uncoded');
  static bool get jumpToNextUncoded => jumpToNextUncodedCheckbox.checked;

  Dataset dataset;
  MessageListViewModel messageList;

  // Cache main elements of the UI
  TableElement messageCodingTable;

  CodaUI();

  init() async {
    await fbt.init();
    auth.init();
    snackbar.init();

    window.onError.listen((e) {
      if (e is! ErrorEvent) {
        log.severe("Unexpected non ErrorEvent error notification ${e.toString()}");
        return;
      }

      var errorEvent = e as ErrorEvent;
      var errorProp = errorEvent.error;

      String stackTrace = errorProp is Error ? errorProp.stackTrace?.toString() : null;
      log.severe(jsonEncode({
        "messageType": "Error",
        "message" : errorEvent.message,
        "filename" : errorEvent.filename,
        "stackTrace" : stackTrace
      }));
    });

    continuousSortingCheckbox.onChange.listen((event) {
      if (continuousSorting) {
        sortTableView();
      }
    });
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

  displayDatasetSelectorView() async {
    clearMessageCodingTable(); // Clear up the table.
    otherContent.innerHtml = ''; // Clear out any of the other content, like error messages.
    messageCodingNavButtons.setAttribute('hidden', 'true'); // Hide coding buttons.
    List<String> availableDatasets = await fbt.getDatasetIdsList();

    otherContent.text = 'Available datasets:';
    UListElement list = new UListElement();
    otherContent.append(list);
    for (String datasetId in availableDatasets) {
      list.append(
        new LIElement()
          ..append(new AnchorElement()
            ..href = '?dataset=$datasetId'
            ..text = datasetId));
    }
  }

  displayDatasetView() async {
    loader.showLoader('Loading dataset');

    // Load the dataset
    String datasetId = Uri.base.queryParameters["dataset"];
    if (datasetId == null) {
      // Show view for selecting datasets to code
      displayDatasetSelectorView();
      loader.hideLoader();
      return;
    }

    try {
      dataset = await fbt.loadDatasetWithOnlyCodeSchemes(datasetId);
      displayDatasetHeadersView(dataset);
    } catch (e, s) {
      displayUrlErrorView(e.toString());

      log.severe(jsonEncode({
        "messageType": "Exception",
        "message" : "Dataset load failed, ${e.toString()}",
        "stackTrace" : s?.toString()
      }));
      loader.hideLoader();
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
      loader.hideLoader();
    });
  }

  displayDatasetHeadersView(Dataset dataset) {
    // Prepare for displaying the dataset view by clearing up the DOM.
    clearMessageCodingTable(); // Clear up the table before loading the new dataset.
    otherContent.innerHtml = ''; // Clear out any of the other content, like error messages.
    messageCodingNavButtons.attributes.remove('hidden'); // Show coding buttons

    // (Re)initialise objects
    this.dataset = dataset;
    this.messageList = new MessageListViewModel();

    messageCodingTable.append(createTableHeader(dataset));
    messageCodingTable.append(createEmptyTableBody(dataset));
    addListenersToMessageCodingTable();
  }

  TableSectionElement createTableHeader(Dataset dataset) {
    TableSectionElement header = new Element.tag('thead');

    TableRowElement headerRow = header.addRow();
    headerRow.addCell()
      ..classes.add('message-seq')
      ..append(new SpanElement()
        ..classes.add('seq-name')
        ..text = 'Seq')
      ..append(new SpanElement()
        ..classes.addAll(['button', 'sort', 'asc']));
    headerRow.addCell()
      ..classes.add('message-text')
      ..text = 'Message';
    dataset.codeSchemes.forEach((codeScheme) {
      headerRow.addCell()
        ..classes.add('message-code')
        ..setAttribute('scheme-id', codeScheme.id)
        ..append(new DivElement()
          ..classes.add('scheme-title')
          ..append(new SpanElement()
            ..classes.add('scheme-name')
            ..text = codeScheme.name)
          ..append(new SpanElement()
            ..classes.addAll(['button', 'sort']))
          ..append(new SpanElement()
            ..classes.add('scheme-id')
            ..text = codeScheme.id));
    });
    return header;
  }

  TableSectionElement createEmptyTableBody(Dataset dataset) {
    return new Element.tag('tbody');
  }

  void addMessagesToView(List<Message> newMessages) {
    TableSectionElement body = messageCodingTable.tBodies.first;

    newMessages.forEach((message) {
      dataset.messages.add(message);
      MessageViewModel messageViewModel = new MessageViewModel(message, dataset);
      int index = messageList.add(dataset, messageViewModel);
      if (index == body.children.length) {
        body.append(messageViewModel.viewElement);
        return;
      }
      body.insertBefore(messageViewModel.viewElement, body.children[index]);
    });

    // It's the first time we're adding messages to the table, select the first code selector
    if (CodeSelector.activeCodeSelector == null) {
      CodeSelector.activeCodeSelector = messageList.messages.first.codeSelectors.first;
    }
  }

  void updateMessagesInView(List<Message> changedMessages) {
    changedMessages.forEach((message) {
      messageList.messageMap[message.id].update(message);
      int index = dataset.messages.indexWhere((m) => m.id == message.id);
      dataset.messages[index] = message;
    });

    if (continuousSorting) {
      sortTableView();
    }
  }

  void sortTableView() {
    messageList.sort(dataset);

    TableSectionElement body = messageCodingTable.tBodies.first;
    var rows = <String, Element>{};
    for (var row in body.children) {
      rows[row.attributes['message-id']] = row;
    }
    body.nodes.clear();

    for (var message in messageList.messages) {
      body.append(rows[message.message.id]);
    }
  }

  addListenersToMessageCodingTable() {
    messageCodingTable.onChange.listen((event) {
      var target = event.target;
      if (target is! InputElement && target is! SelectElement) return;

      TableRowElement row = getAncestors(target).firstWhere((e) => e.classes.contains('message-row'));
      DivElement inputGroup = getAncestors(target).firstWhere((e) => e.classes.contains('input-group'));
      String messageID = row.attributes['message-id'];
      MessageViewModel message = messageList.messageMap[messageID];
      String schemeID = inputGroup.attributes['scheme-id'];

      if (target is InputElement) { // change on checkbox element
        message.schemeCheckChanged(dataset, schemeID, target.checked);
        return;
      }
      if (target is SelectElement) { // change on dropdown select element
        CodeSelector codeSelector = message.getCodeSelectorForSchemeId(schemeID);
        CodeSelector.activeCodeSelector = codeSelector;
        message.schemeCodeChanged(dataset, schemeID, codeSelector.selectedOption);
        if (continuousSorting && messageList.sortBySeqOrSchemeId == schemeID) {
          sortTableView();
        }
        codeSelector.hideWarning();
        selectNextCodeSelector(messageID, schemeID);
      }
    });

    // When clicking on a row, select the first dropdown from that row
    // When clicking around a checkbox or dropdown, select that dropdown
    messageCodingTable.onMouseDown.listen((event) {
      var target = event.target;

      // Change sorting parameters and sort
      if (target is SpanElement && target.classes.contains('sort')) {
        TableCellElement clickedColumn = getAncestors(target).firstWhere((e) => e is TableCellElement);

        if (clickedColumn.classes.contains('message-seq')) {
          messageList.sortBySeqOrSchemeId = 'seq';
        } else if (clickedColumn.classes.contains('message-code')) {
          messageList.sortBySeqOrSchemeId = clickedColumn.getAttribute('scheme-id');
        } else {
          return;
        }

        if (target.classes.contains('asc')) {
          messageCodingTable.tHead.querySelectorAll('.asc').forEach((e) => e.classes.toggle('asc', false));
          messageCodingTable.tHead.querySelectorAll('.desc').forEach((e) => e.classes.toggle('desc', false));
          target.classes.toggle('desc', true);
          messageList.sortAscending = false;
        } else {
          messageCodingTable.tHead.querySelectorAll('.asc').forEach((e) => e.classes.toggle('asc', false));
          messageCodingTable.tHead.querySelectorAll('.desc').forEach((e) => e.classes.toggle('desc', false));
          target.classes.toggle('asc', true);
          messageList.sortAscending = true;
        }

        sortTableView();
        CodeSelector.activeCodeSelector.focus();
        return;
      }

      // Select message row and dropdown
      TableRowElement clickedRow = getAncestors(target).firstWhere((e) => e.classes.contains('message-row'), orElse: () => null);
      TableCellElement messageCodeCell = getAncestors(target).firstWhere((e) => e.classes.contains('message-code'), orElse: () => null);

      // Don't do anything if user didn't click on a message row (e.g. they clicked on the header)
      if (clickedRow == null) {
        return;
      }

       // Select first code selector if user clicked on the message text or id
      if (clickedRow != null && messageCodeCell == null) {
        // If the row clicked is the same as the row with the already selected dropdown, don't do anything
        TableRowElement activeSelectorRow = getAncestors(CodeSelector.activeCodeSelector.viewElement).firstWhere((e) => e.classes.contains('message-row'));
        if (clickedRow == activeSelectorRow) return;

        // Select the first code selector in the clicked row
        String messageID = clickedRow.attributes['message-id'];
        MessageViewModel message = messageList.messageMap[messageID];
        CodeSelector.activeCodeSelector = message.codeSelectors[0];
        return;
      }

      // Select dropdown if user clicked on or around a checkbox or dropdown
      if (messageCodeCell != null) {
        DivElement inputGroup = messageCodeCell.firstChild;
        String messageID = clickedRow.attributes['message-id'];
        MessageViewModel message = messageList.messageMap[messageID];
        String schemeID = inputGroup.attributes['scheme-id'];
        CodeSelector codeSelector = message.getCodeSelectorForSchemeId(schemeID);
        CodeSelector.activeCodeSelector = codeSelector;
      }
    });

    messageCodingTable.onKeyDown.listen((event) {
      if (event.metaKey || event.ctrlKey || event.altKey) return;

      CodeSelector activeCodeSelector = CodeSelector.activeCodeSelector;
      TableRowElement row = getAncestors(CodeSelector.activeCodeSelector.viewElement).firstWhere((e) => e.classes.contains('message-row'));
      String messageId = row.attributes['message-id'];
      
      if (event.key == 'Tab') {
        selectNextCodeSelector(messageId, activeCodeSelector.scheme.id);
        event.preventDefault();
        event.stopPropagation();
        return;
      }

      if (event.key == 'Enter') {
        InputElement checkbox = activeCodeSelector.checkbox;

        if (checkbox.checked) { // Nothing to do here, move onto the next code selector
          selectNextCodeSelector(messageId, activeCodeSelector.scheme.id);
          event.preventDefault();
          event.stopPropagation();
          return;
        }

        checkbox.checked = true;
        messageList.messageMap[messageId].schemeCheckChanged(dataset, activeCodeSelector.scheme.id, checkbox.checked);
        selectNextCodeSelector(messageId, activeCodeSelector.scheme.id);
        event.preventDefault();
        event.stopPropagation();
        return;
      }

      Map activeShortcuts = {};
      CodeSelector.activeCodeSelector.scheme.codes.forEach((code) {
        if (code.shortcut == null) return;
        activeShortcuts[code.shortcut] = code.id;
      });
      activeShortcuts[' '] = CodeSelector.EMPTY_CODE_VALUE; // add space as shortcut for unassigning a code

      if (activeShortcuts.keys.contains(event.key)) {
        activeCodeSelector.selectedOption = activeShortcuts[event.key];
        activeCodeSelector.isManualLabel = true;
        activeCodeSelector.hideWarning();
        selectNextCodeSelector(messageId, activeCodeSelector.scheme.id);
        messageList.messageMap[messageId].schemeCodeChanged(dataset, activeCodeSelector.scheme.id, activeCodeSelector.selectedOption);
        if (continuousSorting && messageList.sortBySeqOrSchemeId == activeCodeSelector.scheme.id) {
          sortTableView();
        }
        CodeSelector.activeCodeSelector.focus();
        event.preventDefault();
        event.stopPropagation();
        return;
      }
    });
  }

  selectNextCodeSelector(String messageID, String schemeID) {
    if (horizontalCoding) {
      selectNextCodeSelectorHorizontal(messageID, schemeID);
    } else {
      selectNextCodeSelectorVertical(messageID, schemeID);
    }
  }

  selectNextCodeSelectorHorizontal(String messageID, String schemeID) {
    MessageViewModel message = messageList.messageMap[messageID];
    int codeSelectorIndex = message.codeSelectors.indexWhere((codeSelector) => codeSelector.scheme.id == schemeID);

    if (codeSelectorIndex < message.codeSelectors.length - 1) { // it's not the code selector in the last column, move to the next column
      CodeSelector.activeCodeSelector = message.codeSelectors[codeSelectorIndex + 1];
      if (jumpToNextUncoded && CodeSelector.activeCodeSelector.selectedOption != CodeSelector.EMPTY_CODE_VALUE) {
        selectNextCodeSelectorHorizontal(messageID, CodeSelector.activeCodeSelector.scheme.id);
      }
    } else { // it's the code selector in the last column, move to the next message
      int messageIndex = messageList.messages.indexOf(message);
      if (messageIndex < messageList.messages.length - 1) { // it's not the last message
        CodeSelector.activeCodeSelector = messageList.messages[messageIndex + 1].codeSelectors[0];
        if (jumpToNextUncoded && CodeSelector.activeCodeSelector.selectedOption != CodeSelector.EMPTY_CODE_VALUE) {
          selectNextCodeSelectorHorizontal(messageList.messages[messageIndex + 1].message.id, CodeSelector.activeCodeSelector.scheme.id);
        }
      } // else, it's the last message, stop
    }
  }

  selectNextCodeSelectorVertical(String messageID, String schemeID) {
    MessageViewModel message = messageList.messageMap[messageID];
    int codeSelectorIndex = message.codeSelectors.indexWhere((codeSelector) => codeSelector.scheme.id == schemeID);
    int messageIndex = messageList.messages.indexOf(message);
    if (messageIndex < messageList.messages.length - 1) { // it's not the last message
      CodeSelector.activeCodeSelector = messageList.messages[messageIndex + 1].codeSelectors[codeSelectorIndex];
      if (jumpToNextUncoded && CodeSelector.activeCodeSelector.selectedOption != CodeSelector.EMPTY_CODE_VALUE) {
        selectNextCodeSelectorVertical(messageList.messages[messageIndex + 1].message.id, CodeSelector.activeCodeSelector.scheme.id);
      }
    } // else, it's the last message, stop
  }

  void clearMessageCodingTable() {
    messageCodingTable?.remove();
    messageCodingTable = new TableElement();
    messageCodingTable.id = 'message-coding-table';
    messageCodingTable.tabIndex = 1;
    Element main = querySelector('main');
    main.insertBefore(messageCodingTable, main.firstChild);
    messageList = null;
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
