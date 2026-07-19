import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates the production database boundary', () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => '/tmp');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final database = AppDatabase.defaults();

    expect(database.schemaVersion, 5);

    await database.close();
  });

  test('executes a query with an in-memory database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final result = await database.customSelect('SELECT 1 AS value').getSingle();

    expect(result.read<int>('value'), 1);
  });

  test('rejects queries after the database is closed', () async {
    final executor = NativeDatabase.memory();
    final database = AppDatabase(executor);

    await database.close();

    expect(
      executor.runSelect('SELECT 1', const []),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'upgrades version 1 to 2 without losing existing schema state',
    () async {
      final executor = NativeDatabase.memory(
        setup: (database) {
          database.execute('CREATE TABLE legacy_marker (value TEXT NOT NULL)');
          database.execute(
            "INSERT INTO legacy_marker (value) VALUES ('preserved')",
          );
          database.userVersion = 1;
        },
      );
      final database = AppDatabase(executor);
      addTearDown(database.close);

      await database.select(database.books).get();
      final marker = await database
          .customSelect('SELECT value FROM legacy_marker')
          .getSingle();

      expect(marker.read<String>('value'), 'preserved');
      expect(database.schemaVersion, 5);
    },
  );

  test('upgrades version 2 books with safe processing defaults', () async {
    final createdAt = DateTime.utc(2026).millisecondsSinceEpoch;
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE books (
            id TEXT NOT NULL PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT NULL,
            cover_path TEXT NULL,
            original_file_name TEXT NOT NULL,
            stored_file_path TEXT NOT NULL,
            file_hash TEXT NOT NULL,
            status TEXT NOT NULL,
            processing_progress REAL NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.execute(
          'INSERT INTO books VALUES '
          "('book-1', 'Livro', NULL, NULL, 'livro.pdf', '/livro.pdf', "
          "'hash', 'importing', 0.0, $createdAt, $createdAt)",
        );
        database.userVersion = 2;
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final book = await database.select(database.books).getSingle();

    expect(
      [
        book.id,
        book.pageCount,
        book.chapterCount,
        book.blockCount,
        book.processingStage,
        book.activeContentRunId,
      ],
      ['book-1', 0, 0, 0, null, null],
    );
    expect(database.schemaVersion, 5);
  });

  test('fresh v5 schema enforces narration records and cascades', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026).millisecondsSinceEpoch;
    await database.customStatement(
      "INSERT INTO books (id,title,original_file_name,stored_file_path,file_hash,"
      "status,processing_progress,created_at,updated_at) VALUES "
      "('book','Livro','book.pdf','/book.pdf','hash','ready',1,$now,$now)",
    );

    await database.customStatement(
      "INSERT INTO narration_settings VALUES "
      "(1,'Ana','pt-BR',1.0,$now)",
    );
    await database.customStatement(
      "INSERT INTO book_narration_settings VALUES "
      "('book','Zeca','pt-BR',1.2,$now)",
    );
    await database.customStatement(
      "INSERT INTO reading_progress VALUES "
      "('book','run','chapter','block',0,'Zeca','pt-BR',1.2,$now)",
    );

    final settings = await database
        .customSelect('SELECT * FROM narration_settings')
        .getSingle();
    final override = await database
        .customSelect('SELECT * FROM book_narration_settings')
        .getSingle();
    final progress = await database
        .customSelect('SELECT * FROM reading_progress')
        .getSingle();
    expect(
      [
        settings.read<int>('id'),
        settings.read<String>('voice_name'),
        settings.read<String>('voice_locale'),
        settings.read<double>('speech_rate'),
        override.read<String>('book_id'),
        progress.read<String>('active_run_id'),
        progress.read<int>('completed'),
      ],
      [1, 'Ana', 'pt-BR', 1.0, 'book', 'run', 0],
    );

    for (final statement in [
      "INSERT INTO narration_settings VALUES (2,NULL,NULL,1.0,$now)",
      "UPDATE narration_settings SET voice_name='Ana', voice_locale=NULL",
      "UPDATE narration_settings SET speech_rate=0.55",
      "UPDATE reading_progress SET completed=2",
    ]) {
      await expectLater(database.customStatement(statement), throwsA(anything));
    }

    await database.customStatement("DELETE FROM books WHERE id='book'");

    expect(
      await database
          .customSelect('SELECT * FROM book_narration_settings')
          .get(),
      isEmpty,
    );
    expect(
      await database.customSelect('SELECT * FROM reading_progress').get(),
      isEmpty,
    );
    expect(
      await database.customSelect('SELECT * FROM narration_settings').get(),
      hasLength(1),
    );
  });

  test('version 4 migration preserves reader and processed content', () async {
    final directory = await Directory.systemTemp.createTemp('narration_v4_');
    final file = File('${directory.path}/database.sqlite');
    addTearDown(() => directory.delete(recursive: true));
    final now = DateTime.utc(2026).millisecondsSinceEpoch;
    var database = AppDatabase(NativeDatabase(file));
    await database.customStatement(
      "INSERT INTO books (id,title,original_file_name,stored_file_path,file_hash,"
      "status,processing_progress,page_count,chapter_count,block_count,created_at,updated_at) "
      "VALUES ('book','Livro','book.pdf','/book.pdf','hash','ready',1,1,1,1,$now,$now)",
    );
    await database.customStatement(
      "INSERT INTO processing_runs VALUES ('run','book','Texto','active',$now,$now)",
    );
    await database.customStatement(
      "UPDATE books SET active_content_run_id='run' WHERE id='book'",
    );
    await database.customStatement(
      "INSERT INTO chapters VALUES ('chapter','run','book','Capítulo',0,1,1,'Texto',$now,$now)",
    );
    await database.customStatement(
      "INSERT INTO narration_blocks VALUES "
      "('block','run','chapter',0,'Texto','Texto',5,1,1)",
    );
    await database.customStatement(
      "INSERT INTO reader_settings_rows VALUES (1,'sepia','serif',24,1.8,$now)",
    );
    await database.customStatement(
      "INSERT INTO reader_positions VALUES "
      "('book','text','chapter','block',1,$now)",
    );
    await database.close();

    database = AppDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('DROP TABLE reading_progress');
          raw.execute('DROP TABLE book_narration_settings');
          raw.execute('DROP TABLE narration_settings');
          raw.userVersion = 4;
        },
      ),
    );
    addTearDown(database.close);

    final preserved = await database
        .customSelect(
          'SELECT books.id AS book_id, books.active_content_run_id, '
          'narration_blocks.normalized_text, reader_settings_rows.theme, '
          'reader_positions.block_id FROM books '
          'JOIN narration_blocks ON narration_blocks.run_id=books.active_content_run_id '
          'JOIN reader_settings_rows ON reader_settings_rows.id=1 '
          'JOIN reader_positions ON reader_positions.book_id=books.id',
        )
        .getSingle();
    expect(
      [
        preserved.read<String>('book_id'),
        preserved.read<String>('active_content_run_id'),
        preserved.read<String>('normalized_text'),
        preserved.read<String>('theme'),
        preserved.read<String>('block_id'),
      ],
      ['book', 'run', 'Texto', 'sepia', 'block'],
    );
    expect(
      await database.customSelect('SELECT * FROM narration_settings').get(),
      isEmpty,
    );
    expect(
      await database
          .customSelect('SELECT * FROM book_narration_settings')
          .get(),
      isEmpty,
    );
    expect(
      await database.customSelect('SELECT * FROM reading_progress').get(),
      isEmpty,
    );
  });
}
