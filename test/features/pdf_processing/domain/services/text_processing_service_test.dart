import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18);
  late _BookRepository books;
  late _ProcessingRepository processing;
  late _Extractor extractor;
  var nextId = 0;

  TextProcessingService service() => TextProcessingService(
    books: books,
    processing: processing,
    extractor: extractor,
    cleaner: const TextCleaner(),
    chapterId: () => 'chapter-${++nextId}',
    blockId: () => 'block-${++nextId}',
    clock: () => now,
    runId: () => 'run-${++nextId}',
  );

  setUp(() {
    nextId = 0;
    books = _BookRepository(_book(now));
    processing = _ProcessingRepository();
    extractor = _Extractor([
      const PdfExtractionOpened('ignored', 2, 42),
      const PdfExtractionPage('ignored', 1, 2, 'Capítulo 1\nTexto.'),
      const PdfExtractionPage('ignored', 2, 2, 'Outro parágrafo.'),
      const PdfExtractionCompleted('ignored', 2),
    ]);
  });

  test(
    'selectable text completes with exact durable content and counts',
    () async {
      final result = await service().process('book-1');

      expect(result, const ProcessingResult.completed());
      expect(processing.activated, [2, 1, 1]);
      expect(processing.rawPages.map((page) => page.text), [
        'Capítulo 1\nTexto.',
        'Outro parágrafo.',
      ]);
      expect(processing.cleanPages.map((page) => page.text), [
        'Capítulo 1\nTexto.',
        'Outro parágrafo.',
      ]);
      expect(processing.chapters.single.title, 'Capítulo 1');
      expect(processing.blocks.single.originalText, 'Texto.\nOutro parágrafo.');
    },
  );

  test('CPU-bound pipeline work executes outside the caller isolate', () async {
    final caller = Isolate.current.hashCode;
    final workers = <int>[];
    final target = TextProcessingService(
      books: books,
      processing: processing,
      extractor: extractor,
      cleaner: const TextCleaner(),
      chapterId: () => 'chapter-worker',
      blockId: () => 'block-worker',
      clock: () => now,
      runId: () => 'run-worker',
      executor: isolateProcessingExecutor,
      onCpuWorkerIsolate: workers.add,
    );

    expect(await target.process('book-1'), const ProcessingResult.completed());
    expect(workers, isNotEmpty);
    expect(workers.every((identity) => identity != caller), isTrue);
    expect(processing.activated, [2, 1, 1]);
  });

  test('pipeline exposes exact monotonic stage ranges incrementally', () async {
    await service().process('book-1');

    expect(processing.progress, [
      (ProcessingStage.extracting, .2),
      (ProcessingStage.extracting, .4),
      (ProcessingStage.cleaning, .4),
      (ProcessingStage.cleaning, .5),
      (ProcessingStage.cleaning, .6),
      (ProcessingStage.detectingChapters, .675),
      (ProcessingStage.detectingChapters, .75),
      (ProcessingStage.buildingBlocks, .95),
      (ProcessingStage.completing, .95),
    ]);
  });

  test(
    'zero non-whitespace text is unsupported and leaves no staging',
    () async {
      extractor.events = [
        const PdfExtractionOpened('ignored', 1, 42),
        const PdfExtractionPage('ignored', 1, 1, ' \n\t'),
        const PdfExtractionCompleted('ignored', 1),
      ];

      final result = await service().process('book-1');

      expect(
        result,
        const ProcessingResult.unsupported(
          'Este PDF não possui texto extraível',
        ),
      );
      expect(processing.discards, [('run-1', BookStatus.unsupported)]);
      expect(processing.activated, isNull);
    },
  );

  test('parser failure is sanitized and discards partial staging', () async {
    extractor.events = [
      const PdfExtractionOpened('ignored', 1, 42),
      const PdfExtractionFailed('ignored', PdfExtractionFailureKind.corrupt),
    ];

    final result = await service().process('book-1');

    expect(
      result,
      const ProcessingResult.failed('Não foi possível processar este PDF'),
    );
    expect(processing.discards, [('run-1', BookStatus.failed)]);
  });

  test(
    'persistence failure is sanitized and retains prior active identity',
    () async {
      processing.activeRunId = 'prior';
      processing.failStageRaw = true;

      final result = await service().process('book-1');

      expect(
        result,
        const ProcessingResult.failed('Não foi possível processar este PDF'),
      );
      expect(processing.activeRunId, 'prior');
      expect(processing.discards, [('run-1', BookStatus.failed)]);
    },
  );

  test('algorithm failure is sanitized and discards staging', () async {
    final failing = TextProcessingService(
      books: books,
      processing: processing,
      extractor: extractor,
      cleaner: const TextCleaner(),
      chapterId: () => throw StateError('algorithm'),
      blockId: () => 'block',
      clock: () => now,
      runId: () => 'run-1',
    );

    final result = await failing.process('book-1');

    expect(
      result,
      const ProcessingResult.failed('Não foi possível processar este PDF'),
    );
    expect(processing.discards.single.$2, BookStatus.failed);
  });

  test(
    'cancellation during extraction stops at the next page boundary',
    () async {
      extractor.pageGate = Completer<void>();
      final target = service();
      final future = target.process('book-1');
      await extractor.firstPage;

      final cancellation = target.cancel('book-1');
      extractor.pageGate!.complete();

      expect(await future, const ProcessingResult.cancelled());
      expect(await cancellation, const ProcessingResult.cancelled());
      expect(extractor.cancelledRunIds, ['run-1']);
      expect(processing.discards, [('run-1', BookStatus.importing)]);
    },
  );

  test(
    'cancellation during cleaning stops before the next clean page',
    () async {
      processing.onProgress = (stage, progress) {
        if (stage == ProcessingStage.cleaning && progress == .5) {
          unawaited(processing.cancel!());
        }
      };
      final target = service();
      processing.cancel = () => target.cancel('book-1');

      final result = await target.process('book-1');

      expect(result, const ProcessingResult.cancelled());
      expect(processing.cleanPages, hasLength(1));
    },
  );

  test(
    'cancellation during chapter detection stops before activation',
    () async {
      processing.onProgress = (stage, progress) {
        if (stage == ProcessingStage.detectingChapters && progress == .675) {
          unawaited(processing.cancel!());
        }
      };
      final target = service();
      processing.cancel = () => target.cancel('book-1');

      expect(
        await target.process('book-1'),
        const ProcessingResult.cancelled(),
      );
      expect(processing.activated, isNull);
    },
  );

  test('cancellation during block generation stops before staging', () async {
    processing.onProgress = (stage, progress) {
      if (stage == ProcessingStage.buildingBlocks && progress == .95) {
        unawaited(processing.cancel!());
      }
    };
    final target = service();
    processing.cancel = () => target.cancel('book-1');

    expect(await target.process('book-1'), const ProcessingResult.cancelled());
    expect(processing.chapters, isEmpty);
    expect(processing.blocks, isEmpty);
    expect(processing.activated, isNull);
  });

  test('duplicate calls for one book join the exact same future', () async {
    extractor.pageGate = Completer<void>();
    final target = service();

    final first = target.process('book-1');
    final second = target.process('book-1');

    expect(identical(first, second), isTrue);
    extractor.pageGate!.complete();
    expect(await first, const ProcessingResult.completed());
    expect(extractor.extractCalls, 1);
  });

  test(
    'runs from different service instances are globally serialized',
    () async {
      extractor.pageGate = Completer<void>();
      final first = service();
      final secondExtractor = _Extractor(extractor.events);
      final second = TextProcessingService(
        books: books,
        processing: _ProcessingRepository(),
        extractor: secondExtractor,
        cleaner: const TextCleaner(),
        chapterId: () => 'c2',
        blockId: () => 'b2',
        clock: () => now,
        runId: () => 'run-second',
      );

      final firstFuture = first.process('book-1');
      final secondFuture = second.process('book-1');
      await extractor.firstPage;

      expect(secondExtractor.extractCalls, 0);
      extractor.pageGate!.complete();
      await firstFuture;
      await secondFuture;
      expect(secondExtractor.extractCalls, 1);
    },
  );

  test('late cancellation cannot alter an activated run', () async {
    final target = service();
    expect(await target.process('book-1'), const ProcessingResult.completed());

    expect(await target.cancel('book-1'), const ProcessingResult.completed());
    expect(processing.discards, isEmpty);
  });

  test('close cancels and awaits cleanup without leaving staging', () async {
    extractor.pageGate = Completer<void>();
    final target = service();
    final future = target.process('book-1');
    await extractor.firstPage;

    final closing = target.close();
    extractor.pageGate!.complete();
    await closing;

    expect(await future, const ProcessingResult.cancelled());
    expect(processing.discards.single.$2, BookStatus.importing);
  });
}

Book _book(DateTime now) => Book(
  id: 'book-1',
  title: 'Livro',
  originalFileName: 'livro.pdf',
  storedFilePath: '/livro.pdf',
  fileHash: 'hash',
  status: BookStatus.importing,
  processingProgress: 0,
  createdAt: now,
  updatedAt: now,
);

final class _BookRepository implements BookRepository {
  _BookRepository(this.book);
  Book book;
  @override
  Future<Book?> findById(String id) async => id == book.id ? book : null;
  @override
  Stream<List<Book>> watchAll() => Stream.value([book]);
  @override
  Future<Book?> findByHash(String hash) async => null;
  @override
  Future<void> insert(Book book) async {}
  @override
  Future<void> deleteById(String id) async {}
  @override
  Future<void> replaceImportedFile({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required BookStatus status,
    required double processingProgress,
    required DateTime updatedAt,
  }) async {}
  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {}
}

final class _Extractor implements PdfTextExtractor {
  _Extractor(this.events);
  List<PdfExtractionEvent> events;
  Completer<void>? pageGate;
  final _firstPage = Completer<void>();
  Future<void> get firstPage => _firstPage.future;
  int extractCalls = 0;
  final cancelledRunIds = <String>[];

  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) async* {
    extractCalls++;
    for (final event in events) {
      if (event is PdfExtractionPage && !_firstPage.isCompleted) {
        _firstPage.complete();
        await pageGate?.future;
      }
      yield switch (event) {
        PdfExtractionOpened() => PdfExtractionOpened(
          request.runId,
          event.pageCount,
          event.workerIdentity,
        ),
        PdfExtractionPage() => PdfExtractionPage(
          request.runId,
          event.pageNumber,
          event.pageCount,
          event.text,
        ),
        PdfExtractionCompleted() => PdfExtractionCompleted(
          request.runId,
          event.pageCount,
        ),
        PdfExtractionFailed() => PdfExtractionFailed(request.runId, event.kind),
      };
    }
  }

  @override
  Future<void> cancel(String runId) async => cancelledRunIds.add(runId);
}

final class _ProcessingRepository implements TextProcessingRepository {
  final rawPages = <RawPage>[];
  final cleanPages = <CleanPage>[];
  final chapters = <ChapterDraft>[];
  final blocks = <NarrationBlockDraft>[];
  final progress = <(ProcessingStage, double)>[];
  final discards = <(String, BookStatus)>[];
  List<int>? activated;
  String? activeRunId;
  bool failStageRaw = false;
  void Function(ProcessingStage, double)? onProgress;
  Future<ProcessingResult> Function()? cancel;

  @override
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
  }) async {}
  @override
  Future<void> stageRawPage(String runId, RawPage page) async {
    if (failStageRaw) throw StateError('persistence');
    rawPages.add(page);
  }

  @override
  Stream<RawPage> streamRawPages(String runId) => Stream.fromIterable(rawPages);
  @override
  Future<void> stageCleanPage(String runId, CleanPage page) async =>
      cleanPages.add(page);
  @override
  Future<void> stageChaptersAndBlocks({
    required String runId,
    required String bookId,
    required List<ChapterDraft> chapters,
    required List<NarrationBlockDraft> blocks,
    required DateTime createdAt,
  }) async {
    this.chapters.addAll(chapters);
    this.blocks.addAll(blocks);
  }

  @override
  Future<void> updateProgress({
    required String bookId,
    required ProcessingStage stage,
    required double progress,
    required DateTime updatedAt,
  }) async {
    this.progress.add((stage, progress));
    onProgress?.call(stage, progress);
  }

  @override
  Future<void> activateRun({
    required String runId,
    required int pageCount,
    required int chapterCount,
    required int blockCount,
    required DateTime completedAt,
  }) async {
    activated = [pageCount, chapterCount, blockCount];
    activeRunId = runId;
  }

  @override
  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  }) async => discards.add((runId, terminalStatus));
  @override
  Future<ActiveProcessedContent?> readActiveContent(String bookId) async =>
      null;
}
