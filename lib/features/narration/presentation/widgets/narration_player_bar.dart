import 'package:flutter/material.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_state.dart';

/// The narration controls at the bottom of the reader.
///
/// The bar has two heights. Collapsed — the default — is a single strip with
/// the chapter, play/pause and a handle; the queue and voice controls live one
/// tap away. Expanded is the full transport. Reading is the primary activity,
/// so the bar gives the page back ~60dp until the reader asks for more.
class NarrationPlayerBar extends StatefulWidget {
  const NarrationPlayerBar({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
    required this.onRetry,
    this.initiallyExpanded = false,
    super.key,
  });

  final NarrationState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;
  final VoidCallback onRetry;
  final bool initiallyExpanded;

  @override
  State<NarrationPlayerBar> createState() => _NarrationPlayerBarState();
}

class _NarrationPlayerBarState extends State<NarrationPlayerBar> {
  late bool _expanded = widget.initiallyExpanded;

  NarrationState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded ? _expandedBar(context) : _collapsedBar(context),
          ),
        ),
      ),
    );
  }

  /// One strip: what is playing, one control to stop it, one handle to get the
  /// rest. An error keeps its retry here too — it is the only way forward.
  Widget _collapsedBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
    child: Row(
      children: [
        _StatusDot(status: state.status),
        const SizedBox(width: 10),
        Expanded(child: _headlineBlock(context, dense: true)),
        if (state.status == NarrationStatus.error)
          _retryButton()
        else
          _playButton(context, size: 48, iconSize: 24),
        _toggle(),
      ],
    ),
  );

  Widget _expandedBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 8, 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _StatusDot(status: state.status),
            const SizedBox(width: 10),
            Expanded(child: _headlineBlock(context, dense: false)),
            _control(
              key: const ValueKey('narration-settings'),
              label: 'Configurações de voz e velocidade',
              onPressed: _canNavigate ? widget.onSettings : null,
              icon: Icons.tune_rounded,
            ),
            _toggle(),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _control(
              key: const ValueKey('previous-narration-block'),
              label: 'Trecho anterior',
              onPressed: _canNavigate && state.canPrevious
                  ? widget.onPrevious
                  : null,
              icon: Icons.skip_previous_rounded,
              size: 28,
            ),
            const SizedBox(width: 12),
            _playButton(context, size: 56, iconSize: 30),
            const SizedBox(width: 12),
            _control(
              key: const ValueKey('next-narration-block'),
              label: 'Próximo trecho',
              onPressed:
                  _canNavigate &&
                      state.status != NarrationStatus.completed &&
                      state.status != NarrationStatus.awaitingDownload &&
                      state.canNext
                  ? widget.onNext
                  : null,
              icon: Icons.skip_next_rounded,
              size: 28,
            ),
            if (state.status == NarrationStatus.error) ...[
              const SizedBox(width: 12),
              _retryButton(),
            ],
          ],
        ),
      ],
    ),
  );

  /// Tapping the headline is a second, larger target for the same toggle.
  Widget _headlineBlock(BuildContext context, {required bool dense}) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: _toggleLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: _toggleExpanded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.message case final message?)
                Text(
                  message,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: state.status == NarrationStatus.error
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle() => _control(
    key: const ValueKey('toggle-narration-controls'),
    label: _toggleLabel,
    onPressed: _toggleExpanded,
    icon: _expanded
        ? Icons.keyboard_arrow_down_rounded
        : Icons.keyboard_arrow_up_rounded,
    size: 24,
  );

  Widget _playButton(
    BuildContext context, {
    required double size,
    required double iconSize,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: _playLabel,
      button: true,
      enabled: _playAction != null,
      excludeSemantics: true,
      child: IconButton.filled(
        key: const ValueKey('play-pause-narration'),
        tooltip: _playLabel,
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        iconSize: iconSize,
        style: IconButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurfaceVariant.withValues(
            alpha: 0.14,
          ),
          disabledForegroundColor: scheme.onSurfaceVariant,
          shape: const CircleBorder(),
        ),
        onPressed: _playAction,
        icon: Icon(_playIcon),
      ),
    );
  }

  Widget _retryButton() => Semantics(
    button: true,
    label: 'Tentar iniciar a narração novamente',
    excludeSemantics: true,
    child: ConstrainedBox(
      constraints: _targetConstraints,
      child: FilledButton(
        onPressed: widget.onRetry,
        child: const Text('Tentar novamente'),
      ),
    ),
  );

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  String get _toggleLabel => _expanded
      ? 'Ocultar controles de narração'
      : 'Mostrar controles de narração';

  bool get _canNavigate => switch (state.status) {
    NarrationStatus.ready ||
    NarrationStatus.playing ||
    NarrationStatus.paused ||
    NarrationStatus.completed ||
    NarrationStatus.awaitingDownload => true,
    _ => false,
  };

  String get _headline => switch (state.status) {
    NarrationStatus.initial => 'Narração',
    NarrationStatus.loading => 'Preparando narração',
    NarrationStatus.unavailable => 'Narração indisponível',
    NarrationStatus.error => 'Erro na narração',
    NarrationStatus.completed => state.chapterTitle ?? 'Narração concluída',
    NarrationStatus.awaitingDownload => 'Próximo capítulo ainda não baixado',
    _ => state.chapterTitle ?? 'Narração',
  };

  String get _playLabel => switch (state.status) {
    NarrationStatus.ready => 'Reproduzir narração',
    NarrationStatus.playing => 'Pausar narração',
    NarrationStatus.paused => 'Retomar narração',
    NarrationStatus.completed => 'Narração concluída',
    NarrationStatus.awaitingDownload => 'Aguardando o próximo capítulo',
    NarrationStatus.unavailable => 'Narração indisponível',
    NarrationStatus.error => 'Narração indisponível',
    NarrationStatus.loading => 'Narração carregando',
    NarrationStatus.initial => 'Narração ainda não disponível',
  };

  VoidCallback? get _playAction => switch (state.status) {
    NarrationStatus.ready || NarrationStatus.paused => widget.onPlay,
    NarrationStatus.playing => widget.onPause,
    _ => null,
  };

  IconData get _playIcon => switch (state.status) {
    NarrationStatus.playing => Icons.pause,
    NarrationStatus.completed => Icons.check,
    NarrationStatus.awaitingDownload => Icons.hourglass_empty,
    _ => Icons.play_arrow,
  };

  Widget _control({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    required IconData icon,
    double size = 22,
  }) => Semantics(
    label: label,
    button: true,
    enabled: onPressed != null,
    excludeSemantics: true,
    child: IconButton(
      key: key,
      tooltip: label,
      constraints: _targetConstraints,
      iconSize: size,
      onPressed: onPressed,
      icon: Icon(icon),
    ),
  );
}

const _targetConstraints = BoxConstraints(minWidth: 48, minHeight: 48);

/// A quiet colour cue for the narration's state, so the bar reads at a glance
/// without another line of text.
final class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final NarrationStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      NarrationStatus.playing => scheme.primary,
      NarrationStatus.paused || NarrationStatus.ready =>
        scheme.onSurfaceVariant,
      NarrationStatus.error || NarrationStatus.unavailable => scheme.error,
      NarrationStatus.completed => scheme.primary.withValues(alpha: 0.5),
      _ => scheme.outline,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: status == NarrationStatus.playing
            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
            : null,
      ),
    );
  }
}
