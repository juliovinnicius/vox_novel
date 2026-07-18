import 'package:vox_novel/features/library/domain/entities/book.dart';

class BookDeletionSnapshot {
  const BookDeletionSnapshot(this.book);

  final Book book;
}

abstract interface class BookRepository {
  Stream<List<Book>> watchAll();

  Future<Book?> findById(String id);

  Future<Book?> findByHash(String hash);

  Future<void> insert(Book book);

  Future<void> replaceImportedFile({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required BookStatus status,
    required double processingProgress,
    required DateTime updatedAt,
  });

  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  });

  Future<void> deleteById(String id);
}

abstract interface class CompensatingBookRepository {
  Future<BookDeletionSnapshot> deleteForCompensation(Book book);

  Future<void> restoreDeletion(BookDeletionSnapshot snapshot);
}
