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

    expect(database.schemaVersion, 4);

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
      expect(database.schemaVersion, 4);
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
    expect(database.schemaVersion, 4);
  });
}
