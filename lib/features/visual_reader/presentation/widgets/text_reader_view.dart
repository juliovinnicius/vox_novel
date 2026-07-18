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
    return Column(
      children: [
        Expanded(
          child: blocks.isEmpty
              ? const Center(child: Text('Este capítulo não possui texto'))
              : ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    final block = blocks[index];
                    final selected = block.id == selectedBlockId;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: 'Bloco ${index + 1}',
                      child: InkWell(
                        key: ValueKey('reader-block-${block.id}'),
                        onTap: () => onBlockSelected(block.id),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            block.originalText,
                            style: textStyle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPreviousChapter ? onPreviousChapter : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Capítulo anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasNextChapter ? onNextChapter : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Próximo capítulo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
