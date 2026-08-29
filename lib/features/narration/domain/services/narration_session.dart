import 'dart:async';

import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';
import 'package:vox_novel/features/narration/domain/services/narration_queue.dart';
import 'package:vox_novel/features/narration/domain/services/narration_settings_resolver.dart';
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
       _loadContent = loadContent;

  static const unavailableMessage =
      'Nenhuma voz de narração está disponível neste dispositivo';
  static const initializationMessage = 'Não foi possível iniciar a narração';
  static const settingsMessage =
      'Não foi possível salvar suas configurações de narração';
  static const speechMessage = 'Não foi possível narrar este trecho';
  static const progressMessage =
      'Não foi possível salvar o progresso da narração';
  static const previewPhrase = 'Esta é uma amostra da voz selecionada';

  final NarrationRepository _repository;
  final NarrationEngine _engine;
  final DateTime Function() _clock;
  final NarrationSettingsResolver _resolver;
  final NarrationContentLoader? _loadContent;

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
  var _transitioning = false;
  var _closed = false;
  NarrationSessionState _state = const NarrationSessionState();

  /// The current value, so a surface attaching mid-playback starts correct
  /// rather than empty (BGN-16).
  @override
  NarrationSessionState get state => _state;

  /// The single source of truth every surface renders (BGN-06).
  @override
  Stream<NarrationSessionState> get stream => _states.stream;

  Future<void> load(ReaderBookContent content) async {
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
    if (_transitioning ||
        !const [
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
    final generation = ++_generation;
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

  @override
  Future<void> pause() async {
    if (_transitioning || _state.status != NarrationStatus.playing) return;
    _transitioning = true;
    final generation = ++_generation;
    _emit(_state.copyWith(status: NarrationStatus.paused, message: null));
    await _stopAndPersist(generation);
    _transitioning = false;
  }

  @override
  Future<void> previous() => _navigate(-1);
  @override
  Future<void> next() => _navigate(1);

  Future<void> _navigate(int offset) async {
    if (_transitioning || _state.settings == null) return;
    final current = _state.current;
    if (current == null) return;
    final target = offset < 0
        ? _queue!.previous(current)
        : _queue!.next(current);
    if (target == null) return;
    _transitioning = true;
    final wasPlaying = _state.status == NarrationStatus.playing;
    final generation = ++_generation;
    if (wasPlaying) {
      try {
        await _engine.stop();
      } catch (_) {
        await _speechFailure(current, generation);
        _transitioning = false;
        return;
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
      _transitioning = false;
      return;
    }
    _transitioning = false;
    if (wasPlaying && _active(generation)) await _start(target);
  }

  Future<void> reloadContent(ReaderBookContent content) async {
    final wasPlaying = _state.status == NarrationStatus.playing;
    ++_generation;
    if (wasPlaying) {
      try {
        await _engine.stop();
      } catch (_) {
        // Reload still replaces stale content.
      }
    }
    await load(content);
  }

  Future<void> _stopAndPersist(int generation) async {
    final entry = _state.current;
    try {
      await _engine.stop();
      if (entry != null && _state.settings != null) {
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
    if (_state.message != null) _emit(_state.copyWith(message: null));
  }

  /// Ends the session, stopping speech and persisting where it stopped.
  @override
  Future<void> stop() async {
    final generation = ++_generation;
    await _stopAndPersist(generation);
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
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
