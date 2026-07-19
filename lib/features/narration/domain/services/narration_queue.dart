import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

final class NarrationQueue {
  NarrationQueue.fromContent(ReaderBookContent content)
    : entries = List.unmodifiable([
        for (final chapter in content.chapters)
          for (final block in chapter.blocks)
            NarrationQueueEntry(
              activeRunId: content.book.activeContentRunId!,
              chapterId: chapter.chapter.id,
              blockId: block.id,
              chapterTitle: chapter.chapter.title,
              normalizedText: block.normalizedText,
            ),
      ]);

  final List<NarrationQueueEntry> entries;

  bool get isEmpty => entries.isEmpty;
  NarrationQueueEntry? get first => entries.firstOrNull;
  NarrationQueueEntry? get last => entries.lastOrNull;

  NarrationQueueEntry? entryFor(String chapterId, String blockId) => entries
      .where(
        (entry) => entry.chapterId == chapterId && entry.blockId == blockId,
      )
      .firstOrNull;

  NarrationQueueEntry? previous(NarrationQueueEntry entry) =>
      _relative(entry, -1);

  NarrationQueueEntry? next(NarrationQueueEntry entry) => _relative(entry, 1);

  NarrationQueueEntry? _relative(NarrationQueueEntry entry, int offset) {
    final index = entries.indexWhere(
      (candidate) =>
          candidate.chapterId == entry.chapterId &&
          candidate.blockId == entry.blockId,
    );
    final target = index + offset;
    return index < 0 || target < 0 || target >= entries.length
        ? null
        : entries[target];
  }
}
