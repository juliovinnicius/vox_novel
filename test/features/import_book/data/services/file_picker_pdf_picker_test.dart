import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/import_book/data/services/file_picker_pdf_picker.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';

void main() {
  test('requests exactly one PDF using the custom extension filter', () async {
    bool? capturedAllowMultiple;
    FileType? capturedType;
    List<String>? capturedAllowedExtensions;
    final picker = FilePickerPdfPicker(
      pickFiles:
          ({
            required allowMultiple,
            required type,
            required allowedExtensions,
          }) async {
            capturedAllowMultiple = allowMultiple;
            capturedType = type;
            capturedAllowedExtensions = allowedExtensions;
            return null;
          },
    );

    await picker.pickPdf();

    expect(capturedAllowMultiple, isFalse);
    expect(capturedType, FileType.custom);
    expect(capturedAllowedExtensions, ['pdf']);
  });

  test('native cancellation returns null without an error', () async {
    final picker = FilePickerPdfPicker(
      pickFiles:
          ({
            required allowMultiple,
            required type,
            required allowedExtensions,
          }) async => null,
    );

    expect(await picker.pickPdf(), isNull);
  });

  test('maps a usable path and exact original filename', () async {
    final picker = FilePickerPdfPicker(
      pickFiles:
          ({
            required allowMultiple,
            required type,
            required allowedExtensions,
          }) async => FilePickerResult([
            PlatformFile(
              name: 'Meu Romance.PDF',
              size: 42,
              path: '/external/Meu Romance.PDF',
            ),
          ]),
    );

    final selected = await picker.pickPdf();

    expect(selected?.sourcePath, '/external/Meu Romance.PDF');
    expect(selected?.originalFileName, 'Meu Romance.PDF');
  });

  test('missing path returns the typed invalid-selection failure', () async {
    final picker = FilePickerPdfPicker(
      pickFiles:
          ({
            required allowMultiple,
            required type,
            required allowedExtensions,
          }) async => FilePickerResult([
            PlatformFile(name: 'book.pdf', size: 42),
          ]),
    );

    expect(
      picker.pickPdf(),
      throwsA(
        isA<PdfPickerException>().having(
          (error) => error.kind,
          'kind',
          PdfPickerFailureKind.invalidSelection,
        ),
      ),
    );
  });
}
