import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';
import 'package:vox_novel/features/narration/presentation/widgets/narration_settings_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required NarrationState state,
    ValueChanged<NarrationVoice>? onVoice,
    ValueChanged<NarrationVoice>? onPreview,
    ValueChanged<bool>? onScope,
    ValueChanged<double>? onRate,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NarrationSettingsSheet(
          state: state,
          onVoiceSelected: onVoice ?? (_) {},
          onVoicePreview: onPreview ?? (_) {},
          onBookOverrideChanged: onScope ?? (_) {},
          onRateChanged: onRate ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('sorts locale then name and marks the exact selected voice', (
    tester,
  ) async {
    final selected = NarrationVoice(name: 'Ana', locale: 'pt-BR');
    await pumpSheet(
      tester,
      state: _state(
        voices: [
          NarrationVoice(name: 'Zoe', locale: 'pt-PT'),
          NarrationVoice(name: 'Bia', locale: 'pt-BR'),
          selected,
          NarrationVoice(name: 'Amy', locale: 'en-US'),
        ],
        selected: selected,
      ),
    );

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('narration-voice-list')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(labels, [
      'Amy',
      'en-US',
      'Ana',
      'pt-BR',
      'Bia',
      'pt-BR',
      'Zoe',
      'pt-PT',
    ]);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Voz Ana, pt-BR'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('emits exact voice selection and preview separately', (
    tester,
  ) async {
    final ana = NarrationVoice(name: 'Ana', locale: 'pt-BR');
    final bia = NarrationVoice(name: 'Bia', locale: 'pt-BR');
    NarrationVoice? selected;
    NarrationVoice? previewed;
    await pumpSheet(
      tester,
      state: _state(voices: [ana, bia], selected: ana),
      onVoice: (voice) => selected = voice,
      onPreview: (voice) => previewed = voice,
    );

    await tester.tap(find.bySemanticsLabel('Voz Bia, pt-BR'));
    await tester.tap(find.bySemanticsLabel('Ouvir amostra de Bia, pt-BR'));
    expect(selected, same(bia));
    expect(previewed, same(bia));
  });

  testWidgets('scope exposes selected semantics and exact callback', (
    tester,
  ) async {
    bool? scope;
    await pumpSheet(
      tester,
      state: _state(usesBookOverride: true),
      onScope: (value) => scope = value,
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Usar ajustes de narração para este livro'),
    );
    expect(semantics.flagsCollection.isToggled, Tristate.isTrue);
    await tester.tap(
      find.bySemanticsLabel('Usar ajustes de narração para este livro'),
    );
    expect(scope, isFalse);
  });

  testWidgets('speed emits only one-decimal 0.1 steps', (tester) async {
    final rates = <double>[];
    await pumpSheet(tester, state: _state(rate: 1.0), onRate: rates.add);

    expect(find.text('1,0×'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Diminuir velocidade da narração'));
    await tester.tap(find.bySemanticsLabel('Aumentar velocidade da narração'));
    expect(rates, [0.9, 1.1]);
  });

  testWidgets('speed actions disable exactly at 0.5 and 2.0', (tester) async {
    await pumpSheet(tester, state: _state(rate: 0.5));
    expect(_button(tester, 'decrease-narration-rate').onPressed, isNull);
    expect(_button(tester, 'increase-narration-rate').onPressed, isNotNull);

    await pumpSheet(tester, state: _state(rate: 2.0));
    expect(_button(tester, 'decrease-narration-rate').onPressed, isNotNull);
    expect(_button(tester, 'increase-narration-rate').onPressed, isNull);
  });

  testWidgets(
    'interactive controls have Portuguese semantics and 48px targets',
    (tester) async {
      final voice = NarrationVoice(name: 'Ana', locale: 'pt-BR');
      await pumpSheet(
        tester,
        state: _state(voices: [voice], selected: voice),
      );

      for (final label in [
        'Voz Ana, pt-BR',
        'Ouvir amostra de Ana, pt-BR',
        'Usar ajustes de narração para este livro',
        'Diminuir velocidade da narração',
        'Aumentar velocidade da narração',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      for (final key in [
        'voice-Ana-pt-BR',
        'preview-Ana-pt-BR',
        'narration-book-scope',
        'decrease-narration-rate',
        'increase-narration-rate',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    },
  );
}

NarrationState _state({
  List<NarrationVoice> voices = const [],
  NarrationVoice? selected,
  double rate = 1.0,
  bool usesBookOverride = false,
}) => NarrationState(
  status: NarrationStatus.ready,
  voices: voices,
  settings: NarrationSettings(voice: selected, rate: rate),
  usesBookOverride: usesBookOverride,
);

IconButton _button(WidgetTester tester, String key) =>
    tester.widget<IconButton>(find.byKey(ValueKey(key)));
