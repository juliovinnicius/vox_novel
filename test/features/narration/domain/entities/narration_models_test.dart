import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';

void main() {
  final voice = NarrationVoice(name: 'Voz A', locale: 'pt-BR');

  test('voice requires paired non-empty identity and has value equality', () {
    expect(
      NarrationVoice(name: 'Voz A', locale: 'pt-BR'),
      NarrationVoice(name: 'Voz A', locale: 'pt-BR'),
    );
    for (final identity in [
      (name: '', locale: 'pt-BR'),
      (name: 'Voz A', locale: ''),
      (name: ' ', locale: 'pt-BR'),
      (name: 'Voz A', locale: ' '),
    ]) {
      expect(
        () => NarrationVoice(name: identity.name, locale: identity.locale),
        throwsA(isA<NarrationValidationException>()),
      );
    }
  });

  test('settings accept exact rate boundaries and one-decimal steps', () {
    for (final rate in [0.5, 0.6, 1.0, 1.9, 2.0]) {
      expect(NarrationSettings(voice: voice, rate: rate).rate, rate);
    }
    expect(
      NarrationSettings.defaults(),
      NarrationSettings(voice: null, rate: 1),
    );
    expect(
      NarrationSettings(voice: voice, rate: 1).copyWith(rate: 1.1),
      NarrationSettings(voice: voice, rate: 1.1),
    );
  });

  test('settings reject every invalid rate branch', () {
    for (final rate in [double.nan, double.infinity, 0.4, 2.1, 0.55]) {
      expect(
        () => NarrationSettings(voice: voice, rate: rate),
        throwsA(isA<NarrationValidationException>()),
      );
    }
  });

  test('override requires book, resolved voice, and UTC timestamp', () {
    final valid = BookNarrationOverride(
      bookId: 'book',
      settings: NarrationSettings(voice: voice, rate: 1),
      updatedAt: DateTime.utc(2026),
    );
    expect(
      [valid.bookId, valid.settings.voice, valid.updatedAt.isUtc],
      ['book', voice, true],
    );

    for (final invalid in [
      () => BookNarrationOverride(
        bookId: '',
        settings: NarrationSettings(voice: voice, rate: 1),
        updatedAt: DateTime.utc(2026),
      ),
      () => BookNarrationOverride(
        bookId: 'book',
        settings: NarrationSettings.defaults(),
        updatedAt: DateTime.utc(2026),
      ),
      () => BookNarrationOverride(
        bookId: 'book',
        settings: NarrationSettings(voice: voice, rate: 1),
        updatedAt: DateTime(2026),
      ),
    ]) {
      expect(invalid, throwsA(isA<NarrationValidationException>()));
    }
  });

  test('progress preserves every complete field and validates identities', () {
    final settings = NarrationSettings(voice: voice, rate: 1.2);
    final progress = NarrationProgress(
      bookId: 'book',
      activeRunId: 'run',
      chapterId: 'chapter',
      blockId: 'block',
      completed: true,
      settings: settings,
      updatedAt: DateTime.utc(2026),
    );
    expect(
      [
        progress.bookId,
        progress.activeRunId,
        progress.chapterId,
        progress.blockId,
        progress.completed,
        progress.settings,
        progress.updatedAt,
      ],
      ['book', 'run', 'chapter', 'block', true, settings, DateTime.utc(2026)],
    );

    for (var index = 0; index < 4; index++) {
      final ids = ['book', 'run', 'chapter', 'block'];
      ids[index] = '';
      expect(
        () => NarrationProgress(
          bookId: ids[0],
          activeRunId: ids[1],
          chapterId: ids[2],
          blockId: ids[3],
          completed: false,
          settings: settings,
          updatedAt: DateTime.utc(2026),
        ),
        throwsA(isA<NarrationValidationException>()),
      );
    }
    expect(
      () => NarrationProgress(
        bookId: 'book',
        activeRunId: 'run',
        chapterId: 'chapter',
        blockId: 'block',
        completed: false,
        settings: NarrationSettings.defaults(),
        updatedAt: DateTime.utc(2026),
      ),
      throwsA(isA<NarrationValidationException>()),
    );
    expect(
      () => NarrationProgress(
        bookId: 'book',
        activeRunId: 'run',
        chapterId: 'chapter',
        blockId: 'block',
        completed: false,
        settings: settings,
        updatedAt: DateTime(2026),
      ),
      throwsA(isA<NarrationValidationException>()),
    );
  });

  test('queue entry retains exact Unicode text and validates identity', () {
    final entry = NarrationQueueEntry(
      activeRunId: 'run',
      chapterId: 'chapter',
      blockId: 'block',
      chapterTitle: 'Capítulo',
      normalizedText: 'Olá 👩🏽‍🚀 第二段',
    );
    expect(entry.normalizedText, 'Olá 👩🏽‍🚀 第二段');
    expect(
      entry,
      NarrationQueueEntry(
        activeRunId: 'run',
        chapterId: 'chapter',
        blockId: 'block',
        chapterTitle: 'Capítulo',
        normalizedText: 'Olá 👩🏽‍🚀 第二段',
      ),
    );
  });

  test(
    'engine contract exposes package-agnostic lifecycle operations',
    () async {
      final engine = _FakeEngine(voice);
      expect(await engine.initialize(), [voice]);
      await engine.configure(voice, 1.3);
      await engine.speak('Texto exato');
      await engine.stop();
      await engine.close();

      expect(engine.calls, [
        'initialize',
        'configure:Voz A:pt-BR:1.3',
        'speak:Texto exato',
        'stop',
        'close',
      ]);
    },
  );
}

final class _FakeEngine implements NarrationEngine {
  _FakeEngine(this.voice);
  final NarrationVoice voice;
  final calls = <String>[];

  @override
  Future<List<NarrationVoice>> initialize() async {
    calls.add('initialize');
    return [voice];
  }

  @override
  Future<void> configure(NarrationVoice voice, double rate) async {
    calls.add('configure:${voice.name}:${voice.locale}:$rate');
  }

  @override
  Future<void> speak(String text) async => calls.add('speak:$text');
  @override
  Future<void> stop() async => calls.add('stop');
  @override
  Future<void> close() async => calls.add('close');
}
