/**
 * A file used to store any data used when prototyping.
 */

library coda.temp.data;

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
