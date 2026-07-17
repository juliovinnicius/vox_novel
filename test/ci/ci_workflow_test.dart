import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late YamlMap workflow;
  late YamlMap androidJob;
  late List<YamlMap> steps;

  setUpAll(() {
    workflow =
        loadYaml(File('.github/workflows/ci.yml').readAsStringSync())
            as YamlMap;
    androidJob = (workflow['jobs'] as YamlMap)['android'] as YamlMap;
    steps = (androidJob['steps'] as YamlList).cast<YamlMap>();
  });

  test('runs for pushes to main and pull requests', () {
    final triggers = workflow['on'] as YamlMap;
    final push = triggers['push'] as YamlMap;
    final branches = (push['branches'] as YamlList).cast<String>();

    expect(branches, contains('main'));
    expect(triggers.containsKey('pull_request'), isTrue);
  });

  test('runs the required Flutter commands in exact order', () {
    final commands = <String>[
      for (final step in steps)
        if (step['run'] case final String command) command,
    ];

    expect(
      commands,
      equals([
        'flutter pub get',
        'flutter analyze',
        'flutter test',
        'flutter build apk --debug',
      ]),
    );
  });

  test('does not suppress failures for the job or required commands', () {
    expect(androidJob.containsKey('continue-on-error'), isFalse);

    final commandSteps = steps.where((step) => step.containsKey('run'));
    expect(
      commandSteps.every((step) => !step.containsKey('continue-on-error')),
      isTrue,
    );
  });
}
