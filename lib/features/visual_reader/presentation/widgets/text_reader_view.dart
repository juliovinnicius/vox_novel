import 'package:flutter/material.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

class TextReaderView extends StatelessWidget {
  const TextReaderView({
    required this.chapter,
    required this.selectedBlockId,
    required this.onBlockSelected,
    required this.onPreviousChapter,
    required this.onNextChapter,
    required this.hasPreviousChapter,
    required this.hasNextChapter,
    this.controller,
    this.textStyle,
    super.key,
  });

  final ReaderChapter chapter;
  final String? selectedBlockId;
  final ValueChanged<String> onBlockSelected;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final bool hasPreviousChapter;
  final bool hasNextChapter;
  final ScrollController? controller;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final blocks = chapter.blocks;
    if (blocks.isEmpty) {
      return Column(
        children: [
          const Expanded(
            child: Center(child: Text('Este capítulo não possui texto')),
          ),
          SafeArea(top: false, child: _navigation(context)),
        ],
      );
    }
    // A measure this wide stays readable on a tablet; without it the
    // paragraphs stretch the full width of the screen.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          // Chapter navigation scrolls with the text instead of holding a
          // fixed strip at the bottom: it is only needed once per chapter,
          // and reading gets those ~68dp back.
          itemCount: blocks.length + 1,
          itemBuilder: (context, index) {
            if (index == blocks.length) {
              return SafeArea(top: false, child: _navigation(context));
            }
            final block = blocks[index];
            final selected = block.id == selectedBlockId;
            return Semantics(
              button: true,
              selected: selected,
              label: 'Bloco ${index + 1}',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  key: ValueKey('reader-block-${block.id}'),
                  onTap: () => onBlockSelected(block.id),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // SelectableText owns the pointer for text selection, so a
                    // tap never reached the InkWell above and choosing a
                    // paragraph did nothing. Its own onTap restores that
                    // without giving up copyable text.
                    child: SelectableText(
                      block.originalText,
                      style: selected
                          ? textStyle?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            )
                          : textStyle,
                      onTap: () => onBlockSelected(block.id),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _navigation(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasPreviousChapter ? onPreviousChapter : null,
            icon: const Icon(Icons.chevron_left, size: 20),
            label: const Text(
              'Capítulo anterior',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: hasNextChapter ? onNextChapter : null,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right, size: 20),
            label: const Text(
              'Próximo capítulo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );
}
