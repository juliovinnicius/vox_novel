import 'dart:async';

import 'package:audio_session/audio_session.dart' as platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/data/services/audio_session_interruptions.dart';
import 'package:vox_novel/features/narration/domain/services/audio_interruptions.dart';

/// BGN-07, BGN-08 — the platform reports one interruption type; which of the
/// two rules applies is decided here. This is the single line separating "comes
/// back on its own" from "stays paused", so it is asserted directly rather than
/// only through the monitor.
void main() {
  late _FakeSession session;
  late AudioSessionInterruptions interruptions;
  late List<AudioInterruption> seen;

  setUp(() async {
    session = _FakeSession();
    interruptions = AudioSessionInterruptions(session: Future.value(session));
    seen = [];
    interruptions.events.listen(seen.add);
    await interruptions.start();
  });

  test('configures the session for speech before listening', () {
    expect(session.configured, isTrue);
  });

  for (final type in [
    platform.AudioInterruptionType.pause,
    platform.AudioInterruptionType.duck,
  ]) {
    test('a beginning $type interruption is transient', () async {
      session.interrupt(begin: true, type: type);
      await pumpEventQueue();

      // Ducking is folded in deliberately: a narration at low volume is not
      // unobtrusive, it is unintelligible.
      expect(seen, [AudioInterruption.transientLoss]);
    });

    test('an ending $type interruption returns focus', () async {
      session.interrupt(begin: false, type: type);
      await pumpEventQueue();

      expect(seen, [AudioInterruption.transientGain]);
    });
  }

  test('a beginning unknown interruption is permanent', () async {
    session.interrupt(begin: true, type: platform.AudioInterruptionType.unknown);
    await pumpEventQueue();

    expect(seen, [AudioInterruption.permanentLoss]);
  });

  test('an ending unknown interruption returns nothing', () async {
    session.interrupt(
      begin: false,
      type: platform.AudioInterruptionType.unknown,
    );
    await pumpEventQueue();

    // Only a transient interruption ends with focus worth returning to;
    // emitting a gain here would resume over the app the reader chose.
    expect(seen, isEmpty);
  });

  test('a noisy output is reported as disconnected', () async {
    session.becomeNoisy();
    await pumpEventQueue();

    expect(seen, [AudioInterruption.outputDisconnected]);
  });

  test('closing stops forwarding platform events', () async {
    await interruptions.close();

    session.interrupt(begin: true, type: platform.AudioInterruptionType.pause);
    await pumpEventQueue();

    expect(seen, isEmpty);
  });
}

/// A stand-in for the platform session. Nothing here touches a device.
final class _FakeSession implements platform.AudioSession {
  final _interruptions =
      StreamController<platform.AudioInterruptionEvent>.broadcast();
  final _noisy = StreamController<void>.broadcast();
  var configured = false;

  void interrupt({
    required bool begin,
    required platform.AudioInterruptionType type,
  }) => _interruptions.add(platform.AudioInterruptionEvent(begin, type));

  void becomeNoisy() => _noisy.add(null);

  @override
  Stream<platform.AudioInterruptionEvent> get interruptionEventStream =>
      _interruptions.stream;

  @override
  Stream<void> get becomingNoisyEventStream => _noisy.stream;

  @override
  Future<void> configure(platform.AudioSessionConfiguration configuration) async {
    configured = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
