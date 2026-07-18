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
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
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

  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  });

  Future<ActiveProcessedContent?> readActiveContent(String bookId);
}
