import 'package:audio_service/audio_service.dart';
import 'package:vox_novel/features/narration/data/services/narration_audio_handler.dart';
import 'package:vox_novel/features/narration/domain/services/audio_focus_monitor.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';

/// Brings the platform media session up around [playback].
///
/// Lives in the data layer because it is the only place `audio_service`'s
/// initialisation belongs; the composition root calls it through a seam so a
/// test never touches the platform.
typedef NarrationMediaSessionStarter =
    Future<void> Function(NarrationPlayback playback, AudioFocusMonitor focus);

Future<void> startNarrationMediaSession(
  NarrationPlayback playback,
  AudioFocusMonitor focus,
) async {
  await AudioService.init(
    builder: () => NarrationAudioHandler(playback),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.vox_novel.narration',
      androidNotificationChannelName: 'Narração',
      // Not dismissible while playing. The package asserts that this requires
      // dropping foreground state on pause, which is exactly the behaviour the
      // spec settled on: dismissible only once narration is paused.
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  // Text to speech produces no audio stream Android recognises as playback, so
  // without this every headset and lock-screen button is silently dropped —
  // the notification still looks functional. Measured in the T2 spike.
  await AudioService.androidForceEnableMediaButtons();
  await focus.start();
}
