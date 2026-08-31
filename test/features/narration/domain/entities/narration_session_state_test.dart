import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

/// BGN-06 — every surface renders one value. These assertions pin the parts of
/// that contract a wrong implementation would quietly break: a field dropped
/// from equality makes two different sessions compare equal, and a `copyWith`
/// that cannot express "clear this" makes the message stick after it is read.
void main() {
  NarrationQueueEntry entry(String blockId) => NarrationQueueEntry(
    activeRunId: 'run-1',
    chapterId: 'chapter-1',
    blockId: blockId,
    chapterTitle: 'Capítulo 1',
    normalizedText: 'Texto do bloco.',
  );

  NarrationSessionState stateWith({
    NarrationStatus status = NarrationStatus.playing,
  }) => NarrationSessionState(
    status: status,
    bookId: 'book-1',
    bookTitle: 'Obra sintética',
    current: entry('block-1'),
    awaitsDownload: true,
    message: 'aviso',
  );

  test('an empty session carries no book and speaks nothing', () {
    const state = NarrationSessionState();

    expect(
      [
        state.status,
        state.bookId,
        state.bookTitle,
        state.current,
        state.awaitsDownload,
        state.message,
      ],
      [NarrationStatus.initial, null, null, null, false, null],
    );
  });

  test('copyWith leaves every unsupplied field untouched', () {
    final original = stateWith();

    final copy = original.copyWith(status: NarrationStatus.paused);

    expect(
      [
        copy.status,
        copy.bookId,
        copy.bookTitle,
        copy.current,
        copy.awaitsDownload,
        copy.message,
      ],
      [
        NarrationStatus.paused,
        'book-1',
        'Obra sintética',
        entry('block-1'),
        true,
        'aviso',
      ],
    );
  });

  test('copyWith can clear a nullable field explicitly', () {
    final cleared = stateWith().copyWith(message: null, current: null);

    expect(cleared.message, isNull);
    expect(cleared.current, isNull);
    // Clearing one field must not clear its neighbours.
    expect(cleared.bookId, 'book-1');
  });

  test('two sessions with the same fields are equal', () {
    expect(stateWith(), stateWith());
    expect(stateWith().hashCode, stateWith().hashCode);
  });

  for (final difference in [
    'status',
    'bookId',
    'bookTitle',
    'current',
    'awaitsDownload',
    'message',
  ]) {
    test('a session differing only in $difference is not equal', () {
      final base = stateWith();
      final other = switch (difference) {
        'status' => base.copyWith(status: NarrationStatus.paused),
        'bookId' => base.copyWith(bookId: 'book-2'),
        'bookTitle' => base.copyWith(bookTitle: 'Outra obra'),
        'current' => base.copyWith(current: entry('block-2')),
        'awaitsDownload' => base.copyWith(awaitsDownload: false),
        _ => base.copyWith(message: null),
      };

      expect(other, isNot(base));
    });
  }
}
