import 'package:flutter/material.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

@immutable
final class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.foreground,
    required this.selectedBackground,
    required this.selectedForeground,
  });

  final Color background;
  final Color foreground;
  final Color selectedBackground;
  final Color selectedForeground;
}

abstract final class ReaderVisualTheme {
  static const light = ReaderPalette(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF1B1B1B),
    selectedBackground: Color(0xFFFFE7C2),
    selectedForeground: Color(0xFF3A2506),
  );

  static const sepia = ReaderPalette(
    background: Color(0xFFF8F1DF),
    foreground: Color(0xFF3C2F20),
    selectedBackground: Color(0xFFE4CFA3),
    selectedForeground: Color(0xFF2A1D0E),
  );

  static const dark = ReaderPalette(
    background: Color(0xFF14120F),
    foreground: Color(0xFFEDE5D8),
    selectedBackground: Color(0xFF4A3A22),
    selectedForeground: Color(0xFFFFF3DF),
  );

  static ReaderPalette palette(ReaderTheme theme) => switch (theme) {
    ReaderTheme.light => light,
    ReaderTheme.sepia => sepia,
    ReaderTheme.dark => dark,
  };

  /// The reader's chrome — app bar, drawer, sheets, player bar — repainted in
  /// the paper palette the reader chose.
  ///
  /// Without this the app's dark chrome framed a sepia or white page, and the
  /// two never looked like the same screen.
  static ThemeData chrome(ThemeData base, ReaderPalette palette) {
    final onPaper = ThemeData.estimateBrightnessForColor(palette.background);
    Color ink(double amount) =>
        Color.lerp(palette.background, palette.foreground, amount)!;
    final scheme = base.colorScheme.copyWith(
      brightness: onPaper,
      surface: palette.background,
      onSurface: palette.foreground,
      onSurfaceVariant: ink(0.68),
      surfaceContainerLowest: ink(0.02),
      surfaceContainerLow: ink(0.04),
      surfaceContainer: ink(0.06),
      surfaceContainerHigh: ink(0.09),
      surfaceContainerHighest: ink(0.12),
      outline: ink(0.35),
      outlineVariant: ink(0.14),
      primaryContainer: palette.selectedBackground,
      onPrimaryContainer: palette.selectedForeground,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: palette.background,
        foregroundColor: palette.foreground,
      ),
      dividerTheme: base.dividerTheme.copyWith(color: scheme.outlineVariant),
      iconTheme: base.iconTheme.copyWith(color: scheme.onSurfaceVariant),
      drawerTheme: base.drawerTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLow,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLow,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.foreground,
        displayColor: palette.foreground,
      ),
    );
  }

  static TextStyle textStyle(ReaderSettings settings) => TextStyle(
    color: palette(settings.theme).foreground,
    fontFamily: switch (settings.fontFamily) {
      ReaderFontFamily.sans => 'sans-serif',
      ReaderFontFamily.serif => 'serif',
    },
    fontSize: settings.fontSize.toDouble(),
    height: settings.lineHeight,
  );
}
