/**
 * Represents the main data types used in Coda.
 */
library coda.model;

/// A collection of messages and code schemes.
class Dataset {
  String id;
  List<Message> messages;
  List<Scheme> codeSchemes;

  Dataset(this.id, this.messages, this.codeSchemes);
  Dataset.empty(this.id) : messages = [], codeSchemes = [];
  Dataset.fromFirebaseMap(String id, Map dataset) {
    this.id = id;
    messages = [];
    for (Map message in dataset['messages']) {
      messages.add(new Message.fromFirebaseMap(message));
    }

    codeSchemes = [];
    for (Map scheme in dataset['code_schemes']) {
      codeSchemes.add(new Scheme.fromFirebaseMap(scheme));
    }
  }
}

/// A textual message being coded.
class Message {
  String id;
  String text;
  DateTime creationDateTime;
  List<Label> labels;

  Message(this.id, this.text, this.creationDateTime) {
    labels = [];
  }
  Message.fromFirebaseMap(Map message) {
    id = message['MessageID'];
    text = message['Text'];
    creationDateTime = message['CreationDateTimeUTC'] is DateTime ? message['CreationDateTimeUTC'] : DateTime.parse(message['CreationDateTimeUTC']);
    labels = <Label>[];

    for (Map labelMap in message['Labels']) {
      labels.add(new Label.fromFirebaseMap(labelMap));
    }
  }

  toFirebaseMap() => {
    "MessageID" : id,
    "Text" : text,
    "CreationDateTimeUTC" : creationDateTime,
    "Labels" : labels.map((f) => f.toFirebaseMap()).toList()
  };

  @override
  String toString() => "$id: $text $labels";
}

/// A code/label assigned to a message.
class Label {
  String schemeId;
  String codeId;
  DateTime dateTime;
  Origin labelOrigin;
  double confidence;
  bool checked;

  static const MANUALLY_UNCODED = 'SPECIAL-MANUALLY_UNCODED';

  Label(this.schemeId, this.dateTime, this.codeId, this.labelOrigin, {this.confidence = 1.0, this.checked = true});
  Label.fromFirebaseMap(Map label) {
    schemeId = label['SchemeID'];
    codeId = label['CodeID'];
    dateTime = label['DateTimeUTC'] is DateTime ? label['DateTimeUTC'] : DateTime.parse(label['DateTimeUTC']);
    labelOrigin = new Origin.fromFirebaseMap(label['Origin']);

    confidence = label.containsKey('Confidence') ? label['Confidence'] : 0.50;
    checked = label.containsKey('Checked') ? label['Checked'] : false;
  }

  @override
  String toString() => "$schemeId: $codeId $labelOrigin";

  toFirebaseMap() => {
    "SchemeID" : schemeId,
    "CodeID" : codeId,
    "DateTimeUTC" : dateTime,
    "Origin" : labelOrigin.toFirebaseMap(),
    "Confidence" : confidence,
    "Checked": checked
  };
}

/// A code scheme being used for coding/labelling messsages.
class Scheme {
  String id;
  String name;
  List<Code> codes;

  String version;
  Map documentation;

  Scheme(this.id) {
    codes = [];
  }

  Scheme.fromFirebaseMap(Map scheme) {
    id = scheme['SchemeID'];
    name = scheme['Name'];
    version = scheme['Version'];
    codes = <Code>[];

    for (Map codeMap in scheme['Codes']) {
      codes.add(new Code.fromFirebaseMap(codeMap));
    }

    if (scheme.containsKey("Documentation")) {
      this.documentation = scheme['Documentation'];
    }
  }

  @override
  String toString() => "$id: $name $codes";

  toFirebaseMap() => {
    "SchemeID": id,
    "Name": name,
    "Version": version,
    "Codes": codes.map((c) => c.toFirebaseMap()).toList()
  };
}

class Code {
  String id;
  String displayText;
  String shortcut;
  int numericValue;
  bool visibleInCoda;
  String color;

  Code(this.id, this.displayText, this.numericValue, this.visibleInCoda, {this.shortcut = "", this.color = ""});

  Code.fromFirebaseMap(Map codeMap) {
    id = codeMap["CodeID"];
    displayText = codeMap["DisplayText"];
    numericValue = codeMap["NumericValue"];
    visibleInCoda = codeMap["VisibleInCoda"];

    shortcut = codeMap.containsKey("Shortcut") ? codeMap["Shortcut"] : "";
    color = codeMap.containsKey("Color") ? codeMap["Color"] : "";
  }

  toFirebaseMap() => {
    "CodeID": id,
    "DisplayText": displayText,
    "NumericValue": numericValue,
    "VisibleInCoda": visibleInCoda,
    "Shortcut": shortcut, // Should this be optional?
    "Color": color
  };
}

class Origin {
  String id;
  String name;
  String originType;
  Map<String, String> metadata;

  Origin(this.id, this.name, [this.originType = "Manual", this.metadata]);
  Origin.fromFirebaseMap(Map origin) {
    id = origin['OriginID'];
    name = origin['Name'];
    originType = origin['OriginType'];
    // The Map from Firebase is Map<String, dynamic>, we need to convert it to Map<String, String>
    if (origin['Metadata'] != null) {
      metadata = (origin['Metadata'] as Map).map((k, v) => new MapEntry(k.toString(), v.toString()));
    }
  }

  toFirebaseMap() => {
    "OriginID" : id,
    "Name" : name,
    "OriginType" : originType,
    "Metadata" : metadata != null ? metadata : <String, String>{}
  };

  @override
    String toString() => "$originType $id";
}
