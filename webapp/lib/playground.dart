/**
 * The entry point of the application.
 */
library coda.playground;

import 'dart:html';

import 'data_model.dart';
import 'view_model.dart';

Playground get playground => _playground;

Playground _playground;

void init() {
  _playground = new Playground();
}

class Playground {
  ButtonElement get saveButton => querySelector('#save-all-button');
  TableElement get messageCodingTable => querySelector('#message-coding-table');

  Dataset dataset;

  Playground() {
    // TODO: This is just for prototyping, the jsondataset will come from a server
    loadDataset(new Dataset.fromJson(jsonDataset));
  }

  loadDataset(Dataset dataset) {
    clear(); // Clear up the playground before loading the new dataset.
    this.dataset = dataset;

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
    messageCodingTable.append(header);

    TableSectionElement body = new Element.tag('tbody');
    dataset.messages.forEach((message) {
      MessageViewModel messageViewModel = new MessageViewModel(message, dataset);
      body.append(messageViewModel.viewElement);
    });
    messageCodingTable.append(body);
  }

  void clear() {
    // TODO: Implement clearing up the table
  }
}

Map jsonDataset = {
  "Name": "Test",
  "Documents": [
    {
      "MessageID": "msg 1",
      "Text": "first message",
      "CreationDateTimeUTC": "2018-09-23T14:12:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 1",
          "LabelOrigin": "info@example.com"
        }
      ]
    },
    {
      "MessageID": "msg 2",
      "Text": "second message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 1",
          "LabelOrigin": "info@example.com"
        },
        {
          "SchemeID": "scheme 2",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 2",
          "LabelOrigin": "info@example.com"
        }
      ]
    },
    {
      "MessageID": "msg 3",
      "Text": "third message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 1",
          "LabelOrigin": "info@example.com"
        },
        {
          "SchemeID": "scheme 2",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 22",
          "LabelOrigin": "info@example.com"
        }
      ]
    },
    {
      "MessageID": "msg 4",
      "Text": "fourth message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 2",
          "LabelOrigin": "info@example.com"
        },
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 1",
          "LabelOrigin": "info@example.com"
        }
      ]
    },
    {
      "MessageID": "msg 5",
      "Text": "fifth message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 2",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 2",
          "LabelOrigin": "info@example.com"
        },
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 11",
          "LabelOrigin": "info@example.com"
        }
      ]
    },
    {
      "MessageID": "msg 6",
      "Text": "sixth message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "MessageID": "msg 7",
      "Text": "seventh message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    }
  ],
  "CodeSchemes": [
    {
      "SchemeID": "scheme 1",
      "Codes": [
        {
          "FriendlyName": "code 1",
          "ValueID": "code 1",
          "Colour": "#f46241",
          "Shortcut": "1"
        },
        {
          "FriendlyName": "code 2",
          "ValueID": "code 2",
          "Shortcut": "2"
        }
      ]
    },
    {
      "SchemeID": "scheme 2",
      "Codes": [
        {
          "FriendlyName": "code 1",
          "ValueID": "code 1",
          "Colour": "#f46241",
          "Shortcut": "a"
        },
        {
          "FriendlyName": "code 2",
          "ValueID": "code 2",
          "Shortcut": "b"
        }
      ]
    }
  ]
};
