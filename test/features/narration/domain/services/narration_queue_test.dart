import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_queue.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

void main() {
  test(
    'flattens numeric source order, skips empty chapters, and keeps text',
    () {
      final queue = NarrationQueue.fromContent(_content());

      expect(
        queue.entries
            .map(
              (entry) => [
                entry.activeRunId,
                entry.chapterId,
                entry.blockId,
                entry.chapterTitle,
                entry.normalizedText,
              ],
            )
            .toList(),
        [
          ['run', 'z', 'block-z-0', 'Primeiro', 'Olá 👩🏽‍🚀'],
          ['run', 'z', 'block-z-1', 'Primeiro', '第二段'],
          ['run', 'a', 'block-a-0', 'Terceiro', 'Fim'],
        ],
      );
    },
  );

  test('first last previous next and lookup cross chapter boundaries', () {
    final queue = NarrationQueue.fromContent(_content());
    final first = queue.first!;
    final middle = queue.entryFor('z', 'block-z-1')!;
    final last = queue.last!;

    expect(first.blockId, 'block-z-0');
    expect(last.blockId, 'block-a-0');
    expect(queue.previous(first), isNull);
    expect(queue.next(first), middle);
    expect(queue.previous(last), middle);
    expect(queue.next(last), isNull);
  });

  test('foreign chapter block and entry identities return null', () {
    final queue = NarrationQueue.fromContent(_content());
    expect(queue.entryFor('foreign', 'block-z-0'), isNull);
    expect(queue.entryFor('z', 'foreign'), isNull);
    final foreign = NarrationQueueEntry(
      activeRunId: 'run',
      chapterId: 'foreign',
      blockId: 'foreign',
      chapterTitle: 'Foreign',
      normalizedText: 'Foreign',
    );
    expect(queue.previous(foreign), isNull);
    expect(queue.next(foreign), isNull);
  });

  test('all empty chapters produce exact empty boundaries', () {
    final queue = NarrationQueue.fromContent(_content(allEmpty: true));
    expect(queue.entries, isEmpty);
    expect(queue.isEmpty, isTrue);
    expect(queue.first, isNull);
    expect(queue.last, isNull);
  });
}

ReaderBookContent _content({bool allEmpty = false}) {
  ReaderChapter chapter(
    String id,
    String title,
    int order,
    List<String> texts,
  ) {
    final draft = ChapterDraft(
      id: id,
      title: title,
      sortOrder: order,
      startPage: order + 1,
      endPage: order + 1,
      cleanText: texts.join('\n'),
    );
    return ReaderChapter(
      chapter: draft,
      blocks: [
        for (var index = 0; index < texts.length; index++)
          NarrationBlockDraft(
            id: 'block-$id-$index',
            chapterId: id,
            sortOrder: index,
            originalText: texts[index],
            normalizedText: texts[index],
            characterCount: texts[index].runes.length,
            startPage: order + 1,
            endPage: order + 1,
          ),
      ],
    );
  }

  final chapters = [
    chapter('z', 'Primeiro', 0, allEmpty ? [] : ['Olá 👩🏽‍🚀', '第二段']),
    chapter('empty', 'Vazio', 1, []),
    chapter('a', 'Terceiro', 2, allEmpty ? [] : ['Fim']),
  ];
  return ReaderBookContent(
    book: Book(
      id: 'book',
      title: 'Livro',
      originalFileName: 'livro.pdf',
      storedFilePath: '/livro.pdf',
      fileHash: 'hash',
      status: BookStatus.ready,
      processingProgress: 1,
      pageCount: 3,
      chapterCount: chapters.length,
      blockCount: chapters.fold(0, (sum, item) => sum + item.blocks.length),
      activeContentRunId: 'run',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
    chapters: chapters,
  );
}
