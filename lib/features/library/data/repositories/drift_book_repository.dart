import 'package:drift/drift.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';

final class DriftBookRepository implements BookRepository {
  const DriftBookRepository(this._database);

  final db.AppDatabase _database;

  @override
  Stream<List<domain.Book>> watchAll() {
    final query = _database.select(_database.books)
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAt),
        (row) => OrderingTerm.asc(row.id),
      ]);
    return query.watch().map(
      (rows) => List<domain.Book>.unmodifiable(rows.map(_toDomain)),
    );
  }

  @override
  Future<domain.Book?> findById(String id) async {
    final query = _database.select(_database.books)
      ..where((row) => row.id.equals(id));
    return (await query.getSingleOrNull())?.let(_toDomain);
  }

  @override
  Future<domain.Book?> findByHash(String hash) async {
    final query = _database.select(_database.books)
      ..where((row) => row.fileHash.equals(hash));
    return (await query.getSingleOrNull())?.let(_toDomain);
  }

  @override
  Future<void> insert(domain.Book book) {
    return _database.into(_database.books).insert(
      db.BooksCompanion.insert(
        id: book.id,
        title: book.title,
        author: Value(book.author),
        coverPath: Value(book.coverPath),
        originalFileName: book.originalFileName,
        storedFilePath: book.storedFilePath,
        fileHash: book.fileHash,
        status: book.status,
        processingProgress: book.processingProgress,
        createdAt: book.createdAt,
        updatedAt: book.updatedAt,
      ),
    );
  }

  @override
  Future<void> replaceImportedFile({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required domain.BookStatus status,
    required double processingProgress,
    required DateTime updatedAt,
  }) {
    return _database.transaction(() async {
      await (_database.update(
        _database.books,
      )..where((row) => row.id.equals(id))).write(
        db.BooksCompanion(
          originalFileName: Value(originalFileName),
          storedFilePath: Value(storedFilePath),
          fileHash: Value(fileHash),
          status: Value(status),
          processingProgress: Value(processingProgress),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {
    final metadata = domain.Book.normalizeMetadata(
      title: title,
      author: author,
    );
    await (_database.update(
      _database.books,
    )..where((row) => row.id.equals(id))).write(
      db.BooksCompanion(
        title: Value(metadata.title),
        author: Value(metadata.author),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await (_database.delete(
      _database.books,
    )..where((row) => row.id.equals(id))).go();
  }

  domain.Book _toDomain(db.Book row) {
    return domain.Book(
      id: row.id,
      title: row.title,
      author: row.author,
      coverPath: row.coverPath,
      originalFileName: row.originalFileName,
      storedFilePath: row.storedFilePath,
      fileHash: row.fileHash,
      status: row.status,
      processingProgress: row.processingProgress,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

extension on db.Book {
  T let<T>(T Function(db.Book value) transform) => transform(this);
}
