import 'package:drift/drift.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';

final class DriftVisualReaderRepository implements VisualReaderRepository {
  DriftVisualReaderRepository(this._database);

  final db.AppDatabase _database;
  final Map<String, Future<void>> _positionTails = {};

  @override
  Future<ReaderBookContent?> loadContent(String bookId) async {
    final bookRow = await (_database.select(
      _database.books,
    )..where((row) => row.id.equals(bookId))).getSingleOrNull();
    if (bookRow == null ||
        bookRow.status != domain.BookStatus.ready ||
        bookRow.activeContentRunId == null) {
      return null;
    }
    final runId = bookRow.activeContentRunId!;
    final run =
        await (_database.select(
              _database.processingRuns,
            )..where((row) => row.id.equals(runId) & row.bookId.equals(bookId)))
            .getSingleOrNull();
    if (run == null) return null;
    final chapterRows =
        await (_database.select(_database.chapters)
              ..where(
                (row) => row.runId.equals(runId) & row.bookId.equals(bookId),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
            .get();
    final blockRows =
        await (_database.select(_database.narrationBlocks)
              ..where((row) => row.runId.equals(runId))
              ..orderBy([
                (row) => OrderingTerm.asc(row.chapterId),
                (row) => OrderingTerm.asc(row.sortOrder),
              ]))
            .get();
    if (chapterRows.length != bookRow.chapterCount ||
        blockRows.length != bookRow.blockCount) {
      return null;
    }
    final chapters = chapterRows
        .map(
          (chapter) => ReaderChapter(
            chapter: ChapterDraft(
              id: chapter.id,
              title: chapter.title,
              sortOrder: chapter.sortOrder,
              startPage: chapter.startPage,
              endPage: chapter.endPage,
              cleanText: chapter.cleanText,
            ),
            blocks: blockRows
                .where((block) => block.chapterId == chapter.id)
                .map(
                  (block) => NarrationBlockDraft(
                    id: block.id,
                    chapterId: block.chapterId,
                    sortOrder: block.sortOrder,
                    originalText: block.originalText,
                    normalizedText: block.normalizedText,
                    characterCount: block.characterCount,
                    startPage: block.startPage,
                    endPage: block.endPage,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    return ReaderBookContent(book: _book(bookRow), chapters: chapters);
  }

  @override
  Future<ReaderSettings> loadSettings() async {
    final row = await _database
        .select(_database.readerSettingsRows)
        .getSingleOrNull();
    return row == null
        ? ReaderSettings.defaults()
        : ReaderSettings(
            theme: row.theme,
            fontFamily: row.fontFamily,
            fontSize: row.fontSize,
            lineHeight: row.lineHeight,
          );
  }

  @override
  Future<void> saveSettings(ReaderSettings settings) {
    return _database
        .into(_database.readerSettingsRows)
        .insertOnConflictUpdate(
          db.ReaderSettingsRowsCompanion.insert(
            id: const Value(1),
            theme: settings.theme,
            fontFamily: settings.fontFamily,
            fontSize: settings.fontSize,
            lineHeight: settings.lineHeight,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<ReaderPosition?> loadPosition(String bookId) async {
    final row = await (_database.select(
      _database.readerPositions,
    )..where((row) => row.bookId.equals(bookId))).getSingleOrNull();
    return row == null
        ? null
        : ReaderPosition(
            bookId: row.bookId,
            mode: row.mode,
            chapterId: row.chapterId,
            blockId: row.blockId,
            pdfPage: row.pdfPage,
            updatedAt: row.updatedAt,
          );
  }

  @override
  Future<void> savePosition(ReaderPosition position) {
    final previous = _positionTails[position.bookId] ?? Future.value();
    final next = previous
        .catchError((_) {})
        .then(
          (_) => _database
              .into(_database.readerPositions)
              .insertOnConflictUpdate(
                db.ReaderPositionsCompanion.insert(
                  bookId: position.bookId,
                  mode: position.mode,
                  chapterId: Value(position.chapterId),
                  blockId: Value(position.blockId),
                  pdfPage: Value(position.pdfPage),
                  updatedAt: position.updatedAt,
                ),
              ),
        );
    _positionTails[position.bookId] = next;
    return next.whenComplete(() {
      if (identical(_positionTails[position.bookId], next)) {
        _positionTails.remove(position.bookId);
      }
    });
  }

  domain.Book _book(db.Book row) => domain.Book(
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
