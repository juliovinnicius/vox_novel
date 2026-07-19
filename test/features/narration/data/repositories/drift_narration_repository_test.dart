import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/data/repositories/drift_narration_repository.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

void main() {
  late AppDatabase database;
  late DriftNarrationRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftNarrationRepository(database);
    await _insertBook(database);
  });
  tearDown(() => database.close());

  test('global settings default and complete records round-trip', () async {
    expect(await repository.loadGlobalSettings(), NarrationSettings.defaults());
    final selected = NarrationSettings(
      voice: NarrationVoice(name: 'Ana', locale: 'pt-BR'),
      rate: 1.4,
    );

    await repository.saveGlobalSettings(selected);
    expect(await repository.loadGlobalSettings(), selected);

    await repository.saveGlobalSettings(NarrationSettings.defaults());
    expect(await repository.loadGlobalSettings(), NarrationSettings.defaults());
    expect(
      await database.select(database.narrationSettingsRows).get(),
      hasLength(1),
    );
  });

  test(
    'book override round-trips complete fields and can be removed',
    () async {
      expect(await repository.loadBookOverride('book'), isNull);
      final override = BookNarrationOverride(
        bookId: 'book',
        settings: NarrationSettings(
          voice: NarrationVoice(name: 'Zeca', locale: 'pt-BR'),
          rate: 0.8,
        ),
        updatedAt: DateTime.utc(2026, 2, 3),
      );

      await repository.saveBookOverride(override);
      final restored = await repository.loadBookOverride('book');
      expect(
        [
          restored?.bookId,
          restored?.settings.voice?.name,
          restored?.settings.voice?.locale,
          restored?.settings.rate,
          restored?.updatedAt,
        ],
        ['book', 'Zeca', 'pt-BR', 0.8, DateTime.utc(2026, 2, 3)],
      );

      await repository.deleteBookOverride('book');
      expect(await repository.loadBookOverride('book'), isNull);
    },
  );

  test('progress round-trips every field as one complete record', () async {
    expect(await repository.loadProgress('book'), isNull);
    final progress = _progress(
      blockId: 'block-1',
      completed: true,
      rate: 1.7,
      updatedAt: DateTime.utc(2026, 3, 4),
    );

    await repository.saveProgress(progress);
    final restored = await repository.loadProgress('book');

    expect(
      [
        restored?.bookId,
        restored?.activeRunId,
        restored?.chapterId,
        restored?.blockId,
        restored?.completed,
        restored?.settings.voice?.name,
        restored?.settings.voice?.locale,
        restored?.settings.rate,
        restored?.updatedAt,
      ],
      [
        'book',
        'run',
        'chapter',
        'block-1',
        true,
        'Ana',
        'pt-BR',
        1.7,
        DateTime.utc(2026, 3, 4),
      ],
    );
  });

  test('progress writes start serially and newest request wins', () async {
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    final starts = <String>[];
    repository = DriftNarrationRepository(
      database,
      beforeProgressWrite: (progress) async {
        starts.add(progress.blockId);
        if (progress.blockId == 'first') {
          firstStarted.complete();
          await releaseFirst.future;
        }
      },
    );
    final first = repository.saveProgress(_progress(blockId: 'first'));
    await firstStarted.future;
    final newest = repository.saveProgress(_progress(blockId: 'newest'));
    await Future<void>.delayed(Duration.zero);

    expect(starts, ['first']);
    releaseFirst.complete();
    await Future.wait([first, newest]);

    expect(starts, ['first', 'newest']);
    expect((await repository.loadProgress('book'))?.blockId, 'newest');
  });

  test(
    'failed progress write propagates and does not poison later save',
    () async {
      var failFirst = true;
      repository = DriftNarrationRepository(
        database,
        beforeProgressWrite: (progress) async {
          if (failFirst) {
            failFirst = false;
            throw StateError('first write failed');
          }
        },
      );

      final failed = repository.saveProgress(_progress(blockId: 'failed'));
      final recovered = repository.saveProgress(
        _progress(blockId: 'recovered'),
      );

      await expectLater(failed, throwsA(isA<StateError>()));
      await recovered;
      expect((await repository.loadProgress('book'))?.blockId, 'recovered');
    },
  );

  test(
    'file-backed book deletion cascades override and progress only',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'narration_repository_',
      );
      final file = File('${directory.path}/database.sqlite');
      addTearDown(() => directory.delete(recursive: true));
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      repository = DriftNarrationRepository(database);
      await _insertBook(database);
      final global = NarrationSettings(
        voice: NarrationVoice(name: 'Global', locale: 'pt-BR'),
        rate: 1.1,
      );
      await repository.saveGlobalSettings(global);
      await repository.saveBookOverride(
        BookNarrationOverride(
          bookId: 'book',
          settings: NarrationSettings(
            voice: NarrationVoice(name: 'Livro', locale: 'pt-BR'),
            rate: 1.2,
          ),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await repository.saveProgress(_progress(blockId: 'block'));

      await (database.delete(
        database.books,
      )..where((row) => row.id.equals('book'))).go();

      expect(await repository.loadBookOverride('book'), isNull);
      expect(await repository.loadProgress('book'), isNull);
      expect(await repository.loadGlobalSettings(), global);
    },
  );
}

NarrationProgress _progress({
  required String blockId,
  bool completed = false,
  double rate = 1,
  DateTime? updatedAt,
}) => NarrationProgress(
  bookId: 'book',
  activeRunId: 'run',
  chapterId: 'chapter',
  blockId: blockId,
  completed: completed,
  settings: NarrationSettings(
    voice: NarrationVoice(name: 'Ana', locale: 'pt-BR'),
    rate: rate,
  ),
  updatedAt: updatedAt ?? DateTime.utc(2026),
);

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
