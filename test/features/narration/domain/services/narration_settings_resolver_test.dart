import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_settings_resolver.dart';

void main() {
  const resolver = NarrationSettingsResolver();
  final ptA = NarrationVoice(name: 'Ana', locale: 'pt-BR');
  final ptZ = NarrationVoice(name: 'Zeca', locale: 'pt-BR');
  final enA = NarrationVoice(name: 'Amy', locale: 'en-US');

  test('sorts locale then name and deduplicates exact voice identities', () {
    expect(resolver.sortVoices([ptZ, ptA, enA, ptA, enA]), [enA, ptA, ptZ]);
  });

  test('book override takes precedence over global exact selection', () {
    final resolution = resolver.resolve(
      voices: [ptA, enA],
      global: NarrationSettings(voice: ptA, rate: 0.8),
      override: BookNarrationOverride(
        bookId: 'book',
        settings: NarrationSettings(voice: enA, rate: 1.4),
        updatedAt: DateTime.utc(2026),
      ),
    );

    expect(resolution?.settings, NarrationSettings(voice: enA, rate: 1.4));
    expect(resolution?.repairedVoice, isFalse);
  });

  test('global selection is used without a book override', () {
    final resolution = resolver.resolve(
      voices: [enA, ptA],
      global: NarrationSettings(voice: ptA, rate: 1.2),
    );
    expect(resolution?.settings, NarrationSettings(voice: ptA, rate: 1.2));
    expect(resolution?.repairedVoice, isFalse);
  });

  test('missing voice repairs to first sorted voice with saved locale', () {
    final missing = NarrationVoice(name: 'Removida', locale: 'pt-BR');
    final resolution = resolver.resolve(
      voices: [ptZ, enA, ptA],
      global: NarrationSettings(voice: missing, rate: 1.1),
    );

    expect(resolution?.settings, NarrationSettings(voice: ptA, rate: 1.1));
    expect(resolution?.repairedVoice, isTrue);
  });

  test('missing locale repairs to first sorted voice overall', () {
    final missing = NarrationVoice(name: 'Removida', locale: 'fr-FR');
    final resolution = resolver.resolve(
      voices: [ptA, enA],
      global: NarrationSettings(voice: missing, rate: 1.7),
    );

    expect(resolution?.settings, NarrationSettings(voice: enA, rate: 1.7));
    expect(resolution?.repairedVoice, isTrue);
  });

  test(
    'no saved voice selects first sorted voice and empty voices return null',
    () {
      final resolution = resolver.resolve(
        voices: [ptA, enA],
        global: NarrationSettings.defaults(),
      );
      expect(resolution?.settings, NarrationSettings(voice: enA, rate: 1));
      expect(resolution?.repairedVoice, isTrue);
      expect(
        resolver.resolve(
          voices: const [],
          global: NarrationSettings.defaults(),
        ),
        isNull,
      );
    },
  );

  test('rate changes exactly one tenth and remains at both boundaries', () {
    expect(resolver.decreaseRate(0.5), 0.5);
    expect(resolver.increaseRate(0.5), 0.6);
    expect(resolver.increaseRate(1.9), 2.0);
    expect(resolver.increaseRate(2.0), 2.0);
    expect(resolver.decreaseRate(2.0), 1.9);
    expect(resolver.decreaseRate(1.1), 1.0);
  });
}
