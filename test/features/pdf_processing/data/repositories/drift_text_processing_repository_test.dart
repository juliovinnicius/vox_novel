import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart' hide RawPage;
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

void main() {
  late AppDatabase database;
  late DriftTextProcessingRepository repository;
  final now = DateTime.utc(2026, 7, 17);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftTextProcessingRepository(database);
    await database
        .into(database.books)
        .insert(
          BooksCompanion.insert(
            id: 'book-1',
            title: 'Livro',
            originalFileName: 'livro.pdf',
            storedFilePath: '/livro.pdf',
            fileHash: 'hash',
            status: BookStatus.importing,
            processingProgress: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
  });
  tearDown(() => database.close());

  Future<void> createRun(String id) =>
      repository.createRun(bookId: 'book-1', runId: id, startedAt: now);

  final chapter = ChapterDraft(
    id: 'chapter-1',
    title: 'Capítulo 1',
    sortOrder: 0,
    startPage: 1,
    endPage: 1,
    cleanText: 'Texto.',
  );
  final block = NarrationBlockDraft(
    id: 'block-1',
    chapterId: 'chapter-1',
    sortOrder: 0,
    originalText: 'Texto.',
    normalizedText: 'Texto.',
    characterCount: 6,
    startPage: 1,
    endPage: 1,
  );

  Future<void> stageComplete(String runId) async {
    await repository.stageRawPage(runId, RawPage(pageNumber: 1, text: 'Raw'));
    await repository.stageCleanPage(
      runId,
      CleanPage(pageNumber: 1, text: 'Texto.'),
    );
    await repository.stageChaptersAndBlocks(
      runId: runId,
      bookId: 'book-1',
      chapters: [chapter],
      blocks: [block],
      createdAt: now,
    );
  }

  test('create run sets exact initial durable processing state', () async {
    await createRun('run-1');

    final book = await database.select(database.books).getSingle();
    final run = await database.select(database.processingRuns).getSingle();

    expect(
      [book.status, book.processingStage, book.processingProgress],
      [BookStatus.processing, ProcessingStage.extracting, 0.0],
    );
    expect([run.id, run.bookId, run.state], ['run-1', 'book-1', 'staging']);
  });

  test('staged rows are exact and excluded from active reads', () async {
    await createRun('run-1');
    await stageComplete('run-1');

    expect(await repository.readActiveContent('book-1'), isNull);
    final raw = await database.select(database.rawPages).getSingle();
    final storedChapter = await database.select(database.chapters).getSingle();
    final storedBlock = await database
        .select(database.narrationBlocks)
        .getSingle();
    expect([raw.rawText, raw.cleanText], ['Raw', 'Texto.']);
    expect(
      [storedChapter.title, storedChapter.cleanText],
      ['Capítulo 1', 'Texto.'],
    );
    expect(
      [
        storedBlock.originalText,
        storedBlock.normalizedText,
        storedBlock.characterCount,
      ],
      ['Texto.', 'Texto.', 6],
    );
  });

  test('raw page stream is one-based and ordered', () async {
    await createRun('run-1');
    await repository.stageRawPage(
      'run-1',
      RawPage(pageNumber: 2, text: 'dois'),
    );
    await repository.stageRawPage('run-1', RawPage(pageNumber: 1, text: 'um'));

    final pages = await repository.streamRawPages('run-1').toList();

    expect(pages, [
      RawPage(pageNumber: 1, text: 'um'),
      RawPage(pageNumber: 2, text: 'dois'),
    ]);
  });

  test('progress is monotonic for repeated and delayed updates', () async {
    await createRun('run-1');
    await repository.updateProgress(
      bookId: 'book-1',
      stage: ProcessingStage.cleaning,
      progress: .55,
      updatedAt: now,
    );
    await repository.updateProgress(
      bookId: 'book-1',
      stage: ProcessingStage.cleaning,
      progress: .45,
      updatedAt: now,
    );
    await repository.updateProgress(
      bookId: 'book-1',
      stage: ProcessingStage.extracting,
      progress: .40,
      updatedAt: now,
    );

    final book = await database.select(database.books).getSingle();
    expect(
      [book.processingStage, book.processingProgress],
      [ProcessingStage.cleaning, .55],
    );
  });

  test('progress is clamped to the current stage upper bound', () async {
    await createRun('run-1');

    await repository.updateProgress(
      bookId: 'book-1',
      stage: ProcessingStage.extracting,
      progress: .91,
      updatedAt: now,
    );

    final book = await database.select(database.books).getSingle();
    expect(book.processingProgress, .40);
  });

  test(
    'activation atomically publishes exact content and book counts',
    () async {
      await createRun('run-1');
      await stageComplete('run-1');

      await repository.activateRun(
        runId: 'run-1',
        pageCount: 1,
        chapterCount: 1,
        blockCount: 1,
        completedAt: now,
      );

      final book = await database.select(database.books).getSingle();
      final content = await repository.readActiveContent('book-1');
      expect(
        [
          book.status,
          book.processingStage,
          book.processingProgress,
          book.pageCount,
          book.chapterCount,
          book.blockCount,
          book.activeContentRunId,
        ],
        [BookStatus.ready, ProcessingStage.completed, 1.0, 1, 1, 1, 'run-1'],
      );
      expect(content!.rawPages, [RawPage(pageNumber: 1, text: 'Raw')]);
      expect(content.cleanPages, [CleanPage(pageNumber: 1, text: 'Texto.')]);
      expect(content.chapters, [chapter]);
      expect(content.blocks, [block]);
    },
  );

  test('failed activation preserves the prior active run', () async {
    await createRun('run-old');
    await stageComplete('run-old');
    await repository.activateRun(
      runId: 'run-old',
      pageCount: 1,
      chapterCount: 1,
      blockCount: 1,
      completedAt: now,
    );

    expect(
      repository.activateRun(
        runId: 'missing',
        pageCount: 9,
        chapterCount: 9,
        blockCount: 9,
        completedAt: now,
      ),
      throwsStateError,
    );
    final book = await database.select(database.books).getSingle();
    expect(book.activeContentRunId, 'run-old');
    expect((await repository.readActiveContent('book-1'))!.rawPages, [
      RawPage(pageNumber: 1, text: 'Raw'),
    ]);
  });

  test('successful retry replaces and cascades the superseded run', () async {
    await createRun('run-old');
    await stageComplete('run-old');
    await repository.activateRun(
      runId: 'run-old',
      pageCount: 1,
      chapterCount: 1,
      blockCount: 1,
      completedAt: now,
    );
    await createRun('run-new');
    await repository.stageRawPage(
      'run-new',
      RawPage(pageNumber: 1, text: 'Novo'),
    );
    await repository.stageCleanPage(
      'run-new',
      CleanPage(pageNumber: 1, text: 'Novo'),
    );

    await repository.activateRun(
      runId: 'run-new',
      pageCount: 1,
      chapterCount: 0,
      blockCount: 0,
      completedAt: now,
    );

    expect((await repository.readActiveContent('book-1'))!.rawPages, [
      RawPage(pageNumber: 1, text: 'Novo'),
    ]);
    expect(
      await (database.select(
        database.processingRuns,
      )..where((row) => row.id.equals('run-old'))).get(),
      isEmpty,
    );
  });

  test('cancel discard removes only staging and resets exact state', () async {
    await createRun('run-old');
    await stageComplete('run-old');
    await repository.activateRun(
      runId: 'run-old',
      pageCount: 1,
      chapterCount: 1,
      blockCount: 1,
      completedAt: now,
    );
    await createRun('run-new');
    await repository.stageRawPage(
      'run-new',
      RawPage(pageNumber: 1, text: 'staged'),
    );

    await repository.discardRun(
      runId: 'run-new',
      terminalStatus: BookStatus.importing,
      updatedAt: now,
    );

    final book = await database.select(database.books).getSingle();
    expect(
      [
        book.status,
        book.processingStage,
        book.processingProgress,
        book.activeContentRunId,
      ],
      [BookStatus.importing, null, 0.0, 'run-old'],
    );
    expect(
      (await repository.readActiveContent('book-1'))!.rawPages.single.text,
      'Raw',
    );
  });

  test(
    'failure discard applies failed state and cascades staged rows',
    () async {
      await createRun('run-1');
      await repository.stageRawPage(
        'run-1',
        RawPage(pageNumber: 1, text: 'partial'),
      );

      await repository.discardRun(
        runId: 'run-1',
        terminalStatus: BookStatus.failed,
        updatedAt: now,
      );

      final book = await database.select(database.books).getSingle();
      expect(
        [book.status, book.processingStage, book.processingProgress],
        [BookStatus.failed, null, 0.0],
      );
      expect(await database.select(database.processingRuns).get(), isEmpty);
      expect(await database.select(database.rawPages).get(), isEmpty);
    },
  );

  test('discarding an unknown run is idempotent', () async {
    await repository.discardRun(
      runId: 'missing',
      terminalStatus: BookStatus.failed,
      updatedAt: now,
    );

    final book = await database.select(database.books).getSingle();
    expect([book.status, book.processingProgress], [BookStatus.importing, 0.0]);
  });
}
