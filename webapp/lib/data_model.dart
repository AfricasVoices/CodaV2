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
  Map<String, dynamic> otherData;

  Message(this.id, this.text, this.creationDateTime) {
    labels = [];
    otherData = {};
  }
  Message.fromFirebaseMap(Map message) {
    otherData = {};
    
    checkMandatoryProperties('message', message, ['MessageID', 'Text', 'CreationDateTimeUTC', 'Labels']);
    message.forEach((property, value) {
      switch (property) {
        case 'MessageID':
          id = value;
          break;
        case 'Text':
          text = value;
          break;
        case 'CreationDateTimeUTC':
          creationDateTime = value is DateTime ? value : DateTime.parse(value);
          break;
        case 'Labels':
          labels = [];
          for (Map labelMap in value) {
            labels.add(new Label.fromFirebaseMap(labelMap));
          }
          break;
        default:
          otherData[property] = value;
      }
    });
  }

  Map<String, dynamic> toFirebaseMap() {
    Map<String, dynamic> result = {
      "MessageID" : id,
      "Text" : text,
      "CreationDateTimeUTC" : creationDateTime.toIso8601String(),
      "Labels" : labels.map((f) => f.toFirebaseMap()).toList()
    };
    otherData.forEach((property, value) => result[property] = value);
    return result;
  }

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
  Map<String, dynamic> otherData;

  static const MANUALLY_UNCODED = 'SPECIAL-MANUALLY_UNCODED';

  Label(this.schemeId, this.dateTime, this.codeId, this.labelOrigin, {this.confidence = 1.0, this.checked = true}) {
    otherData = {};
  }

  Label.fromFirebaseMap(Map label) {
    // "Checked" should always have a value, if it wasn't set in Firebase, then default to false
    checked = false;
    otherData = {};

    checkMandatoryProperties('label', label, ['SchemeID', 'CodeID', 'DateTimeUTC', 'Origin']);
    label.forEach((property, value) {
      switch (property) {
        case 'SchemeID':
          schemeId = value;
          break;
        case 'CodeID':
          codeId = value;
          break;
        case 'DateTimeUTC':
          dateTime = value is DateTime ? value : DateTime.parse(value);
          break;
        case 'Origin':
          labelOrigin = new Origin.fromFirebaseMap(value);
          break;
        case 'Confidence':
          confidence = value;
          break;
        case 'Checked':
          checked = value;
          break;
        default:
          otherData[property] = value;
      }
    });
  }

  @override
  String toString() => "$schemeId: $codeId $labelOrigin";

  Map<String, dynamic> toFirebaseMap() {
    Map<String, dynamic> result = {
      "SchemeID" : schemeId,
      "CodeID" : codeId,
      "DateTimeUTC" : dateTime.toIso8601String(),
      "Origin" : labelOrigin.toFirebaseMap(),
      "Checked": checked
    };
    // Write back the confidence only if it's been explicitly set, either in the UI or from Firebase
    if (confidence != null) {
      result["Confidence"] = confidence;
    }
    otherData.forEach((property, value) => result[property] = value);
    return result;
  }
}

/// A code scheme being used for coding/labelling messsages.
class Scheme {
  String id;
  String name;
  List<Code> codes;
  String version;
  Map documentation;
  Map<String, dynamic> otherData;

  Scheme(this.id) {
    codes = [];
    otherData = {};
  }

  Scheme.fromFirebaseMap(Map scheme) {
    otherData = {};

    checkMandatoryProperties('scheme', scheme, ['SchemeID', 'Name', 'Version', 'Codes']);
    scheme.forEach((property, value) {
      switch (property) {
        case 'SchemeID':
          id = value;
          break;
        case 'Name':
          name = value;
          break;
        case 'Version':
          version = value;
          break;
        case 'Codes':
          codes = <Code>[];
          for (Map code in scheme['Codes']) {
            codes.add(new Code.fromFirebaseMap(code));
          }
          break;
        case 'Documentation':
          documentation = value;
          break;
        default:
          otherData[property] = value;
      }
    });
  }

  @override
  String toString() => "$id: $name $codes";

  Map<String, dynamic> toFirebaseMap() {
    Map<String, dynamic> result = {
      "SchemeID" : id,
      "Name" : name,
      "Version" : version,
      "Codes" : codes.map((c) => c.toFirebaseMap()).toList(),
    };
    // Write back the documentation only if it's been explicitly set, either in Coda or from Firebase
    if (documentation != null) {
      result["Documentation"] = documentation;
    }
    otherData.forEach((property, value) => result[property] = value);
    return result;
  }
}

class Code {
  String id;
  String displayText;
  int numericValue;
  bool visibleInCoda;
  String shortcut;
  String color;
  Map<String, dynamic> otherData;

  Code(this.id, this.displayText, this.numericValue, this.visibleInCoda) {
    otherData = {};
  }

  Code.fromFirebaseMap(Map code) {
    otherData = {};

    checkMandatoryProperties('code', code, ['CodeID', 'DisplayText', 'NumericValue', 'VisibleInCoda']);
    code.forEach((property, value) {
      switch (property) {
        case 'CodeID':
          id = value;
          break;
        case 'DisplayText':
          displayText = value;
          break;
        case 'NumericValue':
          numericValue = value;
          break;
        case 'VisibleInCoda':
          visibleInCoda = value;
          break;
        case 'Shortcut':
          shortcut = value;
          break;
        case 'Color':
          color = value;
          break;
        default:
          otherData[property] = value;
      }
    });
  }

  Map<String, dynamic> toFirebaseMap() {
    Map<String, dynamic> result = {
      "CodeID" : id,
      "DisplayText" : displayText,
      "NumericValue" : numericValue,
      "VisibleInCoda" : visibleInCoda,
    };
    // Write back the shortcut only if it's been explicitly set, either in Coda or from Firebase
    if (shortcut != null) {
      result["Shortcut"] = shortcut;
    }
    // Write back the color only if it's been explicitly set, either in Coda or from Firebase
    if (color != null) {
      result["Color"] = color;
    }
    otherData.forEach((property, value) => result[property] = value);
    return result;
  }
}

class Origin {
  String id;
  String name;
  String originType;
  Map<String, String> metadata;
  Map<String, dynamic> otherData;

  Origin(this.id, this.name, [this.originType = "Manual", this.metadata]) {
    otherData = {};
  }
  Origin.fromFirebaseMap(Map origin) {
    otherData = {};

    checkMandatoryProperties('origin', origin, ['OriginID', 'Name', 'OriginType']);
    origin.forEach((property, value) {
      switch (property) {
        case 'OriginID':
          id = value;
          break;
        case 'Name':
          name = value;
          break;
        case 'OriginType':
          originType = value;
          break;
        case 'Metadata':
          // The map from Firebase has the type Map<String, dynamic>, we need to convert it to Map<String, String>
          metadata = (origin['Metadata'] as Map).map((k, v) => new MapEntry(k.toString(), v.toString()));
          break;
        default:
          otherData[property] = value;
      }
    });
  }

  Map<String, dynamic> toFirebaseMap() {
    Map<String, dynamic> result = {
      "OriginID" : id,
      "Name" : name,
      "OriginType" : originType,
    };
    // Write back the metadata only if it's been explicitly set, either in Coda or from Firebase
    if (metadata != null) {
      result["Metadata"] = metadata;
    }
    otherData.forEach((property, value) => result[property] = value);
    return result;
  }

  @override
    String toString() => "$originType $id";
}

checkMandatoryProperties(String dataType, Map firebaseMap, List<String> propertyList) {
  propertyList.forEach((property) {
    if (!firebaseMap.containsKey(property)) {
      throw 'Cannot read $dataType with missing property "$property"';
    }
  });
}
