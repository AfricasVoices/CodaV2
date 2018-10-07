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
    viewElement.setAttribute('message-id', '${message.messageID}');
    viewElement.addCell()
      ..classes.add('message-id')
      ..text = message.messageID;
    viewElement.addCell()
      ..classes.add('message-text')
      ..text = message.text;

    dataset.codeSchemes.forEach((scheme) {
      CodeSelector codeSelector = new CodeSelector(scheme);
      codeSelectors.add(codeSelector);
      // If the message is already labelled in this scheme, select that code.
      var existingLabels = message.labels.where((label) => label.schemeID == scheme.schemeID);
      if (existingLabels.isNotEmpty) {
        Label label = existingLabels.last;
        codeSelector.selectedOption = label.valueID;
      }

      viewElement.addCell()
        ..classes.add('message-code')
        ..append(codeSelector.viewElement);
    });
  }

  schemeCheckChanged(String schemeID, bool checked) {
    if (VERBOSE) print("Message checkbox: ${message.messageID} ${schemeID} $checked");
    fbt.updateMessage(message);
  }

  schemeCodeChanged(String schemeID, String valueID) {
    if (VERBOSE) print("Message code: ${message.messageID} ${schemeID} $valueID");
    fbt.updateMessage(message);

    // Update the checkbox
    CodeSelector selector = codeSelectors.singleWhere((selector) => selector.scheme.schemeID == schemeID);
    if (valueID == CodeSelector.emptyCodeValue) {
      selector.checked = false;
    } else {
      selector.checked = true;
    }
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

  static final String emptyCodeValue = 'unassign';

  Scheme scheme;

  CodeSelector(this.scheme) {
    viewElement = new DivElement();
    viewElement.classes.add('input-group');
    viewElement.attributes['scheme-id'] = scheme.schemeID;

    // TODO: Implement checkbox read from the scheme
    checkbox = new InputElement(type: 'checkbox');
    viewElement.append(checkbox);

    dropdown = new SelectElement();
    dropdown.classes.add('code-selector');
    // An empty code used to unlabel the message
    OptionElement option = new OptionElement();
    option
      ..attributes['schemeid'] = scheme.schemeID
      ..attributes['valueid'] = emptyCodeValue
      ..selected = true;
    dropdown.append(option);
    scheme.codes.forEach((code) {
      OptionElement option = new OptionElement();
      option
        ..attributes['schemeid'] = scheme.schemeID
        ..attributes['valueid'] = code["valueID"]
        ..text = "${code['name']} (${code['shortcut']})";
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

  set selectedOption(String valueID) {
    OptionElement option = dropdown.querySelector('option[valueid="$valueID"]');
    // When the option set programmatically doesn't exist in the scheme, show the warning sign.
    if (option == null) {
      warning
        ..classes.remove('hidden')
        ..attributes['title'] = 'The message is pre-labelled with the code "$valueID" that doesn\'t exist in the scheme';
    } else {
      option.selected = true;
    }
  }

  String get selectedOption => dropdown.selectedOptions[0].attributes['valueid'];
}
