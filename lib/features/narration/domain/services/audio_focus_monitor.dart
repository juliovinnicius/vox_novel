import 'dart:async';

import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/audio_interruptions.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';

/// Turns platform interruptions into playback commands (BGN-07, BGN-08).
///
/// Ducking is not an option for speech — lowering a narration's volume makes
/// it unintelligible rather than unobtrusive — so every interruption pauses.
/// What differs is whether narration comes back by itself.
final class AudioFocusMonitor {
  AudioFocusMonitor({
    required AudioInterruptions interruptions,
    required NarrationPlayback playback,
  }) : // Public dependency names intentionally omit private prefixes.
       // ignore: prefer_initializing_formals
       _interruptions = interruptions,
       // ignore: prefer_initializing_formals
       _playback = playback;

  final AudioInterruptions _interruptions;
  final NarrationPlayback _playback;
  StreamSubscription<AudioInterruption>? _subscription;

  /// Whether the interruption that paused narration was one it should come
  /// back from. Narration paused by the reader is never resumed by focus.
  var _resumeWhenFocusReturns = false;

  Future<void> start() async {
    _subscription = _interruptions.events.listen(_onInterruption);
    await _interruptions.start();
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _interruptions.close();
  }

  Future<void> _onInterruption(AudioInterruption interruption) async {
    switch (interruption) {
      case AudioInterruption.transientLoss:
        if (_playback.state.status != NarrationStatus.playing) return;
        _resumeWhenFocusReturns = true;
        await _playback.pause();
      case AudioInterruption.permanentLoss:
        _resumeWhenFocusReturns = false;
        if (_playback.state.status != NarrationStatus.playing) return;
        await _playback.pause();
      case AudioInterruption.outputDisconnected:
        // Never resumed by returning focus: the reader took the headphones
        // out on purpose.
        _resumeWhenFocusReturns = false;
        if (_playback.state.status != NarrationStatus.playing) return;
        await _playback.pause();
      case AudioInterruption.transientGain:
        if (!_resumeWhenFocusReturns) return;
        _resumeWhenFocusReturns = false;
        await _playback.play();
    }
  }
}
