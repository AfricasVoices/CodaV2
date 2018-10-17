/**
 * Represents the ViewModel of the application, mediating between the data model and the HTML view.
 */
part of coda.ui;

/// A typedef for the listener function to be called when a checkbox is changed.
typedef void CheckboxChanged(bool checked);
/// A typedef for the listener function to be called when the selected option in a selector is changed.
typedef void SelectorChanged(String valueID);

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
      ..classes.add('message-id')
      ..text = message.id;
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
      codeSelectors.singleWhere((cs) => cs.scheme.id == schemeId).checked = false;
      log.verbose("Cancel message checkbox change on empty code: $messageId $schemeId");
      return;
    }
    // Add a new label which is the current label with the changed checkbox
    Label currentLabel = existingLabels.first;
    message.labels.insert(0,
      new Label(schemeId, new DateTime.now(), currentLabel.codeId,
        new Origin(auth.getUserEmail(), auth.getUserName()),
        checked: checked
        ));
    fbt.updateMessage(dataset, message);
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

    // Update the checkbox
    codeSelectors.singleWhere((selector) => selector.scheme.id == schemeId).checked = checked;

    // Update the data-model by prepending this decision
    message.labels.insert(0,
      new Label(schemeId, new DateTime.now(), codeId,
        new Origin(auth.getUserEmail(), auth.getUserName()),
        checked: checked
        ));
    fbt.updateMessage(dataset, message);
  }

  void update(Message newMessage) {
    // The only changes we expect are in the coding, so warn if the id or text has changed.
    if (newMessage.id != message.id) {
      log.log("updateMessage: Warning! The ID of the updated message (id=${newMessage.id}) differs from the ID of the existing message (id=${message.id})");
    }
    if (newMessage.text != message.text) {
      log.log("updateMessage: Warning! The text of the updated message differs from the ID of the existing message (message-id=${message.id})");
    }
    this.message = newMessage;
    codeSelectors.forEach((codeSelector) => displayLatestLabelForCodeSelector(codeSelector));
  }

  Label getLatestLabelForScheme(Scheme scheme) {
    var existingLabels = message.labels.where((label) => label.schemeId == scheme.id);
    if (existingLabels.isNotEmpty) {
      return existingLabels.first;
    }
    return null;
  }
  void displayLatestLabelForCodeSelector(CodeSelector codeSelector) {
    Label label = getLatestLabelForScheme(codeSelector.scheme);
    if (label != null) {
      codeSelector.selectedOption = label.codeId == Label.MANUALLY_UNCODED ? CodeSelector.EMPTY_CODE_VALUE : label.codeId;
      codeSelector.checked = label.checked;
      return;
    }
    codeSelector.selectedOption = CodeSelector.EMPTY_CODE_VALUE;
  }
}

/// A dropdown code selector used to label a message within a coding scheme.
class CodeSelector {
  DivElement viewElement;
  InputElement checkbox;
  SelectElement dropdown;
  Element warning;

  static CodeSelector _activeCodeSelector;
  static CodeSelector get activeCodeSelector => _activeCodeSelector;
  static set activeCodeSelector(CodeSelector activeCodeSelector) {
    _activeCodeSelector?.viewElement?.classes?.toggle('active', false);
    // Focus on the new code selector
    _activeCodeSelector = activeCodeSelector;
    _activeCodeSelector.viewElement.classes.toggle('active', true);
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
      OptionElement option = new OptionElement();
      option
        ..attributes['schemeid'] = scheme.id
        ..attributes['valueid'] = code.id
        ..text = "${code.displayText} (${code.shortcut})";
      dropdown.append(option);
    });
    viewElement.append(dropdown);

    warning = new Element.tag('i');
    warning
      ..classes.add('fas')
      ..classes.add('fa-exclamation')
      ..classes.add('warning')
      ..classes.add('hidden')
      ..attributes['data-toggle'] = 'tooltip'
      ..attributes['data-placement'] = 'bottom';
    viewElement.append(warning);
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
}
