import 'package:flutter/material.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({
    required this.settings,
    required this.onThemeChanged,
    required this.onFontFamilyChanged,
    required this.onLineHeightChanged,
    required this.onIncreaseFont,
    required this.onDecreaseFont,
    super.key,
  });

  final ReaderSettings settings;
  final ValueChanged<ReaderTheme> onThemeChanged;
  final ValueChanged<ReaderFontFamily> onFontFamilyChanged;
  final ValueChanged<double> onLineHeightChanged;
  final VoidCallback onIncreaseFont;
  final VoidCallback onDecreaseFont;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aparência', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            const Text('Tema'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _choice<ReaderTheme>(
                  label: 'Claro',
                  semanticLabel: 'Tema claro',
                  value: ReaderTheme.light,
                  selected: settings.theme,
                  onSelected: onThemeChanged,
                ),
                _choice<ReaderTheme>(
                  label: 'Sépia',
                  semanticLabel: 'Tema sépia',
                  value: ReaderTheme.sepia,
                  selected: settings.theme,
                  onSelected: onThemeChanged,
                ),
                _choice<ReaderTheme>(
                  label: 'Escuro',
                  semanticLabel: 'Tema escuro',
                  value: ReaderTheme.dark,
                  selected: settings.theme,
                  onSelected: onThemeChanged,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Fonte'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _choice<ReaderFontFamily>(
                  label: 'Sem serifa',
                  semanticLabel: 'Fonte sem serifa',
                  value: ReaderFontFamily.sans,
                  selected: settings.fontFamily,
                  onSelected: onFontFamilyChanged,
                ),
                _choice<ReaderFontFamily>(
                  label: 'Serifada',
                  semanticLabel: 'Fonte serifada',
                  value: ReaderFontFamily.serif,
                  selected: settings.fontFamily,
                  onSelected: onFontFamilyChanged,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Tamanho da fonte'),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('decrease-font'),
                  tooltip: 'Diminuir tamanho da fonte',
                  onPressed: settings.fontSize == 14 ? null : onDecreaseFont,
                  icon: const Icon(Icons.remove),
                ),
                Semantics(
                  label: 'Tamanho atual ${settings.fontSize}',
                  child: SizedBox(
                    width: 48,
                    child: Text(
                      '${settings.fontSize}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('increase-font'),
                  tooltip: 'Aumentar tamanho da fonte',
                  onPressed: settings.fontSize == 32 ? null : onIncreaseFont,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Espaçamento entre linhas'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final height in const [1.2, 1.5, 1.8, 2.0])
                  _choice<double>(
                    label: height.toStringAsFixed(1).replaceAll('.', ','),
                    semanticLabel:
                        'Espaçamento ${height.toStringAsFixed(1).replaceAll('.', ',')}',
                    value: height,
                    selected: settings.lineHeight,
                    onSelected: onLineHeightChanged,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice<T>({
    required String label,
    required String semanticLabel,
    required T value,
    required T selected,
    required ValueChanged<T> onSelected,
  }) => Semantics(
    label: semanticLabel,
    selected: value == selected,
    button: true,
    excludeSemantics: true,
    child: ChoiceChip(
      label: Text(label),
      selected: value == selected,
      onSelected: (_) => onSelected(value),
    ),
  );
}
