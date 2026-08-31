import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

/// The visual vocabulary shared by the library's list and grid items.

/// A generated cover: novels imported from a PDF or a site have no artwork, so
/// the tile is derived from the book's own id — the same book always gets the
/// same pair of hues.
final class BookCover extends StatelessWidget {
  const BookCover({required this.book, this.size = 56, super.key});

  final Book book;

  /// The tile's shorter side; the grid passes it through a fixed aspect ratio.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = _gradients[_slot];
    final radius = BorderRadius.circular(size < 80 ? 12 : 16);
    return Container(
      width: size,
      height: size * 1.35,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              _initials,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: size * 0.42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Icon(
              book.sourceType == BookSourceType.web
                  ? Icons.public
                  : Icons.picture_as_pdf,
              size: size * 0.22,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  int get _slot {
    var hash = 0;
    for (final unit in book.id.codeUnits) {
      hash = (hash * 31 + unit) % 1000;
    }
    return hash % _gradients.length;
  }

  String get _initials {
    final words = book.title
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words[1].substring(0, 1))
        .toUpperCase();
  }
}

/// Muted, earthy pairs picked by hand: a generated hue wandered into teals
/// and blues that fought the app's warm palette.
const _gradients = <List<Color>>[
  [Color(0xFF4A3A22), Color(0xFF241B10)],
  [Color(0xFF43302C), Color(0xFF211614)],
  [Color(0xFF2C3A33), Color(0xFF141F1A)],
  [Color(0xFF333A48), Color(0xFF181C24)],
  [Color(0xFF433040), Color(0xFF211820)],
  [Color(0xFF3D3A27), Color(0xFF1E1C13)],
];

/// The status pill. Ready books get no pill: "Pronto" is the norm, and a badge
/// on every row would say nothing.
final class BookStatusChip extends StatelessWidget {
  const BookStatusChip({required this.status, required this.label, super.key});

  final BookStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      BookStatus.ready => (
        scheme.primary.withValues(alpha: 0.16),
        scheme.primary,
      ),
      BookStatus.importing || BookStatus.processing => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      BookStatus.failed || BookStatus.unsupported => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// The progress line of a running import: its label above a slim bar.
final class BookProgressLine extends StatelessWidget {
  const BookProgressLine({
    required this.label,
    required this.progress,
    super.key,
  });

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress, minHeight: 4),
        ),
      ],
    );
  }
}

/// A library action rendered small enough that four of them still fit a grid
/// card, without dropping below the 40px touch target.
final class BookAction extends StatelessWidget {
  const BookAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      iconSize: 20,
      style: emphasized
          ? IconButton.styleFrom(
              backgroundColor: scheme.primary.withValues(alpha: 0.16),
              foregroundColor: scheme.primary,
            )
          : null,
      icon: Icon(icon),
    );
  }
}
