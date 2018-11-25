import 'data_model.dart';

Dataset generateEmptyDataset(String datasetId, int schemeCount, int messageCount) {
  Dataset dataset = new Dataset.empty(datasetId);
  for (int i = 0; i < schemeCount; i++) {
    Scheme scheme = new Scheme('scheme $i');
    for (int c = 0; c < 5; c++) {

      scheme.codes.add(
        new Code("$c", "Code $c", c, true)
      );
    }
    dataset.codeSchemes.add(scheme);
  }

  for (int i = 0; i < messageCount; i++) {
    dataset.messages.add(new Message('msg_$i', i, 'message', new DateTime.now()));
  }

  return dataset;
}
