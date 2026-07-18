import 'package:drift/drift.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';

final class DriftBookRepository
    implements BookRepository, CompensatingBookRepository {
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
    return _database.into(_database.books).insert(_bookCompanion(book));
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

  @override
  Future<BookDeletionSnapshot> deleteForCompensation(domain.Book book) {
    return _database.transaction(() async {
      final storedBook = await (_database.select(
        _database.books,
      )..where((row) => row.id.equals(book.id))).getSingle();
      final runs = await (_database.select(
        _database.processingRuns,
      )..where((row) => row.bookId.equals(book.id))).get();
      final runIds = runs.map((run) => run.id).toList();
      final rawPages = runIds.isEmpty
          ? <db.RawPage>[]
          : await (_database.select(
              _database.rawPages,
            )..where((row) => row.runId.isIn(runIds))).get();
      final chapters = await (_database.select(
        _database.chapters,
      )..where((row) => row.bookId.equals(book.id))).get();
      final chapterIds = chapters.map((chapter) => chapter.id).toList();
      final blocks = chapterIds.isEmpty
          ? <db.NarrationBlock>[]
          : await (_database.select(
              _database.narrationBlocks,
            )..where((row) => row.chapterId.isIn(chapterIds))).get();

      await (_database.delete(
        _database.books,
      )..where((row) => row.id.equals(book.id))).go();
      return _DriftBookDeletionSnapshot(
        book: _toDomain(storedBook),
        runs: runs,
        rawPages: rawPages,
        chapters: chapters,
        blocks: blocks,
      );
    });
  }

  @override
  Future<void> restoreDeletion(BookDeletionSnapshot snapshot) {
    if (snapshot is! _DriftBookDeletionSnapshot) {
      return insert(snapshot.book);
    }
    return _database.transaction(() async {
      final book = snapshot.book;
      await _database
          .into(_database.books)
          .insert(_bookCompanion(book, clearActiveContentRunId: true));
      for (final run in snapshot.runs) {
        await _database.into(_database.processingRuns).insert(run);
      }
      for (final page in snapshot.rawPages) {
        await _database.into(_database.rawPages).insert(page);
      }
      for (final chapter in snapshot.chapters) {
        await _database.into(_database.chapters).insert(chapter);
      }
      for (final block in snapshot.blocks) {
        await _database.into(_database.narrationBlocks).insert(block);
      }
      if (book.activeContentRunId != null) {
        await (_database.update(
          _database.books,
        )..where((row) => row.id.equals(book.id))).write(
          db.BooksCompanion(activeContentRunId: Value(book.activeContentRunId)),
        );
      }
    });
  }

  db.BooksCompanion _bookCompanion(
    domain.Book book, {
    bool clearActiveContentRunId = false,
  }) {
    return db.BooksCompanion.insert(
      id: book.id,
      title: book.title,
      author: Value(book.author),
      coverPath: Value(book.coverPath),
      originalFileName: book.originalFileName,
      storedFilePath: book.storedFilePath,
      fileHash: book.fileHash,
      status: book.status,
      processingProgress: book.processingProgress,
      pageCount: Value(book.pageCount),
      chapterCount: Value(book.chapterCount),
      blockCount: Value(book.blockCount),
      processingStage: Value(book.processingStage),
      activeContentRunId: Value(
        clearActiveContentRunId ? null : book.activeContentRunId,
      ),
      createdAt: book.createdAt,
      updatedAt: book.updatedAt,
    );
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
      pageCount: row.pageCount,
      chapterCount: row.chapterCount,
      blockCount: row.blockCount,
      processingStage: row.processingStage,
      activeContentRunId: row.activeContentRunId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

final class _DriftBookDeletionSnapshot extends BookDeletionSnapshot {
  const _DriftBookDeletionSnapshot({
    required domain.Book book,
    required this.runs,
    required this.rawPages,
    required this.chapters,
    required this.blocks,
  }) : super(book);

  final List<db.ProcessingRun> runs;
  final List<db.RawPage> rawPages;
  final List<db.Chapter> chapters;
  final List<db.NarrationBlock> blocks;
}

extension on db.Book {
  T let<T>(T Function(db.Book value) transform) => transform(this);
}
