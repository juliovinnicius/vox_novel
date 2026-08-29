import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/audio_focus_monitor.dart';
import 'package:vox_novel/features/narration/domain/services/audio_interruptions.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';

/// BGN-07, BGN-08 — narration yields to a call and comes back, and yields for
/// good to another audio app. Interruptions arrive through the domain
/// contract, so no device is involved.
void main() {
  late _FakeInterruptions interruptions;
  late _FakePlayback playback;
  late AudioFocusMonitor monitor;

  setUp(() async {
    interruptions = _FakeInterruptions();
    playback = _FakePlayback();
    monitor = AudioFocusMonitor(
      interruptions: interruptions,
      playback: playback,
    );
    await monitor.start();
  });

  test('starting subscribes before the source begins emitting', () {
    expect(interruptions.started, isTrue);
  });

  test('a transient loss pauses narration', () async {
    playback.status = NarrationStatus.playing;

    await interruptions.emit(AudioInterruption.transientLoss);

    expect(playback.calls, ['pause']);
  });

  test('narration resumes when a transient interruption ends', () async {
    playback.status = NarrationStatus.playing;
    await interruptions.emit(AudioInterruption.transientLoss);
    playback.status = NarrationStatus.paused;

    await interruptions.emit(AudioInterruption.transientGain);

    expect(playback.calls, ['pause', 'play']);
  });

  test('a permanent loss pauses narration', () async {
    playback.status = NarrationStatus.playing;

    await interruptions.emit(AudioInterruption.permanentLoss);

    expect(playback.calls, ['pause']);
  });

  test('narration does not resume after a permanent loss', () async {
    playback.status = NarrationStatus.playing;
    await interruptions.emit(AudioInterruption.permanentLoss);
    playback.status = NarrationStatus.paused;

    await interruptions.emit(AudioInterruption.transientGain);

    // The reader chose another app's audio; narration must not talk over it.
    expect(playback.calls, ['pause']);
  });

  test('a permanent loss cancels a pending transient resume', () async {
    playback.status = NarrationStatus.playing;
    await interruptions.emit(AudioInterruption.transientLoss);
    playback.status = NarrationStatus.paused;
    await interruptions.emit(AudioInterruption.permanentLoss);

    await interruptions.emit(AudioInterruption.transientGain);

    expect(playback.calls, ['pause']);
  });

  test('an interruption while already paused changes nothing', () async {
    playback.status = NarrationStatus.paused;

    await interruptions.emit(AudioInterruption.transientLoss);

    expect(playback.calls, isEmpty);
  });

  test('narration paused by the reader is not resumed by returning focus',
      () async {
    playback.status = NarrationStatus.paused;
    await interruptions.emit(AudioInterruption.transientLoss);

    await interruptions.emit(AudioInterruption.transientGain);

    // Focus never took it away, so focus must not give it back.
    expect(playback.calls, isEmpty);
  });

  test('closing stops following interruptions', () async {
    await monitor.close();
    playback.status = NarrationStatus.playing;

    await interruptions.emit(AudioInterruption.transientLoss);

    expect(playback.calls, isEmpty);
  });
}

final class _FakeInterruptions implements AudioInterruptions {
  final _controller = StreamController<AudioInterruption>.broadcast(sync: true);
  var started = false;
  var closed = false;

  @override
  Stream<AudioInterruption> get events => _controller.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  Future<void> emit(AudioInterruption interruption) async {
    if (_controller.isClosed) return;
    _controller.add(interruption);
    await pumpEventQueue();
  }
}

final class _FakePlayback implements NarrationPlayback {
  final calls = <String>[];
  NarrationStatus status = NarrationStatus.ready;

  @override
  NarrationSessionState get state => NarrationSessionState(status: status);

  @override
  Stream<NarrationSessionState> get stream => const Stream.empty();

  @override
  Future<void> play() async => calls.add('play');

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> previous() async => calls.add('previous');

  @override
  Future<void> stop() async => calls.add('stop');
}
