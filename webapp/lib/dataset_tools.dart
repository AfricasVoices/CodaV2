import 'data_model.dart';

Dataset generateEmptyDataset(String name, int schemeCount, int messageCount) {
  Dataset dataset = new Dataset(name);
  for (int i = 0; i < schemeCount; i++) {
    Scheme scheme = new Scheme('scheme $i');
    for (int c = 0; c < 5; c++) {
      scheme.codes.add({
        'name': 'Code $c',
        'valueID': 'code $c',
        'shortcut': '$c'
      });
    }
    dataset.codeSchemes.add(scheme);
  }

  for (int i = 0; i < messageCount; i++) {
    dataset.messages.add(new Message('msg_$i', 'message', new DateTime.now()));
  }

  return dataset;
}
