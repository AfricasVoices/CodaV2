@TestOn("browser")
library coda.view_model_test;

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';

import 'package:CodaV2/data_model.dart';
import 'package:CodaV2/main_ui.dart';
import 'package:CodaV2/config.dart' as config;
import 'package:CodaV2/logger.dart' as log;
import 'package:CodaV2/sample_data/sample_json_datasets.dart';


void main() {
  group("message setup", () {
    group("no scheme", () {
      Dataset dataset;

      setUp(() {
        dataset = new Dataset.fromJson(jsonDatasetNoSchemes);
      });

      tearDown(() {
        dataset = null;
      });

      test("no code selectors", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[0], dataset);

        expect(message.codeSelectors.length, 0);
        expect(message.message.id, "msg 0");
      });
    });
    group("one scheme", () {
      Dataset dataset;

      setUp(() {
        dataset = new Dataset.fromJson(jsonDatasetOneScheme);
      });

      tearDown(() {
        dataset = null;
      });

      test("no code", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[0], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.id, "msg 0");
        expect(message.codeSelectors[0].selectedOption, "unassign");
      });

      test("one code", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[1], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.id, "msg 1");
        expect(message.codeSelectors[0].selectedOption, "code 1");
      });

      test("code that is not part of the scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[2], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.id, "msg 2");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[0].warning.classes.contains('hidden'), false);
      });

      test("coded multiple times with the same scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[3], dataset);

        expect(message.codeSelectors.length, 1);
        expect(message.message.id, "msg 3");
        expect(message.codeSelectors[0].selectedOption, "code 1");
      });
    });
    group("two schemes", () {
      Dataset dataset;

      setUp(() {
        dataset = new Dataset.fromJson(jsonDatasetTwoSchemes);
      });

      tearDown(() {
        dataset = null;
      });

      test("no codes", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[0], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.id, "msg 0");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "unassign");
      });

      test("one code in the first scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[1], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.id, "msg 1");
        expect(message.codeSelectors[0].selectedOption, "code 1");
        expect(message.codeSelectors[1].selectedOption, "unassign");
      });

      test("one code in the second scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[2], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.id, "msg 2");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "code 2");
      });

      test("one code in each scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[3], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.id, "msg 3");
        expect(message.codeSelectors[0].selectedOption, "code 1");
        expect(message.codeSelectors[1].selectedOption, "code 2");
      });

      test("coded multiple times with the first scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[4], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.id, "msg 4");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "code 1");
      });

      test("one code in the second scheme that is not part of the scheme", () {
        MessageViewModel message = new MessageViewModel(dataset.messages[5], dataset);

        expect(message.codeSelectors.length, 2);
        expect(message.message.id, "msg 5");
        expect(message.codeSelectors[0].selectedOption, "unassign");
        expect(message.codeSelectors[1].selectedOption, "unassign");
        expect(message.codeSelectors[1].warning.classes.contains('hidden'), false);
      });
    });
  });

  group("message coding", () {
    config.TEST_MODE = true;
    TableElement table = new TableElement();
    table.id = "message-coding-table";
    document.body.append(table);
    Dataset dataset = new Dataset.fromJson(jsonDatasetTwoSchemes);
    CodaUI ui = new CodaUI();
    ui.displayDatasetView(dataset);

    test("from empty", () async {
      MessageViewModel message = ui.messages[0];

      expect(message.codeSelectors.length, 2);
      expect(message.message.id, "msg 0");
      expect(message.codeSelectors[0].selectedOption, "unassign");

      TableRowElement row = querySelector('tbody').firstChild;
      SelectElement select = row.querySelector('.input-group[scheme-id="scheme 1"] select');
      OptionElement option = select.querySelector('option[valueid="code 2"]');

      option.selected = true;
      select.dispatchEvent(new Event('change'));
      await new Future.delayed(const Duration(milliseconds: 200));

      expect(log.firestoreCallLog.last['callType'], 'updateMessage');
      expect(log.firestoreCallLog.last['content'], message.message.toMap());
      expect(message.codeSelectors[0].selectedOption, "code 2");
    });

    test("recoding a code that is not part of the scheme", () async {
      MessageViewModel message = ui.messages[5];

      expect(message.codeSelectors.length, 2);
      expect(message.message.id, "msg 5");
      expect(message.codeSelectors[1].selectedOption, "unassign");
      expect(message.codeSelectors[1].warning.classes.contains('hidden'), false);

      TableRowElement row = querySelector('tbody').children[5];
      SelectElement select = row.querySelector('.input-group[scheme-id="scheme 2"] select');
      OptionElement option = select.querySelector('option[valueid="code 2"]');

      option.selected = true;
      select.dispatchEvent(new Event('change'));
      await new Future.delayed(const Duration(milliseconds: 200));

      expect(log.firestoreCallLog.last['callType'], 'updateMessage');
      expect(log.firestoreCallLog.last['content'], message.message.toMap());
      expect(message.codeSelectors[1].selectedOption, "code 2");
      expect(message.codeSelectors[1].warning.classes.contains('hidden'), true);
    });
  });
}
