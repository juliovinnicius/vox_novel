import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

void main() {
  late AppDatabase database;
  final createdAt = DateTime.utc(2026, 7, 17, 12);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => database.close());

  Future<void> insertBook({String id = 'book-1'}) {
    return database
        .into(database.books)
        .insert(
          BooksCompanion.insert(
            id: id,
            title: 'Livro',
            originalFileName: 'livro.pdf',
            storedFilePath: '/books/livro.pdf',
            fileHash: 'hash-$id',
            status: BookStatus.importing,
            processingProgress: 0,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
  }

  Future<void> insertRun({String id = 'run-1', String bookId = 'book-1'}) {
    return database
        .into(database.processingRuns)
        .insert(
          ProcessingRunsCompanion.insert(
            id: id,
            bookId: bookId,
            state: 'staging',
            startedAt: createdAt,
          ),
        );
  }

  test('fresh schema persists every book and processing run field', () async {
    await insertBook();
    await insertRun();
    await (database.update(
      database.processingRuns,
    )..where((row) => row.id.equals('run-1'))).write(
      ProcessingRunsCompanion(
        cleanText: const Value('texto limpo'),
        state: const Value('active'),
        completedAt: Value(createdAt.add(const Duration(minutes: 1))),
      ),
    );
    await (database.update(
      database.books,
    )..where((row) => row.id.equals('book-1'))).write(
      const BooksCompanion(
        status: Value(BookStatus.ready),
        processingProgress: Value(1),
        pageCount: Value(2),
        chapterCount: Value(1),
        blockCount: Value(1),
        processingStage: Value(ProcessingStage.completed),
        activeContentRunId: Value('run-1'),
      ),
    );

    final book = await database.select(database.books).getSingle();
    final run = await database.select(database.processingRuns).getSingle();

    expect(
      [
        book.status,
        book.processingProgress,
        book.pageCount,
        book.chapterCount,
        book.blockCount,
        book.processingStage,
        book.activeContentRunId,
      ],
      [BookStatus.ready, 1.0, 2, 1, 1, ProcessingStage.completed, 'run-1'],
    );
    expect(
      [run.bookId, run.cleanText, run.state, run.startedAt, run.completedAt],
      [
        'book-1',
        'texto limpo',
        'active',
        createdAt,
        createdAt.add(const Duration(minutes: 1)),
      ],
    );
  });

  test(
    'raw pages round-trip empty and non-empty text in source order',
    () async {
      await insertBook();
      await insertRun();
      await database.batch((batch) {
        batch.insertAll(database.rawPages, [
          RawPagesCompanion.insert(
            runId: 'run-1',
            pageNumber: 2,
            rawText: 'segunda',
            cleanText: Value('limpa'),
          ),
          RawPagesCompanion.insert(
            runId: 'run-1',
            pageNumber: 1,
            rawText: '',
            cleanText: Value(''),
          ),
        ]);
      });

      final query = database.select(database.rawPages)
        ..orderBy([(row) => OrderingTerm.asc(row.pageNumber)]);
      final pages = await query.get();

      expect(
        pages.map((page) => [page.pageNumber, page.rawText, page.cleanText]),
        [
          [1, '', ''],
          [2, 'segunda', 'limpa'],
        ],
      );
    },
  );

  test(
    'chapters and blocks persist exact payloads including empty text',
    () async {
      await insertBook();
      await insertRun();
      await database
          .into(database.chapters)
          .insert(
            ChaptersCompanion.insert(
              id: 'chapter-1',
              runId: 'run-1',
              bookId: 'book-1',
              title: 'Início',
              sortOrder: 0,
              startPage: 1,
              endPage: 2,
              cleanText: '',
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
      await database
          .into(database.narrationBlocks)
          .insert(
            NarrationBlocksCompanion.insert(
              id: 'block-1',
              runId: 'run-1',
              chapterId: 'chapter-1',
              sortOrder: 0,
              originalText: 'Olá.',
              normalizedText: 'Olá.',
              characterCount: 5,
              startPage: 2,
              endPage: 2,
            ),
          );

      final chapter = await database.select(database.chapters).getSingle();
      final block = await database.select(database.narrationBlocks).getSingle();

      expect(
        [
          chapter.id,
          chapter.runId,
          chapter.bookId,
          chapter.title,
          chapter.sortOrder,
          chapter.startPage,
          chapter.endPage,
          chapter.cleanText,
          chapter.createdAt,
          chapter.updatedAt,
        ],
        [
          'chapter-1',
          'run-1',
          'book-1',
          'Início',
          0,
          1,
          2,
          '',
          createdAt,
          createdAt,
        ],
      );
      expect(
        [
          block.id,
          block.runId,
          block.chapterId,
          block.sortOrder,
          block.originalText,
          block.normalizedText,
          block.characterCount,
          block.startPage,
          block.endPage,
        ],
        ['block-1', 'run-1', 'chapter-1', 0, 'Olá.', 'Olá.', 5, 2, 2],
      );
    },
  );

  test('unique run and chapter ordering constraints are enforced', () async {
    await insertBook();
    await insertRun();
    Future<void> chapter(String id, int order) => database
        .into(database.chapters)
        .insert(
          ChaptersCompanion.insert(
            id: id,
            runId: 'run-1',
            bookId: 'book-1',
            title: id,
            sortOrder: order,
            startPage: 1,
            endPage: 1,
            cleanText: '',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await chapter('chapter-1', 0);

    expect(chapter('chapter-2', 0), throwsA(isA<SqliteException>()));
  });

  test('unique chapter block ordering constraint is enforced', () async {
    await insertBook();
    await insertRun();
    await database
        .into(database.chapters)
        .insert(
          ChaptersCompanion.insert(
            id: 'chapter-1',
            runId: 'run-1',
            bookId: 'book-1',
            title: 'Capítulo 1',
            sortOrder: 0,
            startPage: 1,
            endPage: 1,
            cleanText: 'texto',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    Future<void> block(String id) => database
        .into(database.narrationBlocks)
        .insert(
          NarrationBlocksCompanion.insert(
            id: id,
            runId: 'run-1',
            chapterId: 'chapter-1',
            sortOrder: 0,
            originalText: id,
            normalizedText: id,
            characterCount: id.length,
            startPage: 1,
            endPage: 1,
          ),
        );
    await block('block-1');

    expect(block('block-2'), throwsA(isA<SqliteException>()));
  });

  test('active run reference rejects a run from no existing row', () async {
    await insertBook();

    final update =
        (database.update(
          database.books,
        )..where((row) => row.id.equals('book-1'))).write(
          const BooksCompanion(activeContentRunId: Value('missing-run')),
        );

    expect(update, throwsA(isA<SqliteException>()));
  });

  test('deleting a run cascades pages chapters and blocks', () async {
    await insertBook();
    await insertRun();
    await database
        .into(database.rawPages)
        .insert(
          RawPagesCompanion.insert(runId: 'run-1', pageNumber: 1, rawText: ''),
        );
    await database
        .into(database.chapters)
        .insert(
          ChaptersCompanion.insert(
            id: 'chapter-1',
            runId: 'run-1',
            bookId: 'book-1',
            title: 'Início',
            sortOrder: 0,
            startPage: 1,
            endPage: 1,
            cleanText: '',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await database
        .into(database.narrationBlocks)
        .insert(
          NarrationBlocksCompanion.insert(
            id: 'block-1',
            runId: 'run-1',
            chapterId: 'chapter-1',
            sortOrder: 0,
            originalText: 'a',
            normalizedText: 'a',
            characterCount: 1,
            startPage: 1,
            endPage: 1,
          ),
        );

    await database.delete(database.processingRuns).go();

    expect(await database.select(database.rawPages).get(), isEmpty);
    expect(await database.select(database.chapters).get(), isEmpty);
    expect(await database.select(database.narrationBlocks).get(), isEmpty);
  });

  test('deleting a book cascades the entire processing dataset', () async {
    await insertBook();
    await insertRun();

    await database.delete(database.books).go();

    expect(await database.select(database.processingRuns).get(), isEmpty);
  });
}
