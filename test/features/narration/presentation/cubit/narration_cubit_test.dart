import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_session.dart';
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

  test('selected play pauses and stale completion cannot advance', () async {
    final completion = Completer<void>();
    final repository = _FakeRepository();
    final engine = _FakeEngine(voices: [ana], speakFuture: completion.future);
    final cubit = _cubit(repository, engine);
    addTearDown(cubit.close);
    await cubit.load(_content());
    cubit.setPendingStart('chapter-1', 'block-2');

    final playing = cubit.play();
    await Future<void>.delayed(Duration.zero);
    expect(
      [cubit.state.status, cubit.state.blockId, engine.spoken],
      [
        NarrationStatus.playing,
        'block-2',
        ['Dois'],
      ],
    );
    await cubit.pause();
    completion.complete();
    await playing;

    expect(
      [
        cubit.state.status,
        cubit.state.blockId,
        engine.stopCalls,
        repository.progressSaves.last.completed,
      ],
      [NarrationStatus.paused, 'block-2', 1, false],
    );
    await cubit.play();
    expect(engine.spoken, ['Dois', 'Dois']);
  });

  test(
    'automatic advance persists before speak and completes without wrap',
    () async {
      final events = <String>[];
      final repository = _FakeRepository(events: events);
      final engine = _FakeEngine(voices: [ana], events: events);
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);
      await cubit.load(_content());
      events.clear();

      await cubit.play();

      expect(events, [
        'speak:Um',
        'save:block-1:false',
        'save:block-2:false',
        'speak:Dois',
        'save:block-2:true',
      ]);
      expect(
        [cubit.state.status, cubit.state.blockId, engine.spoken],
        [
          NarrationStatus.completed,
          'block-2',
          ['Um', 'Dois'],
        ],
      );
      await cubit.next();
      expect(engine.spoken, ['Um', 'Dois']);
    },
  );

  test(
    'manual navigation persists target and speaks only while playing',
    () async {
      final repository = _FakeRepository();
      final engine = _FakeEngine(voices: [ana]);
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);
      await cubit.load(_content());

      await cubit.next();
      expect(
        [
          cubit.state.blockId,
          cubit.state.status,
          repository.progressSaves.last.blockId,
          engine.spoken,
        ],
        ['block-2', NarrationStatus.ready, 'block-2', isEmpty],
      );
      await cubit.previous();
      expect(cubit.state.blockId, 'block-1');
      await cubit.previous();
      expect(repository.progressSaves, hasLength(2));
    },
  );

  test('manual next invalidates speech and narrates target once', () async {
    final firstSpeech = Completer<void>();
    final repository = _FakeRepository();
    final engine = _FakeEngine(voices: [ana], speakFuture: firstSpeech.future);
    final cubit = _cubit(repository, engine);
    addTearDown(cubit.close);
    await cubit.load(_content());
    final firstPlay = cubit.play();
    await Future<void>.delayed(Duration.zero);
    engine.speakFuture = null;

    await cubit.next();
    firstSpeech.complete();
    await firstPlay;

    expect(
      [
        cubit.state.status,
        cubit.state.blockId,
        engine.stopCalls,
        engine.spoken,
        repository.progressSaves.last.blockId,
      ],
      [
        NarrationStatus.completed,
        'block-2',
        1,
        ['Um', 'Dois'],
        'block-2',
      ],
    );
  });

  test(
    'manual transition is observable under 500ms while persistence is pending',
    () async {
      final save = Completer<void>();
      addTearDown(() {
        if (!save.isCompleted) save.complete();
      });
      final repository = _FakeRepository(progressSaveFuture: save.future);
      final engine = _FakeEngine(voices: [ana]);
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);
      await cubit.load(_content());
      final stopwatch = Stopwatch()..start();

      final transition = cubit.next();
      await Future<void>.delayed(Duration.zero);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
      expect(
        [cubit.state.status, cubit.state.blockId],
        [NarrationStatus.ready, 'block-2'],
      );
      var framePumped = false;
      await Future<void>(() => framePumped = true);
      expect(framePumped, isTrue);
      save.complete();
      await transition;
      expect(repository.progressSaves.single.blockId, 'block-2');
    },
  );

  test(
    'reload replaces an open active run and never resumes old speech',
    () async {
      final oldSpeech = Completer<void>();
      final repository = _FakeRepository(
        progress: _progress(blockId: 'block-1'),
      );
      final engine = _FakeEngine(voices: [ana], speakFuture: oldSpeech.future);
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);
      await cubit.load(_content());
      final oldPlay = cubit.play();
      await Future<void>.delayed(Duration.zero);
      expect(engine.spoken, ['Um']);
      engine.speakFuture = null;

      await cubit.reloadContent(
        _content(
          activeRunId: 'run-2',
          blockPrefix: 'new-block',
          firstText: 'Novo um',
          secondText: 'Novo dois',
        ),
      );
      expect(engine.stopCalls, 1);
      expect(
        [cubit.state.status, cubit.state.activeRunId, cubit.state.blockId],
        [NarrationStatus.ready, 'run-2', 'new-block-1'],
      );
      expect(
        [
          repository.progressSaves.last.activeRunId,
          repository.progressSaves.last.blockId,
          repository.progressSaves.last.completed,
        ],
        ['run-2', 'new-block-1', false],
      );

      oldSpeech.complete();
      await oldPlay;
      expect(engine.spoken, ['Um']);
      await cubit.play();
      expect(engine.spoken, ['Um', 'Novo um', 'Novo dois']);
      expect(engine.spoken.skip(1), isNot(contains('Um')));
    },
  );

  test('closing the cubit detaches without stopping playback', () async {
    final repository = _FakeRepository();
    final engine = _FakeEngine(voices: [ana]);
    final session = NarrationSession(
      repository: repository,
      engine: engine,
      clock: () => DateTime.utc(2026),
    );
    final cubit = NarrationCubit(session: session);
    await session.load(_content());

    await cubit.close();

    // Playback is owned by the application-scoped session (AD-013): leaving
    // the reader must not silence narration that is meant to keep going in
    // the background. Stopping and persisting on close is the session's
    // contract now, asserted in narration_session_test.dart.
    expect(engine.stopCalls, 0);
    expect(repository.progressSaves, isEmpty);
    expect(session.state.current?.blockId, 'block-1');
  });

  test('a cubit attaching mid-playback adopts the live session state', () async {
    final repository = _FakeRepository();
    final engine = _FakeEngine(voices: [ana]);
    final session = NarrationSession(
      repository: repository,
      engine: engine,
      clock: () => DateTime.utc(2026),
    );
    await session.load(_content());

    final cubit = NarrationCubit(session: session);
    addTearDown(cubit.close);

    expect(cubit.state.status, session.state.status);
    expect(cubit.state.blockId, 'block-1');
  });

  test('lifecycle pauses synchronously and awaits stop and progress', () async {
    final stop = Completer<void>();
    final speech = Completer<void>();
    final repository = _FakeRepository();
    final engine = _FakeEngine(
      voices: [ana],
      speakFuture: speech.future,
      stopFuture: stop.future,
    );
    final cubit = _cubit(repository, engine);
    addTearDown(cubit.close);
    await cubit.load(_content());
    final playing = cubit.play();
    await Future<void>.delayed(Duration.zero);

    final lifecycle = cubit.pause();
    expect(cubit.state.status, NarrationStatus.paused);
    expect(repository.progressSaves, isEmpty);
    stop.complete();
    await lifecycle;
    expect(repository.progressSaves.single.blockId, 'block-1');
    speech.complete();
    await playing;
    expect(cubit.state.status, NarrationStatus.paused);
  });

  test(
    'speak and progress failures retain block with exact messages',
    () async {
      final repository = _FakeRepository();
      final engine = _FakeEngine(
        voices: [ana],
        speakError: StateError('speak'),
      );
      final cubit = _cubit(repository, engine);
      addTearDown(cubit.close);
      await cubit.load(_content());

      await cubit.play();
      expect(
        [cubit.state.status, cubit.state.blockId, cubit.state.message],
        [NarrationStatus.paused, 'block-1', NarrationCubit.speechMessage],
      );

      engine.speakError = null;
      repository.failProgressSave = true;
      await cubit.play();
      expect(
        [cubit.state.status, cubit.state.blockId, cubit.state.message],
        [NarrationStatus.paused, 'block-1', NarrationCubit.progressMessage],
      );
    },
  );

  test('missing selected voice repairs once and retries same block', () async {
    final zeca = NarrationVoice(name: 'Zeca', locale: 'pt-BR');
    final repository = _FakeRepository(
      global: NarrationSettings(voice: ana, rate: 1),
    );
    final engine = _FakeEngine(voices: [ana, zeca], configureFailures: 1);
    final cubit = _cubit(repository, engine);
    addTearDown(cubit.close);
    await cubit.load(_content());

    await cubit.play();

    expect(engine.configurations.take(2), ['Ana:pt-BR:1.0', 'Zeca:pt-BR:1.0']);
    expect(engine.spoken, ['Um', 'Dois']);
    expect(cubit.state.settings?.voice, zeca);
    expect(repository.globalSaves.last.voice, zeca);
  });

  test('the download boundary reloads content exactly once and awaits the '
      'next chapter', () async {
    final repository = _FakeRepository();
    final engine = _FakeEngine(voices: [ana]);
    final loader = _FakeContentLoader([_webContent(chapters: 1)]);
    final cubit = _cubit(repository, engine, loadContent: loader.call);
    addTearDown(cubit.close);
    await cubit.load(_webContent(chapters: 1));

    await cubit.play();

    expect(loader.calls, 1);
    expect(cubit.state.status, NarrationStatus.awaitingDownload);
    expect(cubit.state.blockId, 'web-block-1');
    expect(engine.spoken, ['Texto 1']);
  });

  test('a reload that finds a new chapter narrates it without user action',
      () async {
    final repository = _FakeRepository();
    final engine = _FakeEngine(voices: [ana]);
    final loader = _FakeContentLoader([
      _webContent(chapters: 2),
      _webContent(chapters: 2, downloading: false),
    ]);
    final cubit = _cubit(repository, engine, loadContent: loader.call);
    addTearDown(cubit.close);
    await cubit.load(_webContent(chapters: 1));

    await cubit.play();

    expect(engine.spoken, ['Texto 1', 'Texto 2']);
    expect(cubit.state.blockId, 'web-block-2');
    expect(cubit.state.status, NarrationStatus.completed);
  });

  test('the download boundary never stores the book as completed', () async {
    final repository = _FakeRepository();
    final loader = _FakeContentLoader([_webContent(chapters: 1)]);
    final cubit = _cubit(
      repository,
      _FakeEngine(voices: [ana]),
      loadContent: loader.call,
    );
    addTearDown(cubit.close);
    await cubit.load(_webContent(chapters: 1));

    await cubit.play();

    expect(repository.progressSaves.last.blockId, 'web-block-1');
    expect(repository.progressSaves.last.completed, isFalse);
  });

  test('a fully downloaded web book still ends at its last block', () async {
    final repository = _FakeRepository();
    final loader = _FakeContentLoader([_webContent(chapters: 2)]);
    final cubit = _cubit(
      repository,
      _FakeEngine(voices: [ana]),
      loadContent: loader.call,
    );
    addTearDown(cubit.close);
    await cubit.load(_webContent(chapters: 2, downloading: false));

    await cubit.play();

    expect(loader.calls, 0);
    expect(cubit.state.status, NarrationStatus.completed);
    expect(repository.progressSaves.last.completed, isTrue);
  });

  test('a pdf book never reloads at its last block', () async {
    final repository = _FakeRepository();
    final loader = _FakeContentLoader([_content()]);
    final cubit = _cubit(
      repository,
      _FakeEngine(voices: [ana]),
      loadContent: loader.call,
    );
    addTearDown(cubit.close);
    await cubit.load(_content());

    await cubit.play();

    expect(loader.calls, 0);
    expect(cubit.state.status, NarrationStatus.completed);
  });

  test('a downloading book with no reloader awaits the next chapter', () async {
    final repository = _FakeRepository();
    final cubit = _cubit(repository, _FakeEngine(voices: [ana]));
    addTearDown(cubit.close);
    await cubit.load(_webContent(chapters: 1));

    await cubit.play();

    expect(cubit.state.status, NarrationStatus.awaitingDownload);
    expect(repository.progressSaves.last.completed, isFalse);
  });

  test('a failed reload at the boundary still reports awaiting download',
      () async {
    final repository = _FakeRepository();
    final cubit = _cubit(
      repository,
      _FakeEngine(voices: [ana]),
      loadContent: (_) async => throw StateError('offline'),
    );
    addTearDown(cubit.close);
    await cubit.load(_webContent(chapters: 1));

    await cubit.play();

    expect(cubit.state.status, NarrationStatus.awaitingDownload);
  });
}

/// The Cubit is a client of the session now, so the fakes are wired into a
/// real session and the assertions below stay exactly as they were.
NarrationCubit _cubit(
  _FakeRepository repository,
  _FakeEngine engine, {
  NarrationContentLoader? loadContent,
}) => NarrationCubit(
  session: NarrationSession(
    repository: repository,
    engine: engine,
    clock: () => DateTime.utc(2026),
    loadContent: loadContent,
  ),
);

/// A web book whose queue holds [chapters] chapters of one block each, still
/// downloading unless [downloading] is false.
ReaderBookContent _webContent({
  required int chapters,
  bool downloading = true,
}) => ReaderBookContent(
  book: Book(
    id: 'book',
    title: 'Obra',
    sourceType: BookSourceType.web,
    sourceRef: 'https://exemplo.com/series/obra/',
    status: downloading ? BookStatus.processing : BookStatus.ready,
    processingProgress: downloading ? 0.5 : 1,
    pageCount: 4,
    chapterCount: chapters,
    blockCount: chapters,
    activeContentRunId: 'run',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  chapters: [
    for (var order = 0; order < chapters; order++)
      ReaderChapter(
        chapter: ChapterDraft(
          id: 'chapter-${order + 1}',
          title: 'Capítulo ${order + 1}',
          sortOrder: order,
          startPage: order + 1,
          endPage: order + 1,
          cleanText: 'Texto ${order + 1}',
        ),
        blocks: [
          NarrationBlockDraft(
            id: 'web-block-${order + 1}',
            chapterId: 'chapter-${order + 1}',
            sortOrder: 0,
            originalText: 'Texto ${order + 1}',
            normalizedText: 'Texto ${order + 1}',
            characterCount: 7,
            startPage: order + 1,
            endPage: order + 1,
          ),
        ],
      ),
  ],
);

/// Counts how many times narration asked the book for fresh content.
final class _FakeContentLoader {
  _FakeContentLoader(this.responses);

  final List<ReaderBookContent?> responses;
  var calls = 0;

  Future<ReaderBookContent?> call(String bookId) async {
    final response = responses.isEmpty
        ? null
        : responses[calls.clamp(0, responses.length - 1)];
    calls++;
    return response;
  }
}

final class _FakeEngine implements NarrationEngine {
  _FakeEngine({
    this.voices = const [],
    this.initializeError,
    this.initializeFuture,
    this.speakFuture,
    this.stopFuture,
    this.speakError,
    this.events,
    this.configureFailures = 0,
  });

  List<NarrationVoice> voices;
  Object? initializeError;
  Future<List<NarrationVoice>>? initializeFuture;
  Future<void>? speakFuture;
  Future<void>? stopFuture;
  Object? speakError;
  final List<String>? events;
  int configureFailures;
  final spoken = <String>[];
  final configurations = <String>[];
  var stopCalls = 0;

  @override
  Future<List<NarrationVoice>> initialize() async {
    final future = initializeFuture;
    initializeFuture = null;
    if (future != null) return future;
    if (initializeError != null) throw initializeError!;
    return voices;
  }

  @override
  Future<void> configure(NarrationVoice voice, double rate) async {
    configurations.add('${voice.name}:${voice.locale}:$rate');
    if (configureFailures > 0) {
      configureFailures--;
      throw StateError('voice missing');
    }
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    events?.add('speak:$text');
    if (speakError != null) throw speakError!;
    await speakFuture;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    await stopFuture;
  }

  @override
  Future<void> close() async {}
}

final class _FakeRepository implements NarrationRepository {
  _FakeRepository({
    NarrationSettings? global,
    this.progress,
    this.events,
    this.progressSaveFuture,
  }) : global = global ?? NarrationSettings.defaults();

  NarrationSettings global;
  BookNarrationOverride? bookOverride;
  NarrationProgress? progress;
  final globalSaves = <NarrationSettings>[];
  final overrideSaves = <BookNarrationOverride>[];
  final progressSaves = <NarrationProgress>[];
  final deletedOverrides = <String>[];
  final List<String>? events;
  final Future<void>? progressSaveFuture;
  var failGlobalSave = false;
  var failProgressSave = false;

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
    if (failProgressSave) throw StateError('progress failed');
    await progressSaveFuture;
    progress = value;
    progressSaves.add(value);
    events?.add('save:${value.blockId}:${value.completed}');
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

ReaderBookContent _content({
  String bookId = 'book',
  bool empty = false,
  String activeRunId = 'run',
  String blockPrefix = 'block',
  String firstText = 'Um',
  String secondText = 'Dois',
}) => ReaderBookContent(
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
    activeContentRunId: activeRunId,
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
        cleanText: empty ? '' : '$firstText$secondText',
      ),
      blocks: empty
          ? []
          : [
              _block('$blockPrefix-1', 0, firstText),
              _block('$blockPrefix-2', 1, secondText),
            ],
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
