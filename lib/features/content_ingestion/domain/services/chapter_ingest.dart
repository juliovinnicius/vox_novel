import 'dart:async';

import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/chapter_detector.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/narration_block_splitter.dart';

final class IngestedChapters {
  const IngestedChapters({
    required this.chapterCount,
    required this.blockCount,
  });

  final int chapterCount;
  final int blockCount;

  @override
  bool operator ==(Object other) =>
      other is IngestedChapters &&
      other.chapterCount == chapterCount &&
      other.blockCount == blockCount;

  @override
  int get hashCode => Object.hash(chapterCount, blockCount);
}

/// Invoked with the drafts about to be persisted, before they are staged, so a
/// caller can report progress or abort the ingest.
typedef ChapterIngestDrafts =
    Future<void> Function(
      List<ChapterDraft> chapters,
      List<NarrationBlockDraft> blocks,
    );

typedef ChapterIngestExecutor =
    Future<T> Function<T>(FutureOr<T> Function() computation);

Future<T> inlineChapterIngestExecutor<T>(
  FutureOr<T> Function() computation,
) async => await computation();

/// Turns detected chapters into persisted chapters and narration blocks.
///
/// This is the single ingest path for every content source: a paged source
/// hands it the whole document at once, a chaptered source hands it one chapter
/// at a time. Repeated calls on one run append.
final class ChapterIngest {
  ChapterIngest({
    required TextProcessingRepository processing,
    required ProcessingIdGenerator chapterId,
    required ProcessingIdGenerator blockId,
    ChapterIngestExecutor cpu = inlineChapterIngestExecutor,
  }) : // Public dependency names intentionally omit private implementation
       // prefixes while preserving named constructor injection.
       // ignore: prefer_initializing_formals
       _processing = processing,
       // ignore: prefer_initializing_formals
       _chapterId = chapterId,
       // ignore: prefer_initializing_formals
       _blockId = blockId,
       // ignore: prefer_initializing_formals
       _cpu = cpu;

  final TextProcessingRepository _processing;
  final ProcessingIdGenerator _chapterId;
  final ProcessingIdGenerator _blockId;
  final ChapterIngestExecutor _cpu;

  Future<IngestedChapters> ingest({
    required String runId,
    required String bookId,
    required List<ChapterDraft> chapters,
    required DateTime createdAt,
    ChapterIngestDrafts? onDrafts,
  }) async {
    final chapterIds = <String, String>{};
    final chapterDrafts = [
      for (final chapter in chapters)
        ChapterDraft(
          id: chapterIds[chapter.id] = _chapterId(),
          title: chapter.title,
          sortOrder: chapter.sortOrder,
          startPage: chapter.startPage,
          endPage: chapter.endPage,
          cleanText: chapter.cleanText,
        ),
    ];
    final splitBlocks = await _cpu(() {
      final splitter = NarrationBlockSplitter(_workerId);
      return [for (final chapter in chapters) ...splitter.split(chapter)];
    });
    final blockDrafts = [
      for (final block in splitBlocks)
        NarrationBlockDraft(
          id: _blockId(),
          chapterId: chapterIds[block.chapterId]!,
          sortOrder: block.sortOrder,
          originalText: block.originalText,
          normalizedText: block.normalizedText,
          characterCount: block.characterCount,
          startPage: block.startPage,
          endPage: block.endPage,
        ),
    ];
    await onDrafts?.call(chapterDrafts, blockDrafts);
    await _processing.stageChaptersAndBlocks(
      runId: runId,
      bookId: bookId,
      chapters: chapterDrafts,
      blocks: blockDrafts,
      createdAt: createdAt,
    );
    return IngestedChapters(
      chapterCount: chapterDrafts.length,
      blockCount: blockDrafts.length,
    );
  }
}

var _workerIdSequence = 0;
String _workerId() => 'ingest-worker-${_workerIdSequence++}';
