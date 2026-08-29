/// What the platform can do to narration's audio, expressed without any
/// package type so the coordination below is testable off a device.
enum AudioInterruption {
  /// Something else needs the audio briefly — a call, a navigation prompt.
  /// Narration should come back on its own afterwards.
  transientLoss,

  /// The brief interruption ended.
  transientGain,

  /// Another app took the audio for good. Narration stays paused until the
  /// reader asks for it again.
  permanentLoss,

  /// The audio output went away — headphones unplugged, a Bluetooth device
  /// disconnected. Continuing would move the book to the room's speaker.
  outputDisconnected,
}

/// A source of audio interruptions.
abstract interface class AudioInterruptions {
  Stream<AudioInterruption> get events;

  Future<void> start();
  Future<void> close();
}
