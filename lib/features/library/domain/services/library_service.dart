import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';

final class MetadataEditResult {
  const MetadataEditResult._({required this.success, this.message});

  const MetadataEditResult.success() : this._(success: true);
  const MetadataEditResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String? message;
}

final class DeleteBookResult {
  const DeleteBookResult._({required this.success, this.message});

  const DeleteBookResult.success() : this._(success: true);
  const DeleteBookResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String? message;
}

final class LibraryService {
  const LibraryService({
    required this.repository,
    required this.storage,
    required this.clock,
  });

  static const saveError = 'Não foi possível salvar as alterações';
  static const deleteError = 'Não foi possível excluir o livro';

  final BookRepository repository;
  final BookFileStorage storage;
  final DateTime Function() clock;

  Future<MetadataEditResult> updateMetadata({
    required String id,
    required String title,
    String? author,
  }) async {
    late final BookMetadata metadata;
    try {
      metadata = Book.normalizeMetadata(title: title, author: author);
    } on BookMetadataValidationException catch (error) {
      return MetadataEditResult.failure(error.message);
    }

    try {
      await repository.updateMetadata(
        id: id,
        title: metadata.title,
        author: metadata.author,
        updatedAt: clock(),
      );
      return const MetadataEditResult.success();
    } catch (_) {
      return const MetadataEditResult.failure(saveError);
    }
  }

  Future<DeleteBookResult> deleteBook(Book book) async {
    QuarantinedBookFiles? quarantine;
    try {
      quarantine = await storage.quarantineOwnedFiles(
        pdfPath: book.storedFilePath,
        coverPath: book.coverPath,
      );
      await repository.deleteById(book.id);
    } catch (_) {
      if (quarantine != null) {
        await _restoreDeletion(book, quarantine);
      }
      return const DeleteBookResult.failure(deleteError);
    }

    try {
      await storage.discardQuarantine(quarantine);
    } catch (_) {
      // The row is already durably deleted and the files remain quarantined
      // for cleanup on storage initialization.
    }
    return const DeleteBookResult.success();
  }

  Future<void> _restoreDeletion(
    Book book,
    QuarantinedBookFiles quarantine,
  ) async {
    try {
      if (await repository.findById(book.id) == null) {
        await repository.insert(book);
      }
    } catch (_) {}
    try {
      await storage.restoreQuarantine(quarantine);
    } catch (_) {}
  }
}
