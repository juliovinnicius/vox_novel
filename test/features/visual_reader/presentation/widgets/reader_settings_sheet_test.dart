import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/reader_settings_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required ReaderSettings settings,
    ValueChanged<ReaderTheme>? onTheme,
    ValueChanged<ReaderFontFamily>? onFamily,
    ValueChanged<double>? onHeight,
    VoidCallback? onIncrease,
    VoidCallback? onDecrease,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReaderSettingsSheet(
          settings: settings,
          onThemeChanged: onTheme ?? (_) {},
          onFontFamilyChanged: onFamily ?? (_) {},
          onLineHeightChanged: onHeight ?? (_) {},
          onIncreaseFont: onIncrease ?? () {},
          onDecreaseFont: onDecrease ?? () {},
        ),
      ),
    ),
  );

  testWidgets('exposes exact values and accessible labels', (tester) async {
    await pumpSheet(
      tester,
      settings: ReaderSettings(
        theme: ReaderTheme.sepia,
        fontFamily: ReaderFontFamily.serif,
        fontSize: 22,
        lineHeight: 1.8,
      ),
    );

    expect(find.text('22'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Tema sépia'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Fonte serifada'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(find.bySemanticsLabel('Espaçamento 1,8'), findsOneWidget);
  });

  testWidgets('size actions emit once and disable exactly at bounds', (
    tester,
  ) async {
    var increases = 0;
    var decreases = 0;
    await pumpSheet(
      tester,
      settings: ReaderSettings.defaults(),
      onIncrease: () => increases++,
      onDecrease: () => decreases++,
    );
    await tester.tap(find.byKey(const ValueKey('increase-font')));
    await tester.tap(find.byKey(const ValueKey('decrease-font')));
    expect((increases, decreases), (1, 1));

    await pumpSheet(
      tester,
      settings: ReaderSettings.defaults().copyWith(fontSize: 14),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('decrease-font')))
          .onPressed,
      isNull,
    );

    await pumpSheet(
      tester,
      settings: ReaderSettings.defaults().copyWith(fontSize: 32),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('increase-font')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('only emits choices from the allowed domain values', (
    tester,
  ) async {
    ReaderTheme? theme;
    ReaderFontFamily? family;
    double? height;
    await pumpSheet(
      tester,
      settings: ReaderSettings.defaults(),
      onTheme: (value) => theme = value,
      onFamily: (value) => family = value,
      onHeight: (value) => height = value,
    );

    await tester.tap(find.bySemanticsLabel('Tema escuro'));
    await tester.tap(find.bySemanticsLabel('Fonte serifada'));
    await tester.tap(find.bySemanticsLabel('Espaçamento 2,0'));

    expect(theme, ReaderTheme.dark);
    expect(family, ReaderFontFamily.serif);
    expect(height, 2.0);
    expect(ReaderTheme.values, contains(theme));
    expect(ReaderFontFamily.values, contains(family));
    expect(const [1.2, 1.5, 1.8, 2.0], contains(height));
  });
}
