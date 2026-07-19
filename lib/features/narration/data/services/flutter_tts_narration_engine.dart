import 'package:flutter_tts/flutter_tts.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_settings_resolver.dart';

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
  }) : _facade = facade ?? PluginFlutterTtsFacade(),
       // Public injection name intentionally omits a private prefix.
       // ignore: prefer_initializing_formals
       _resolver = resolver;

  final FlutterTtsFacade _facade;
  final NarrationSettingsResolver _resolver;
  Future<List<NarrationVoice>>? _initialization;

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
  Future<void> speak(String text) =>
      _requireSuccess('speak', _facade.speak(text));

  @override
  Future<void> stop() => _requireSuccess('stop', _facade.stop());

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
}
