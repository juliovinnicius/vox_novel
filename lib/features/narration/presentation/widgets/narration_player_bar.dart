import 'package:flutter/material.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';

class NarrationPlayerBar extends StatelessWidget {
  const NarrationPlayerBar({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
    required this.onRetry,
    super.key,
  });

  final NarrationState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final canNavigate = switch (status) {
      NarrationStatus.ready ||
      NarrationStatus.playing ||
      NarrationStatus.paused ||
      NarrationStatus.completed => true,
      _ => false,
    };
    final canOpenSettings = switch (status) {
      NarrationStatus.ready ||
      NarrationStatus.playing ||
      NarrationStatus.paused ||
      NarrationStatus.completed => true,
      _ => false,
    };

    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (state.message case final message?) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _control(
                    key: const ValueKey('previous-narration-block'),
                    label: 'Trecho anterior',
                    onPressed: canNavigate && state.canPrevious
                        ? onPrevious
                        : null,
                    icon: Icons.skip_previous,
                  ),
                  _control(
                    key: const ValueKey('play-pause-narration'),
                    label: _playLabel,
                    onPressed: _playAction,
                    icon: _playIcon,
                  ),
                  _control(
                    key: const ValueKey('next-narration-block'),
                    label: 'Próximo trecho',
                    onPressed:
                        canNavigate &&
                            status != NarrationStatus.completed &&
                            state.canNext
                        ? onNext
                        : null,
                    icon: Icons.skip_next,
                  ),
                  _control(
                    key: const ValueKey('narration-settings'),
                    label: 'Configurações de voz e velocidade',
                    onPressed: canOpenSettings ? onSettings : null,
                    icon: Icons.record_voice_over_outlined,
                  ),
                  if (status == NarrationStatus.error)
                    Semantics(
                      button: true,
                      label: 'Tentar iniciar a narração novamente',
                      excludeSemantics: true,
                      child: ConstrainedBox(
                        constraints: _targetConstraints,
                        child: FilledButton(
                          onPressed: onRetry,
                          child: const Text('Tentar novamente'),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _headline => switch (state.status) {
    NarrationStatus.initial => 'Narração',
    NarrationStatus.loading => 'Preparando narração',
    NarrationStatus.unavailable => 'Narração indisponível',
    NarrationStatus.error => 'Erro na narração',
    NarrationStatus.completed => state.chapterTitle ?? 'Narração concluída',
    _ => state.chapterTitle ?? 'Narração',
  };

  String get _playLabel => switch (state.status) {
    NarrationStatus.ready => 'Reproduzir narração',
    NarrationStatus.playing => 'Pausar narração',
    NarrationStatus.paused => 'Retomar narração',
    NarrationStatus.completed => 'Narração concluída',
    NarrationStatus.unavailable => 'Narração indisponível',
    NarrationStatus.error => 'Narração indisponível',
    NarrationStatus.loading => 'Narração carregando',
    NarrationStatus.initial => 'Narração ainda não disponível',
  };

  VoidCallback? get _playAction => switch (state.status) {
    NarrationStatus.ready || NarrationStatus.paused => onPlay,
    NarrationStatus.playing => onPause,
    _ => null,
  };

  IconData get _playIcon => switch (state.status) {
    NarrationStatus.playing => Icons.pause,
    NarrationStatus.completed => Icons.check,
    _ => Icons.play_arrow,
  };

  Widget _control({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
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
}

const _targetConstraints = BoxConstraints(minWidth: 48, minHeight: 48);
