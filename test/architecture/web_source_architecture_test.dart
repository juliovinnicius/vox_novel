import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_queue.dart';
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/visual_reader/data/repositories/drift_visual_reader_repository.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_download_service.dart';

const String politeFetcherPath =
    'lib/features/web_source/data/services/polite_web_fetcher.dart';

Iterable<File> dartSourcesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void main() {
  test('only the polite fetcher reaches for package:http (AD-010)', () {
    final importers = <String>[
      for (final source in [
        ...dartSourcesIn('lib'),
        ...dartSourcesIn('test'),
      ])
        if (RegExp(
          r"""import\s+'package:http/""",
        ).hasMatch(source.readAsStringSync()))
          source.path,
    ];

    expect(
      importers,
      [politeFetcherPath],
      reason:
          'Network access must stay inside PoliteWebFetcher so per-host '
          'throttling cannot be bypassed.',
    );
  });

  test('the web download service stays out of the global processing tail '
      '(AD-009)', () {
    // Prose may name the constraint; only executable references count.
    final source = File(
      'lib/features/web_source/domain/services/web_novel_download_service.dart',
    ).readAsStringSync().split('\n').where((line) {
      final trimmed = line.trimLeft();
      return !trimmed.startsWith('//');
    }).join('\n');

    expect(
      source,
      isNot(contains('text_processing_service.dart')),
      reason:
          'A long web download must not enter TextProcessingService\'s '
          'static _globalTail, which would starve PDF imports.',
    );
    expect(source, isNot(contains('TextProcessingService')));
    expect(source, isNot(contains('_globalTail')));
  });

  test('a pdf import proceeds while a web download is mid-queue', () async {
    final blocked = Completer<void>();
    final processing = FakeProcessingRepository();
    final webService = WebNovelDownloadService(
      books: FakeBookRepository({
        'web-book': Book(
          id: 'web-book',
          title: 'Obra da web',
          status: BookStatus.processing,
          processingProgress: 0,
          createdAt: DateTime.utc(2026, 8, 18),
          updatedAt: DateTime.utc(2026, 8, 18),
          sourceType: BookSourceType.web,
          sourceRef: 'https://exemplo.com/series/obra/',
        ),
      }),
      source: FakeWebSourceRepository(),
      processing: processing,
      ingest: ChapterIngest(
        processing: processing,
        chapterId: () => 'web-chapter',
        blockId: () => 'web-block',
      ),
      fetcher: BlockingWebFetcher(blocked),
      recipes: SiteRecipeRegistry(const [exampleRecipe]),
      clock: () => DateTime.utc(2026, 8, 18),
      runId: () => 'web-run',
    );

    var webFinished = false;
    final webDownload = webService.download('web-book');
    unawaited(webDownload.then((_) => webFinished = true));
    // Let the queue reach its first request and park there.
    await Future<void>.delayed(Duration.zero);

    final pdfResult = await pdfService().process('pdf-book');

    expect(pdfResult, const ProcessingResult.completed());
    expect(
      webFinished,
      isFalse,
      reason:
          'The PDF import must not have waited for the web queue to drain.',
    );

    blocked.complete();
    await webDownload;
    expect(webFinished, isTrue);
  });

  test('narration order of an appended chapter follows sortOrder, not '
      'chapter id', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final at = DateTime.utc(2026, 8, 18);
    final processing = DriftTextProcessingRepository(database);

    await database
        .into(database.books)
        .insert(
          db.BooksCompanion.insert(
            id: 'web-book',
            title: 'Obra da web',
            sourceType: const Value(BookSourceType.web),
            sourceRef: const Value('https://exemplo.com/series/obra/'),
            status: BookStatus.processing,
            processingProgress: 0,
            createdAt: at,
            updatedAt: at,
          ),
        );
    await processing.createRun(
      bookId: 'web-book',
      runId: 'run-1',
      startedAt: at,
    );

    // The first chapter's id sorts *after* the appended one, so any consumer
    // reading blocks flat would narrate the second chapter first.
    await stageChapter(processing, id: 'zzzz-chapter', ordinal: 1, text: 'Um.');
    await stageChapter(
      processing,
      id: 'aaaa-chapter',
      ordinal: 2,
      text: 'Dois.',
    );
    await processing.activateRun(
      runId: 'run-1',
      pageCount: 2,
      chapterCount: 2,
      blockCount: 2,
      completedAt: at,
    );

    final flat = await processing.readActiveContent('web-book');
    expect(
      flat!.blocks.map((block) => block.chapterId),
      ['aaaa-chapter', 'zzzz-chapter'],
      reason: 'Flat block order really is id-ordered — the risk is real.',
    );

    final content = await DriftVisualReaderRepository(
      database,
    ).loadContent('web-book');
    final queue = NarrationQueue.fromContent(content!);

    expect(queue.entries.map((entry) => entry.chapterId), [
      'zzzz-chapter',
      'aaaa-chapter',
    ]);
    expect(queue.entries.map((entry) => entry.normalizedText), ['Um.', 'Dois.']);
  });
}

Future<void> stageChapter(
  TextProcessingRepository processing, {
  required String id,
  required int ordinal,
  required String text,
}) => processing.stageChaptersAndBlocks(
  runId: 'run-1',
  bookId: 'web-book',
  chapters: [
    ChapterDraft(
      id: id,
      title: 'Capítulo $ordinal',
      sortOrder: ordinal - 1,
      startPage: ordinal,
      endPage: ordinal,
      cleanText: text,
    ),
  ],
  blocks: [
    NarrationBlockDraft(
      id: 'block-$ordinal',
      chapterId: id,
      sortOrder: 0,
      originalText: text,
      normalizedText: text,
      characterCount: text.runes.length,
      startPage: ordinal,
      endPage: ordinal,
    ),
  ],
  createdAt: DateTime.utc(2026, 8, 18),
);

TextProcessingService pdfService() {
  var nextId = 0;
  return TextProcessingService(
    books: FakeBookRepository({
      'pdf-book': Book(
        id: 'pdf-book',
        title: 'Obra em pdf',
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: DateTime.utc(2026, 8, 18),
        updatedAt: DateTime.utc(2026, 8, 18),
        storedFilePath: '/tmp/obra.pdf',
      ),
    }),
    processing: FakeProcessingRepository(),
    extractor: const FakePdfExtractor(),
    cleaner: const TextCleaner(),
    chapterId: () => 'pdf-chapter-${++nextId}',
    blockId: () => 'pdf-block-${++nextId}',
    clock: () => DateTime.utc(2026, 8, 18),
    runId: () => 'pdf-run',
  );
}

const SiteRecipe exampleRecipe = SiteRecipe(
  domain: 'exemplo.com',
  seriesPathPrefix: '/series/',
  seriesLinkSelector: "a[itemprop=item][href*='/series/']",
  chapterIndexSelector: 'div.eplister li > a',
  chapterIndexTitleSelector: 'div.epl-title',
  chapterIndexOrder: ChapterIndexOrder.descending,
  chapterTitleSelector: 'h1.entry-title',
  contentSelector: 'div.epcontent.entry-content',
  paragraphSelector: 'p',
  nextChapterSelector: 'a[rel=next]',
  disallowedPathPatterns: ['/pdf/'],
  minimumChapterCharacters: 200,
);

/// Parks on [gate] instead of answering, so the web queue can be held
/// mid-request while another import runs.
final class BlockingWebFetcher implements WebFetcher {
  const BlockingWebFetcher(this._gate);

  final Completer<void> _gate;

  @override
  Future<WebFetchResult> fetch(Uri url) async {
    await _gate.future;
    return WebFetchFailed(
      WebFetchFailureKind.network,
      'Interrompido em $url',
    );
  }
}

final class FakePdfExtractor implements PdfTextExtractor {
  const FakePdfExtractor();

  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) async* {
    yield PdfExtractionOpened(request.runId, 1, 0);
    yield PdfExtractionPage(
      request.runId,
      1,
      1,
      'Capítulo 1\n\nTexto sintético do pdf para o detector de capítulos.',
    );
    yield PdfExtractionCompleted(request.runId, 1);
  }

  @override
  Future<void> cancel(String runId) async {}
}

final class FakeBookRepository implements BookRepository {
  const FakeBookRepository(this._books);

  final Map<String, Book> _books;

  @override
  Future<Book?> findById(String id) async => _books[id];

  @override
  Stream<List<Book>> watchAll() => throw UnimplementedError();
  @override
  Future<Book?> findByHash(String hash) => throw UnimplementedError();
  @override
  Future<Book?> findBySourceRef(String sourceRef) => throw UnimplementedError();
  @override
  Future<void> insert(Book book) => throw UnimplementedError();
  @override
  Future<void> replaceImportedFile({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required BookStatus status,
    required double processingProgress,
    required DateTime updatedAt,
  }) => throw UnimplementedError();
  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) => throw UnimplementedError();
  @override
  Future<void> deleteById(String id) => throw UnimplementedError();
}

final class FakeWebSourceRepository implements WebSourceRepository {
  final entries = <WebChapterEntry>[
    WebChapterEntry(
      bookId: 'web-book',
      sortOrder: 1,
      url: 'https://exemplo.com/obra-capitulo-1/',
      title: 'Capítulo 1',
      state: WebChapterState.pending,
      attemptCount: 0,
      updatedAt: DateTime.utc(2026, 8, 18),
    ),
  ];

  @override
  Future<List<WebChapterEntry>> pending(String bookId) async => entries;
  @override
  Future<WebChapterCounts> counts(String bookId) async =>
      WebChapterCounts(total: entries.length, stored: 0, failed: 0);
  @override
  Future<void> markFailed(
    String bookId,
    int sortOrder,
    String reason,
    DateTime at,
  ) async {}
  @override
  Future<void> markStored(String bookId, int sortOrder, DateTime at) async {}
  @override
  Future<List<WebChapterEntry>> failed(String bookId) async => const [];
  @override
  Future<Set<String>> knownUrls(String bookId) async => const {};
  @override
  Future<void> replaceIndex(String bookId, List<WebChapterRef> chapters) =>
      throw UnimplementedError();
  @override
  Future<int> appendNew(String bookId, List<WebChapterRef> chapters) =>
      throw UnimplementedError();
}

final class FakeProcessingRepository implements TextProcessingRepository {
  final rawPages = <RawPage>[];

  @override
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
    ProcessingStage stage = ProcessingStage.extracting,
  }) async {}

  @override
  Future<void> stageRawPage(String runId, RawPage page) async =>
      rawPages.add(page);

  @override
  Stream<RawPage> streamRawPages(String runId) => Stream.fromIterable(rawPages);

  @override
  Future<void> stageCleanPage(String runId, CleanPage page) async {}

  @override
  Future<void> stageChaptersAndBlocks({
    required String runId,
    required String bookId,
    required List<ChapterDraft> chapters,
    required List<NarrationBlockDraft> blocks,
    required DateTime createdAt,
  }) async {}

  @override
  Future<void> updateProgress({
    required String bookId,
    required ProcessingStage stage,
    required double progress,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<void> activateRun({
    required String runId,
    required int pageCount,
    required int chapterCount,
    required int blockCount,
    required DateTime completedAt,
  }) async {}

  @override
  Future<void> activatePartialRun({
    required String runId,
    required DateTime activatedAt,
  }) async {}

  @override
  Future<void> updateRunCounts({
    required String runId,
    required int chapterCount,
    required int blockCount,
    required double progress,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  }) async {}

  @override
  Future<ActiveProcessedContent?> readActiveContent(String bookId) async =>
      null;
}
