import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';

void main() {
  late _ProcessingRepository processing;
  var nextId = 0;
  final createdAt = DateTime.utc(2026, 8, 17);

  ChapterIngest ingest() => ChapterIngest(
    processing: processing,
    chapterId: () => 'chapter-${++nextId}',
    blockId: () => 'block-${++nextId}',
  );

  ChapterDraft detected({
    String id = 'detected-1',
    String title = 'Capítulo 1',
    int sortOrder = 0,
    int page = 1,
    String cleanText = 'Primeiro parágrafo.',
  }) => ChapterDraft(
    id: id,
    title: title,
    sortOrder: sortOrder,
    startPage: page,
    endPage: page,
    cleanText: cleanText,
  );

  setUp(() {
    nextId = 0;
    processing = _ProcessingRepository();
  });

  test('reports the persisted chapter and block counts', () async {
    final result = await ingest().ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [
        detected(cleanText: 'Um parágrafo.\n\nOutro parágrafo.'),
        detected(id: 'detected-2', title: 'Capítulo 2', sortOrder: 1, page: 2),
      ],
      createdAt: createdAt,
    );

    expect(result, const IngestedChapters(chapterCount: 2, blockCount: 3));
    expect(processing.chapters, hasLength(2));
    expect(processing.blocks, hasLength(3));
  });

  test('assigns fresh ids and rewires blocks to their chapter', () async {
    await ingest().ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [
        detected(cleanText: 'Primeiro.'),
        detected(id: 'detected-2', title: 'Capítulo 2', sortOrder: 1, page: 2),
      ],
      createdAt: createdAt,
    );

    expect(processing.chapters.map((chapter) => chapter.id), [
      'chapter-1',
      'chapter-2',
    ]);
    expect(processing.blocks.map((block) => block.id), [
      'block-3',
      'block-4',
    ]);
    expect(processing.blocks.map((block) => block.chapterId), [
      'chapter-1',
      'chapter-2',
    ]);
  });

  test('preserves the chapter payload and page bounds verbatim', () async {
    await ingest().ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [
        detected(title: 'Capítulo 7', sortOrder: 6, page: 7, cleanText: 'Oi.'),
      ],
      createdAt: createdAt,
    );

    final chapter = processing.chapters.single;
    expect(
      [
        chapter.title,
        chapter.sortOrder,
        chapter.startPage,
        chapter.endPage,
        chapter.cleanText,
      ],
      ['Capítulo 7', 6, 7, 7, 'Oi.'],
    );
    final block = processing.blocks.single;
    expect(
      [
        block.sortOrder,
        block.originalText,
        block.normalizedText,
        block.startPage,
        block.endPage,
      ],
      [0, 'Oi.', 'Oi.', 7, 7],
    );
  });

  test('stages against the given run, book and timestamp', () async {
    await ingest().ingest(
      runId: 'run-9',
      bookId: 'book-9',
      chapters: [detected()],
      createdAt: createdAt,
    );

    expect(processing.stagings, [('run-9', 'book-9', createdAt)]);
  });

  test('a second ingest on one run appends instead of replacing', () async {
    final target = ingest();
    await target.ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [detected()],
      createdAt: createdAt,
    );

    final second = await target.ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [
        detected(id: 'detected-2', title: 'Capítulo 2', sortOrder: 1, page: 2),
      ],
      createdAt: createdAt,
    );

    expect(second, const IngestedChapters(chapterCount: 1, blockCount: 1));
    expect(processing.chapters.map((chapter) => chapter.title), [
      'Capítulo 1',
      'Capítulo 2',
    ]);
    expect(processing.blocks.map((block) => block.chapterId), [
      'chapter-1',
      'chapter-3',
    ]);
    expect(processing.stagings, hasLength(2));
  });

  test('an empty chapter list stages an empty batch and zero counts', () async {
    final result = await ingest().ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: const [],
      createdAt: createdAt,
    );

    expect(result, const IngestedChapters(chapterCount: 0, blockCount: 0));
    expect(processing.chapters, isEmpty);
    expect(processing.blocks, isEmpty);
  });

  test('onDrafts sees the final drafts before anything is staged', () async {
    var chapterIdsAtCallback = <String>[];
    var stagedWhenCalled = 0;

    await ingest().ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [detected()],
      createdAt: createdAt,
      onDrafts: (chapters, blocks) async {
        chapterIdsAtCallback = chapters.map((c) => c.id).toList();
        stagedWhenCalled = processing.stagings.length;
      },
    );

    expect(chapterIdsAtCallback, ['chapter-1']);
    expect(stagedWhenCalled, 0);
    expect(processing.stagings, hasLength(1));
  });

  test('an onDrafts failure aborts the ingest before staging', () async {
    await expectLater(
      ingest().ingest(
        runId: 'run-1',
        bookId: 'book-1',
        chapters: [detected()],
        createdAt: createdAt,
        onDrafts: (chapters, blocks) async => throw StateError('cancelled'),
      ),
      throwsA(isA<StateError>()),
    );

    expect(processing.stagings, isEmpty);
    expect(processing.chapters, isEmpty);
  });

  test('splits a long chapter into ordered blocks', () async {
    final result = await ingest().ingest(
      runId: 'run-1',
      bookId: 'book-1',
      chapters: [detected(cleanText: 'Um.\n\nDois.\n\nTrês.')],
      createdAt: createdAt,
    );

    expect(result.blockCount, 3);
    expect(processing.blocks.map((block) => block.sortOrder), [0, 1, 2]);
    expect(processing.blocks.map((block) => block.originalText), [
      'Um.',
      'Dois.',
      'Três.',
    ]);
  });
}

final class _ProcessingRepository implements TextProcessingRepository {
  final chapters = <ChapterDraft>[];
  final blocks = <NarrationBlockDraft>[];
  final stagings = <(String, String, DateTime)>[];

  @override
  Future<void> stageChaptersAndBlocks({
    required String runId,
    required String bookId,
    required List<ChapterDraft> chapters,
    required List<NarrationBlockDraft> blocks,
    required DateTime createdAt,
  }) async {
    stagings.add((runId, bookId, createdAt));
    this.chapters.addAll(chapters);
    this.blocks.addAll(blocks);
  }

  @override
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
    ProcessingStage stage = ProcessingStage.extracting,
  }) async => throw UnimplementedError();

  @override
  Future<void> stageRawPage(String runId, RawPage page) async =>
      throw UnimplementedError();

  @override
  Stream<RawPage> streamRawPages(String runId) => throw UnimplementedError();

  @override
  Future<void> stageCleanPage(String runId, CleanPage page) async =>
      throw UnimplementedError();

  @override
  Future<void> updateProgress({
    required String bookId,
    required ProcessingStage stage,
    required double progress,
    required DateTime updatedAt,
  }) async => throw UnimplementedError();

  @override
  Future<void> activateRun({
    required String runId,
    required int pageCount,
    required int chapterCount,
    required int blockCount,
    required DateTime completedAt,
  }) async => throw UnimplementedError();

  @override
  Future<void> activatePartialRun({
    required String runId,
    required DateTime activatedAt,
  }) async => throw UnimplementedError();

  @override
  Future<void> updateRunCounts({
    required String runId,
    required int chapterCount,
    required int blockCount,
    required double progress,
    required DateTime updatedAt,
  }) async => throw UnimplementedError();

  @override
  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  }) async => throw UnimplementedError();

  @override
  Future<ActiveProcessedContent?> readActiveContent(String bookId) async =>
      throw UnimplementedError();
}
