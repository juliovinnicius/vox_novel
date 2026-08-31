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
    this.onBookDeleted,
  });

  static const saveError = 'Não foi possível salvar as alterações';
  static const deleteError = 'Não foi possível excluir o livro';

  final BookRepository repository;
  final BookFileStorage storage;
  final DateTime Function() clock;

  /// Notified once a book is gone. A callback rather than a dependency so the
  /// library keeps knowing nothing about narration.
  final Future<void> Function(String bookId)? onBookDeleted;

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
    BookDeletionSnapshot? snapshot;
    final storedFilePath = book.storedFilePath;
    try {
      // A web book owns no local file. The three file columns became nullable
      // when web sources landed, and this path still assumed a PDF: deleting a
      // web book threw here, the failure was swallowed, and the reader was
      // told the book could not be deleted.
      quarantine = storedFilePath == null
          ? null
          : await storage.quarantineOwnedFiles(
              pdfPath: storedFilePath,
              coverPath: book.coverPath,
            );
      if (repository is CompensatingBookRepository) {
        final compensating = repository as CompensatingBookRepository;
        snapshot = await compensating.deleteForCompensation(book);
      } else {
        await repository.deleteById(book.id);
        snapshot = BookDeletionSnapshot(book);
      }
    } catch (_) {
      if (quarantine != null) {
        await _restoreDeletion(snapshot, book, quarantine);
      }
      return const DeleteBookResult.failure(deleteError);
    }

    // The book is gone: a narration session still pointing at it would keep a
    // notification alive for something the reader removed.
    await onBookDeleted?.call(book.id);

    if (quarantine == null) return const DeleteBookResult.success();

    try {
      await storage.discardQuarantine(quarantine);
    } catch (_) {
      await _restoreDeletion(snapshot, book, quarantine);
      return const DeleteBookResult.failure(deleteError);
    }
    return const DeleteBookResult.success();
  }

  Future<void> _restoreDeletion(
    BookDeletionSnapshot? snapshot,
    Book book,
    QuarantinedBookFiles quarantine,
  ) async {
    try {
      if (await repository.findById(book.id) == null) {
        if (snapshot != null) {
          if (repository is CompensatingBookRepository) {
            final compensating = repository as CompensatingBookRepository;
            await compensating.restoreDeletion(snapshot);
          } else {
            await repository.insert(snapshot.book);
          }
        } else {
          await repository.insert(book);
        }
      }
    } catch (_) {}
    try {
      await storage.restoreQuarantine(quarantine);
    } catch (_) {}
  }
}
