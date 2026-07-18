import 'package:drift/drift.dart' show Value;
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart' hide ReaderPosition;
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/visual_reader/data/repositories/drift_visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

void main() {
  late AppDatabase database;
  late DriftVisualReaderRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftVisualReaderRepository(database);
    await _seed(database);
  });
  tearDown(() => database.close());

  test(
    'loads only exact ready active content in numeric source order',
    () async {
      final content = await repository.loadContent('book');

      expect(content?.book.id, 'book');
      expect(content?.chapters.map((value) => value.chapter.id), ['z', 'a']);
      expect(content?.chapters.first.blocks.map((value) => value.id), [
        '9',
        '1',
      ]);
      expect(
        content?.chapters.first.blocks.map((value) => value.originalText),
        ['Primeiro', 'Segundo'],
      );
    },
  );

  test('missing not-ready and stale active content return null', () async {
    expect(await repository.loadContent('missing'), isNull);
    await (database.update(database.books)
          ..where((row) => row.id.equals('book')))
        .write(const BooksCompanion(status: Value(BookStatus.processing)));
    expect(await repository.loadContent('book'), isNull);
    await (database.update(
      database.books,
    )..where((row) => row.id.equals('book'))).write(
      const BooksCompanion(
        status: Value(BookStatus.ready),
        chapterCount: Value(3),
      ),
    );
    expect(await repository.loadContent('book'), isNull);
  });

  test('settings round-trip complete fields and default when absent', () async {
    expect(await repository.loadSettings(), ReaderSettings.defaults());
    final settings = ReaderSettings(
      theme: ReaderTheme.dark,
      fontFamily: ReaderFontFamily.serif,
      fontSize: 32,
      lineHeight: 2,
    );
    await repository.saveSettings(settings);

    expect(await repository.loadSettings(), settings);
    expect(
      await database.select(database.readerSettingsRows).get(),
      hasLength(1),
    );
  });

  test('positions round-trip and newest concurrent request wins', () async {
    final first = ReaderPosition(
      bookId: 'book',
      mode: ReaderMode.text,
      chapterId: 'z',
      blockId: '9',
      pdfPage: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final newest = ReaderPosition(
      bookId: 'book',
      mode: ReaderMode.pdf,
      chapterId: 'a',
      blockId: null,
      pdfPage: 2,
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    await Future.wait([
      repository.savePosition(first),
      repository.savePosition(newest),
    ]);

    final restored = await repository.loadPosition('book');
    expect(
      [
        restored?.bookId,
        restored?.mode,
        restored?.chapterId,
        restored?.blockId,
        restored?.pdfPage,
        restored?.updatedAt,
      ],
      ['book', ReaderMode.pdf, 'a', null, 2, DateTime.utc(2026, 1, 2)],
    );
    expect(await database.select(database.readerPositions).get(), hasLength(1));
  });

  test(
    'physical position writes start serially and persist the second',
    () async {
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final starts = <String?>[];
      repository = DriftVisualReaderRepository(
        database,
        beforePositionWrite: (position) async {
          starts.add(position.blockId);
          if (position.blockId == '9') {
            firstStarted.complete();
            await releaseFirst.future;
          }
        },
      );
      final first = ReaderPosition(
        bookId: 'book',
        mode: ReaderMode.text,
        chapterId: 'z',
        blockId: '9',
        pdfPage: 1,
        updatedAt: DateTime.utc(2026, 2, 1),
      );
      final second = ReaderPosition(
        bookId: 'book',
        mode: ReaderMode.pdf,
        chapterId: 'a',
        blockId: '1',
        pdfPage: 2,
        updatedAt: DateTime.utc(2026, 2, 2),
      );

      final firstWrite = repository.savePosition(first);
      await firstStarted.future;
      final secondWrite = repository.savePosition(second);
      await Future<void>.delayed(Duration.zero);
      final startsBeforeRelease = [...starts];

      releaseFirst.complete();
      await Future.wait([firstWrite, secondWrite]);
      expect(startsBeforeRelease, ['9']);
      expect(starts, ['9', '1']);
      final durable = await repository.loadPosition('book');
      expect(
        [
          durable?.bookId,
          durable?.mode,
          durable?.chapterId,
          durable?.blockId,
          durable?.pdfPage,
          durable?.updatedAt,
        ],
        ['book', ReaderMode.pdf, 'a', '1', 2, DateTime.utc(2026, 2, 2)],
      );
    },
  );

  test('query and save errors propagate without partial content', () async {
    await database.close();

    expect(repository.loadContent('book'), throwsA(isA<StateError>()));
    expect(
      repository.savePosition(
        ReaderPosition(
          bookId: 'book',
          mode: ReaderMode.text,
          chapterId: null,
          blockId: null,
          pdfPage: 1,
          updatedAt: DateTime.utc(2026),
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}

Future<void> _seed(AppDatabase database) async {
  final now = DateTime.utc(2026);
  await database
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
          pageCount: const Value(2),
          chapterCount: const Value(2),
          blockCount: const Value(2),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await database.customStatement(
    "INSERT INTO processing_runs VALUES ('run','book','Texto','active',${now.millisecondsSinceEpoch},${now.millisecondsSinceEpoch})",
  );
  await database.customStatement(
    "UPDATE books SET active_content_run_id='run' WHERE id='book'",
  );
  await database.customStatement(
    "INSERT INTO chapters VALUES ('z','run','book','Um',0,1,1,'Primeiro\\n\\nSegundo',1,1),"
    "('a','run','book','Dois',1,2,2,'',1,1)",
  );
  await database.customStatement(
    "INSERT INTO narration_blocks VALUES ('9','run','z',0,'Primeiro','Primeiro',8,1,1),"
    "('1','run','z',1,'Segundo','Segundo',7,1,1)",
  );
}
