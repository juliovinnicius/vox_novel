import 'package:drift/drift.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';

final class DriftTextProcessingRepository implements TextProcessingRepository {
  const DriftTextProcessingRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
  }) {
    return _database.transaction(() async {
      await _database
          .into(_database.processingRuns)
          .insert(
            db.ProcessingRunsCompanion.insert(
              id: runId,
              bookId: bookId,
              state: 'staging',
              startedAt: startedAt,
            ),
          );
      await (_database.update(
        _database.books,
      )..where((row) => row.id.equals(bookId))).write(
        db.BooksCompanion(
          status: const Value(BookStatus.processing),
          processingProgress: const Value(0),
          processingStage: const Value(ProcessingStage.extracting),
          updatedAt: Value(startedAt),
        ),
      );
    });
  }

  @override
  Future<void> stageRawPage(String runId, RawPage page) {
    return _database
        .into(_database.rawPages)
        .insert(
          db.RawPagesCompanion.insert(
            runId: runId,
            pageNumber: page.pageNumber,
            rawText: page.text,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Stream<RawPage> streamRawPages(String runId) async* {
    var lastPageNumber = 0;
    while (true) {
      final query = _database.select(_database.rawPages)
        ..where(
          (row) =>
              row.runId.equals(runId) &
              row.pageNumber.isBiggerThanValue(lastPageNumber),
        )
        ..orderBy([(row) => OrderingTerm.asc(row.pageNumber)])
        ..limit(1);
      final row = await query.getSingleOrNull();
      if (row == null) return;
      yield RawPage(pageNumber: row.pageNumber, text: row.rawText);
      lastPageNumber = row.pageNumber;
    }
  }

  @override
  Future<void> stageCleanPage(String runId, CleanPage page) async {
    final changed =
        await (_database.update(_database.rawPages)..where(
              (row) =>
                  row.runId.equals(runId) &
                  row.pageNumber.equals(page.pageNumber),
            ))
            .write(db.RawPagesCompanion(cleanText: Value(page.text)));
    if (changed != 1) {
      throw StateError('Raw page not found');
    }
  }

  @override
  Future<void> stageChaptersAndBlocks({
    required String runId,
    required String bookId,
    required List<ChapterDraft> chapters,
    required List<NarrationBlockDraft> blocks,
    required DateTime createdAt,
  }) {
    return _database.transaction(() async {
      await _database.batch((batch) {
        batch.insertAll(_database.chapters, [
          for (final chapter in chapters)
            db.ChaptersCompanion.insert(
              id: chapter.id,
              runId: runId,
              bookId: bookId,
              title: chapter.title,
              sortOrder: chapter.sortOrder,
              startPage: chapter.startPage,
              endPage: chapter.endPage,
              cleanText: chapter.cleanText,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
        ]);
        batch.insertAll(_database.narrationBlocks, [
          for (final block in blocks)
            db.NarrationBlocksCompanion.insert(
              id: block.id,
              runId: runId,
              chapterId: block.chapterId,
              sortOrder: block.sortOrder,
              originalText: block.originalText,
              normalizedText: block.normalizedText,
              characterCount: block.characterCount,
              startPage: block.startPage,
              endPage: block.endPage,
            ),
        ]);
      });
    });
  }

  @override
  Future<void> updateProgress({
    required String bookId,
    required ProcessingStage stage,
    required double progress,
    required DateTime updatedAt,
  }) async {
    await _database.transaction(() async {
      final book = await (_database.select(
        _database.books,
      )..where((row) => row.id.equals(bookId))).getSingle();
      if (book.status != BookStatus.processing) return;
      final currentStage = book.processingStage;
      if (currentStage != null && stage.index < currentStage.index) return;
      final bounded = progress.clamp(
        stage.minimumProgress,
        stage.maximumProgress,
      );
      final candidate = bounded < book.processingProgress
          ? book.processingProgress
          : bounded;
      await (_database.update(
        _database.books,
      )..where((row) => row.id.equals(bookId))).write(
        db.BooksCompanion(
          processingStage: Value(stage),
          processingProgress: Value(candidate),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  @override
  Future<void> activateRun({
    required String runId,
    required int pageCount,
    required int chapterCount,
    required int blockCount,
    required DateTime completedAt,
  }) {
    return _database.transaction(() async {
      final run = await (_database.select(
        _database.processingRuns,
      )..where((row) => row.id.equals(runId))).getSingle();
      final book = await (_database.select(
        _database.books,
      )..where((row) => row.id.equals(run.bookId))).getSingle();
      final previousRunId = book.activeContentRunId;
      final cleanRows =
          await (_database.select(_database.rawPages)..where(
                (row) => row.runId.equals(runId) & row.cleanText.isNotNull(),
              ))
              .get();
      final cleanText = cleanRows.map((page) => page.cleanText!).join('\n');
      await (_database.update(
        _database.processingRuns,
      )..where((row) => row.id.equals(runId))).write(
        db.ProcessingRunsCompanion(
          cleanText: Value(cleanText),
          state: const Value('active'),
          completedAt: Value(completedAt),
        ),
      );
      await (_database.update(
        _database.books,
      )..where((row) => row.id.equals(run.bookId))).write(
        db.BooksCompanion(
          status: const Value(BookStatus.ready),
          processingProgress: const Value(1),
          pageCount: Value(pageCount),
          chapterCount: Value(chapterCount),
          blockCount: Value(blockCount),
          processingStage: const Value(ProcessingStage.completed),
          activeContentRunId: Value(runId),
          updatedAt: Value(completedAt),
        ),
      );
      if (previousRunId != null && previousRunId != runId) {
        await (_database.delete(
          _database.processingRuns,
        )..where((row) => row.id.equals(previousRunId))).go();
      }
    });
  }

  @override
  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  }) {
    return _database.transaction(() async {
      final run = await (_database.select(
        _database.processingRuns,
      )..where((row) => row.id.equals(runId))).getSingleOrNull();
      if (run == null) return;
      await (_database.delete(
        _database.processingRuns,
      )..where((row) => row.id.equals(runId))).go();
      await (_database.update(
        _database.books,
      )..where((row) => row.id.equals(run.bookId))).write(
        db.BooksCompanion(
          status: Value(terminalStatus),
          processingProgress: const Value(0),
          processingStage: const Value(null),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  @override
  Future<ActiveProcessedContent?> readActiveContent(String bookId) async {
    final book = await (_database.select(
      _database.books,
    )..where((row) => row.id.equals(bookId))).getSingleOrNull();
    final runId = book?.activeContentRunId;
    if (runId == null) return null;
    final pagesQuery = _database.select(_database.rawPages)
      ..where((row) => row.runId.equals(runId))
      ..orderBy([(row) => OrderingTerm.asc(row.pageNumber)]);
    final chaptersQuery = _database.select(_database.chapters)
      ..where((row) => row.runId.equals(runId))
      ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]);
    final blocksQuery = _database.select(_database.narrationBlocks)
      ..where((row) => row.runId.equals(runId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.chapterId),
        (row) => OrderingTerm.asc(row.sortOrder),
      ]);
    final pages = await pagesQuery.get();
    final chapters = await chaptersQuery.get();
    final blocks = await blocksQuery.get();
    return ActiveProcessedContent(
      rawPages: [
        for (final page in pages)
          RawPage(pageNumber: page.pageNumber, text: page.rawText),
      ],
      cleanPages: [
        for (final page in pages)
          if (page.cleanText != null)
            CleanPage(pageNumber: page.pageNumber, text: page.cleanText!),
      ],
      chapters: [
        for (final chapter in chapters)
          ChapterDraft(
            id: chapter.id,
            title: chapter.title,
            sortOrder: chapter.sortOrder,
            startPage: chapter.startPage,
            endPage: chapter.endPage,
            cleanText: chapter.cleanText,
          ),
      ],
      blocks: [
        for (final block in blocks)
          NarrationBlockDraft(
            id: block.id,
            chapterId: block.chapterId,
            sortOrder: block.sortOrder,
            originalText: block.originalText,
            normalizedText: block.normalizedText,
            characterCount: block.characterCount,
            startPage: block.startPage,
            endPage: block.endPage,
          ),
      ],
    );
  }
}
