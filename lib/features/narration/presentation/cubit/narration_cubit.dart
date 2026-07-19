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
  static const previewPhrase = 'Esta é uma amostra da voz selecionada';

  final NarrationRepository _repository;
  final NarrationEngine _engine;
  final DateTime Function() _clock;
  final NarrationSettingsResolver _resolver;
  ReaderBookContent? _content;
  NarrationQueue? _queue;
  var _generation = 0;

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

  @override
  Future<void> close() {
    _generation++;
    return super.close();
  }
}
