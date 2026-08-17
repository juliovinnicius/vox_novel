import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('fresh schema persists every designed field', () async {
    final createdAt = DateTime.utc(2026, 7, 17);
    final updatedAt = DateTime.utc(2026, 7, 18);

    await database.into(database.books).insert(
      BooksCompanion.insert(
        id: 'book-1',
        title: 'Título',
        author: const Value('Autora'),
        coverPath: const Value('/books/cover.jpg'),
        originalFileName: Value('original.pdf'),
        storedFilePath: Value('/books/book-1.pdf'),
        fileHash: Value('hash-1'),
        status: BookStatus.importing,
        processingProgress: 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );

    final row = await database.select(database.books).getSingle();

    expect(row.id, 'book-1');
    expect(row.title, 'Título');
    expect(row.author, 'Autora');
    expect(row.coverPath, '/books/cover.jpg');
    expect(row.originalFileName, 'original.pdf');
    expect(row.storedFilePath, '/books/book-1.pdf');
    expect(row.fileHash, 'hash-1');
    expect(row.status, BookStatus.importing);
    expect(row.processingProgress, 0);
    expect(row.createdAt, createdAt);
    expect(row.updatedAt, updatedAt);
  });

  for (final status in BookStatus.values) {
    test('persists and reads ${status.name} exactly', () async {
      await database.into(database.books).insert(
        BooksCompanion.insert(
          id: 'book-${status.name}',
          title: 'Livro',
          originalFileName: Value('livro.pdf'),
          storedFilePath: Value('/books/${status.name}.pdf'),
          fileHash: Value('hash-${status.name}'),
          status: status,
          processingProgress: 0,
          createdAt: DateTime.utc(2026, 7, 17),
          updatedAt: DateTime.utc(2026, 7, 17),
        ),
      );

      final row = await database.select(database.books).getSingle();

      expect(row.status, status);
    });
  }

  test('rejects duplicate file hashes', () async {
    BooksCompanion companion(String id) => BooksCompanion.insert(
      id: id,
      title: 'Livro',
      originalFileName: Value('$id.pdf'),
      storedFilePath: Value('/books/$id.pdf'),
      fileHash: Value('same-hash'),
      status: BookStatus.importing,
      processingProgress: 0,
      createdAt: DateTime.utc(2026, 7, 17),
      updatedAt: DateTime.utc(2026, 7, 17),
    );

    await database.into(database.books).insert(companion('book-1'));

    expect(
      database.into(database.books).insert(companion('book-2')),
      throwsA(isA<SqliteException>()),
    );
  });

  group('schema v5 to v6 migration', () {
    const v5Books = '''
      CREATE TABLE "books" (
        "id" TEXT NOT NULL,
        "title" TEXT NOT NULL,
        "author" TEXT NULL,
        "cover_path" TEXT NULL,
        "original_file_name" TEXT NOT NULL,
        "stored_file_path" TEXT NOT NULL,
        "file_hash" TEXT NOT NULL,
        "status" TEXT NOT NULL,
        "processing_progress" REAL NOT NULL,
        "page_count" INTEGER NOT NULL DEFAULT 0,
        "chapter_count" INTEGER NOT NULL DEFAULT 0,
        "block_count" INTEGER NOT NULL DEFAULT 0,
        "processing_stage" TEXT NULL,
        "active_content_run_id" TEXT NULL
          REFERENCES processing_runs(id) ON DELETE SET NULL,
        "created_at" INTEGER NOT NULL,
        "updated_at" INTEGER NOT NULL,
        PRIMARY KEY ("id")
      )
    ''';
    const v5ProcessingRuns = '''
      CREATE TABLE "processing_runs" (
        "id" TEXT NOT NULL,
        "book_id" TEXT NOT NULL REFERENCES books (id) ON DELETE CASCADE,
        "clean_text" TEXT NULL,
        "state" TEXT NOT NULL,
        "started_at" INTEGER NOT NULL,
        "completed_at" INTEGER NULL,
        PRIMARY KEY ("id")
      )
    ''';
    final createdAt = DateTime.utc(2026, 7, 17);
    final updatedAt = DateTime.utc(2026, 7, 18);

    AppDatabase openUpgradedFromV5() {
      final createdAtMillis = createdAt.millisecondsSinceEpoch;
      final updatedAtMillis = updatedAt.millisecondsSinceEpoch;
      return AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(v5Books);
            raw.execute(v5ProcessingRuns);
            raw.execute(
              'CREATE UNIQUE INDEX books_file_hash_unique '
              'ON books (file_hash)',
            );
            raw.execute(
              "INSERT INTO processing_runs VALUES "
              "('run-1','book-1','Texto','active',$createdAtMillis,NULL)",
            );
            raw.execute(
              'INSERT INTO books VALUES '
              "('book-1','Título','Autora','/books/cover.jpg',"
              "'original.pdf','/books/book-1.pdf','hash-1','ready',1.0,"
              "12,3,42,'completed','run-1',"
              '$createdAtMillis,$updatedAtMillis)',
            );
            raw.execute(
              'INSERT INTO books VALUES '
              "('book-2','Segundo',NULL,NULL,"
              "'outro.pdf','/books/book-2.pdf','hash-2','importing',0.0,"
              "0,0,0,NULL,NULL,"
              '$createdAtMillis,$createdAtMillis)',
            );
            raw.userVersion = 5;
          },
        ),
      );
    }

    test('preserves every seeded column value of a v5 pdf book', () async {
      final upgraded = openUpgradedFromV5();
      addTearDown(upgraded.close);

      final rows =
          await (upgraded.select(upgraded.books)
                ..orderBy([(row) => OrderingTerm.asc(row.id)]))
              .get();

      expect(rows, hasLength(2));
      final first = rows.first;
      expect(
        [
          first.id,
          first.title,
          first.author,
          first.coverPath,
          first.originalFileName,
          first.storedFilePath,
          first.fileHash,
          first.status,
          first.processingProgress,
          first.pageCount,
          first.chapterCount,
          first.blockCount,
          first.processingStage,
          first.activeContentRunId,
          first.createdAt,
          first.updatedAt,
        ],
        [
          'book-1',
          'Título',
          'Autora',
          '/books/cover.jpg',
          'original.pdf',
          '/books/book-1.pdf',
          'hash-1',
          BookStatus.ready,
          1.0,
          12,
          3,
          42,
          ProcessingStage.completed,
          'run-1',
          createdAt,
          updatedAt,
        ],
      );
      expect(rows.last.id, 'book-2');
      expect(rows.last.author, isNull);
      expect(rows.last.activeContentRunId, isNull);
    });

    test('defaults upgraded rows to the pdf source with no source ref', () async {
      final upgraded = openUpgradedFromV5();
      addTearDown(upgraded.close);

      final rows = await upgraded.select(upgraded.books).get();

      expect(
        rows.map((row) => row.sourceType),
        everyElement(BookSourceType.pdf),
      );
      expect(rows.map((row) => row.sourceRef), everyElement(isNull));
    });

    test('accepts a web book with no file columns after upgrade', () async {
      final upgraded = openUpgradedFromV5();
      addTearDown(upgraded.close);

      await upgraded.into(upgraded.books).insert(
        BooksCompanion.insert(
          id: 'book-web',
          title: 'Novela',
          sourceType: const Value(BookSourceType.web),
          sourceRef: const Value('https://centralnovel.com/series/a/'),
          status: BookStatus.processing,
          processingProgress: 0,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final row = await (upgraded.select(
        upgraded.books,
      )..where((row) => row.id.equals('book-web'))).getSingle();

      expect(row.sourceType, BookSourceType.web);
      expect(row.sourceRef, 'https://centralnovel.com/series/a/');
      expect(row.originalFileName, isNull);
      expect(row.storedFilePath, isNull);
      expect(row.fileHash, isNull);
    });

    test(
      'keeps books_file_hash_unique rejecting duplicates after upgrade',
      () async {
        final upgraded = openUpgradedFromV5();
        addTearDown(upgraded.close);

        await expectLater(
          upgraded.into(upgraded.books).insert(
            BooksCompanion.insert(
              id: 'book-3',
              title: 'Duplicado',
              originalFileName: const Value('outro.pdf'),
              storedFilePath: const Value('/books/book-3.pdf'),
              fileHash: const Value('hash-1'),
              status: BookStatus.importing,
              processingProgress: 0,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          ),
          throwsA(isA<SqliteException>()),
        );
      },
    );

    test('tolerates many null file hashes after upgrade', () async {
      final upgraded = openUpgradedFromV5();
      addTearDown(upgraded.close);

      BooksCompanion webBook(String id) => BooksCompanion.insert(
        id: id,
        title: 'Novela $id',
        sourceType: const Value(BookSourceType.web),
        sourceRef: Value('https://centralnovel.com/series/$id/'),
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      await upgraded.into(upgraded.books).insert(webBook('web-1'));
      await upgraded.into(upgraded.books).insert(webBook('web-2'));

      final nullHashed = await (upgraded.select(
        upgraded.books,
      )..where((row) => row.fileHash.isNull())).get();
      expect(nullHashed, hasLength(2));
    });

    test('books_source_ref_unique rejects a duplicate series url', () async {
      final upgraded = openUpgradedFromV5();
      addTearDown(upgraded.close);

      BooksCompanion webBook(String id) => BooksCompanion.insert(
        id: id,
        title: 'Novela $id',
        sourceType: const Value(BookSourceType.web),
        sourceRef: const Value('https://centralnovel.com/series/mesma/'),
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: createdAt,
        updatedAt: createdAt,
      );

      await upgraded.into(upgraded.books).insert(webBook('web-1'));

      await expectLater(
        upgraded.into(upgraded.books).insert(webBook('web-2')),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
