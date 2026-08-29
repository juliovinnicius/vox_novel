import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/data/services/narration_audio_handler.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_playback.dart';

/// BGN-04, BGN-05, BGN-06, BGN-15 — the notification, the lock screen and any
/// external control reach playback through this handler. No foreground service
/// and no device are involved: playback is a hand-written fake.
void main() {
  late _FakePlayback playback;

  NarrationQueueEntry entry(String blockId, {String chapter = 'Capítulo 1'}) =>
      NarrationQueueEntry(
        activeRunId: 'run-1',
        chapterId: 'chapter-1',
        blockId: blockId,
        chapterTitle: chapter,
        normalizedText: 'Texto.',
      );

  NarrationSessionState playing({
    bool canPrevious = true,
    bool canNext = true,
    NarrationStatus status = NarrationStatus.playing,
  }) => NarrationSessionState(
    status: status,
    bookId: 'book-1',
    bookTitle: 'Obra sintética',
    current: entry('block-2'),
    canPrevious: canPrevious,
    canNext: canNext,
  );

  setUp(() => playback = _FakePlayback());

  group('commands reach playback', () {
    test('each control calls its playback method exactly once', () async {
      final handler = NarrationAudioHandler(playback);

      await handler.play();
      await handler.pause();
      await handler.skipToNext();
      await handler.skipToPrevious();

      expect(playback.calls, ['play', 'pause', 'next', 'previous']);
    });

    test('next moves one block, not one chapter', () async {
      final handler = NarrationAudioHandler(playback);

      await handler.skipToNext();

      // The session's next() is the same unit the in-app button moves; a
      // chapter-level skip would be a different method entirely.
      expect(playback.calls, ['next']);
    });

    test('stop ends playback and stops following the session', () async {
      final handler = NarrationAudioHandler(playback);

      await handler.stop();
      playback.emit(playing());

      expect(playback.calls.first, 'stop');
      // After stopping, a late session event must not resurrect a
      // notification claiming playback.
      expect(handler.playbackState.value.playing, isFalse);
    });
  });

  group('published state follows the session', () {
    test('a playing session publishes playing with a pause control', () {
      final handler = NarrationAudioHandler(playback);

      playback.emit(playing());

      expect(handler.playbackState.value.playing, isTrue);
      expect(
        handler.playbackState.value.controls,
        [MediaControl.skipToPrevious, MediaControl.pause, MediaControl.skipToNext],
      );
    });

    test('a paused session publishes a play control instead', () {
      final handler = NarrationAudioHandler(playback);

      playback.emit(playing(status: NarrationStatus.paused));

      expect(handler.playbackState.value.playing, isFalse);
      expect(
        handler.playbackState.value.controls.contains(MediaControl.play),
        isTrue,
      );
    });

    test('a change from the app updates the notification', () {
      final handler = NarrationAudioHandler(playback);
      playback.emit(playing());

      playback.emit(playing(status: NarrationStatus.paused));

      expect(handler.playbackState.value.playing, isFalse);
    });

    test('attaching adopts the state the session already holds', () {
      playback.state = playing();

      final handler = NarrationAudioHandler(playback);

      expect(handler.playbackState.value.playing, isTrue);
      expect(handler.mediaItem.value?.title, 'Obra sintética');
    });

    test('the notification names the book and its chapter', () {
      final handler = NarrationAudioHandler(playback);

      playback.emit(playing());

      expect(handler.mediaItem.value?.title, 'Obra sintética');
      expect(handler.mediaItem.value?.artist, 'Capítulo 1');
    });

    test('the first block offers no previous control', () {
      final handler = NarrationAudioHandler(playback);

      playback.emit(playing(canPrevious: false));

      expect(
        handler.playbackState.value.controls.contains(
          MediaControl.skipToPrevious,
        ),
        isFalse,
      );
    });

    test('the last block completes without offering next', () {
      final handler = NarrationAudioHandler(playback);

      playback.emit(
        playing(canNext: false, status: NarrationStatus.completed),
      );

      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.completed,
      );
      expect(
        handler.playbackState.value.controls.contains(MediaControl.skipToNext),
        isFalse,
      );
      expect(handler.playbackState.value.playing, isFalse);
    });

    test('a download boundary buffers rather than completing', () {
      final handler = NarrationAudioHandler(playback);

      playback.emit(
        playing(canNext: false, status: NarrationStatus.awaitingDownload),
      );

      // Reporting completed here would tell the platform the book ended when
      // it is only waiting for a chapter.
      expect(
        handler.playbackState.value.processingState,
        AudioProcessingState.buffering,
      );
    });
  });
}

final class _FakePlayback implements NarrationPlayback {
  final _controller = StreamController<NarrationSessionState>.broadcast(
    sync: true,
  );
  final calls = <String>[];

  @override
  NarrationSessionState state = const NarrationSessionState();

  @override
  Stream<NarrationSessionState> get stream => _controller.stream;

  void emit(NarrationSessionState next) {
    state = next;
    _controller.add(next);
  }

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
