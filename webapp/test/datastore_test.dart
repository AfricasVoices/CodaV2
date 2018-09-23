import 'dart:convert' show json;

import 'package:test/test.dart';

import 'package:CodaV2/datastore.dart' as ds;

void main() {
  test("Empty dataset", () {
    ds.Dataset dataset = new ds.Dataset('Name');
    expect(dataset.messages, []);
    expect(dataset.codeSchemes, []);
  });

  test("Simple dataset from JSON", () {
    Map datasetMap = json.decode(testJsonCollection);
    ds.Dataset dataset = new ds.Dataset.fromJson(datasetMap);

    expect(dataset.messages.length, 2);
    expect(dataset.codeSchemes.length, 1);
    expect(dataset.messages[0].messageID, "1");
    expect(dataset.codeSchemes[0].schemeID, "scheme 1");
  });
}

String testJsonCollection =
"""{
  "Name": "Test",
  "Documents": [
    {
      "MessageID": "1",
      "Text": "first message",
      "CreationDateTimeUTC": "2018-09-23T14:12:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "1",
          "LabelOrigin": "manual"
        }
      ]
    },
    {
      "MessageID": "2",
      "Text": "second message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": [
        {
          "SchemeID": "scheme 1",
          "DateTimeUTC": "2018-09-23T14:12:00Z",
          "ValueID": "2",
          "LabelOrigin": "manual"
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
          "ValueID": "1",
          "Colour": "red"
        },
        {
          "FriendlyName": "code 2",
          "ValueID": "2",
          "Colour": "blue"
        }
      ]
    }
  ]
}""";
