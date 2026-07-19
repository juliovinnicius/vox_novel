import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';
import 'package:vox_novel/features/narration/presentation/widgets/narration_player_bar.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required NarrationState state,
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    VoidCallback? onSettings,
    VoidCallback? onRetry,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: NarrationPlayerBar(
          state: state,
          onPlay: onPlay ?? () {},
          onPause: onPause ?? () {},
          onPrevious: onPrevious ?? () {},
          onNext: onNext ?? () {},
          onSettings: onSettings ?? () {},
          onRetry: onRetry ?? () {},
        ),
      ),
    ),
  );

  testWidgets('ready exposes chapter and enabled play/settings controls', (
    tester,
  ) async {
    var plays = 0;
    var settings = 0;
    await pumpBar(
      tester,
      state: _state(NarrationStatus.ready, canNext: true),
      onPlay: () => plays++,
      onSettings: () => settings++,
    );

    expect(find.text('Capítulo 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Reproduzir narração'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Configurações de voz e velocidade'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Reproduzir narração'));
    await tester.tap(
      find.bySemanticsLabel('Configurações de voz e velocidade'),
    );
    expect((plays, settings), (1, 1));
    expect(_button(tester, 'previous-narration-block').onPressed, isNull);
    expect(_button(tester, 'next-narration-block').onPressed, isNotNull);
  });

  testWidgets('playing exposes pause and exact queue actions', (tester) async {
    var pauses = 0;
    var previous = 0;
    var next = 0;
    await pumpBar(
      tester,
      state: _state(NarrationStatus.playing, canPrevious: true, canNext: true),
      onPause: () => pauses++,
      onPrevious: () => previous++,
      onNext: () => next++,
    );

    await tester.tap(find.bySemanticsLabel('Pausar narração'));
    await tester.tap(find.bySemanticsLabel('Trecho anterior'));
    await tester.tap(find.bySemanticsLabel('Próximo trecho'));
    expect((pauses, previous, next), (1, 1, 1));
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('paused remains resumable and presents its exact message', (
    tester,
  ) async {
    await pumpBar(
      tester,
      state: _state(
        NarrationStatus.paused,
        message: 'Não foi possível narrar este trecho',
      ),
    );

    expect(find.bySemanticsLabel('Retomar narração'), findsOneWidget);
    expect(find.text('Não foi possível narrar este trecho'), findsOneWidget);
  });

  testWidgets('completed is terminal and does not wrap', (tester) async {
    await pumpBar(
      tester,
      state: _state(
        NarrationStatus.completed,
        canPrevious: true,
        canNext: false,
      ),
    );

    expect(find.bySemanticsLabel('Narração concluída'), findsOneWidget);
    expect(_button(tester, 'play-pause-narration').onPressed, isNull);
    expect(_button(tester, 'previous-narration-block').onPressed, isNotNull);
    expect(_button(tester, 'next-narration-block').onPressed, isNull);
  });

  testWidgets('unavailable disables playback and shows exact message', (
    tester,
  ) async {
    await pumpBar(
      tester,
      state: const NarrationState(
        status: NarrationStatus.unavailable,
        message: 'Nenhuma voz de narração está disponível neste dispositivo',
      ),
    );

    expect(
      find.text('Nenhuma voz de narração está disponível neste dispositivo'),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('play-pause-narration')))
          .label,
      'Narração indisponível',
    );
    expect(_button(tester, 'play-pause-narration').onPressed, isNull);
    expect(_button(tester, 'narration-settings').onPressed, isNull);
  });

  testWidgets('initialization error exposes one accessible retry action', (
    tester,
  ) async {
    var retries = 0;
    await pumpBar(
      tester,
      state: const NarrationState(
        status: NarrationStatus.error,
        message: 'Não foi possível iniciar a narração',
      ),
      onRetry: () => retries++,
    );

    expect(find.text('Não foi possível iniciar a narração'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Tentar iniciar a narração novamente'),
      findsOneWidget,
    );
    await tester.tap(
      find.bySemanticsLabel('Tentar iniciar a narração novamente'),
    );
    expect(retries, 1);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('loading disables controls with exact status label', (
    tester,
  ) async {
    await pumpBar(
      tester,
      state: const NarrationState(status: NarrationStatus.loading),
    );

    expect(find.text('Preparando narração'), findsOneWidget);
    expect(_button(tester, 'play-pause-narration').onPressed, isNull);
  });

  testWidgets('every control has Portuguese semantics and a 48px target', (
    tester,
  ) async {
    await pumpBar(
      tester,
      state: _state(NarrationStatus.playing, canPrevious: true, canNext: true),
    );

    for (final label in [
      'Trecho anterior',
      'Pausar narração',
      'Próximo trecho',
      'Configurações de voz e velocidade',
    ]) {
      final finder = find.bySemanticsLabel(label);
      expect(finder, findsOneWidget);
      final semantics = tester.getSemantics(finder);
      expect(semantics.flagsCollection.isButton, isTrue);
    }
    for (final key in [
      'previous-narration-block',
      'play-pause-narration',
      'next-narration-block',
      'narration-settings',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey(key)));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });
}

NarrationState _state(
  NarrationStatus status, {
  bool canPrevious = false,
  bool canNext = false,
  String? message,
}) => NarrationState(
  status: status,
  chapterTitle: 'Capítulo 1',
  canPrevious: canPrevious,
  canNext: canNext,
  message: message,
);

IconButton _button(WidgetTester tester, String key) =>
    tester.widget<IconButton>(find.byKey(ValueKey(key)));
