import 'dart:async';

import 'package:audio_session/audio_session.dart' as platform;
import 'package:vox_novel/features/narration/domain/services/audio_interruptions.dart';

/// Reads interruptions from the platform's audio session.
///
/// `audio_service` does not handle audio focus — it delegates to
/// `audio_session` — so this is the only place the platform's focus events
/// enter the app.
final class AudioSessionInterruptions implements AudioInterruptions {
  AudioSessionInterruptions({Future<platform.AudioSession>? session})
    : _session = session ?? platform.AudioSession.instance;

  final Future<platform.AudioSession> _session;
  final _events = StreamController<AudioInterruption>.broadcast();
  StreamSubscription<platform.AudioInterruptionEvent>? _subscription;
  StreamSubscription<void>? _noisy;

  @override
  Stream<AudioInterruption> get events => _events.stream;

  @override
  Future<void> start() async {
    final session = await _session;
    await session.configure(const platform.AudioSessionConfiguration.speech());
    _subscription = session.interruptionEventStream.listen(_forward);
    _noisy = session.becomingNoisyEventStream.listen(
      (_) => _events.add(AudioInterruption.outputDisconnected),
    );
  }

  void _forward(platform.AudioInterruptionEvent event) {
    if (event.begin) {
      // `duck` is folded into a pause: a narration at low volume is not
      // unobtrusive, it is unintelligible.
      _events.add(
        event.type == platform.AudioInterruptionType.unknown
            ? AudioInterruption.permanentLoss
            : AudioInterruption.transientLoss,
      );
      return;
    }
    // Only a transient interruption ends with focus worth returning to.
    if (event.type != platform.AudioInterruptionType.unknown) {
      _events.add(AudioInterruption.transientGain);
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _noisy?.cancel();
    await _events.close();
  }
}
