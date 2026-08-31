import 'dart:async';

import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';
import 'package:vox_novel/features/narration/domain/services/narration_queue.dart';
import 'package:vox_novel/features/narration/domain/services/narration_settings_resolver.dart';
import 'package:vox_novel/features/narration/domain/services/notification_permission.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

/// Re-reads a book's reader content — `VisualReaderRepository.loadContent` in
/// production — so narration can pick up chapters that landed while it played.
typedef NarrationContentLoader =
    Future<ReaderBookContent?> Function(String bookId);

/// Owns narration playback for the whole application.
///
/// One queue, one engine, one progress writer, regardless of which surface
/// issued the command — the in-app player, the media notification, or a
/// headset button. A background session outlives any route, so ownership
/// cannot live in a route-scoped Cubit (AD-013).
final class NarrationSession implements NarrationPlayback {
  NarrationSession({
    required NarrationRepository repository,
    required NarrationEngine engine,
    required DateTime Function() clock,
    NarrationSettingsResolver resolver = const NarrationSettingsResolver(),
    NarrationContentLoader? loadContent,
    NotificationPermission? notifications,
  }) : // Public dependency names intentionally omit private prefixes.
       // ignore: prefer_initializing_formals
       _repository = repository,
       // ignore: prefer_initializing_formals
       _engine = engine,
       // ignore: prefer_initializing_formals
       _clock = clock,
       // ignore: prefer_initializing_formals
       _resolver = resolver,
       // ignore: prefer_initializing_formals
       _loadContent = loadContent,
       // ignore: prefer_initializing_formals
       _notifications = notifications;

  static const unavailableMessage =
      'Nenhuma voz de narração está disponível neste dispositivo';
  static const initializationMessage = 'Não foi possível iniciar a narração';
  static const settingsMessage =
      'Não foi possível salvar suas configurações de narração';
  static const speechMessage = 'Não foi possível narrar este trecho';
  static const progressMessage =
      'Não foi possível salvar o progresso da narração';
  static const previewPhrase = 'Esta é uma amostra da voz selecionada';
  static const notificationsMessage =
      'Sem permissão de notificação, os controles fora do app não aparecem';
  static const mediaSessionMessage =
      'A narração funciona no app, mas os controles fora dele não estão '
      'disponíveis';

  final NarrationRepository _repository;
  final NarrationEngine _engine;
  final DateTime Function() _clock;
  final NarrationSettingsResolver _resolver;
  final NarrationContentLoader? _loadContent;
  final NotificationPermission? _notifications;

  // Synchronous delivery: a surface must never render a state older than the
  // one the session already holds, or the in-app player and the notification
  // disagree for a frame. Listeners only project the value, so re-entrancy is
  // not a concern here.
  final StreamController<NarrationSessionState> _states =
      StreamController<NarrationSessionState>.broadcast(sync: true);

  ReaderBookContent? _content;
  NarrationQueue? _queue;
  NarrationQueueEntry? _pendingStart;
  var _generation = 0;
  /// Commands from the app, the notification and a headset can arrive at the
  /// same moment. They queue behind each other rather than being dropped, so
  /// every surface ends on the state the last one asked for (BGN-12).
  Future<void> _commands = Future.value();

  /// A play is between its first await and its first spoken word. A pause
  /// arriving now must still count.
  var _starting = false;

  /// Whether the reader wants narration running. A skip pauses briefly while
  /// it moves, so the transient status cannot answer "was it playing?" for a
  /// second skip arriving right behind the first.
  var _playIntent = false;
  var _closed = false;
  var _reportedMediaSessionFailure = false;
  var _askedForNotifications = false;

  /// Held until a state can actually carry it. The media session fails at
  /// startup, before any book is open, and loading a book emits a fresh state
  /// — without this the reader would never see the warning.
  String? _pendingMediaSessionMessage;
  NarrationSessionState _state = const NarrationSessionState();

  /// The current value, so a surface attaching mid-playback starts correct
  /// rather than empty (BGN-16).
  @override
  NarrationSessionState get state => _state;

  /// The single source of truth every surface renders (BGN-06).
  @override
  Stream<NarrationSessionState> get stream => _states.stream;

  Future<void> load(ReaderBookContent content) async {
    // Re-entering the reader for the book already loaded must not disturb it.
    // The host loads on every mount, so without this, leaving the library and
    // opening the book being narrated killed the live session (BGN-16).
    // The run id is reused across a web book's download passes, so it is not
    // content identity on its own: a chapter that landed since must still
    // reach the queue.
    if (_state.bookId == content.book.id &&
        _content?.book.activeContentRunId == content.book.activeContentRunId &&
        _content?.chapters.length == content.chapters.length) {
      return;
    }
    // A different book replaces this one: stop the speech that is running
    // before its queue is thrown away, or it plays on under the new book
    // (BGN-18).
    if (_state.status == NarrationStatus.playing) {
      try {
        await _engine.stop();
      } catch (_) {
        // The queue is being replaced either way.
      }
    }
    final generation = ++_generation;
    _content = content;
    final queue = NarrationQueue.fromContent(content);
    _queue = queue;
    _emit(const NarrationSessionState(status: NarrationStatus.loading));
    try {
      final voices = await _engine.initialize();
      if (!_active(generation)) return;
      if (voices.isEmpty) {
        _emit(
          const NarrationSessionState(
            status: NarrationStatus.unavailable,
            message: unavailableMessage,
          ),
        );
        return;
      }
      if (queue.isEmpty) {
        _emit(const NarrationSessionState(status: NarrationStatus.unavailable));
        return;
      }
      final global = await _repository.loadGlobalSettings();
      final override = await _repository.loadBookOverride(content.book.id);
      if (!_active(generation)) return;
      final resolution = _resolver.resolve(
        voices: voices,
        global: global,
        override: override,
      )!;
      final settings = resolution.settings;
      if (resolution.repairedVoice) {
        if (override == null) {
          await _repository.saveGlobalSettings(settings);
        } else {
          await _repository.saveBookOverride(
            BookNarrationOverride(
              bookId: content.book.id,
              settings: settings,
              updatedAt: _clock().toUtc(),
            ),
          );
        }
      }
      final saved = await _repository.loadProgress(content.book.id);
      if (!_active(generation)) return;
      var entry = saved == null
          ? queue.first!
          : queue.entryFor(saved.chapterId, saved.blockId);
      final valid =
          saved != null &&
          saved.activeRunId == content.book.activeContentRunId &&
          entry != null &&
          (!saved.completed || entry == queue.last);
      if (!valid) {
        entry = queue.first!;
        if (saved != null) {
          await _repository.saveProgress(
            _progress(entry, settings, completed: false),
          );
        }
      }
      if (!_active(generation)) return;
      _emitEntry(
        entry,
        status: valid && saved.completed
            ? NarrationStatus.completed
            : NarrationStatus.ready,
        voices: _resolver.sortVoices(voices),
        settings: settings,
        usesBookOverride: override != null,
      );
    } catch (_) {
      if (_active(generation)) {
        _emit(
          const NarrationSessionState(
            status: NarrationStatus.error,
            message: initializationMessage,
          ),
        );
      }
    }
  }

  Future<void> retryInitialization() async {
    final content = _content;
    if (content == null) return;
    await load(content);
  }

  Future<void> selectVoice(NarrationVoice voice) => _applySettings(
    NarrationSettings(voice: voice, rate: _state.settings!.rate),
  );

  Future<void> setRate(double rate) =>
      _applySettings(NarrationSettings(voice: _state.settings!.voice, rate: rate));

  Future<void> _applySettings(NarrationSettings settings) async {
    _emit(_state.copyWith(settings: settings, message: null));
    try {
      if (_state.usesBookOverride) {
        await _repository.saveBookOverride(
          BookNarrationOverride(
            bookId: _state.bookId!,
            settings: settings,
            updatedAt: _clock().toUtc(),
          ),
        );
      } else {
        await _repository.saveGlobalSettings(settings);
      }
    } catch (_) {
      // The selection stands even when it could not be stored: reverting it
      // under the reader would be a second surprise on top of the failure.
      if (!_closed) _emit(_state.copyWith(message: settingsMessage));
    }
  }

  Future<void> enableBookOverride() async {
    final settings = _state.settings;
    if (settings == null || _state.usesBookOverride) return;
    _emit(_state.copyWith(usesBookOverride: true, message: null));
    try {
      await _repository.saveBookOverride(
        BookNarrationOverride(
          bookId: _state.bookId!,
          settings: settings,
          updatedAt: _clock().toUtc(),
        ),
      );
    } catch (_) {
      if (!_closed) _emit(_state.copyWith(message: settingsMessage));
    }
  }

  Future<void> removeBookOverride() async {
    if (!_state.usesBookOverride) return;
    try {
      await _repository.deleteBookOverride(_state.bookId!);
      final global = await _repository.loadGlobalSettings();
      final resolved = _resolver.resolve(voices: _state.voices, global: global)!;
      _emit(
        _state.copyWith(
          settings: resolved.settings,
          usesBookOverride: false,
          message: null,
        ),
      );
      if (resolved.repairedVoice) {
        await _repository.saveGlobalSettings(resolved.settings);
      }
    } catch (_) {
      if (!_closed) _emit(_state.copyWith(message: settingsMessage));
    }
  }

  Future<void> previewVoice(NarrationVoice voice) async {
    if (_state.status == NarrationStatus.playing) return;
    final settings = _state.settings;
    if (settings == null) return;
    try {
      await _engine.configure(voice, settings.rate);
      await _engine.speak(previewPhrase);
    } catch (_) {
      _emit(_state.copyWith(message: speechMessage));
    }
  }

  void setPendingStart(String chapterId, String blockId) {
    _pendingStart = _queue?.entryFor(chapterId, blockId);
  }

  @override
  Future<void> play() async {
    // Waits for queued transitions, then plays *outside* the queue: speaking
    // runs for the length of a paragraph, and holding the queue for that long
    // would make pause unable to interrupt it.
    await _commands;
    await _play();
  }

  @override
  Future<void> pause() {
    if (_state.status != NarrationStatus.playing && !_starting) {
      _playIntent = false;
      return Future.value();
    }
    _playIntent = false;
    if (_starting && _state.status != NarrationStatus.playing) {
      // Cancels the start that has not spoken yet.
      ++_generation;
      return Future.value();
    }
    // The status flips synchronously so the button never lags, and the
    // generation bump invalidates the speech already in flight. Only the
    // engine stop and the progress write go through the queue.
    final generation = ++_generation;
    _emit(_state.copyWith(status: NarrationStatus.paused, message: null));
    return _serialize(() => _stopAndPersist(generation));
  }

  @override
  Future<void> previous() => _move(-1);

  @override
  Future<void> next() => _move(1);

  /// Moves one block, then speaks **outside** the queue.
  ///
  /// Speaking runs for the length of a paragraph. Holding the queue for that
  /// long would make pause unable to interrupt a skip, and two quick presses
  /// would advance only one block — the same reason `play` stays outside it.
  Future<void> _move(int offset) async {
    final target = await _serialize(() => _navigate(offset));
    if (target == null) return;
    // Re-checked inside the queue, not beside it: a skip queued behind this
    // one has already moved past, and speaking now would drag the reader back
    // to the block they skipped.
    final stillThere = await _serialize(() async => _state.current == target);
    if (stillThere) await _start(target);
  }

  Future<T> _serialize<T>(Future<T> Function() command) {
    final queued = _commands.then((_) => command());
    // The tail swallows errors so one failed command cannot poison the ones
    // queued behind it; the caller still sees its own failure.
    _commands = queued.then<void>((_) {}, onError: (_) {});
    return queued;
  }

  Future<void> _play() async {
    if (!const [
          NarrationStatus.ready,
          NarrationStatus.paused,
          NarrationStatus.completed,
          NarrationStatus.awaitingDownload,
        ].contains(_state.status)) {
      return;
    }
    final selected = _pendingStart;
    if (_atEndOfQueue(_state.status) && selected == null) return;
    _pendingStart = null;
    final entry = selected ?? _state.current;
    if (entry == null || _state.settings == null) return;
    await _start(entry);
  }

  Future<void> _start(NarrationQueueEntry entry) async {
    // The generation is claimed before the permission dialog, which on first
    // play is a system prompt seconds wide: a pause arriving during it has to
    // be able to cancel the start rather than be swallowed by it.
    final generation = ++_generation;
    _playIntent = true;
    _starting = true;
    try {
      await _ensureNotifications();
    } finally {
      _starting = false;
    }
    if (!_active(generation)) return;
    _emitPlaybackEntry(entry, NarrationStatus.playing);
    try {
      await _speakWithVoiceRepair(entry, generation);
      if (!_active(generation)) return;
      await _complete(entry, generation);
    } catch (_) {
      if (_active(generation)) await _speechFailure(entry, generation);
    }
  }

  Future<void> _speakWithVoiceRepair(
    NarrationQueueEntry entry,
    int generation,
  ) async {
    final original = _state.settings!;
    try {
      await _engine.configure(original.voice!, original.rate);
      if (!_active(generation)) return;
      await _engine.speak(entry.normalizedText);
      return;
    } catch (_) {
      if (!_active(generation)) return;
      final fallback = _state.voices
          .where((voice) => voice != original.voice)
          .firstOrNull;
      if (fallback == null) rethrow;
      final repaired = NarrationSettings(voice: fallback, rate: original.rate);
      _emit(_state.copyWith(settings: repaired));
      if (_state.usesBookOverride) {
        await _repository.saveBookOverride(
          BookNarrationOverride(
            bookId: _state.bookId!,
            settings: repaired,
            updatedAt: _clock().toUtc(),
          ),
        );
      } else {
        await _repository.saveGlobalSettings(repaired);
      }
      await _engine.configure(fallback, repaired.rate);
      if (!_active(generation)) return;
      await _engine.speak(entry.normalizedText);
    }
  }

  Future<void> _complete(NarrationQueueEntry entry, int generation) async {
    var next = _queue!.next(entry);
    var awaiting = false;
    if (next == null && _queue!.awaitsDownload) {
      // The queue ended while chapters are still downloading: look once for a
      // chapter that landed while this block played.
      await _reloadAtBoundary(generation);
      if (!_active(generation)) return;
      next = _queue!.next(entry);
      // A reload that reveals the queue has drained turns the boundary back
      // into a real end of book.
      awaiting = next == null && _queue!.awaitsDownload;
    }
    try {
      await _repository.saveProgress(
        _progress(
          entry,
          _state.settings!,
          // A download boundary is not the end of the book, so the stored
          // progress must not mark the book finished.
          completed: !awaiting && entry == _queue!.last,
        ),
      );
    } catch (_) {
      if (_active(generation)) {
        _emit(
          _state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return;
    }
    if (!_active(generation)) return;
    if (next == null) {
      _playIntent = false;
      _emitPlaybackEntry(
        entry,
        awaiting ? NarrationStatus.awaitingDownload : NarrationStatus.completed,
      );
      return;
    }
    try {
      await _repository.saveProgress(
        _progress(next, _state.settings!, completed: false),
      );
    } catch (_) {
      if (_active(generation)) {
        _emit(
          _state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return;
    }
    if (_active(generation)) await _start(next);
  }

  /// Replaces the loaded content with whatever the book holds now.
  ///
  /// A reload that fails or finds nothing new is indistinguishable from a
  /// chapter that has not downloaded yet, and both mean the same thing here.
  Future<void> _reloadAtBoundary(int generation) async {
    final loader = _loadContent;
    final content = _content;
    if (loader == null || content == null) return;
    try {
      final refreshed = await loader(content.book.id);
      if (refreshed == null || !_active(generation)) return;
      _content = refreshed;
      _queue = NarrationQueue.fromContent(refreshed);
    } catch (_) {
      // Keep the queue that is already loaded.
    }
  }

  static bool _atEndOfQueue(NarrationStatus status) =>
      status == NarrationStatus.completed ||
      status == NarrationStatus.awaitingDownload;

  /// Returns the block to speak next, or null when nothing should be spoken.
  Future<NarrationQueueEntry?> _navigate(int offset) async {
    if (_state.settings == null) return null;
    final current = _state.current;
    if (current == null) return null;
    final target = offset < 0
        ? _queue!.previous(current)
        : _queue!.next(current);
    if (target == null) return null;
    final wasPlaying = _playIntent;
    final generation = ++_generation;
    if (wasPlaying) {
      try {
        await _engine.stop();
      } catch (_) {
        await _speechFailure(current, generation);
        return null;
      }
    }
    if (_active(generation)) {
      _emitPlaybackEntry(
        target,
        wasPlaying ? NarrationStatus.paused : _state.status,
      );
    }
    try {
      await _repository.saveProgress(
        _progress(target, _state.settings!, completed: false),
      );
    } catch (_) {
      if (_active(generation)) {
        _emit(
          _state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return null;
    }
    return wasPlaying && _active(generation) ? target : null;
  }

  Future<void> reloadContent(ReaderBookContent content) async {
    // `load` stops the running speech before replacing the queue, so this no
    // longer stops it too — doing both silenced the engine twice.
    await load(content);
  }

  Future<void> _stopAndPersist(int generation) async {
    final entry = _state.current;
    // A session that never held a block never asked the engine to speak, so
    // there is nothing to stop — and on a device without narration configured,
    // asking anyway is an error rather than a no-op.
    if (entry == null) return;
    try {
      await _engine.stop();
      if (_state.settings != null) {
        await _repository.saveProgress(
          _progress(entry, _state.settings!, completed: false),
        );
      }
    } catch (_) {
      if (_active(generation)) {
        _emit(
          _state.copyWith(
            status: NarrationStatus.paused,
            message: speechMessage,
          ),
        );
      }
    }
  }

  Future<void> _speechFailure(
    NarrationQueueEntry entry,
    int generation,
  ) async {
    try {
      await _repository.saveProgress(
        _progress(entry, _state.settings!, completed: false),
      );
    } catch (_) {
      if (_active(generation)) {
        _emit(
          _state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return;
    }
    if (_active(generation)) {
      _emit(
        _state.copyWith(status: NarrationStatus.paused, message: speechMessage),
      );
    }
  }

  void clearMessage() {
    _pendingMediaSessionMessage = null;
    if (_state.message != null) _emit(_state.copyWith(message: null));
  }

  /// Asks for the notification permission the first time narration actually
  /// needs the notification.
  ///
  /// Not at startup: a permission dialog before the reader has asked for
  /// anything is a prompt with no context. Asked once per session, so a
  /// refusal does not become a dialog on every block.
  Future<void> _ensureNotifications() async {
    final notifications = _notifications;
    if (notifications == null || _askedForNotifications) return;
    _askedForNotifications = true;
    try {
      if (await notifications.ensureGranted()) return;
    } catch (_) {
      // A permission channel that fails is a platform that cannot promise the
      // notification either; say the same thing.
    }
    if (_closed) return;
    _pendingMediaSessionMessage = notificationsMessage;
    _emit(_state.copyWith(message: notificationsMessage));
  }

  /// The platform media session could not be brought up.
  ///
  /// Narration still plays: refusing to speak would punish the reader for a
  /// platform capability the core feature does not need. Reported once, not
  /// once per play, so a failure at startup is not a message on every block.
  void reportMediaSessionUnavailable() {
    if (_reportedMediaSessionFailure || _closed) return;
    _reportedMediaSessionFailure = true;
    _pendingMediaSessionMessage = mediaSessionMessage;
    _emit(_state.copyWith(message: mediaSessionMessage));
  }

  /// Ends the session if it is narrating [bookId].
  ///
  /// Called when a book is deleted: a session pointing at rows that no longer
  /// exist would keep a notification alive for a book the reader removed.
  Future<void> discardBook(String bookId) async {
    if (_state.bookId != bookId) return;
    _playIntent = false;
    ++_generation;
    try {
      await _engine.stop();
    } catch (_) {
      // The book is gone either way; there is nothing left to persist.
    }
    // No generation guard: ending is terminal. Skipping the emit because a
    // command arrived meanwhile would leave a session — and a notification —
    // pointing at a book that no longer exists.
    _content = null;
    _queue = null;
    _pendingStart = null;
    _emit(const NarrationSessionState());
  }

  /// Ends the session, stopping speech and persisting where it stopped.
  @override
  Future<void> stop() async {
    _playIntent = false;
    final generation = ++_generation;
    await _stopAndPersist(generation);
    // Ending the session has to be visible. Persisting silently left every
    // surface — the notification included — still reporting playing, so a
    // MEDIA_STOP from a headset produced a notification that lied.
    _content = null;
    _queue = null;
    _pendingStart = null;
    _emit(const NarrationSessionState());
  }

  Future<void> close() async {
    final generation = ++_generation;
    await _stopAndPersist(generation);
    _closed = true;
    await _states.close();
  }

  bool _active(int generation) => generation == _generation && !_closed;

  NarrationProgress _progress(
    NarrationQueueEntry entry,
    NarrationSettings settings, {
    required bool completed,
  }) => NarrationProgress(
    bookId: _content!.book.id,
    activeRunId: entry.activeRunId,
    chapterId: entry.chapterId,
    blockId: entry.blockId,
    completed: completed,
    settings: settings,
    updatedAt: _clock().toUtc(),
  );

  void _emitEntry(
    NarrationQueueEntry entry, {
    required NarrationStatus status,
    required List<NarrationVoice> voices,
    required NarrationSettings settings,
    required bool usesBookOverride,
  }) {
    final queue = _queue!;
    _emit(
      NarrationSessionState(
        status: status,
        voices: voices,
        settings: settings,
        usesBookOverride: usesBookOverride,
        bookId: _content!.book.id,
        bookTitle: _content!.book.title,
        current: entry,
        canPrevious: queue.previous(entry) != null,
        canNext: queue.next(entry) != null,
        awaitsDownload: queue.awaitsDownload,
      ),
    );
  }

  void _emitPlaybackEntry(NarrationQueueEntry entry, NarrationStatus status) {
    _emitEntry(
      entry,
      status: status,
      voices: _state.voices,
      settings: _state.settings!,
      usesBookOverride: _state.usesBookOverride,
    );
  }

  void _emit(NarrationSessionState next) {
    final pending = _pendingMediaSessionMessage;
    if (pending != null && next.message == null) {
      next = next.copyWith(message: pending);
    }
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
