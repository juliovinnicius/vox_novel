import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_session.dart';
import 'package:vox_novel/features/narration/domain/services/notification_permission.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

/// BGN-03, BGN-05, BGN-13, BGN-18 — the session owns playback for the whole
/// application, so these assertions cover what a surface can ask of it without
/// any Cubit alive.
void main() {
  final ana = NarrationVoice(name: 'Ana', locale: 'pt-BR');
  final bia = NarrationVoice(name: 'Bia', locale: 'pt-BR');

  late _FakeRepository repository;
  late _FakeEngine engine;

  NarrationSession sessionFor({
    NarrationContentLoader? loadContent,
    NotificationPermission? notifications,
  }) => NarrationSession(
    repository: repository,
    engine: engine,
    clock: () => DateTime.utc(2026),
    loadContent: loadContent,
    notifications: notifications,
  );

  setUp(() {
    repository = _FakeRepository();
    engine = _FakeEngine(voices: [ana, bia]);
  });

  group('load', () {
    test('starts ready at the first block of a fresh book', () async {
      final session = sessionFor();

      await session.load(_content(chapters: 2));

      expect(session.state.status, NarrationStatus.ready);
      expect(session.state.current?.blockId, 'block-1');
      expect(session.state.bookTitle, 'Obra');
      expect(engine.spoken, isEmpty);
    });

    test('publishes every state change on its stream', () async {
      final session = sessionFor();
      final seen = <NarrationStatus>[];
      session.stream.listen((state) => seen.add(state.status));

      await session.load(_content(chapters: 2));
      await pumpEventQueue();

      expect(seen, [NarrationStatus.loading, NarrationStatus.ready]);
    });

    test('reports unavailable when the device offers no voice', () async {
      engine.voices = const [];
      final session = sessionFor();

      await session.load(_content(chapters: 1));

      expect(session.state.status, NarrationStatus.unavailable);
      expect(session.state.message, NarrationSession.unavailableMessage);
    });

    test('restores the saved block instead of the first', () async {
      repository.progressByBook['book'] = _progressAt(
        'chapter-2',
        'block-2',
        voice: ana,
      );
      final session = sessionFor();

      await session.load(_content(chapters: 3));

      expect(session.state.current?.blockId, 'block-2');
      expect(session.state.status, NarrationStatus.ready);
    });

    test('loading a second book stops the first session', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      await session.play();

      await session.load(_content(chapters: 2, id: 'outro'));

      expect(session.state.bookId, 'outro');
      expect(session.state.current?.blockId, 'block-1');
      // The first book's playback must not keep speaking into the new one.
      expect(session.state.status, NarrationStatus.ready);
    });
  });

  group('re-entering and stopping', () {
    test('loading the book already narrated leaves it playing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      // The reader host loads on every mount, so leaving the library and
      // re-opening the narrated book must not disturb the live session.
      await session.load(_content(chapters: 2));

      expect(session.state.status, NarrationStatus.playing);
      expect(engine.stopCalls, 0);
      expect(engine.spoken, ['Texto 1']);
    });

    test('loading another book silences the one playing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      await session.load(_content(chapters: 2, id: 'outro'));

      // Without this the first book's paragraph plays on under the second.
      expect(engine.stopCalls, 1);
      expect(session.state.bookId, 'outro');
    });

    test('stop ends the session visibly, not just quietly', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      await session.stop();

      // Persisting without emitting left every surface — the notification
      // included — still reporting playing.
      expect(session.state, const NarrationSessionState());
      expect(engine.stopCalls, 1);
      expect(repository.progressSaves.last.blockId, 'block-1');
    });
  });

  group('commands arriving together', () {
    test('a pause then a play ends playing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      unawaited(session.pause());
      unawaited(session.play());
      await pumpEventQueue();

      // Arrival order wins (BGN-12). Dropping the second command instead of
      // queueing it left the surfaces disagreeing.
      expect(session.state.status, NarrationStatus.playing);
    });

    test('a play then a pause ends paused', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;

      unawaited(session.play());
      await pumpEventQueue();
      unawaited(session.pause());
      await pumpEventQueue();

      expect(session.state.status, NarrationStatus.paused);
    });

    test('pause reaches the surfaces without waiting for the engine', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();
      engine.stopFuture = Completer<void>().future;

      unawaited(session.pause());

      // Synchronous: the button must not lag behind the engine.
      expect(session.state.status, NarrationStatus.paused);
    });
  });

  group('play and pause', () {
    test('play speaks the current block and reports playing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));
      engine.speakFuture = Completer<void>().future;

      unawaited(session.play());
      await pumpEventQueue();

      expect(session.state.status, NarrationStatus.playing);
      expect(engine.spoken, ['Texto 1']);
    });

    test('a second play while already playing speaks nothing more', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      await session.play();

      expect(engine.spoken, ['Texto 1']);
    });

    test('pause stops the engine and persists where it stopped', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      await session.pause();

      expect(session.state.status, NarrationStatus.paused);
      expect(engine.stopCalls, 1);
      expect(repository.progressSaves.last.blockId, 'block-1');
    });

    test('pause while already paused stops nothing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));

      await session.pause();

      expect(engine.stopCalls, 0);
    });
  });

  group('navigation', () {
    test('next moves exactly one block', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 3));

      await session.next();

      expect(session.state.current?.blockId, 'block-2');
    });

    test('previous moves exactly one block back', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 3));
      await session.next();
      await session.next();

      await session.previous();

      expect(session.state.current?.blockId, 'block-2');
    });

    test('navigating persists the destination block', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));

      await session.next();

      expect(repository.progressSaves.last.blockId, 'block-2');
      expect(repository.progressSaves.last.completed, isFalse);
    });

    test('previous at the first block changes nothing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));

      await session.previous();

      expect(session.state.current?.blockId, 'block-1');
      expect(repository.progressSaves, isEmpty);
    });

    test('navigating while playing restarts speech at the destination',
        () async {
      final session = sessionFor();
      await session.load(_content(chapters: 3));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      // Not awaited: the destination block's speech is held open by the
      // pending completer, so awaiting next() would wait for speech that never
      // finishes.
      unawaited(session.next());
      await pumpEventQueue();

      expect(engine.spoken, ['Texto 1', 'Texto 2']);
      expect(session.state.status, NarrationStatus.playing);
    });
  });

  group('resuming after an interruption', () {
    test('a resumed block is spoken again from its beginning', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 3));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();
      await session.pause();

      engine.speakFuture = null;
      await session.play();
      await pumpEventQueue();

      // AC13: the interrupted paragraph restarts rather than continuing from
      // wherever the engine stopped mid-sentence.
      expect(engine.spoken.take(2), ['Texto 1', 'Texto 1']);
    });
  });

  group('end of book', () {
    test('playing the last block completes without wrapping', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));

      await session.play();
      await pumpEventQueue();

      expect(session.state.status, NarrationStatus.completed);
      expect(engine.spoken, ['Texto 1']);
      expect(repository.progressSaves.last.completed, isTrue);
    });

    test('play on a completed book speaks nothing more', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));
      await session.play();
      await pumpEventQueue();

      await session.play();

      expect(engine.spoken, ['Texto 1']);
    });

    test('next on the last block keeps the completed state', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));
      await session.play();
      await pumpEventQueue();

      await session.next();

      expect(session.state.status, NarrationStatus.completed);
      expect(session.state.current?.blockId, 'block-1');
    });
  });

  group('download boundary', () {
    test('a still-downloading book awaits instead of ending', () async {
      final loader = _FakeContentLoader(const []);
      final session = sessionFor(loadContent: loader.call);
      await session.load(_content(chapters: 1, downloading: true));

      await session.play();
      await pumpEventQueue();

      expect(session.state.status, NarrationStatus.awaitingDownload);
      // A boundary is not the end of the book.
      expect(repository.progressSaves.last.completed, isFalse);
    });

    test('the boundary asks the book for new chapters exactly once', () async {
      final loader = _FakeContentLoader(const []);
      final session = sessionFor(loadContent: loader.call);
      await session.load(_content(chapters: 1, downloading: true));

      await session.play();
      await pumpEventQueue();

      expect(loader.calls, 1);
    });

    test('a chapter that landed mid-block continues narration', () async {
      final loader = _FakeContentLoader([
        _content(chapters: 2, downloading: true),
      ]);
      final session = sessionFor(loadContent: loader.call);
      await session.load(_content(chapters: 1, downloading: true));

      await session.play();
      await pumpEventQueue();

      expect(engine.spoken, ['Texto 1', 'Texto 2']);
    });
  });

  group('failures', () {
    test('a speech failure pauses and keeps the block', () async {
      engine.speakError = StateError('speech failed');
      engine.configureFailures = 2;
      final session = sessionFor();
      await session.load(_content(chapters: 2));

      await session.play();
      await pumpEventQueue();

      expect(session.state.status, NarrationStatus.paused);
      expect(session.state.message, NarrationSession.speechMessage);
      expect(session.state.current?.blockId, 'block-1');
    });

    test('a voice that fails is repaired to another and persisted', () async {
      engine.configureFailures = 1;
      final session = sessionFor();
      await session.load(_content(chapters: 1));

      await session.play();
      await pumpEventQueue();

      expect(session.state.settings?.voice, bia);
      expect(repository.globalSaves.last.voice, bia);
    });

    test('a progress failure pauses with the progress message', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      repository.failProgressSave = true;

      await session.play();
      await pumpEventQueue();

      expect(session.state.status, NarrationStatus.paused);
      expect(session.state.message, NarrationSession.progressMessage);
    });
  });

  group('notification permission', () {
    test('is asked for when narration first needs the notification', () async {
      final notifications = _FakeNotifications();
      final session = sessionFor(notifications: notifications);
      await session.load(_content(chapters: 2));

      // Nothing asked yet: a permission dialog before the reader has asked for
      // anything is a prompt with no context.
      expect(notifications.calls, 0);

      await session.play();
      await pumpEventQueue();

      expect(notifications.calls, 1);
    });

    test('a granted permission says nothing', () async {
      final session = sessionFor(notifications: _FakeNotifications());
      await session.load(_content(chapters: 1));

      await session.play();
      await pumpEventQueue();

      expect(session.state.message, isNull);
    });

    test('a denial still narrates and warns once', () async {
      final session = sessionFor(
        notifications: _FakeNotifications(granted: false),
      );
      await session.load(_content(chapters: 1));

      await session.play();
      await pumpEventQueue();

      expect(engine.spoken, ['Texto 1']);
      expect(session.state.message, NarrationSession.notificationsMessage);
    });

    test('it is asked once per session, not once per block', () async {
      final notifications = _FakeNotifications(granted: false);
      final session = sessionFor(notifications: notifications);
      await session.load(_content(chapters: 3));

      await session.play();
      await pumpEventQueue();

      // Three blocks played through; one dialog.
      expect(notifications.calls, 1);
    });

    test('a permission channel that throws warns like a denial', () async {
      final session = sessionFor(
        notifications: _FakeNotifications(fails: true),
      );
      await session.load(_content(chapters: 1));

      await session.play();
      await pumpEventQueue();

      expect(session.state.message, NarrationSession.notificationsMessage);
      expect(engine.spoken, ['Texto 1']);
    });

    test('a session without a permission source narrates unchanged', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));

      await session.play();
      await pumpEventQueue();

      expect(engine.spoken, ['Texto 1']);
      expect(session.state.message, isNull);
    });
  });

  group('without a media session', () {
    test('reports that outside controls are unavailable', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));

      session.reportMediaSessionUnavailable();

      expect(session.state.message, NarrationSession.mediaSessionMessage);
    });

    test('narration still plays', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 1));
      session.reportMediaSessionUnavailable();

      await session.play();
      await pumpEventQueue();

      // Refusing to speak would punish the reader for a platform capability
      // the core feature does not need.
      expect(engine.spoken, ['Texto 1']);
    });

    test('reporting twice does not repeat the message', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      session.reportMediaSessionUnavailable();
      session.clearMessage();

      session.reportMediaSessionUnavailable();

      // One failure at startup must not become a message on every block.
      expect(session.state.message, isNull);
    });

    test('the report leaves playback state untouched', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      final before = session.state.status;

      session.reportMediaSessionUnavailable();

      expect(session.state.status, before);
      expect(session.state.current?.blockId, 'block-1');
    });

    test('a closed session reports nothing', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      await session.close();

      session.reportMediaSessionUnavailable();

      expect(session.state.message, isNull);
    });
  });

  group('the book disappears', () {
    test('deleting the narrated book ends the session', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      await session.discardBook('book');

      expect(session.state, const NarrationSessionState());
      expect(engine.stopCalls, 1);
    });

    test('deleting a different book leaves the session alone', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));

      await session.discardBook('outro');

      expect(session.state.bookId, 'book');
      expect(engine.stopCalls, 0);
    });

    test('the discarded session speaks nothing more', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      await session.discardBook('book');

      await session.play();

      expect(engine.spoken, isEmpty);
    });

    test('an engine that fails to stop still ends the session', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.stopFuture = Future<void>.error(StateError('stop failed'));

      await session.discardBook('book');

      // The book is gone either way; refusing to let go would strand a
      // notification for something the reader removed.
      expect(session.state, const NarrationSessionState());
    });
  });

  group('lifecycle', () {
    test('close stops the engine and persists', () async {
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      engine.speakFuture = Completer<void>().future;
      unawaited(session.play());
      await pumpEventQueue();

      await session.close();

      expect(engine.stopCalls, 1);
      expect(repository.progressSaves.last.blockId, 'block-1');
    });

    test('close awaits the engine stopping before it persists', () async {
      final stop = Completer<void>();
      engine.stopFuture = stop.future;
      final session = sessionFor();
      await session.load(_content(chapters: 2));
      var closed = false;

      final closing = session.close().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      // Persisting before the engine has stopped would record a position the
      // reader has already spoken past.
      expect([closed, repository.progressSaves], [false, isEmpty]);

      stop.complete();
      await closing;

      expect([closed, repository.progressSaves.single.blockId], [
        true,
        'block-1',
      ]);
    });

    test('closing a session that never loaded never touches the engine',
        () async {
      final session = sessionFor();

      await session.close();

      // A session built by the container but never used has nothing to stop,
      // and on a device with no narration configured asking anyway is an
      // error rather than a no-op.
      expect(engine.stopCalls, 0);
    });

    test('close on an empty session persists nothing', () async {
      final session = sessionFor();

      await session.close();

      expect(repository.progressSaves, isEmpty);
    });
  });
}

NarrationProgress _progressAt(
  String chapterId,
  String blockId, {
  required NarrationVoice voice,
}) => NarrationProgress(
  bookId: 'book',
  activeRunId: 'run',
  chapterId: chapterId,
  blockId: blockId,
  completed: false,
  // Progress rejects a settings value without a voice, so a stored position
  // always carries the voice it was spoken with.
  settings: NarrationSettings(voice: voice, rate: 1),
  updatedAt: DateTime.utc(2026),
);

/// A book whose queue holds [chapters] chapters of one block each.
ReaderBookContent _content({
  required int chapters,
  bool downloading = false,
  String id = 'book',
}) => ReaderBookContent(
  book: Book(
    id: id,
    title: 'Obra',
    sourceType: downloading ? BookSourceType.web : BookSourceType.pdf,
    sourceRef: downloading ? 'https://exemplo.com/series/obra/' : null,
    storedFilePath: downloading ? null : '/obra.pdf',
    status: downloading ? BookStatus.processing : BookStatus.ready,
    processingProgress: downloading ? 0.5 : 1,
    pageCount: chapters,
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
            id: 'block-${order + 1}',
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

final class _FakeNotifications implements NotificationPermission {
  _FakeNotifications({this.granted = true, this.fails = false});

  final bool granted;
  final bool fails;
  var calls = 0;

  @override
  Future<bool> ensureGranted() async {
    calls++;
    if (fails) throw StateError('permission channel failed');
    return granted;
  }
}

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
  _FakeEngine({this.voices = const []});

  List<NarrationVoice> voices;
  Future<void>? speakFuture;
  Future<void>? stopFuture;
  Object? speakError;
  int configureFailures = 0;
  final spoken = <String>[];
  var stopCalls = 0;

  @override
  Future<List<NarrationVoice>> initialize() async => voices;

  @override
  Future<void> configure(NarrationVoice voice, double rate) async {
    if (configureFailures > 0) {
      configureFailures--;
      throw StateError('voice missing');
    }
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
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
  NarrationSettings global = NarrationSettings.defaults();
  BookNarrationOverride? bookOverride;
  final progressByBook = <String, NarrationProgress>{};
  final globalSaves = <NarrationSettings>[];
  final overrideSaves = <BookNarrationOverride>[];
  final progressSaves = <NarrationProgress>[];
  final deletedOverrides = <String>[];
  var failProgressSave = false;

  @override
  Future<NarrationSettings> loadGlobalSettings() async => global;

  @override
  Future<void> saveGlobalSettings(NarrationSettings settings) async {
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
  Future<NarrationProgress?> loadProgress(String bookId) async =>
      progressByBook[bookId];

  @override
  Future<void> saveProgress(NarrationProgress value) async {
    if (failProgressSave) throw StateError('progress failed');
    progressByBook[value.bookId] = value;
    progressSaves.add(value);
  }
}
