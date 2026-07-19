import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/narration/data/repositories/drift_narration_repository.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase database;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('narration_integration_');
    file = File('${directory.path}/library.sqlite');
    database = AppDatabase(NativeDatabase(file));
    await _insertBook(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'file-backed restart restores exact settings and progress without play',
    () async {
      var repository = DriftNarrationRepository(database);
      final selected = NarrationSettings(
        voice: NarrationVoice(name: 'Bia', locale: 'pt-BR'),
        rate: 1.6,
      );
      await repository.saveGlobalSettings(
        NarrationSettings(
          voice: NarrationVoice(name: 'Ana', locale: 'pt-BR'),
          rate: 1.2,
        ),
      );
      await repository.saveBookOverride(
        BookNarrationOverride(
          bookId: 'book',
          settings: selected,
          updatedAt: DateTime.utc(2026, 7, 19),
        ),
      );
      await repository.saveProgress(
        NarrationProgress(
          bookId: 'book',
          activeRunId: 'run-1',
          chapterId: 'chapter-2',
          blockId: 'block-2',
          completed: false,
          settings: selected,
          updatedAt: DateTime.utc(2026, 7, 19),
        ),
      );
      await database.close();

      database = AppDatabase(NativeDatabase(file));
      repository = DriftNarrationRepository(database);
      final engine = _Engine();
      final cubit = _cubit(repository, engine);
      await cubit.load(_content());

      expect(cubit.state.status, NarrationStatus.ready);
      expect(
        [
          cubit.state.chapterId,
          cubit.state.blockId,
          cubit.state.settings?.voice?.name,
          cubit.state.settings?.voice?.locale,
          cubit.state.settings?.rate,
          cubit.state.usesBookOverride,
        ],
        ['chapter-2', 'block-2', 'Bia', 'pt-BR', 1.6, true],
      );
      expect(engine.spoken, isEmpty);
      await cubit.close();
    },
  );

  test(
    'automatic chapter advance and lifecycle pause persist file-backed state',
    () async {
      final repository = DriftNarrationRepository(database);
      final engine = _Engine();
      final cubit = _cubit(repository, engine);
      await cubit.load(_content());

      unawaited(cubit.play());
      await _until(() => engine.spoken.length == 1);
      expect(engine.spoken, ['Texto um']);
      engine.complete(0);
      await _until(() => engine.spoken.length == 2);

      expect(engine.spoken, ['Texto um', 'Texto dois']);
      expect(
        [cubit.state.status, cubit.state.chapterId, cubit.state.blockId],
        [NarrationStatus.playing, 'chapter-2', 'block-2'],
      );
      final advanced = await repository.loadProgress('book');
      expect(
        [
          advanced?.activeRunId,
          advanced?.chapterId,
          advanced?.blockId,
          advanced?.completed,
        ],
        ['run-1', 'chapter-2', 'block-2', false],
      );

      final pause = cubit.onAppLifecyclePause();
      expect(cubit.state.status, NarrationStatus.paused);
      await pause;
      expect(engine.stopCalls, 1);
      expect((await repository.loadProgress('book'))?.blockId, 'block-2');
      expect(cubit.state.status, NarrationStatus.paused);
      await cubit.close();
    },
  );

  test(
    'reprocessing repair, speech failure, and delete cascade stay durable',
    () async {
      final repository = DriftNarrationRepository(database);
      final settings = NarrationSettings(
        voice: NarrationVoice(name: 'Ana', locale: 'pt-BR'),
        rate: 1,
      );
      await repository.saveGlobalSettings(settings);
      await repository.saveProgress(
        NarrationProgress(
          bookId: 'book',
          activeRunId: 'old-run',
          chapterId: 'old-chapter',
          blockId: 'old-block',
          completed: false,
          settings: settings,
          updatedAt: DateTime.utc(2026),
        ),
      );
      final engine = _Engine()..failSpeak = true;
      final cubit = _cubit(repository, engine);
      await cubit.load(_content(runId: 'run-2'));

      expect(
        [cubit.state.chapterId, cubit.state.blockId, cubit.state.status],
        ['chapter-1', 'block-1', NarrationStatus.ready],
      );
      final repaired = await repository.loadProgress('book');
      expect(
        [repaired?.activeRunId, repaired?.blockId, repaired?.completed],
        ['run-2', 'block-1', false],
      );

      await cubit.play();
      expect(cubit.state.status, NarrationStatus.paused);
      expect(cubit.state.message, NarrationCubit.speechMessage);
      expect((await repository.loadProgress('book'))?.blockId, 'block-1');
      await repository.saveBookOverride(
        BookNarrationOverride(
          bookId: 'book',
          settings: settings,
          updatedAt: DateTime.utc(2026),
        ),
      );
      final globalBeforeDelete = await repository.loadGlobalSettings();
      await (database.delete(
        database.books,
      )..where((row) => row.id.equals('book'))).go();

      expect(await repository.loadProgress('book'), isNull);
      expect(await repository.loadBookOverride('book'), isNull);
      final retainedGlobal = await repository.loadGlobalSettings();
      expect(
        [
          retainedGlobal.voice?.name,
          retainedGlobal.voice?.locale,
          retainedGlobal.rate,
        ],
        [
          globalBeforeDelete.voice?.name,
          globalBeforeDelete.voice?.locale,
          globalBeforeDelete.rate,
        ],
      );
      await cubit.close();
    },
  );
}

NarrationCubit _cubit(DriftNarrationRepository repository, _Engine engine) =>
    NarrationCubit(
      repository: repository,
      engine: engine,
      clock: () => DateTime.utc(2026, 7, 19),
    );

ReaderBookContent _content({String runId = 'run-1'}) {
  ReaderChapter chapter(String id, String blockId, String title, int order) {
    final text = order == 0 ? 'Texto um' : 'Texto dois';
    return ReaderChapter(
      chapter: ChapterDraft(
        id: id,
        title: title,
        sortOrder: order,
        startPage: order + 1,
        endPage: order + 1,
        cleanText: text,
      ),
      blocks: [
        NarrationBlockDraft(
          id: blockId,
          chapterId: id,
          sortOrder: 0,
          originalText: text,
          normalizedText: text,
          characterCount: text.runes.length,
          startPage: order + 1,
          endPage: order + 1,
        ),
      ],
    );
  }

  return ReaderBookContent(
    book: domain.Book(
      id: 'book',
      title: 'Livro',
      originalFileName: 'livro.pdf',
      storedFilePath: '/livro.pdf',
      fileHash: 'hash',
      status: domain.BookStatus.ready,
      processingProgress: 1,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      pageCount: 2,
      chapterCount: 2,
      blockCount: 2,
      activeContentRunId: runId,
    ),
    chapters: [
      chapter('chapter-1', 'block-1', 'Capítulo 1', 0),
      chapter('chapter-2', 'block-2', 'Capítulo 2', 1),
    ],
  );
}

Future<void> _insertBook(AppDatabase database) => database
    .into(database.books)
    .insert(
      BooksCompanion.insert(
        id: 'book',
        title: 'Livro',
        originalFileName: 'livro.pdf',
        storedFilePath: '/livro.pdf',
        fileHash: 'hash',
        status: domain.BookStatus.ready,
        processingProgress: 1,
        pageCount: const Value(2),
        chapterCount: const Value(2),
        blockCount: const Value(2),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 50 && !condition(); attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

final class _Engine implements NarrationEngine {
  final voices = [
    NarrationVoice(name: 'Ana', locale: 'pt-BR'),
    NarrationVoice(name: 'Bia', locale: 'pt-BR'),
  ];
  final spoken = <String>[];
  final _completions = <Completer<void>>[];
  var stopCalls = 0;
  var failSpeak = false;

  void complete(int index) => _completions[index].complete();

  @override
  Future<List<NarrationVoice>> initialize() async => voices;
  @override
  Future<void> configure(NarrationVoice voice, double rate) async {}
  @override
  Future<void> speak(String text) {
    spoken.add(text);
    if (failSpeak) {
      return Future.error(StateError('speak failed'));
    }
    final completion = Completer<void>();
    _completions.add(completion);
    return completion.future;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> close() async {}
}
