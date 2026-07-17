final class PickedPdf {
  const PickedPdf({required this.sourcePath, required this.originalFileName});

  final String sourcePath;
  final String originalFileName;
}

enum PdfPickerFailureKind { invalidSelection }

final class PdfPickerException implements Exception {
  const PdfPickerException(this.kind);

  final PdfPickerFailureKind kind;
}

abstract interface class PdfPicker {
  Future<PickedPdf?> pickPdf();
}
