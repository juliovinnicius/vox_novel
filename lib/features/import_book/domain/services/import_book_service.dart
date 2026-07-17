import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';

final class ImportBookException implements Exception {
  const ImportBookException();

  static const message = 'Não foi possível importar este PDF';
}

final class ImportBookService {
  const ImportBookService({
    required this.repository,
    required this.storage,
    required this.generateId,
    required this.clock,
  });

  final BookRepository repository;
  final BookFileStorage storage;
  final String Function() generateId;
  final DateTime Function() clock;

  Future<Book> importPdf(PickedPdf selected) async {
    StagedBookFile? staged;
    String? committedPath;
    BookFileBackup? backup;
    Book? existing;
    var repositoryChanged = false;
    try {
      final validated = await storage.validateAndHash(selected);
      existing = await repository.findByHash(validated.hash);
      final id = existing?.id ?? generateId();
      staged = await storage.stageCopy(source: selected, bookId: id);
      if (existing != null) {
        backup = await storage.backupOwnedFile(existing.storedFilePath);
      }
      committedPath = await storage.commitStage(staged);
      final now = clock();
      if (existing == null) {
        final book = Book(
          id: id,
          title: Book.titleFromFileName(selected.originalFileName),
          originalFileName: selected.originalFileName,
          storedFilePath: committedPath,
          fileHash: validated.hash,
          status: BookStatus.importing,
          processingProgress: 0,
          createdAt: now,
          updatedAt: now,
        );
        await repository.insert(book);
        repositoryChanged = true;
        return book;
      }

      await repository.replaceImportedFile(
        id: existing.id,
        originalFileName: selected.originalFileName,
        storedFilePath: committedPath,
        fileHash: validated.hash,
        status: BookStatus.importing,
        processingProgress: 0,
        updatedAt: now,
      );
      repositoryChanged = true;
      if (backup != null) {
        await storage.discardBackup(backup);
      }
      return existing.copyWith(
        originalFileName: selected.originalFileName,
        storedFilePath: committedPath,
        fileHash: validated.hash,
        status: BookStatus.importing,
        processingProgress: 0,
        updatedAt: now,
      );
    } catch (_) {
      await _compensate(
        existing: existing,
        staged: staged,
        committedPath: committedPath,
        backup: backup,
        repositoryChanged: repositoryChanged,
      );
      throw const ImportBookException();
    }
  }

  Future<void> _compensate({
    required Book? existing,
    required StagedBookFile? staged,
    required String? committedPath,
    required BookFileBackup? backup,
    required bool repositoryChanged,
  }) async {
    try {
      if (repositoryChanged && existing != null) {
        await repository.replaceImportedFile(
          id: existing.id,
          originalFileName: existing.originalFileName,
          storedFilePath: existing.storedFilePath,
          fileHash: existing.fileHash,
          status: existing.status,
          processingProgress: existing.processingProgress,
          updatedAt: existing.updatedAt,
        );
      } else if (repositoryChanged && existing == null) {
        // The inserted ID is encoded in the committed path but the returned
        // book is not available after an exception. Repository insert is the
        // last operation for new imports, so no later operation can fail.
      }
    } catch (_) {}
    try {
      if (committedPath != null) {
        await storage.removeOwnedFiles(pdfPath: committedPath);
      } else if (staged != null) {
        await storage.discardStage(staged);
      }
    } catch (_) {}
    try {
      if (backup != null) {
        await storage.restoreBackup(backup);
      }
    } catch (_) {}
  }
}
