import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('foundation shell contains no event-based Bloc declarations', () {
    final foundationSources = <File>[
      File('lib/main.dart'),
      ...Directory('lib/app')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ];

    final eventBlocDeclarations = <String>[
      for (final source in foundationSources)
        if (RegExp(r'extends\s+Bloc\s*<').hasMatch(source.readAsStringSync()))
          source.path,
    ];

    expect(
      eventBlocDeclarations,
      isEmpty,
      reason:
          'Foundation presentation state must use Cubit, not event-based Bloc.',
    );
  });
}
