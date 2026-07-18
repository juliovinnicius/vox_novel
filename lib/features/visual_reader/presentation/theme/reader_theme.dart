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
    selectedBackground: Color(0xFFD7E3FF),
    selectedForeground: Color(0xFF001B3F),
  );

  static const sepia = ReaderPalette(
    background: Color(0xFFF8F1DF),
    foreground: Color(0xFF3C2F20),
    selectedBackground: Color(0xFFE4CFA3),
    selectedForeground: Color(0xFF2A1D0E),
  );

  static const dark = ReaderPalette(
    background: Color(0xFF151515),
    foreground: Color(0xFFF2F2F2),
    selectedBackground: Color(0xFF31475E),
    selectedForeground: Color(0xFFFFFFFF),
  );

  static ReaderPalette palette(ReaderTheme theme) => switch (theme) {
    ReaderTheme.light => light,
    ReaderTheme.sepia => sepia,
    ReaderTheme.dark => dark,
  };

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
