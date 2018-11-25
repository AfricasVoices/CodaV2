import 'package:test/test.dart';

import 'package:CodaV2/data_model.dart';
import 'package:CodaV2/sample_data/sample_json_datasets.dart';

void main() {
  test("Empty dataset", () {
    Dataset dataset = new Dataset.empty('test');
    expect(dataset.messages, []);
    expect(dataset.codeSchemes, []);
  });

  test("Simple dataset from JSON", () {
    Dataset dataset = new Dataset.fromFirebaseMap('test', jsonDatasetTwoSchemes);

    expect(dataset.messages.length, 6);
    expect(dataset.codeSchemes.length, 2);
    expect(dataset.messages[0].id, "msg 0");
    expect(dataset.codeSchemes[0].id, "scheme 1");
    expect(dataset.codeSchemes[0].codes[0].color, '#f46241');
    expect(dataset.codeSchemes[0].codes[1].color, null);
  });
}
