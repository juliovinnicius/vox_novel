import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';

enum PdfValidationFailureKind { missing, directory, unreadable, nonPdf }

final class PdfValidationException implements Exception {
  const PdfValidationException(this.kind);

  final PdfValidationFailureKind kind;
}

final class UnsafeBookPathException implements Exception {
  const UnsafeBookPathException(this.path);

  final String path;
}

final class ValidatedPdf {
  const ValidatedPdf({required this.hash});

  final String hash;
}

final class StagedBookFile {
  const StagedBookFile({required this.stagingPath, required this.finalPath});

  final String stagingPath;
  final String finalPath;
}

final class BookFileBackup {
  const BookFileBackup({required this.originalPath, required this.backupPath});

  final String originalPath;
  final String backupPath;
}

final class QuarantinedBookFiles {
  const QuarantinedBookFiles(this.files);

  final List<BookFileBackup> files;
}

abstract interface class BookFileStorage {
  Future<ValidatedPdf> validateAndHash(PickedPdf source);

  Future<StagedBookFile> stageCopy({
    required PickedPdf source,
    required String bookId,
  });

  Future<String> commitStage(StagedBookFile staged);

  Future<void> discardStage(StagedBookFile staged);

  Future<BookFileBackup?> backupOwnedFile(String path);

  Future<void> restoreBackup(BookFileBackup backup);

  Future<void> discardBackup(BookFileBackup backup);

  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  });

  Future<void> restoreQuarantine(QuarantinedBookFiles quarantine);

  Future<void> discardQuarantine(QuarantinedBookFiles quarantine);

  Future<void> removeOwnedFiles({required String pdfPath, String? coverPath});
}
