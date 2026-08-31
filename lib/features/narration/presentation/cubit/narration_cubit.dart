import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_session.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

/// Presentation state for narration.
///
/// Owns nothing: playback lives in the application-scoped [NarrationSession]
/// (AD-013), because a background session outlives any route. This renders the
/// session's state and forwards what the reader asks for, so the in-app player
/// and the media notification cannot disagree.
final class NarrationCubit extends Cubit<NarrationState> {
  NarrationCubit({required NarrationSession session})
    : // Public dependency name intentionally omits a private prefix.
      // ignore: prefer_initializing_formals
      _session = session,
      super(const NarrationState()) {
    // Adopt whatever the session is already doing, so attaching mid-playback
    // shows the live session rather than an empty one (BGN-16, BGN-17).
    _project(_session.state);
    _subscription = _session.stream.listen(_project);
  }

  static const unavailableMessage = NarrationSession.unavailableMessage;
  static const initializationMessage = NarrationSession.initializationMessage;
  static const settingsMessage = NarrationSession.settingsMessage;
  static const speechMessage = NarrationSession.speechMessage;
  static const progressMessage = NarrationSession.progressMessage;
  static const previewPhrase = NarrationSession.previewPhrase;

  final NarrationSession _session;
  StreamSubscription<NarrationSessionState>? _subscription;

  Future<void> load(ReaderBookContent content) => _session.load(content);

  Future<void> retryInitialization() => _session.retryInitialization();

  Future<void> selectVoice(NarrationVoice voice) => _session.selectVoice(voice);

  Future<void> setRate(double rate) => _session.setRate(rate);

  Future<void> enableBookOverride() => _session.enableBookOverride();

  Future<void> removeBookOverride() => _session.removeBookOverride();

  Future<void> previewVoice(NarrationVoice voice) =>
      _session.previewVoice(voice);

  void setPendingStart(String chapterId, String blockId) =>
      _session.setPendingStart(chapterId, blockId);

  Future<void> play() => _session.play();

  Future<void> pause() => _session.pause();

  Future<void> previous() => _session.previous();

  Future<void> next() => _session.next();

  Future<void> reloadContent(ReaderBookContent content) =>
      _session.reloadContent(content);

  void clearMessage() => _session.clearMessage();

  void _project(NarrationSessionState session) {
    if (isClosed) return;
    final entry = session.current;
    emit(
      NarrationState(
        status: session.status,
        voices: session.voices,
        settings: session.settings,
        usesBookOverride: session.usesBookOverride,
        bookId: session.bookId,
        activeRunId: entry?.activeRunId,
        chapterId: entry?.chapterId,
        blockId: entry?.blockId,
        chapterTitle: entry?.chapterTitle,
        canPrevious: session.canPrevious,
        canNext: session.canNext,
        message: session.message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
