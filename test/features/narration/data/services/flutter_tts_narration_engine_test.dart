import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/data/services/flutter_tts_narration_engine.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

void main() {
  test('closing tolerates an engine that cannot stop', () async {
    final facade = _FakeFacade(result: 0);
    final engine = FlutterTtsNarrationEngine(facade: facade);

    // Disposal must not fail: throwing here takes the whole dependency reset
    // down with it, including on a device where narration was never used.
    await expectLater(engine.close(), completes);
  });

  test(
    'initializes once and strictly maps deduplicated sorted voices',
    () async {
      final facade = _FakeFacade(
        voices: [
          {'name': 'Zeca', 'locale': 'pt-BR'},
          {'name': 'Amy', 'locale': 'en-US'},
          {'name': 'Zeca', 'locale': 'pt-BR'},
          {'name': '', 'locale': 'pt-BR'},
          {'name': 'Sem locale'},
          'invalid',
        ],
      );
      final engine = FlutterTtsNarrationEngine(facade: facade);

      final results = await Future.wait([
        engine.initialize(),
        engine.initialize(),
      ]);

      expect(results[0], [
        NarrationVoice(name: 'Amy', locale: 'en-US'),
        NarrationVoice(name: 'Zeca', locale: 'pt-BR'),
      ]);
      expect(results[1], results[0]);
      expect(facade.awaitCompletionValues, [true]);
      expect(facade.getVoicesCalls, 1);
    },
  );

  test('configures and speaks exact voice rate and Unicode text', () async {
    final facade = _FakeFacade();
    final engine = FlutterTtsNarrationEngine(facade: facade);
    final voice = NarrationVoice(name: 'Ana', locale: 'pt-BR');

    await engine.configure(voice, 1.3);
    await engine.speak('Olá 👩🏽‍🚀 第二段');
    await engine.stop();
    await engine.close();

    expect(facade.voiceValues, [
      {'name': 'Ana', 'locale': 'pt-BR'},
    ]);
    expect(facade.rateValues, [1.3]);
    expect(facade.spokenValues, ['Olá 👩🏽‍🚀 第二段']);
    expect(facade.stopCalls, 2);
  });

  test('non-success plugin results become adapter failures', () async {
    final facade = _FakeFacade(result: 0);
    final engine = FlutterTtsNarrationEngine(facade: facade);
    final voice = NarrationVoice(name: 'Ana', locale: 'pt-BR');

    await expectLater(
      engine.configure(voice, 1),
      throwsA(isA<NarrationEngineException>()),
    );
    await expectLater(
      engine.speak('Texto'),
      throwsA(isA<NarrationEngineException>()),
    );
    await expectLater(engine.stop(), throwsA(isA<NarrationEngineException>()));
  });

  test(
    'failed initialization can retry without retaining a failed future',
    () async {
      final facade = _FakeFacade(voices: StateError('voices unavailable'));
      final engine = FlutterTtsNarrationEngine(facade: facade);

      await expectLater(
        engine.initialize(),
        throwsA(isA<NarrationEngineException>()),
      );
      facade.voices = [
        {'name': 'Ana', 'locale': 'pt-BR'},
      ];

      expect(await engine.initialize(), [
        NarrationVoice(name: 'Ana', locale: 'pt-BR'),
      ]);
      expect(facade.awaitCompletionValues, [true, true]);
      expect(facade.getVoicesCalls, 2);
    },
  );

  test('speak future remains pending until plugin completion', () async {
    final completion = Completer<dynamic>();
    final facade = _FakeFacade(speakResult: completion.future);
    final engine = FlutterTtsNarrationEngine(facade: facade);
    var completed = false;

    final speech = engine.speak('Texto').then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    completion.complete(1);
    await speech;
    expect(completed, isTrue);
  });

  test(
    'joins visual line breaks and keeps commas in the same utterance',
    () async {
      final facade = _FakeFacade();
      final delays = <Duration>[];
      final engine = FlutterTtsNarrationEngine(
        facade: facade,
        delay: (duration) async => delays.add(duration),
      );

      await engine.speak('Ele caminhou até a\r\nporta, olhou para trás.');

      expect(facade.spokenValues, [
        'Ele caminhou até a porta, olhou para trás.',
      ]);
      expect(delays, isEmpty);
    },
  );

  test('speaks sentences separately with a short pause between them', () async {
    final facade = _FakeFacade();
    final delays = <Duration>[];
    final engine = FlutterTtsNarrationEngine(
      facade: facade,
      delay: (duration) async => delays.add(duration),
    );

    await engine.speak('Primeira. Segunda? Terceira! Última.');

    expect(facade.spokenValues, [
      'Primeira.',
      'Segunda?',
      'Terceira!',
      'Última.',
    ]);
    expect(delays, [
      const Duration(milliseconds: 220),
      const Duration(milliseconds: 220),
      const Duration(milliseconds: 220),
    ]);
  });

  test(
    'uses a longer pause between paragraphs and normalizes CR breaks',
    () async {
      final facade = _FakeFacade();
      final delays = <Duration>[];
      final engine = FlutterTtsNarrationEngine(
        facade: facade,
        delay: (duration) async => delays.add(duration),
      );

      await engine.speak('Primeiro parágrafo.\r\rSegundo 👩🏽‍🚀 parágrafo.');

      expect(facade.spokenValues, [
        'Primeiro parágrafo.',
        'Segundo 👩🏽‍🚀 parágrafo.',
      ]);
      expect(delays, [const Duration(milliseconds: 420)]);
    },
  );

  test('stop during an artificial pause prevents remaining speech', () async {
    final facade = _FakeFacade();
    final pause = Completer<void>();
    final engine = FlutterTtsNarrationEngine(
      facade: facade,
      delay: (_) => pause.future,
    );

    final speech = engine.speak('Primeira. Segunda.');
    await Future<void>.delayed(Duration.zero);
    await engine.stop();
    pause.complete();
    await speech;

    expect(facade.spokenValues, ['Primeira.']);
    expect(facade.stopCalls, 1);
  });
}

final class _FakeFacade implements FlutterTtsFacade {
  _FakeFacade({
    this.voices = const <dynamic>[],
    this.result = 1,
    this.speakResult,
  });

  dynamic voices;
  final dynamic result;
  final Future<dynamic>? speakResult;
  final awaitCompletionValues = <bool>[];
  final voiceValues = <Map<String, String>>[];
  final rateValues = <double>[];
  final spokenValues = <String>[];
  var getVoicesCalls = 0;
  var stopCalls = 0;

  @override
  Future<dynamic> awaitSpeakCompletion(bool enabled) async {
    awaitCompletionValues.add(enabled);
    return result;
  }

  @override
  Future<dynamic> getVoices() async {
    getVoicesCalls++;
    if (voices case final Object error when error is Error) throw error;
    return voices;
  }

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    voiceValues.add(voice);
    return result;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    rateValues.add(rate);
    return result;
  }

  @override
  Future<dynamic> speak(String text) {
    spokenValues.add(text);
    return speakResult ?? Future.value(result);
  }

  @override
  Future<dynamic> stop() async {
    stopCalls++;
    return result;
  }
}
