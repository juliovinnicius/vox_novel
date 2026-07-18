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
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'Capítulos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: chapters.isEmpty
                  ? const Center(child: Text('Nenhum capítulo disponível'))
                  : ListView.builder(
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index].chapter;
                        final current = chapter.id == currentChapterId;
                        return Semantics(
                          selected: current,
                          label: current
                              ? '${chapter.title}, capítulo atual'
                              : chapter.title,
                          child: ListTile(
                            key: ValueKey('chapter-${chapter.id}'),
                            selected: current,
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(chapter.title),
                            trailing: current
                                ? const Icon(
                                    Icons.check,
                                    semanticLabel: 'Capítulo atual',
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
