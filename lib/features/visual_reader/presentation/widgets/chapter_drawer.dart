import 'package:flutter/material.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

class ChapterDrawer extends StatelessWidget {
  const ChapterDrawer({
    required this.chapters,
    required this.currentChapterId,
    required this.onChapterSelected,
    super.key,
  });

  final List<ReaderChapter> chapters;
  final String? currentChapterId;
  final ValueChanged<String> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Capítulos', style: theme.textTheme.titleMedium),
                        Text(
                          chapters.length == 1
                              ? '1 capítulo'
                              : '${chapters.length} capítulos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: chapters.isEmpty
                  ? const Center(child: Text('Nenhum capítulo disponível'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index].chapter;
                        final current = chapter.id == currentChapterId;
                        // The chapter's own number, not its position in the
                        // list: a web chapter that failed to download leaves a
                        // hole, and numbering by position would quietly shift
                        // every chapter after it.
                        final number = chapter.sortOrder + 1;
                        final label = '$number - ${chapter.title}';
                        return Semantics(
                          selected: current,
                          label: current ? '$label, capítulo atual' : label,
                          child: ListTile(
                            key: ValueKey('chapter-${chapter.id}'),
                            selected: current,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(
                              current
                                  ? Icons.play_circle_fill_rounded
                                  : Icons.article_outlined,
                              size: 20,
                              color: current
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: current
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: current
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: current
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    semanticLabel: 'Capítulo atual',
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              onChapterSelected(chapter.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
