import 'package:file_picker/file_picker.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';

typedef PickFiles = Future<FilePickerResult?> Function({
  required bool allowMultiple,
  required FileType type,
  required List<String> allowedExtensions,
});

final class FilePickerPdfPicker implements PdfPicker {
  FilePickerPdfPicker({PickFiles? pickFiles})
    : _pickFiles =
          pickFiles ??
          (({
                required bool allowMultiple,
                required FileType type,
                required List<String> allowedExtensions,
              }) => FilePicker.platform.pickFiles(
                allowMultiple: allowMultiple,
                type: type,
                allowedExtensions: allowedExtensions,
              ));

  final PickFiles _pickFiles;

  @override
  Future<PickedPdf?> pickPdf() async {
    final result = await _pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null) {
      return null;
    }

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      throw const PdfPickerException(PdfPickerFailureKind.invalidSelection);
    }

    return PickedPdf(sourcePath: path, originalFileName: file.name);
  }
}
