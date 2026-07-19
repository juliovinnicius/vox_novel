import 'package:flutter/material.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';

class NarrationSettingsSheet extends StatelessWidget {
  const NarrationSettingsSheet({
    required this.state,
    required this.onVoiceSelected,
    required this.onVoicePreview,
    required this.onBookOverrideChanged,
    required this.onRateChanged,
    super.key,
  });

  final NarrationState state;
  final ValueChanged<NarrationVoice> onVoiceSelected;
  final ValueChanged<NarrationVoice> onVoicePreview;
  final ValueChanged<bool> onBookOverrideChanged;
  final ValueChanged<double> onRateChanged;

  @override
  Widget build(BuildContext context) {
    final voices = [...state.voices]
      ..sort((left, right) {
        final locale = left.locale.compareTo(right.locale);
        return locale != 0 ? locale : left.name.compareTo(right.name);
      });
    final rate = state.settings?.rate ?? 1.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voz e velocidade',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Usar ajustes de narração para este livro',
              toggled: state.usesBookOverride,
              excludeSemantics: true,
              child: SwitchListTile(
                key: const ValueKey('narration-book-scope'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Usar ajustes para este livro'),
                value: state.usesBookOverride,
                onChanged: onBookOverrideChanged,
              ),
            ),
            const SizedBox(height: 12),
            Text('Voz', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Column(
              key: const ValueKey('narration-voice-list'),
              children: [for (final voice in voices) _voiceRow(context, voice)],
            ),
            const SizedBox(height: 16),
            Text('Velocidade', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                _rateButton(
                  key: const ValueKey('decrease-narration-rate'),
                  label: 'Diminuir velocidade da narração',
                  icon: Icons.remove,
                  onPressed: rate <= 0.5
                      ? null
                      : () => onRateChanged(_step(rate, -1)),
                ),
                Semantics(
                  label:
                      'Velocidade atual ${rate.toStringAsFixed(1).replaceAll('.', ',')}',
                  child: SizedBox(
                    width: 72,
                    child: Text(
                      '${rate.toStringAsFixed(1).replaceAll('.', ',')}×',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                _rateButton(
                  key: const ValueKey('increase-narration-rate'),
                  label: 'Aumentar velocidade da narração',
                  icon: Icons.add,
                  onPressed: rate >= 2.0
                      ? null
                      : () => onRateChanged(_step(rate, 1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceRow(BuildContext context, NarrationVoice voice) {
    final selected = state.settings?.voice == voice;
    final identity = '${voice.name}, ${voice.locale}';

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Voz $identity',
            selected: selected,
            button: true,
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: _targetConstraints,
              child: InkWell(
                key: ValueKey('voice-${voice.name}-${voice.locale}'),
                onTap: () => onVoiceSelected(voice),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(voice.name)),
                      Text(voice.locale),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          label: 'Ouvir amostra de $identity',
          button: true,
          excludeSemantics: true,
          child: IconButton(
            key: ValueKey('preview-${voice.name}-${voice.locale}'),
            tooltip: 'Ouvir amostra de $identity',
            constraints: _targetConstraints,
            onPressed: () => onVoicePreview(voice),
            icon: const Icon(Icons.volume_up_outlined),
          ),
        ),
      ],
    );
  }

  Widget _rateButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => Semantics(
    label: label,
    button: true,
    enabled: onPressed != null,
    excludeSemantics: true,
    child: IconButton(
      key: key,
      tooltip: label,
      constraints: _targetConstraints,
      onPressed: onPressed,
      icon: Icon(icon),
    ),
  );

  double _step(double rate, int direction) =>
      ((rate * 10).round() + direction) / 10;
}

const _targetConstraints = BoxConstraints(minWidth: 48, minHeight: 48);
