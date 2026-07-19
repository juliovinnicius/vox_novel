import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

final class NarrationSettingsResolution {
  const NarrationSettingsResolution({
    required this.settings,
    required this.repairedVoice,
  });

  final NarrationSettings settings;
  final bool repairedVoice;
}

final class NarrationSettingsResolver {
  const NarrationSettingsResolver();

  List<NarrationVoice> sortVoices(Iterable<NarrationVoice> voices) {
    final unique = <String, NarrationVoice>{};
    for (final voice in voices) {
      unique.putIfAbsent('${voice.locale}\u0000${voice.name}', () => voice);
    }
    final sorted = unique.values.toList()
      ..sort((first, second) {
        final locale = first.locale.compareTo(second.locale);
        return locale != 0 ? locale : first.name.compareTo(second.name);
      });
    return List.unmodifiable(sorted);
  }

  NarrationSettingsResolution? resolve({
    required Iterable<NarrationVoice> voices,
    required NarrationSettings global,
    BookNarrationOverride? override,
  }) {
    final sorted = sortVoices(voices);
    if (sorted.isEmpty) return null;
    final preferred = override?.settings ?? global;
    final savedVoice = preferred.voice;
    final exact = savedVoice == null
        ? null
        : sorted.where((voice) => voice == savedVoice).firstOrNull;
    final sameLocale = savedVoice == null
        ? null
        : sorted
              .where((voice) => voice.locale == savedVoice.locale)
              .firstOrNull;
    final resolvedVoice = exact ?? sameLocale ?? sorted.first;
    return NarrationSettingsResolution(
      settings: NarrationSettings(voice: resolvedVoice, rate: preferred.rate),
      repairedVoice: resolvedVoice != savedVoice,
    );
  }

  double increaseRate(double rate) => _adjustRate(rate, 1);
  double decreaseRate(double rate) => _adjustRate(rate, -1);

  double _adjustRate(double rate, int tenths) {
    NarrationSettings(voice: null, rate: rate);
    final adjusted = ((rate * 10).round() + tenths).clamp(5, 20);
    return adjusted / 10;
  }
}
