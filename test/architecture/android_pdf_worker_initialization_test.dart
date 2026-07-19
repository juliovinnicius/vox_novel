import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF worker forwards the Flutter cache directory to pdfrx', () {
    final source = File(
      'lib/features/pdf_processing/data/services/'
      'pdfrx_pdf_text_extractor.dart',
    ).readAsStringSync();

    expect(source, contains('Pdfrx.cacheDirectoryPath,'));
    expect(source, contains('pdfrxInitialize(tmpPath: cacheDirectoryPath)'));
  });
}
