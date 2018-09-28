@TestOn("browser")
library coda.view_model_test;

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';

import 'package:CodaV2/data_model.dart';
import 'package:CodaV2/view_model.dart';
import 'package:CodaV2/main_ui.dart' as coda_ui;

void main() {
  group("message setup", () {
    group("no scheme", () {
      Dataset dataset;

      setUp(() {
        dataset = new Dataset.fromJson(jsonDatasetNoSchemes);
      });

      tearDown(() {
        dataset = null;
      });

      test("no code selectors", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[0], dataset);

        expect(message.codeSelectors.length, 0);
        expect(message.message.messageID, "msg 0");
      });
    });
    group("one scheme", () {
      Dataset dataset;

      setUp(() {
        dataset = new Dataset.fromJson(jsonDatasetOneScheme);
      });

      tearDown(() {
        dataset = null;
      });

      test("no code", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[0], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.messageID, "msg 0");
        expect(message.codeSelectors[0].selectedOption, "unassign");
      });

      test("one code", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[1], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.messageID, "msg 1");
        expect(message.codeSelectors[0].selectedOption, "code 1");
      });

      test("code that is not part of the scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[2], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.messageID, "msg 2");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[0].warning.classes.contains('hidden'), false);
      });

      test("coded multiple times with the same scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[3], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.messageID, "msg 3");
        expect(message.codeSelectors[0].selectedOption, "code 2");
      });
    });
    group("two schemes", () {
      Dataset dataset;

      setUp(() {
        dataset = new Dataset.fromJson(jsonDatasetTwoSchemes);
      });

      tearDown(() {
        dataset = null;
      });

      test("no codes", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[0], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.messageID, "msg 0");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "unassign");
      });

      test("one code in the first scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[1], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.messageID, "msg 1");
        expect(message.codeSelectors[0].selectedOption, "code 1");
        expect(message.codeSelectors[1].selectedOption, "unassign");
      });

      test("one code in the second scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[2], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.messageID, "msg 2");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "code 2");
      });

      test("one code in each scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[3], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.messageID, "msg 3");
        expect(message.codeSelectors[0].selectedOption, "code 1");
        expect(message.codeSelectors[1].selectedOption, "code 2");
      });

      test("coded multiple times with the first scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[4], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.messageID, "msg 4");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "code 2");
      });

      test("one code in the second scheme that is not part of the scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[5], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.messageID, "msg 5");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "unassign");
        expect(message.codeSelectors[1].warning.classes.contains('hidden'), false);
      });
    });
  });

  group("message coding", () {
    Dataset dataset = new Dataset.fromJson(jsonDatasetTwoSchemes);
    coda_ui.CodaUI ui = new coda_ui.CodaUI();
    ui.displayDataset(dataset);

    test("from empty", () async {
      MessageViewModel message = ui.messages[0];

      expect(message.codeSelectors.length, 2);
      expect(message.message.messageID, "msg 0");
      expect(message.codeSelectors[0].selectedOption, "unassign");

      TableRowElement row = querySelector('tbody').firstChild;
      SelectElement select = row.querySelector('.input-group[scheme="scheme 1"] select');
      OptionElement option = select.querySelector('option[valueid="code 2"]');

      option.selected = true;
      option.dispatchEvent(new Event('change'));
      await new Future.delayed(const Duration(milliseconds: 200));

      expect(message.codeSelectors[0].selectedOption, "code 2");
    });

    test("recoding a code that is not part of the scheme", () async {
      MessageViewModel message = ui.messages[5];

      expect(message.codeSelectors.length, 2);
      expect(message.message.messageID, "msg 5");
      expect(message.codeSelectors[1].selectedOption, "unassign");
      expect(message.codeSelectors[1].warning.classes.contains('hidden'), false);

      TableRowElement row = querySelector('tbody').children[5];
      SelectElement select = row.querySelector('.input-group[scheme="scheme 2"] select');
      OptionElement option = select.querySelector('option[valueid="code 2"]');

      option.selected = true;
      option.dispatchEvent(new Event('change'));
      await new Future.delayed(const Duration(milliseconds: 200));

      expect(message.codeSelectors[1].selectedOption, "code 2");
      expect(message.codeSelectors[1].warning.classes.contains('hidden'), true);
    });
  });
}

Map jsonDatasetNoSchemes = {
  "Name": "Test",
  "Documents": [
    {
      "MessageID": "msg 0",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
  ],
  "CodeSchemes": []
};


Map jsonDatasetOneScheme = {
  "Name": "Test",
  "Documents": [
    {
      "MessageID": "msg 0",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "MessageID": "msg 1",
      "Text": "message",
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
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 11",
          "LabelOrigin": "info@example.com"
        }
      ]
    },
    {
      "MessageID": "msg 3",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 1",
          "LabelOrigin": "info@example.com"
        },
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 2",
          "LabelOrigin": "info@example.com"
        }
      ]
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
  ]
};


Map jsonDatasetTwoSchemes = {
  "Name": "Test",
  "Documents": [
    {
      "MessageID": "msg 0",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "MessageID": "msg 1",
      "Text": "message",
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
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:12:00Z",
      "Labels": [
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
      "Text": "message",
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
      "MessageID": "msg 4",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 2",
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
      "MessageID": "msg 5",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 2",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "code 22",
          "LabelOrigin": "info@example.com"
        },
      ]
    },
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
