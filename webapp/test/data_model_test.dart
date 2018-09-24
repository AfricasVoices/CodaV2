import 'dart:convert' show json;

import 'package:test/test.dart';

import 'package:CodaV2/data_model.dart';

void main() {
  test("Empty dataset", () {
    Dataset dataset = new Dataset('Name');
    expect(dataset.messages, []);
    expect(dataset.codeSchemes, []);
  });

  test("Simple dataset from JSON", () {
    Map datasetMap = json.decode(testJsonDataset);
    Dataset dataset = new Dataset.fromJson(datasetMap);

    expect(dataset.messages.length, 2);
    expect(dataset.codeSchemes.length, 1);
    expect(dataset.messages[0].messageID, "msg 1");
    expect(dataset.codeSchemes[0].schemeID, "scheme 1");
    expect(dataset.codeSchemes[0].codes[0]['colour'], new Colour.hex('f46241'));
    expect(dataset.codeSchemes[0].codes[1]['colour'], new Colour());
  });
}

const String testJsonDataset =
"""{
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
          "ValueID": "code1",
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
          "Colour": "#f46241"
        },
        {
          "FriendlyName": "code 2",
          "ValueID": "code 2"
        }
      ]
    }
  ]
}""";
