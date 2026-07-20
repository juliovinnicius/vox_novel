import 'package:flutter_tts/flutter_tts.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_settings_resolver.dart';

typedef NarrationDelay = Future<void> Function(Duration duration);

Future<void> _defaultNarrationDelay(Duration duration) =>
    Future<void>.delayed(duration);

final class NarrationEngineException implements Exception {
  const NarrationEngineException(this.operation, [this.cause]);

  final String operation;
  final Object? cause;
}

abstract interface class FlutterTtsFacade {
  Future<dynamic> awaitSpeakCompletion(bool enabled);
  Future<dynamic> getVoices();
  Future<dynamic> setVoice(Map<String, String> voice);
  Future<dynamic> setSpeechRate(double rate);
  Future<dynamic> speak(String text);
  Future<dynamic> stop();
}

final class PluginFlutterTtsFacade implements FlutterTtsFacade {
  PluginFlutterTtsFacade([FlutterTts? plugin])
    : _plugin = plugin ?? FlutterTts();

  final FlutterTts _plugin;

  @override
  Future<dynamic> awaitSpeakCompletion(bool enabled) =>
      _plugin.awaitSpeakCompletion(enabled);

  @override
  Future<dynamic> getVoices() => _plugin.getVoices;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) =>
      _plugin.setVoice(voice);

  @override
  Future<dynamic> setSpeechRate(double rate) => _plugin.setSpeechRate(rate);

  @override
  Future<dynamic> speak(String text) => _plugin.speak(text);

  @override
  Future<dynamic> stop() => _plugin.stop();
}

final class FlutterTtsNarrationEngine implements NarrationEngine {
  FlutterTtsNarrationEngine({
    FlutterTtsFacade? facade,
    NarrationSettingsResolver resolver = const NarrationSettingsResolver(),
    NarrationDelay delay = _defaultNarrationDelay,
  }) : _facade = facade ?? PluginFlutterTtsFacade(),
       // Public injection name intentionally omits a private prefix.
       // ignore: prefer_initializing_formals
       _resolver = resolver,
       // Public injection name intentionally omits a private prefix.
       // ignore: prefer_initializing_formals
       _delay = delay;

  final FlutterTtsFacade _facade;
  final NarrationSettingsResolver _resolver;
  final NarrationDelay _delay;
  Future<List<NarrationVoice>>? _initialization;
  var _speechGeneration = 0;

  @override
  Future<List<NarrationVoice>> initialize() async {
    final existing = _initialization;
    if (existing != null) return existing;
    final pending = _initialize();
    _initialization = pending;
    try {
      return await pending;
    } catch (_) {
      if (identical(_initialization, pending)) _initialization = null;
      rethrow;
    }
  }

  Future<List<NarrationVoice>> _initialize() async {
    try {
      await _facade.awaitSpeakCompletion(true);
      final raw = await _facade.getVoices();
      final voices = <NarrationVoice>[];
      if (raw is Iterable) {
        for (final item in raw) {
          if (item is! Map) continue;
          final name = item['name'];
          final locale = item['locale'];
          if (name is! String ||
              locale is! String ||
              name.trim().isEmpty ||
              locale.trim().isEmpty) {
            continue;
          }
          voices.add(NarrationVoice(name: name, locale: locale));
        }
      }
      return _resolver.sortVoices(voices);
    } catch (error) {
      throw NarrationEngineException('initialize', error);
    }
  }

  @override
  Future<void> configure(NarrationVoice voice, double rate) async {
    await _requireSuccess(
      'setVoice',
      _facade.setVoice({'name': voice.name, 'locale': voice.locale}),
    );
    await _requireSuccess('setSpeechRate', _facade.setSpeechRate(rate));
  }

  @override
  Future<void> speak(String text) async {
    final generation = ++_speechGeneration;
    final parts = _speechParts(text);
    for (var index = 0; index < parts.length; index++) {
      if (generation != _speechGeneration) return;
      await _requireSuccess('speak', _facade.speak(parts[index].text));
      if (generation != _speechGeneration || index == parts.length - 1) return;
      await _delay(parts[index].pauseAfter);
    }
  }

  @override
  Future<void> stop() {
    _speechGeneration++;
    return _requireSuccess('stop', _facade.stop());
  }

  @override
  Future<void> close() => stop();

  Future<void> _requireSuccess(String operation, Future<dynamic> result) async {
    try {
      if (await result != 1) throw NarrationEngineException(operation);
    } on NarrationEngineException {
      rethrow;
    } catch (error) {
      throw NarrationEngineException(operation, error);
    }
  }

  List<_SpeechPart> _speechParts(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n'))
        .map(
          (paragraph) => paragraph.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim(),
        )
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
    final parts = <_SpeechPart>[];
    for (
      var paragraphIndex = 0;
      paragraphIndex < paragraphs.length;
      paragraphIndex++
    ) {
      final sentences = _sentences(paragraphs[paragraphIndex]);
      for (
        var sentenceIndex = 0;
        sentenceIndex < sentences.length;
        sentenceIndex++
      ) {
        final isLastSentence = sentenceIndex == sentences.length - 1;
        final hasNextParagraph = paragraphIndex < paragraphs.length - 1;
        parts.add(
          _SpeechPart(
            sentences[sentenceIndex],
            isLastSentence && hasNextParagraph
                ? const Duration(milliseconds: 420)
                : const Duration(milliseconds: 220),
          ),
        );
      }
    }
    return parts;
  }

  List<String> _sentences(String paragraph) {
    final boundary = RegExp(r'[.!?。！？]+(?=\s|$)');
    final sentences = <String>[];
    var start = 0;
    for (final match in boundary.allMatches(paragraph)) {
      final sentence = paragraph.substring(start, match.end).trim();
      if (sentence.isNotEmpty) sentences.add(sentence);
      start = match.end;
    }
    final remainder = paragraph.substring(start).trim();
    if (remainder.isNotEmpty) sentences.add(remainder);
    return sentences;
  }
}

final class _SpeechPart {
  const _SpeechPart(this.text, this.pauseAfter);

  final String text;
  final Duration pauseAfter;
}
