library coda.test.data;

Map jsonDatasetNoSchemes = {
  "Name": "Test",
  "Id": "test_dataset_id",
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
  "Id": "test_dataset_id",
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
  "Id": "test_dataset_id",
  "Documents": [
    {
      "Id": "msg 0",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "Id": "msg 1",
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
      "Id": "msg 2",
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
      "Id": "msg 3",
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
      "Id": "msg 4",
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
      "Id": "msg 5",
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

Map jsonDatasetTwoSchemesNoCodes = {
  "Name": "Test",
  "Id": "test_dataset_id",
  "Documents": [
    {
      "Id": "msg 0",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "Id": "msg 1",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:12:00Z",
      "Labels": []
    },
    {
      "Id": "msg 2",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:12:00Z",
      "Labels": []
    },
    {
      "Id": "msg 3",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "Id": "msg 4",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
    },
    {
      "Id": "msg 5",
      "Text": "message",
      "CreationDateTimeUTC": "2018-09-23T14:14:00Z",
      "Labels": []
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
