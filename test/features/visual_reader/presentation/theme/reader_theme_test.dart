import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/presentation/theme/reader_theme.dart';

void main() {
  double contrast(Color first, Color second) {
    final lighter = first.computeLuminance() > second.computeLuminance()
        ? first
        : second;
    final darker = identical(lighter, first) ? second : first;
    return (lighter.computeLuminance() + 0.05) /
        (darker.computeLuminance() + 0.05);
  }

  test('all palettes meet normal-text contrast and distinguish selection', () {
    for (final theme in ReaderTheme.values) {
      final palette = ReaderVisualTheme.palette(theme);
      expect(
        contrast(palette.background, palette.foreground),
        greaterThan(4.5),
      );
      expect(
        contrast(palette.selectedBackground, palette.selectedForeground),
        greaterThan(4.5),
      );
      expect(palette.selectedBackground, isNot(palette.background));
    }
  });

  test('typography applies exact family, size, height, and theme color', () {
    final settings = ReaderSettings(
      theme: ReaderTheme.sepia,
      fontFamily: ReaderFontFamily.serif,
      fontSize: 26,
      lineHeight: 1.8,
    );
    final style = ReaderVisualTheme.textStyle(settings);

    expect(style.fontFamily, 'serif');
    expect(style.fontSize, 26);
    expect(style.height, 1.8);
    expect(style.color, ReaderVisualTheme.sepia.foreground);
  });
}
