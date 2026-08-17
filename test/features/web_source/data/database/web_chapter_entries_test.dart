import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 8, 17);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.into(database.books).insert(
      BooksCompanion.insert(
        id: 'book-web',
        title: 'Novela',
        sourceType: const Value(BookSourceType.web),
        sourceRef: const Value('https://centralnovel.com/series/novela/'),
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() => database.close());

  WebChapterEntriesCompanion entry({
    String bookId = 'book-web',
    required int sortOrder,
    String? url,
    String title = 'Capítulo',
    String state = 'pending',
  }) {
    return WebChapterEntriesCompanion.insert(
      bookId: bookId,
      sortOrder: sortOrder,
      url: url ?? 'https://centralnovel.com/novela-capitulo-$sortOrder/',
      title: title,
      state: state,
      updatedAt: now,
    );
  }

  test('persists every designed field with its defaults', () async {
    await database.into(database.webChapterEntries).insert(
      WebChapterEntriesCompanion.insert(
        bookId: 'book-web',
        sortOrder: 1,
        url: 'https://centralnovel.com/novela-capitulo-1/',
        title: 'Capítulo 1',
        state: 'failed',
        lastError: const Value('404'),
        updatedAt: now,
      ),
    );

    final row = await database.select(database.webChapterEntries).getSingle();

    expect(
      [
        row.bookId,
        row.sortOrder,
        row.url,
        row.title,
        row.state,
        row.attemptCount,
        row.lastError,
        row.updatedAt,
      ],
      [
        'book-web',
        1,
        'https://centralnovel.com/novela-capitulo-1/',
        'Capítulo 1',
        'failed',
        0,
        '404',
        now,
      ],
    );
  });

  test('leaves lastError null until a failure is recorded', () async {
    await database.into(database.webChapterEntries).insert(entry(sortOrder: 1));

    final row = await database.select(database.webChapterEntries).getSingle();

    expect(row.lastError, isNull);
    expect(row.attemptCount, 0);
  });

  test('rejects a duplicate sort order within one book', () async {
    await database.into(database.webChapterEntries).insert(entry(sortOrder: 1));

    await expectLater(
      database
          .into(database.webChapterEntries)
          .insert(entry(sortOrder: 1, url: 'https://centralnovel.com/outro/')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('rejects a duplicate url within one book', () async {
    await database.into(database.webChapterEntries).insert(
      entry(sortOrder: 1, url: 'https://centralnovel.com/capitulo-1/'),
    );

    await expectLater(
      database.into(database.webChapterEntries).insert(
        entry(sortOrder: 2, url: 'https://centralnovel.com/capitulo-1/'),
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('allows the same url under a different book', () async {
    await database.into(database.books).insert(
      BooksCompanion.insert(
        id: 'book-other',
        title: 'Outra',
        sourceType: const Value(BookSourceType.web),
        sourceRef: const Value('https://centralnovel.com/series/outra/'),
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    const sharedUrl = 'https://centralnovel.com/capitulo-1/';

    await database
        .into(database.webChapterEntries)
        .insert(entry(sortOrder: 1, url: sharedUrl));
    await database.into(database.webChapterEntries).insert(
      entry(bookId: 'book-other', sortOrder: 1, url: sharedUrl),
    );

    final rows = await database.select(database.webChapterEntries).get();
    expect(rows.map((row) => row.bookId), ['book-web', 'book-other']);
  });

  test('deleting a book cascades its entries away', () async {
    await database.into(database.webChapterEntries).insert(entry(sortOrder: 1));
    await database.into(database.webChapterEntries).insert(entry(sortOrder: 2));

    await (database.delete(
      database.books,
    )..where((row) => row.id.equals('book-web'))).go();

    expect(await database.select(database.webChapterEntries).get(), isEmpty);
  });

  test('a v5 database gains the table through the v6 upgrade', () async {
    final upgraded = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE "books" ('
            '"id" TEXT NOT NULL, "title" TEXT NOT NULL, "author" TEXT NULL, '
            '"cover_path" TEXT NULL, "original_file_name" TEXT NOT NULL, '
            '"stored_file_path" TEXT NOT NULL, "file_hash" TEXT NOT NULL, '
            '"status" TEXT NOT NULL, "processing_progress" REAL NOT NULL, '
            '"page_count" INTEGER NOT NULL DEFAULT 0, '
            '"chapter_count" INTEGER NOT NULL DEFAULT 0, '
            '"block_count" INTEGER NOT NULL DEFAULT 0, '
            '"processing_stage" TEXT NULL, '
            '"active_content_run_id" TEXT NULL, '
            '"created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
            'PRIMARY KEY ("id"))',
          );
          raw.userVersion = 5;
        },
      ),
    );
    addTearDown(upgraded.close);

    expect(await upgraded.select(upgraded.webChapterEntries).get(), isEmpty);
  });
}
