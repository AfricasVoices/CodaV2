/**
 * Represents the ViewModel of the application, mediating between the data model and the HTML view.
 */
library coda.viewmodel;

import 'dart:html';

import 'data_model.dart';
import 'config.dart';
import 'firebase_tools.dart' as fbt;
import 'authentication.dart' as auth;

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
    viewElement.addCell()
      ..classes.add('message-id')
      ..text = message.id;
    viewElement.addCell()
      ..classes.add('message-text')
      ..text = message.text;

    dataset.codeSchemes.forEach((scheme) {
      CodeSelector codeSelector = new CodeSelector(scheme);
      codeSelectors.add(codeSelector);
      // If the message is already labelled in this scheme, select that code.
      var existingLabels = message.labels.where((label) => label.schemeID == scheme.id);
      if (existingLabels.isNotEmpty) {
        Label label = existingLabels.first;
        codeSelector.selectedOption = label.valueID;
      }

      codeSelector.addCheckboxListener((bool checked) {
        if (VERBOSE) print("Message checkbox: ${message.id} $checked");
        fbt.updateMessage(dataset, message);
      });
      codeSelector.addCodeSelectorListener((String valueID) {
        final messageId = message.id;
        final schemeId = scheme.id;
        if (VERBOSE) print("Message code-value: $messageId $schemeId => $valueID");

        // Update the data-model by prepending this decision
        message.labels.add(
          new Label(schemeId, new DateTime.now(), valueID, 
            new Origin(auth.getUserEmail(), auth.getUserName())
            ));
        fbt.updateMessage(dataset, message);
      });
      viewElement.addCell()
        ..classes.add('message-code')
        ..append(codeSelector.viewElement);
    });
  }
}

/// A dropdown code selector used to label a message within a coding scheme.
class CodeSelector {
  DivElement viewElement;
  InputElement checkbox;
  SelectElement codeSelector;
  Element warning;

  CodeSelector(Scheme scheme) {
    viewElement = new DivElement();
    viewElement.classes.add('input-group');
    viewElement.attributes['scheme'] = scheme.id;

    checkbox = new InputElement(type: 'checkbox');
    viewElement.append(checkbox);

    codeSelector = new SelectElement();
    codeSelector.classes.add('code-selector');
    // An empty code used to unlabel the message
    OptionElement option = new OptionElement();
    option
      ..attributes['schemeid'] = scheme.id
      ..attributes['valueid'] = 'unassign'
      ..selected = true;
    codeSelector.append(option);
    scheme.codes.forEach((code) {
      OptionElement option = new OptionElement();
      option
        ..attributes['schemeid'] = scheme.id
        ..attributes['valueid'] = code["valueID"]
        ..text = code['name'];
      codeSelector.append(option);
    });
    viewElement.append(codeSelector);

    warning = new Element.tag('i');
    warning
      ..classes.add('fas')
      ..classes.add('fa-exclamation')
      ..classes.add('warning')
      ..classes.add('hidden')
      ..attributes['data-toggle'] = 'tooltip'
      ..attributes['data-placement'] = 'bottom';
    viewElement.append(warning);
    // When an option from the list has been selected manually, the warning message should be hidden if it's not already.
    addCodeSelectorListener((String valueID) => warning.classes.toggle('hidden', true));
  }

  addCheckboxListener(CheckboxChanged checkboxChanged) {
    checkbox.onChange.listen((event) {
      checkboxChanged(checkbox.checked);
    });
  }

  addCodeSelectorListener(SelectorChanged selectorChanged) {
    codeSelector.onChange.listen((event) {
      selectorChanged(codeSelector.selectedOptions[0].attributes["valueid"]);
    });
  }

  set checked(bool checked) => checkbox.checked = checked;
  bool get checked => checkbox.checked;

  set selectedOption(String valueID) {
    OptionElement option = codeSelector.querySelector('option[valueid="$valueID"]');
    // When the option set programmatically doesn't exist in the scheme, show the warning sign.
    if (option == null) {
      warning
        ..classes.remove('hidden')
        ..attributes['title'] = 'The message is pre-labelled with the code "$valueID" that doesn\'t exist in the scheme';
    } else {
      option.selected = true;
    }
  }

  String get selectedOption => codeSelector.selectedOptions[0].attributes['valueid'];
}
