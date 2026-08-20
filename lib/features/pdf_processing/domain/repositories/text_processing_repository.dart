import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

final class ActiveProcessedContent {
  const ActiveProcessedContent({
    required this.rawPages,
    required this.cleanPages,
    required this.chapters,
    required this.blocks,
  });

  final List<RawPage> rawPages;
  final List<CleanPage> cleanPages;
  final List<ChapterDraft> chapters;
  final List<NarrationBlockDraft> blocks;
}

abstract interface class TextProcessingRepository {
  /// Opens a staging run for [bookId].
  ///
  /// [stage] is the stage the book enters. A paged source starts extracting; a
  /// chaptered source starts downloading, and must say so here because
  /// `updateProgress` refuses to move a book to an earlier stage than the one
  /// it already carries.
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
    ProcessingStage stage = ProcessingStage.extracting,
  });

  Future<void> stageRawPage(String runId, RawPage page);
  Stream<RawPage> streamRawPages(String runId);
  Future<void> stageCleanPage(String runId, CleanPage page);

  Future<void> stageChaptersAndBlocks({
    required String runId,
    required String bookId,
    required List<ChapterDraft> chapters,
    required List<NarrationBlockDraft> blocks,
    required DateTime createdAt,
  });

  Future<void> updateProgress({
    required String bookId,
    required ProcessingStage stage,
    required double progress,
    required DateTime updatedAt,
  });

  Future<void> activateRun({
    required String runId,
    required int pageCount,
    required int chapterCount,
    required int blockCount,
    required DateTime completedAt,
  });

  /// Makes [runId] the book's active content while it is still growing:
  /// the run becomes `active` but keeps no `completedAt`, and the book keeps
  /// its `processing` status.
  Future<void> activatePartialRun({
    required String runId,
    required DateTime activatedAt,
  });

  /// Refreshes the counts and progress of an already-active run.
  Future<void> updateRunCounts({
    required String runId,
    required int chapterCount,
    required int blockCount,
    required double progress,
    required DateTime updatedAt,
  });

  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  });

  Future<ActiveProcessedContent?> readActiveContent(String bookId);
}
