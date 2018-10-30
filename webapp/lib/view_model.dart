/**
 * Represents the ViewModel of the application, mediating between the data model and the HTML view.
 */
part of coda.ui;

/// A typedef for the listener function to be called when a checkbox is changed.
typedef void CheckboxChanged(bool checked);
/// A typedef for the listener function to be called when the selected option in a selector is changed.
typedef void SelectorChanged(String valueID);

/// Maintains a sorted view model over the list of messages.
class MessageListViewModel {
  List<MessageViewModel> messages = [];
  Map<String, MessageViewModel> messageMap = {};

  MessageListViewModel();

  String sortBySeqOrSchemeId = "seq";
  bool sortAscending = true;

  int add(Dataset dataset, MessageViewModel messageViewModel) {
    messages.add(messageViewModel);
    messageMap[messageViewModel.message.id] = messageViewModel;
    sort(dataset);
    return messages.indexOf(messageViewModel);
  }

  void sort(Dataset dataset) {
    if (messages.length == 0) return;

    if (sortBySeqOrSchemeId == "seq") {
      messages.sort(
        (a, b) => sortAscending ? a.message.sequenceNumber.compareTo(b.message.sequenceNumber)
                                : b.message.sequenceNumber.compareTo(a.message.sequenceNumber));
      return;
    }

    Scheme scheme = dataset.codeSchemes.singleWhere((s) => s.id == sortBySeqOrSchemeId);
    var codeCompare = <MessageViewModel, String>{};
    for (var message in messages) {
      String codeId = message.getLatestLabelForSchemeId(sortBySeqOrSchemeId)?.codeId;
      String codeName;
      if (codeId == null || codeId == Label.MANUALLY_UNCODED) {
        codeName = '~';
      } else {
        codeName = scheme.codes.singleWhere((c) => c.id == codeId).displayText;
      }
      String sequenceNumber = message.message.sequenceNumber.toString().padLeft(10, '0');
      String aCompareString = '$codeName-$sequenceNumber';

      codeCompare[message] = aCompareString;
    }
    messages.sort(
      (a, b) => sortAscending ? codeCompare[a].compareTo(codeCompare[b])
                              : codeCompare[b].compareTo(codeCompare[a]));
  }

  labelMessage(Dataset dataset, String messageId, String schemeId, String selectedOption) {
    messageMap[messageId].schemeCodeChanged(dataset, schemeId, selectedOption);
    sort(dataset);
  }
}

/// A ViewModel for a message, corresponding to a table row in the UI.
class MessageViewModel {
  Message message;
  TableRowElement viewElement;
  List<CodeSelector> codeSelectors = [];

  MessageViewModel(this.message, Dataset dataset) {
    viewElement = new TableRowElement();
    viewElement.classes.add('message-row');
    viewElement.setAttribute('message-id', '${message.id}');
    viewElement.addCell()
      ..classes.add('message-seq')
      ..text = '${message.sequenceNumber}';
    viewElement.addCell()
      ..classes.add('message-text')
      ..text = message.text;

    dataset.codeSchemes.forEach((scheme) {
      CodeSelector codeSelector = new CodeSelector(scheme);
      codeSelectors.add(codeSelector);
      displayLatestLabelForCodeSelector(codeSelector);
      viewElement.addCell()
        ..classes.add('message-code')
        ..append(codeSelector.viewElement);
    });
  }

  schemeCheckChanged(Dataset dataset, String schemeId, bool checked) {
    final messageId = message.id;
    log.verbose("Message checkbox: $messageId $schemeId => $checked");

    var existingLabels = message.labels.where((label) => label.schemeId == schemeId);
    // Don't allow checking when a code hasn't been picked from the scheme
    if (existingLabels.isEmpty || existingLabels.first.codeId == Label.MANUALLY_UNCODED) {
      getCodeSelectorForSchemeId(schemeId).checked = false;
      log.verbose("Cancel message checkbox change on empty code: $messageId $schemeId");
      return;
    }
    // Add a new label which is the current label with the changed checkbox
    Label currentLabel = existingLabels.first;
    message.labels.insert(0,
      new Label(schemeId, new DateTime.now().toUtc(), currentLabel.codeId,
        new Origin(auth.getUserEmail(), auth.getUserName()),
        checked: checked
        ));
    fbt.updateMessage(dataset, message);

    // Update the origin
    displayLatestLabelForCodeSelector(getCodeSelectorForSchemeId(schemeId));
  }

  schemeCodeChanged(Dataset dataset, String schemeId, String codeId) {
    final messageId = message.id;
    log.verbose("Message code-value: $messageId $schemeId => $codeId");

    // If uncoding a previously coded message, mark it with a special label
    // Also prepare the checkbox status
    bool checked;
    if (codeId == CodeSelector.EMPTY_CODE_VALUE) {
      codeId = Label.MANUALLY_UNCODED;
      checked = false;
    } else {
      checked = true;
    }

    // Update the data-model by prepending this decision
    message.labels.insert(0,
      new Label(schemeId, new DateTime.now().toUtc(), codeId,
        new Origin(auth.getUserEmail(), auth.getUserName()),
        checked: checked
        ));
    fbt.updateMessage(dataset, message);

    // Update the checkbox and origin
    displayLatestLabelForCodeSelector(getCodeSelectorForSchemeId(schemeId));
  }

  void update(Message newMessage) {
    // The only changes we expect are in the coding, so warn if the id or text has changed.
    if (newMessage.id != message.id) {
      log.log("updateMessage: Warning! The ID of the updated message (id=${newMessage.id}) differs from the ID of the existing message (id=${message.id})");
    }
    if (newMessage.text != message.text) {
      log.log("updateMessage: Warning! The text of the updated message differs from the ID of the existing message (message-seq=${message.id})");
    }
    this.message = newMessage;
    codeSelectors.forEach((codeSelector) => displayLatestLabelForCodeSelector(codeSelector));
  }

  CodeSelector getCodeSelectorForSchemeId(String schemeId) =>
    codeSelectors.singleWhere((selector) => selector.scheme.id == schemeId);

  Label getLatestLabelForSchemeId(String schemeId) {
    var existingLabels = message.labels.where((label) => label.schemeId == schemeId);
    if (existingLabels.isNotEmpty) {
      return existingLabels.first;
    }
    return null;
  }

  void displayLatestLabelForCodeSelector(CodeSelector codeSelector) {
    Label label = getLatestLabelForSchemeId(codeSelector.scheme.id);
    if (label != null) {
      codeSelector.selectedOption = label.codeId == Label.MANUALLY_UNCODED ? CodeSelector.EMPTY_CODE_VALUE : label.codeId;
      codeSelector.checked = label.checked;
      codeSelector.origin = label.labelOrigin.name;
      return;
    }
    codeSelector.selectedOption = CodeSelector.EMPTY_CODE_VALUE;
    codeSelector.checked = false;
    codeSelector.origin = '';
  }
}

/// A dropdown code selector used to label a message within a coding scheme.
class CodeSelector {
  DivElement viewElement;
  InputElement checkbox;
  SelectElement dropdown;
  Element warning;
  DivElement originElement;

  static CodeSelector _activeCodeSelector;
  static CodeSelector get activeCodeSelector => _activeCodeSelector;
  static set activeCodeSelector(CodeSelector activeCodeSelector) {
    _activeCodeSelector?.viewElement?.classes?.toggle('active', false);

    if (_activeCodeSelector?.viewElement != null) {
      Element messageElement = getAncestors(_activeCodeSelector.viewElement).firstWhere((a) => a.classes.contains('message-row'));
      messageElement.classes.toggle('active', false);
    }
    // _activeCodeSelector?.viewElement?.parent?.parent?.classes?
    // Focus on the new code selector
    _activeCodeSelector = activeCodeSelector;
    _activeCodeSelector.viewElement.classes.toggle('active', true);
    if (_activeCodeSelector?.viewElement != null) {
      Element messageElement = getAncestors(_activeCodeSelector.viewElement).firstWhere((a) => a.classes.contains('message-row'));
      messageElement.classes.toggle('active', true);
    }
    _activeCodeSelector.dropdown.focus();
  }

  static const EMPTY_CODE_VALUE = 'unassign';

  Scheme scheme;

  CodeSelector(this.scheme) {
    viewElement = new DivElement();
    viewElement.classes.add('input-group');
    viewElement.attributes['scheme-id'] = scheme.id;

    // TODO: Implement checkbox read from the scheme
    checkbox = new InputElement(type: 'checkbox');
    viewElement.append(checkbox);

    dropdown = new SelectElement();
    dropdown.classes.add('code-selector');
    // An empty code used to unlabel the message
    OptionElement option = new OptionElement();
    option
      ..attributes['schemeid'] = scheme.id
      ..attributes['valueid'] = EMPTY_CODE_VALUE
      ..selected = true;
    dropdown.append(option);
    scheme.codes.forEach((code) {
      if (!code.visibleInCoda) return;

      OptionElement option = new OptionElement();
      option
        ..attributes['schemeid'] = scheme.id
        ..attributes['valueid'] = code.id
        ..text = "${code.displayText} (${code.shortcut})";
      dropdown.append(option);
    });
    viewElement.append(dropdown);

    warning = new SpanElement();
    warning
      ..classes.add('warning')
      ..classes.add('hidden')
      ..attributes['data-toggle'] = 'tooltip'
      ..attributes['data-placement'] = 'bottom'
      ..attributes['title'] = 'Latest code is not in code scheme or is not visible in Coda'
      ..text = '!';
    viewElement.append(warning);

    originElement = new DivElement();
    originElement.classes.add('origin');
    viewElement.append(originElement);
  }

  /// When an option from the list has been selected manually, the warning message should be hidden if it's not already.
  hideWarning() => warning.classes.toggle('hidden', true);

  set checked(bool checked) => checkbox.checked = checked;
  bool get checked => checkbox.checked;

  set selectedOption(String codeId) {
    OptionElement option = dropdown.querySelector('option[valueid="$codeId"]');
    // When the option set programmatically doesn't exist in the scheme, show the warning sign.
    if (option == null) {
      warning
        ..classes.remove('hidden')
        ..attributes['title'] = 'The message is pre-labelled with the code "$codeId" that doesn\'t exist in the scheme';
    } else {
      option.selected = true;
    }
  }

  String get selectedOption => dropdown.selectedOptions[0].attributes['valueid'];

  set origin(String text) => originElement.text = text;

  focus() {
    dropdown.focus();
  }
}
