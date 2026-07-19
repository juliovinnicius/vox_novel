import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

void main() {
  final ana = NarrationVoice(name: 'Ana', locale: 'pt-BR');

  test(
    'load resolves defaults and restores first block without speech',
    () async {
      final repository = _FakeRepository();
      final engine = _FakeEngine(voices: [ana]);
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);

      await cubit.load(_content());

      expect(
        [
          cubit.state.status,
          cubit.state.voices,
          cubit.state.settings,
          cubit.state.bookId,
          cubit.state.activeRunId,
          cubit.state.chapterId,
          cubit.state.blockId,
          cubit.state.canPrevious,
          cubit.state.canNext,
        ],
        [
          NarrationStatus.ready,
          [ana],
          NarrationSettings(voice: ana, rate: 1),
          'book',
          'run',
          'chapter-1',
          'block-1',
          false,
          true,
        ],
      );
      expect(engine.spoken, isEmpty);
      expect(repository.globalSaves, [NarrationSettings(voice: ana, rate: 1)]);
    },
  );

  test(
    'load exposes exact unavailable and initialization error states',
    () async {
      final noVoices = _cubit(_FakeRepository(), _FakeEngine());
      addTearDown(noVoices.close);
      await noVoices.load(_content());
      expect(
        [noVoices.state.status, noVoices.state.message],
        [NarrationStatus.unavailable, NarrationCubit.unavailableMessage],
      );

      final failedEngine = _FakeEngine(initializeError: StateError('init'));
      final failed = _cubit(_FakeRepository(), failedEngine);
      addTearDown(failed.close);
      await failed.load(_content());
      expect(
        [failed.state.status, failed.state.message],
        [NarrationStatus.error, NarrationCubit.initializationMessage],
      );
      failedEngine.initializeError = null;
      failedEngine.voices = [ana];
      await failed.retryInitialization();
      expect(failed.state.status, NarrationStatus.ready);
    },
  );

  test('empty queue is unavailable and never speaks', () async {
    final engine = _FakeEngine(voices: [ana]);
    final cubit = _cubit(_FakeRepository(), engine);
    addTearDown(cubit.close);

    await cubit.load(_content(empty: true));

    expect(cubit.state.status, NarrationStatus.unavailable);
    expect(engine.spoken, isEmpty);
  });

  test(
    'restores valid completion and repairs stale progress durably',
    () async {
      final completedRepository = _FakeRepository(
        progress: _progress(blockId: 'block-2', completed: true),
      );
      final completed = _cubit(completedRepository, _FakeEngine(voices: [ana]));
      addTearDown(completed.close);
      await completed.load(_content());
      expect(
        [completed.state.status, completed.state.blockId],
        [NarrationStatus.completed, 'block-2'],
      );
      expect(completedRepository.progressSaves, isEmpty);

      final staleRepository = _FakeRepository(
        progress: _progress(blockId: 'foreign', activeRunId: 'old-run'),
      );
      final stale = _cubit(staleRepository, _FakeEngine(voices: [ana]));
      addTearDown(stale.close);
      await stale.load(_content());
      expect(
        [stale.state.status, stale.state.blockId],
        [NarrationStatus.ready, 'block-1'],
      );
      expect(
        [
          staleRepository.progressSaves.single.activeRunId,
          staleRepository.progressSaves.single.blockId,
          staleRepository.progressSaves.single.completed,
        ],
        ['run', 'block-1', false],
      );
    },
  );

  test(
    'override settings persist only for book and removal restores global',
    () async {
      final global = NarrationSettings(voice: ana, rate: 0.8);
      final zeca = NarrationVoice(name: 'Zeca', locale: 'pt-BR');
      final repository = _FakeRepository(global: global);
      final cubit = _cubit(repository, _FakeEngine(voices: [ana, zeca]));
      addTearDown(cubit.close);
      await cubit.load(_content());

      await cubit.enableBookOverride();
      await cubit.selectVoice(zeca);
      await cubit.setRate(1.4);
      expect(
        [
          cubit.state.usesBookOverride,
          repository.overrideSaves.last.settings.voice,
          repository.overrideSaves.last.settings.rate,
          repository.globalSaves,
        ],
        [true, zeca, 1.4, isEmpty],
      );

      repository.global = global;
      await cubit.removeBookOverride();
      expect(
        [cubit.state.usesBookOverride, cubit.state.settings],
        [false, global],
      );
      expect(repository.deletedOverrides, ['book']);
    },
  );

  test(
    'preview speaks fixed phrase and preserves state and progress',
    () async {
      final repository = _FakeRepository();
      final engine = _FakeEngine(voices: [ana]);
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);
      await cubit.load(_content());
      final before = cubit.state;

      await cubit.previewVoice(ana);

      expect(engine.spoken, [NarrationCubit.previewPhrase]);
      expect(engine.configurations, ['Ana:pt-BR:1.0']);
      expect(repository.progressSaves, isEmpty);
      expect(
        [cubit.state.status, cubit.state.chapterId, cubit.state.blockId],
        [before.status, before.chapterId, before.blockId],
      );
    },
  );

  test('settings failure keeps selection and shows exact message', () async {
    final repository = _FakeRepository(
      global: NarrationSettings(voice: ana, rate: 1),
    );
    final zeca = NarrationVoice(name: 'Zeca', locale: 'pt-BR');
    final cubit = _cubit(repository, _FakeEngine(voices: [ana, zeca]));
    addTearDown(cubit.close);
    await cubit.load(_content());
    repository.failGlobalSave = true;

    await cubit.selectVoice(zeca);

    expect(
      [cubit.state.settings?.voice, cubit.state.message],
      [zeca, NarrationCubit.settingsMessage],
    );
  });

  test('late preview completion cannot overwrite newer load', () async {
    final completion = Completer<void>();
    final engine = _FakeEngine(voices: [ana], speakFuture: completion.future);
    final cubit = _cubit(_FakeRepository(), engine);
    addTearDown(cubit.close);
    await cubit.load(_content(bookId: 'old'));

    final preview = cubit.previewVoice(ana);
    await Future<void>.delayed(Duration.zero);
    await cubit.load(_content(bookId: 'new'));
    completion.complete();
    await preview;

    expect(
      [cubit.state.status, cubit.state.bookId],
      [NarrationStatus.ready, 'new'],
    );
  });

  test('late load cannot overwrite a newer content request', () async {
    final pending = Completer<List<NarrationVoice>>();
    final engine = _FakeEngine(initializeFuture: pending.future);
    final cubit = _cubit(_FakeRepository(), engine);
    addTearDown(cubit.close);

    final first = cubit.load(_content(bookId: 'old'));
    engine.initializeFuture = Future.value([ana]);
    final newest = cubit.load(_content(bookId: 'new'));
    await newest;
    pending.complete([ana]);
    await first;

    expect(
      [cubit.state.status, cubit.state.bookId],
      [NarrationStatus.ready, 'new'],
    );
  });
}

NarrationCubit _cubit(_FakeRepository repository, _FakeEngine engine) =>
    NarrationCubit(
      repository: repository,
      engine: engine,
      clock: () => DateTime.utc(2026),
    );

final class _FakeEngine implements NarrationEngine {
  _FakeEngine({
    this.voices = const [],
    this.initializeError,
    this.initializeFuture,
    this.speakFuture,
  });

  List<NarrationVoice> voices;
  Object? initializeError;
  Future<List<NarrationVoice>>? initializeFuture;
  Future<void>? speakFuture;
  final spoken = <String>[];
  final configurations = <String>[];

  @override
  Future<List<NarrationVoice>> initialize() async {
    final future = initializeFuture;
    initializeFuture = null;
    if (future != null) return future;
    if (initializeError != null) throw initializeError!;
    return voices;
  }

  @override
  Future<void> configure(NarrationVoice voice, double rate) async =>
      configurations.add('${voice.name}:${voice.locale}:$rate');

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    await speakFuture;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> close() async {}
}

final class _FakeRepository implements NarrationRepository {
  _FakeRepository({NarrationSettings? global, this.bookOverride, this.progress})
    : global = global ?? NarrationSettings.defaults();

  NarrationSettings global;
  BookNarrationOverride? bookOverride;
  NarrationProgress? progress;
  final globalSaves = <NarrationSettings>[];
  final overrideSaves = <BookNarrationOverride>[];
  final progressSaves = <NarrationProgress>[];
  final deletedOverrides = <String>[];
  var failGlobalSave = false;

  @override
  Future<NarrationSettings> loadGlobalSettings() async => global;

  @override
  Future<void> saveGlobalSettings(NarrationSettings settings) async {
    if (failGlobalSave) throw StateError('save failed');
    global = settings;
    globalSaves.add(settings);
  }

  @override
  Future<BookNarrationOverride?> loadBookOverride(String bookId) async =>
      bookOverride;

  @override
  Future<void> saveBookOverride(BookNarrationOverride value) async {
    bookOverride = value;
    overrideSaves.add(value);
  }

  @override
  Future<void> deleteBookOverride(String bookId) async {
    bookOverride = null;
    deletedOverrides.add(bookId);
  }

  @override
  Future<NarrationProgress?> loadProgress(String bookId) async => progress;

  @override
  Future<void> saveProgress(NarrationProgress value) async {
    progress = value;
    progressSaves.add(value);
  }
}

NarrationProgress _progress({
  required String blockId,
  String activeRunId = 'run',
  bool completed = false,
}) => NarrationProgress(
  bookId: 'book',
  activeRunId: activeRunId,
  chapterId: 'chapter-1',
  blockId: blockId,
  completed: completed,
  settings: NarrationSettings(
    voice: NarrationVoice(name: 'Ana', locale: 'pt-BR'),
    rate: 1,
  ),
  updatedAt: DateTime.utc(2026),
);

ReaderBookContent _content({String bookId = 'book', bool empty = false}) =>
    ReaderBookContent(
      book: Book(
        id: bookId,
        title: 'Book',
        author: null,
        coverPath: null,
        originalFileName: 'book.pdf',
        storedFilePath: '/book.pdf',
        fileHash: 'hash-$bookId',
        status: BookStatus.ready,
        processingProgress: 1,
        pageCount: 1,
        chapterCount: 1,
        blockCount: empty ? 0 : 2,
        processingStage: ProcessingStage.completed,
        activeContentRunId: 'run',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      chapters: [
        ReaderChapter(
          chapter: ChapterDraft(
            id: 'chapter-1',
            title: 'Capítulo',
            sortOrder: 0,
            startPage: 1,
            endPage: 1,
            cleanText: empty ? '' : 'UmDois',
          ),
          blocks: empty
              ? []
              : [_block('block-1', 0, 'Um'), _block('block-2', 1, 'Dois')],
        ),
      ],
    );

NarrationBlockDraft _block(String id, int order, String text) =>
    NarrationBlockDraft(
      id: id,
      chapterId: 'chapter-1',
      sortOrder: order,
      originalText: text,
      normalizedText: text,
      characterCount: text.runes.length,
      startPage: 1,
      endPage: 1,
    );
