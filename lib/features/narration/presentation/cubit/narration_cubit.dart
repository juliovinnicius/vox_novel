import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_queue.dart';
import 'package:vox_novel/features/narration/domain/services/narration_settings_resolver.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

final class NarrationCubit extends Cubit<NarrationState> {
  NarrationCubit({
    required NarrationRepository repository,
    required NarrationEngine engine,
    required DateTime Function() clock,
    NarrationSettingsResolver resolver = const NarrationSettingsResolver(),
  }) : // Public dependency names intentionally omit private prefixes.
       // ignore: prefer_initializing_formals
       _repository = repository,
       // ignore: prefer_initializing_formals
       _engine = engine,
       // ignore: prefer_initializing_formals
       _clock = clock,
       // ignore: prefer_initializing_formals
       _resolver = resolver,
       super(const NarrationState());

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
  ReaderBookContent? _content;
  NarrationQueue? _queue;
  NarrationQueueEntry? _pendingStart;
  var _generation = 0;
  var _transitioning = false;

  Future<void> load(ReaderBookContent content) async {
    final generation = ++_generation;
    _content = content;
    final queue = NarrationQueue.fromContent(content);
    _queue = queue;
    emit(const NarrationState(status: NarrationStatus.loading));
    try {
      final voices = await _engine.initialize();
      if (!_active(generation)) return;
      if (voices.isEmpty) {
        emit(
          const NarrationState(
            status: NarrationStatus.unavailable,
            message: unavailableMessage,
          ),
        );
        return;
      }
      if (queue.isEmpty) {
        emit(const NarrationState(status: NarrationStatus.unavailable));
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
        entry!,
        status: valid && saved!.completed
            ? NarrationStatus.completed
            : NarrationStatus.ready,
        voices: _resolver.sortVoices(voices),
        settings: settings,
        usesBookOverride: override != null,
      );
    } catch (_) {
      if (_active(generation)) {
        emit(
          const NarrationState(
            status: NarrationStatus.error,
            message: initializationMessage,
          ),
        );
      }
    }
  }

  Future<void> retryInitialization() async {
    final content = _content;
    if (content != null) await load(content);
  }

  Future<void> selectVoice(NarrationVoice voice) => _applySettings(
    NarrationSettings(voice: voice, rate: state.settings!.rate),
  );

  Future<void> setRate(double rate) => _applySettings(
    NarrationSettings(voice: state.settings!.voice, rate: rate),
  );

  Future<void> _applySettings(NarrationSettings settings) async {
    emit(state.copyWith(settings: settings, message: null));
    try {
      if (state.usesBookOverride) {
        await _repository.saveBookOverride(
          BookNarrationOverride(
            bookId: state.bookId!,
            settings: settings,
            updatedAt: _clock().toUtc(),
          ),
        );
      } else {
        await _repository.saveGlobalSettings(settings);
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(message: settingsMessage));
    }
  }

  Future<void> enableBookOverride() async {
    final settings = state.settings;
    if (settings == null || state.usesBookOverride) return;
    emit(state.copyWith(usesBookOverride: true, message: null));
    try {
      await _repository.saveBookOverride(
        BookNarrationOverride(
          bookId: state.bookId!,
          settings: settings,
          updatedAt: _clock().toUtc(),
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(message: settingsMessage));
    }
  }

  Future<void> removeBookOverride() async {
    if (!state.usesBookOverride) return;
    try {
      await _repository.deleteBookOverride(state.bookId!);
      final global = await _repository.loadGlobalSettings();
      final resolved = _resolver.resolve(voices: state.voices, global: global)!;
      emit(
        state.copyWith(
          settings: resolved.settings,
          usesBookOverride: false,
          message: null,
        ),
      );
      if (resolved.repairedVoice) {
        await _repository.saveGlobalSettings(resolved.settings);
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(message: settingsMessage));
    }
  }

  Future<void> previewVoice(NarrationVoice voice) async {
    final generation = ++_generation;
    final prior = state;
    try {
      await _engine.stop();
      if (!_active(generation)) return;
      await _engine.configure(voice, state.settings!.rate);
      await _engine.speak(previewPhrase);
    } catch (_) {
      // Preview is intentionally non-destructive.
    }
    if (_active(generation)) emit(prior);
  }

  void setPendingStart(String chapterId, String blockId) {
    _pendingStart = _queue?.entryFor(chapterId, blockId);
  }

  Future<void> play() async {
    if (_transitioning ||
        !const [
          NarrationStatus.ready,
          NarrationStatus.paused,
          NarrationStatus.completed,
        ].contains(state.status)) {
      return;
    }
    final selected = _pendingStart;
    if (state.status == NarrationStatus.completed && selected == null) return;
    _pendingStart = null;
    final entry =
        selected ??
        _queue?.entryFor(state.chapterId ?? '', state.blockId ?? '');
    if (entry == null || state.settings == null) return;
    await _start(entry);
  }

  Future<void> _start(NarrationQueueEntry entry) async {
    final generation = ++_generation;
    _emitPlaybackEntry(entry, NarrationStatus.playing);
    try {
      await _engine.configure(state.settings!.voice!, state.settings!.rate);
      if (!_active(generation)) return;
      await _engine.speak(entry.normalizedText);
      if (!_active(generation)) return;
      await _complete(entry, generation);
    } catch (_) {
      if (_active(generation)) await _speechFailure(entry, generation);
    }
  }

  Future<void> _complete(NarrationQueueEntry entry, int generation) async {
    try {
      await _repository.saveProgress(
        _progress(entry, state.settings!, completed: entry == _queue!.last),
      );
    } catch (_) {
      if (_active(generation)) {
        emit(
          state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return;
    }
    if (!_active(generation)) return;
    final next = _queue!.next(entry);
    if (next == null) {
      _emitPlaybackEntry(entry, NarrationStatus.completed);
      return;
    }
    try {
      await _repository.saveProgress(
        _progress(next, state.settings!, completed: false),
      );
    } catch (_) {
      if (_active(generation)) {
        emit(
          state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return;
    }
    if (_active(generation)) await _start(next);
  }

  Future<void> pause() async {
    if (_transitioning || state.status != NarrationStatus.playing) return;
    _transitioning = true;
    final generation = ++_generation;
    emit(state.copyWith(status: NarrationStatus.paused, message: null));
    await _stopAndPersist(generation);
    _transitioning = false;
  }

  Future<void> previous() => _navigate(-1);
  Future<void> next() => _navigate(1);

  Future<void> _navigate(int offset) async {
    if (_transitioning || state.settings == null) return;
    final current = _queue?.entryFor(
      state.chapterId ?? '',
      state.blockId ?? '',
    );
    if (current == null) return;
    final target = offset < 0
        ? _queue!.previous(current)
        : _queue!.next(current);
    if (target == null) return;
    _transitioning = true;
    final wasPlaying = state.status == NarrationStatus.playing;
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
    try {
      await _repository.saveProgress(
        _progress(target, state.settings!, completed: false),
      );
    } catch (_) {
      if (_active(generation)) {
        emit(
          state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      _transitioning = false;
      return;
    }
    if (_active(generation)) {
      _emitPlaybackEntry(
        target,
        wasPlaying ? NarrationStatus.paused : state.status,
      );
    }
    _transitioning = false;
    if (wasPlaying && _active(generation)) await _start(target);
  }

  Future<void> onAppLifecyclePause() {
    if (state.status != NarrationStatus.playing) return Future.value();
    final generation = ++_generation;
    emit(state.copyWith(status: NarrationStatus.paused, message: null));
    return _stopAndPersist(generation);
  }

  Future<void> reloadContent(ReaderBookContent content) async {
    final wasPlaying = state.status == NarrationStatus.playing;
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
    final entry = _queue?.entryFor(state.chapterId ?? '', state.blockId ?? '');
    try {
      await _engine.stop();
      if (entry != null && state.settings != null) {
        await _repository.saveProgress(
          _progress(entry, state.settings!, completed: false),
        );
      }
    } catch (_) {
      if (_active(generation)) {
        emit(
          state.copyWith(
            status: NarrationStatus.paused,
            message: speechMessage,
          ),
        );
      }
    }
  }

  Future<void> _speechFailure(NarrationQueueEntry entry, int generation) async {
    try {
      await _repository.saveProgress(
        _progress(entry, state.settings!, completed: false),
      );
    } catch (_) {
      if (_active(generation)) {
        emit(
          state.copyWith(
            status: NarrationStatus.paused,
            message: progressMessage,
          ),
        );
      }
      return;
    }
    if (_active(generation)) {
      emit(
        state.copyWith(status: NarrationStatus.paused, message: speechMessage),
      );
    }
  }

  void clearMessage() {
    if (state.message != null) emit(state.copyWith(message: null));
  }

  bool _active(int generation) => generation == _generation && !isClosed;

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
    emit(
      NarrationState(
        status: status,
        voices: voices,
        settings: settings,
        usesBookOverride: usesBookOverride,
        bookId: _content!.book.id,
        activeRunId: entry.activeRunId,
        chapterId: entry.chapterId,
        blockId: entry.blockId,
        chapterTitle: entry.chapterTitle,
        canPrevious: queue.previous(entry) != null,
        canNext: queue.next(entry) != null,
      ),
    );
  }

  void _emitPlaybackEntry(NarrationQueueEntry entry, NarrationStatus status) {
    _emitEntry(
      entry,
      status: status,
      voices: state.voices,
      settings: state.settings!,
      usesBookOverride: state.usesBookOverride,
    );
  }

  @override
  Future<void> close() async {
    final generation = ++_generation;
    if (_queue != null && state.settings != null) {
      await _stopAndPersist(generation);
    }
    return super.close();
  }
}
