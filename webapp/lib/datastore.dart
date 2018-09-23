
class Dataset {
  String name;
  List<Message> messages;
  List<Scheme> codeSchemes;

  Dataset(this.name) {
    messages = [];
    codeSchemes = [];
  }
  Dataset.fromJson(Map jsonDataset) {
    name = jsonDataset['Name'];
    messages = (jsonDataset['Documents'] as List).map<Message>((jsonDocument) => new Message.fromJson(jsonDocument)).toList();
    codeSchemes = (jsonDataset['CodeSchemes'] as List).map<Scheme>((jsonScheme) => new Scheme.fromJson(jsonScheme)).toList();
  }
}

class Message {
  String messageID;
  String text;
  DateTime creationDateTime;
  List<Label> labels;

  Message(this.messageID, this.text, this.creationDateTime) {
    labels = [];
  }
  Message.fromJson(Map jsonDocument) {
    messageID = jsonDocument['MessageID'];
    text = jsonDocument['Text'];
    creationDateTime = DateTime.parse(jsonDocument['CreationDateTimeUTC']);
    labels = (jsonDocument['Labels'] as List).map<Label>((jsonLabel) => new Label.fromJson(jsonLabel)).toList();
  }
}

class Label {
  String schemeID;
  DateTime dateTime;
  String valueID;
  String labelOrigin;

  Label(this.schemeID, this.dateTime, this.valueID, this.labelOrigin);
  Label.fromJson(Map jsonLabel) {
    schemeID = jsonLabel['SchemeID'];
    dateTime = DateTime.parse(jsonLabel['DateTimeUTC']);
    valueID = jsonLabel['ValueID'];
    labelOrigin = jsonLabel['LabelOrigin'];
  }
}

class Scheme {
  String schemeID;
  List<Map> codes;

  Scheme(this.schemeID) {
    codes = [];
  }
  Scheme.fromJson(Map jsonScheme) {
    schemeID = jsonScheme['SchemeID'];
    codes = [];
    jsonScheme['Codes'].forEach((code) {
      codes.add({
        'name': code['FriendlyName'],
        'valueID': code['ValueID'],
        'colour': code['Colour']
      });
    });
  }
}
