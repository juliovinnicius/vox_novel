import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => database.close());

  test('fresh schema stores one global settings row exactly', () async {
    final now = DateTime.utc(2026);
    await database
        .into(database.readerSettingsRows)
        .insert(
          ReaderSettingsRowsCompanion.insert(
            id: const Value(1),
            theme: ReaderTheme.sepia,
            fontFamily: ReaderFontFamily.serif,
            fontSize: 24,
            lineHeight: 1.8,
            updatedAt: now,
          ),
        );

    final row = await database.select(database.readerSettingsRows).getSingle();
    expect(
      [
        row.id,
        row.theme,
        row.fontFamily,
        row.fontSize,
        row.lineHeight,
        row.updatedAt,
      ],
      [1, ReaderTheme.sepia, ReaderFontFamily.serif, 24, 1.8, now],
    );
    await expectLater(
      database
          .into(database.readerSettingsRows)
          .insert(
            ReaderSettingsRowsCompanion.insert(
              id: const Value(2),
              theme: ReaderTheme.light,
              fontFamily: ReaderFontFamily.sans,
              fontSize: 18,
              lineHeight: 1.5,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('stores one exact visual position per book', () async {
    await _insertBook(database);
    final now = DateTime.utc(2026);
    await database
        .into(database.readerPositions)
        .insert(
          ReaderPositionsCompanion.insert(
            bookId: 'book',
            mode: ReaderMode.pdf,
            chapterId: const Value('chapter'),
            blockId: const Value('block'),
            pdfPage: const Value(7),
            updatedAt: now,
          ),
        );
    final row = await database.select(database.readerPositions).getSingle();

    expect(
      [
        row.bookId,
        row.mode,
        row.chapterId,
        row.blockId,
        row.pdfPage,
        row.updatedAt,
      ],
      ['book', ReaderMode.pdf, 'chapter', 'block', 7, now],
    );
    await expectLater(
      database
          .into(database.readerPositions)
          .insert(
            ReaderPositionsCompanion.insert(
              bookId: 'book',
              mode: ReaderMode.text,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('raw invalid enum and bounds fail deterministically', () async {
    final now = DateTime.utc(2026).millisecondsSinceEpoch;
    await expectLater(
      database.customStatement(
        "INSERT INTO reader_settings_rows VALUES (1, 'unknown', 'sans', 18, 1.5, $now)",
      ),
      completes,
    );
    expect(
      database.select(database.readerSettingsRows).getSingle(),
      throwsA(isA<FormatException>()),
    );
    await database.delete(database.readerSettingsRows).go();
    for (final values in [
      "1, 'light', 'sans', 15, 1.5",
      "1, 'light', 'sans', 18, 1.4",
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO reader_settings_rows VALUES ($values, $now)',
        ),
        throwsA(anything),
      );
    }
  });

  test(
    'book deletion cascades position but preserves global settings',
    () async {
      await _insertBook(database);
      final now = DateTime.utc(2026);
      await database
          .into(database.readerSettingsRows)
          .insert(
            ReaderSettingsRowsCompanion.insert(
              id: const Value(1),
              theme: ReaderTheme.light,
              fontFamily: ReaderFontFamily.sans,
              fontSize: 18,
              lineHeight: 1.5,
              updatedAt: now,
            ),
          );
      await database
          .into(database.readerPositions)
          .insert(
            ReaderPositionsCompanion.insert(
              bookId: 'book',
              mode: ReaderMode.text,
              updatedAt: now,
            ),
          );

      await (database.delete(
        database.books,
      )..where((row) => row.id.equals('book'))).go();

      expect(await database.select(database.readerPositions).get(), isEmpty);
      expect(
        await database.select(database.readerSettingsRows).get(),
        hasLength(1),
      );
    },
  );

  test('version 3 migration preserves every processed payload', () async {
    final directory = await Directory.systemTemp.createTemp('reader_v3_');
    final file = File('${directory.path}/database.sqlite');
    addTearDown(() => directory.delete(recursive: true));
    await database.close();
    database = AppDatabase(NativeDatabase(file));
    final timestamp = DateTime.utc(2026).millisecondsSinceEpoch;
    await database.customStatement(
      "INSERT INTO books (id,title,original_file_name,stored_file_path,file_hash,"
      "status,processing_progress,page_count,chapter_count,block_count,created_at,updated_at) "
      "VALUES ('book','Livro','book.pdf','/book.pdf','hash','ready',1,1,1,1,$timestamp,$timestamp)",
    );
    await database.customStatement(
      "INSERT INTO processing_runs VALUES ('run','book','Texto','active',$timestamp,$timestamp)",
    );
    await database.customStatement(
      "UPDATE books SET active_content_run_id='run' WHERE id='book'",
    );
    await database.customStatement(
      "INSERT INTO raw_pages VALUES ('run',1,'Raw','Texto')",
    );
    await database.customStatement(
      "INSERT INTO chapters VALUES ('chapter','run','book','Capítulo',0,1,1,'Texto',$timestamp,$timestamp)",
    );
    await database.customStatement(
      "INSERT INTO narration_blocks VALUES ('block','run','chapter',0,'Texto','Texto',5,1,1)",
    );
    await database.close();
    database = AppDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('DROP TABLE reader_positions');
          raw.execute('DROP TABLE reader_settings_rows');
          raw.userVersion = 3;
        },
      ),
    );
    final book = await database.select(database.books).getSingle();
    final run = await database.select(database.processingRuns).getSingle();
    final page = await database.select(database.rawPages).getSingle();
    final chapter = await database.select(database.chapters).getSingle();
    final block = await database.select(database.narrationBlocks).getSingle();

    expect(
      [book.id, book.status, book.activeContentRunId, book.blockCount],
      ['book', BookStatus.ready, 'run', 1],
    );
    expect([run.id, run.cleanText, run.state], ['run', 'Texto', 'active']);
    expect(
      [page.pageNumber, page.rawText, page.cleanText],
      [1, 'Raw', 'Texto'],
    );
    expect(
      [chapter.id, chapter.title, chapter.cleanText],
      ['chapter', 'Capítulo', 'Texto'],
    );
    expect(
      [
        block.id,
        block.originalText,
        block.normalizedText,
        block.characterCount,
      ],
      ['block', 'Texto', 'Texto', 5],
    );
    expect(await database.select(database.readerSettingsRows).get(), isEmpty);
    expect(await database.select(database.readerPositions).get(), isEmpty);
  });
}

Future<void> _insertBook(AppDatabase database) => database
    .into(database.books)
    .insert(
      BooksCompanion.insert(
        id: 'book',
        title: 'Book',
        originalFileName: 'book.pdf',
        storedFilePath: '/book.pdf',
        fileHash: 'hash',
        status: BookStatus.ready,
        processingProgress: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
