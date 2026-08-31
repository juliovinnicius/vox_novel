import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';

/// Bridges the platform's media session to narration playback.
///
/// It owns no playback of its own: every command is forwarded to
/// [NarrationPlayback] and every published state is derived from that one
/// value, so the notification, the lock screen and the in-app player cannot
/// disagree about what is playing (BGN-06).
final class NarrationAudioHandler extends BaseAudioHandler {
  NarrationAudioHandler(this._playback) {
    _publish(_playback.state);
    _subscription = _playback.stream.listen(_publish);
  }

  final NarrationPlayback _playback;
  StreamSubscription<NarrationSessionState>? _subscription;

  @override
  Future<void> play() => _playback.play();

  @override
  Future<void> pause() => _playback.pause();

  /// One narration block forward, the same unit the in-app button moves.
  @override
  Future<void> skipToNext() => _playback.next();

  /// One narration block back, the same unit the in-app button moves.
  @override
  Future<void> skipToPrevious() => _playback.previous();

  @override
  Future<void> stop() async {
    await _playback.stop();
    await _subscription?.cancel();
    await super.stop();
  }

  void _publish(NarrationSessionState state) {
    final entry = state.current;
    if (entry != null) {
      mediaItem.add(
        MediaItem(
          id: state.bookId ?? entry.blockId,
          // The book is what the listener is hearing; the chapter is the
          // secondary line Android renders beneath it (BGN-04).
          title: state.bookTitle ?? '',
          artist: entry.chapterTitle,
        ),
      );
    }
    playbackState.add(
      playbackState.value.copyWith(
        playing: state.status == NarrationStatus.playing,
        processingState: _processingState(state.status),
        controls: _controls(state),
        // The first and last block have nothing to skip to, and a control the
        // platform shows but the session refuses is worse than none.
        systemActions: {
          if (state.canPrevious) MediaAction.skipToPrevious,
          if (state.canNext) MediaAction.skipToNext,
        },
      ),
    );
  }

  List<MediaControl> _controls(NarrationSessionState state) => [
    if (state.canPrevious) MediaControl.skipToPrevious,
    if (state.status == NarrationStatus.playing)
      MediaControl.pause
    else
      MediaControl.play,
    if (state.canNext) MediaControl.skipToNext,
  ];

  static AudioProcessingState _processingState(NarrationStatus status) =>
      switch (status) {
        NarrationStatus.initial => AudioProcessingState.idle,
        NarrationStatus.loading => AudioProcessingState.loading,
        NarrationStatus.completed => AudioProcessingState.completed,
        // A download boundary is not the end of the book: the queue is waiting
        // for a chapter, which is a buffering state, not a finished one.
        NarrationStatus.awaitingDownload => AudioProcessingState.buffering,
        NarrationStatus.unavailable ||
        NarrationStatus.error => AudioProcessingState.error,
        _ => AudioProcessingState.ready,
      };
}
