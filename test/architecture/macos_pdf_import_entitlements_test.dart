import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final configuration in ['DebugProfile', 'Release']) {
    test('$configuration permits reading a PDF selected by the user', () {
      final entitlements = File(
        'macos/Runner/$configuration.entitlements',
      ).readAsStringSync();

      expect(
        entitlements,
        contains(
          '<key>com.apple.security.files.user-selected.read-only</key>\n'
          '\t<true/>',
        ),
      );
    });
  }
}
