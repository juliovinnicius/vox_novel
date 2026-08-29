import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

/// What a surface may ask of narration playback.
///
/// The media handler and any other client depend on this rather than on
/// [NarrationSession] itself, which is a `final class` and so cannot be
/// substituted in a test. Keeping the contract this narrow also means a
/// surface cannot reach past playback into settings or persistence.
abstract interface class NarrationPlayback {
  NarrationSessionState get state;
  Stream<NarrationSessionState> get stream;

  Future<void> play();
  Future<void> pause();
  Future<void> previous();
  Future<void> next();
  Future<void> stop();
}
