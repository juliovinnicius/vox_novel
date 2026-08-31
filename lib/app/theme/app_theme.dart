import 'package:flutter/material.dart';

/// The app's visual identity: a dark-first reading environment in warm amber.
///
/// Both brightnesses are built here so the reader's own paper themes
/// (`ReaderVisualTheme`) sit on chrome that never clashes with them.
abstract final class AppTheme {
  /// Amber accent — the one colour the app is recognised by.
  static const seed = Color(0xFFE0A45C);

  static const _radius = 18.0;

  static ThemeData get dark => _build(_darkScheme);

  static ThemeData get light => _build(_lightScheme);

  static final _darkScheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: seed,
        onPrimary: const Color(0xFF3A2506),
        primaryContainer: const Color(0xFF5A3E14),
        onPrimaryContainer: const Color(0xFFFFDDAF),
        secondary: const Color(0xFFD7C3A5),
        onSecondary: const Color(0xFF3A2E1D),
        secondaryContainer: const Color(0xFF3A3123),
        onSecondaryContainer: const Color(0xFFEBDCC4),
        surface: const Color(0xFF14120F),
        onSurface: const Color(0xFFEDE5D8),
        surfaceContainerLowest: const Color(0xFF0E0D0A),
        surfaceContainerLow: const Color(0xFF1A1713),
        surfaceContainer: const Color(0xFF1E1B16),
        surfaceContainerHigh: const Color(0xFF272219),
        surfaceContainerHighest: const Color(0xFF322C22),
        onSurfaceVariant: const Color(0xFFB9AE9C),
        outline: const Color(0xFF6F6555),
        outlineVariant: const Color(0xFF3A342B),
      );

  static final _lightScheme =
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF8A5A12),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFFFDDAF),
        onPrimaryContainer: const Color(0xFF2C1700),
        surface: const Color(0xFFFBF6EE),
        onSurface: const Color(0xFF211D17),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFF6F0E6),
        surfaceContainer: const Color(0xFFF1EADD),
        surfaceContainerHigh: const Color(0xFFEBE3D4),
        surfaceContainerHighest: const Color(0xFFE5DCCB),
        onSurfaceVariant: const Color(0xFF5C5347),
        outline: const Color(0xFF8E8375),
        outlineVariant: const Color(0xFFDCD2C2),
      );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = _textTheme(base.textTheme);
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 3,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
        selectedColor: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledElevation: 0,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearMinHeight: 4,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) => base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    titleLarge: base.titleLarge?.copyWith(letterSpacing: -0.2),
    titleMedium: base.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    labelLarge: base.labelLarge?.copyWith(letterSpacing: 0),
    labelMedium: base.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );
}
