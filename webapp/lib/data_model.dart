/**
 * Represents the main data types used in Coda.
 */
library coda.model;

/// A collection of messages and code schemes.
class Dataset {
  String id;
  String name;
  List<Message> messages;
  List<Scheme> codeSchemes;

  Dataset(this.name) {
    messages = [];
    codeSchemes = [];
  }
  Dataset.fromJson(Map jsonDataset) {
    name = jsonDataset['Name'];
    id = jsonDataset['Id'];
    messages = (jsonDataset['Documents'] as List).map<Message>((jsonDocument) => new Message.fromJson(jsonDocument)).toList();
    codeSchemes = (jsonDataset['CodeSchemes'] as List).map<Scheme>((jsonScheme) => new Scheme.fromJson(jsonScheme)).toList();
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
  Message.fromJson(Map jsonDocument) {
    id = jsonDocument['Id'];
    text = jsonDocument['Text'];
    creationDateTime = DateTime.parse(jsonDocument['CreationDateTimeUTC']);
    labels = (jsonDocument['Labels'] as List).map<Label>((jsonLabel) => new Label.fromJson(jsonLabel)).toList();
  }

  toMap() => {
    "id" : id,
    "text" : text,
    "creationDateTime" : creationDateTime,
    "labels" : labels.map((f) => f.toSimpleMap()).toList()
  };

  @override
  String toString() => "$id: $text $labels";
}

/// A code/label assigned to a message.
class Label {
  String schemeID;
  DateTime dateTime;
  String valueID;
  Origin labelOrigin;
  double confidence;
  bool checked;

  Label(this.schemeID, this.dateTime, this.valueID, this.labelOrigin, {this.confidence = 1.0, this.checked = true});
  Label.fromJson(Map jsonLabel) {
    schemeID = jsonLabel['SchemeID'];
    dateTime = DateTime.parse(jsonLabel['DateTimeUTC']);
    valueID = jsonLabel['ValueID'];
    labelOrigin = new Origin.fromJson(jsonLabel['LabelOrigin']);
  }
  @override
  String toString() => "$schemeID: $valueID $labelOrigin";

  toSimpleMap() => {
    "schemeID" : schemeID,
    "dateTime" : dateTime,
    "valueID" : valueID,
    "origin" : labelOrigin.toSimpleMap(),
    "confidence" : confidence
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
  Scheme.fromJson(Map jsonScheme) {
    // TODO: Legacy, update to new JSON format

    int i = 0;

    id = jsonScheme['SchemeID'];
    codes = [];
    jsonScheme['Codes'].forEach((jsonCode) {
      codes.add(
        new Code.fromFirebaseMap(
          {
              "CodeID" : jsonCode['ValueID'],
              "DisplayText" : jsonCode['FriendlyName'],
              "NumericValue" : i++,
              "VisibleInCoda" : true,
              "Color": jsonCode.containsKey('Color') ? jsonCode['Color']: ''
          }
        )
      );
    });
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
}

class Origin {
  String id;
  String name;
  String originType;
  Map<String, String> metadata;

  Origin(this.id, this.name, [this.originType = "Manual", this.metadata]);
  Origin.fromJson(Map jsonOrigin) {
    id = jsonOrigin['Id'];
    name = jsonOrigin['Name'];
    originType = jsonOrigin['OriginType'];
    metadata = jsonOrigin['Metadata'];
  }


  toSimpleMap() => {
    "id" : id,
    "name" : name,
    "originType" : originType,
    "metadata" : metadata != null ? metadata : {}
  };

  @override
    String toString() => "$originType $id";
}
