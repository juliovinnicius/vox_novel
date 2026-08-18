import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/web_source/data/services/polite_web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_download_service.dart';

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
  disallowedPathPatterns: ['/pdf/', '/search/', '/?s='],
  minimumChapterCharacters: 200,
);

String chapterUrl(int ordinal) =>
    'https://exemplo.com/obra-sintetica-capitulo-$ordinal/';

/// A chapter page whose body clears the recipe's minimum length in a single
/// paragraph, so one chapter yields exactly one narration block.
String chapterPage(int ordinal) =>
    '<html><body><h1 class="entry-title">Página do capítulo $ordinal</h1>'
    '<div class="epcontent entry-content"><p>'
    '${'Texto sintético do capítulo $ordinal. ' * 10}'
    '</p></div></body></html>';

/// A clock that only moves when the injected delay is awaited, so the
/// fetcher's backoff is asserted without the suite sleeping.
final class FakeClock {
  DateTime now = DateTime.utc(2026, 8, 18, 9);

  DateTime call() => now;

  Future<void> delay(Duration duration) async {
    now = now.add(duration);
  }
}

/// A hand-written transport fake. It never touches the network.
final class FakeTransport {
  FakeTransport(this._respond);

  final HttpExchange Function(Uri url) _respond;
  final List<Uri> requests = [];

  Future<HttpExchange> send(Uri url, Map<String, String> headers) async {
    requests.add(url);
    return _respond(url);
  }
}

final class FakeWebFetcher implements WebFetcher {
  FakeWebFetcher(this.pages, {this.delays = const {}, this.onFetch});

  final Map<String, String> pages;
  final Map<String, Duration> delays;

  /// Runs before the response is produced, so a test can act mid-download.
  final void Function(Uri url)? onFetch;
  final List<Uri> requests = [];

  @override
  Future<WebFetchResult> fetch(Uri url) async {
    requests.add(url);
    onFetch?.call(url);
    final delay = delays[url.toString()];
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    final body = pages[url.toString()];
    if (body == null) {
      return WebFetchFailed(
        WebFetchFailureKind.notFound,
        'Página não encontrada: $url',
      );
    }
    return WebFetchSucceeded(url: url, body: body);
  }
}

final class FakeBookRepository implements BookRepository {
  FakeBookRepository(this.book);

  Book? book;

  @override
  Future<Book?> findById(String id) async => book?.id == id ? book : null;

  @override
  Stream<List<Book>> watchAll() => throw UnimplementedError();
  @override
  Future<Book?> findByHash(String hash) => throw UnimplementedError();
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
  FakeWebSourceRepository(this.entries);

  final List<WebChapterEntry> entries;

  WebChapterEntry _at(int sortOrder) =>
      entries.firstWhere((entry) => entry.sortOrder == sortOrder);

  void _replace(WebChapterEntry entry) =>
      entries[entries.indexWhere((it) => it.sortOrder == entry.sortOrder)] =
          entry;

  @override
  Future<List<WebChapterEntry>> pending(String bookId) async =>
      (entries.where((entry) => entry.state != WebChapterState.stored).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

  @override
  Future<List<WebChapterEntry>> failed(String bookId) async =>
      entries.where((entry) => entry.state == WebChapterState.failed).toList();

  @override
  Future<WebChapterCounts> counts(String bookId) async => WebChapterCounts(
    total: entries.length,
    stored: entries.where((e) => e.state == WebChapterState.stored).length,
    failed: entries.where((e) => e.state == WebChapterState.failed).length,
  );

  @override
  Future<void> markStored(String bookId, int sortOrder, DateTime at) async {
    final entry = _at(sortOrder);
    _replace(
      WebChapterEntry(
        bookId: entry.bookId,
        sortOrder: entry.sortOrder,
        url: entry.url,
        title: entry.title,
        state: WebChapterState.stored,
        attemptCount: entry.attemptCount,
        updatedAt: at,
      ),
    );
  }

  @override
  Future<void> markFailed(
    String bookId,
    int sortOrder,
    String reason,
    DateTime at,
  ) async {
    final entry = _at(sortOrder);
    _replace(
      WebChapterEntry(
        bookId: entry.bookId,
        sortOrder: entry.sortOrder,
        url: entry.url,
        title: entry.title,
        state: WebChapterState.failed,
        attemptCount: entry.attemptCount + 1,
        lastError: reason,
        updatedAt: at,
      ),
    );
  }

  @override
  Future<Set<String>> knownUrls(String bookId) async =>
      entries.map((entry) => entry.url).toSet();
  @override
  Future<void> replaceIndex(String bookId, List<WebChapterRef> chapters) =>
      throw UnimplementedError();
  @override
  Future<int> appendNew(String bookId, List<WebChapterRef> chapters) =>
      throw UnimplementedError();
}

final class FakeProcessingRepository implements TextProcessingRepository {
  final createdRuns = <(String bookId, String runId)>[];
  final chapters = <ChapterDraft>[];
  final blocks = <NarrationBlockDraft>[];
  final partialActivations = <String>[];
  final runCountUpdates = <(String, int, int, double)>[];
  final progressUpdates = <(ProcessingStage, double)>[];
  final activations = <(String runId, int pages, int chapters, int blocks)>[];
  final discards = <(String runId, BookStatus status)>[];

  /// Cumulative staged-block count at the moment each chapter was marked
  /// stored, recorded by the test through [onStage].
  void Function()? onStage;

  int chaptersAtFirstActivation = -1;
  final activationsAtEachStage = <int>[];

  @override
  Future<void> createRun({
    required String bookId,
    required String runId,
    required DateTime startedAt,
  }) async => createdRuns.add((bookId, runId));

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
    activationsAtEachStage.add(activations.length);
    onStage?.call();
  }

  @override
  Future<void> activatePartialRun({
    required String runId,
    required DateTime activatedAt,
  }) async {
    partialActivations.add(runId);
    chaptersAtFirstActivation = chapters.length;
  }

  @override
  Future<void> updateRunCounts({
    required String runId,
    required int chapterCount,
    required int blockCount,
    required double progress,
    required DateTime updatedAt,
  }) async =>
      runCountUpdates.add((runId, chapterCount, blockCount, progress));

  @override
  Future<void> updateProgress({
    required String bookId,
    required ProcessingStage stage,
    required double progress,
    required DateTime updatedAt,
  }) async => progressUpdates.add((stage, progress));

  @override
  Future<void> activateRun({
    required String runId,
    required int pageCount,
    required int chapterCount,
    required int blockCount,
    required DateTime completedAt,
  }) async =>
      activations.add((runId, pageCount, chapterCount, blockCount));

  @override
  Future<void> discardRun({
    required String runId,
    required BookStatus terminalStatus,
    required DateTime updatedAt,
  }) async => discards.add((runId, terminalStatus));

  @override
  Future<void> stageRawPage(String runId, RawPage page) =>
      throw UnimplementedError();
  @override
  Stream<RawPage> streamRawPages(String runId) => throw UnimplementedError();
  @override
  Future<void> stageCleanPage(String runId, CleanPage page) =>
      throw UnimplementedError();
  @override
  Future<ActiveProcessedContent?> readActiveContent(String bookId) =>
      throw UnimplementedError();
}

void main() {
  const bookId = 'book-1';
  final now = DateTime.utc(2026, 8, 18, 9);

  late FakeBookRepository books;
  late FakeWebSourceRepository source;
  late FakeProcessingRepository processing;
  late FakeWebFetcher fetcher;
  var nextId = 0;

  Book webBook({
    String? activeContentRunId,
    int chapterCount = 0,
    int blockCount = 0,
  }) => Book(
    id: bookId,
    title: 'Obra sintética',
    status: BookStatus.processing,
    processingProgress: 0,
    createdAt: now,
    updatedAt: now,
    sourceType: BookSourceType.web,
    sourceRef: 'https://exemplo.com/series/obra-sintetica/',
    chapterCount: chapterCount,
    blockCount: blockCount,
    activeContentRunId: activeContentRunId,
  );

  WebChapterEntry entry(
    int ordinal, {
    String? title,
    WebChapterState state = WebChapterState.pending,
  }) => WebChapterEntry(
    bookId: bookId,
    sortOrder: ordinal,
    url: chapterUrl(ordinal),
    title: title ?? 'Capítulo $ordinal do índice',
    state: state,
    attemptCount: 0,
    updatedAt: now,
  );

  WebNovelDownloadService serviceFor() => WebNovelDownloadService(
    books: books,
    source: source,
    processing: processing,
    ingest: ChapterIngest(
      processing: processing,
      chapterId: () => 'chapter-${++nextId}',
      blockId: () => 'block-${++nextId}',
    ),
    fetcher: fetcher,
    recipes: SiteRecipeRegistry(const [exampleRecipe]),
    clock: () => now,
    runId: () => 'run-1',
  );

  setUp(() {
    nextId = 0;
    books = FakeBookRepository(webBook());
    source = FakeWebSourceRepository([entry(1), entry(2), entry(3)]);
    processing = FakeProcessingRepository();
    fetcher = FakeWebFetcher({
      for (var ordinal = 1; ordinal <= 3; ordinal++)
        chapterUrl(ordinal): chapterPage(ordinal),
    });
  });

  test('activates the run at the first stored chapter, not at the end', () async {
    await serviceFor().download(bookId);

    expect(processing.createdRuns, [(bookId, 'run-1')]);
    expect(processing.partialActivations, ['run-1']);
    expect(processing.chaptersAtFirstActivation, 1);
  });

  test('stages each chapter with its narration blocks in the same step', () async {
    final blocksWhenStored = <int>[];
    processing.onStage = () => blocksWhenStored.add(processing.blocks.length);

    await serviceFor().download(bookId);

    expect(blocksWhenStored, [1, 2, 3]);
    expect(processing.blocks.map((block) => block.chapterId), [
      'chapter-1',
      'chapter-3',
      'chapter-5',
    ]);
    expect(processing.chapters.map((chapter) => chapter.id), [
      'chapter-1',
      'chapter-3',
      'chapter-5',
    ]);
  });

  test('reports stored-over-total progress at the downloading stage', () async {
    await serviceFor().download(bookId);

    expect(processing.progressUpdates, [
      (ProcessingStage.downloading, 1 / 3),
      (ProcessingStage.downloading, 2 / 3),
      (ProcessingStage.downloading, 1.0),
    ]);
  });

  test('refreshes the run counts as each chapter lands', () async {
    await serviceFor().download(bookId);

    expect(processing.runCountUpdates, [
      ('run-1', 1, 1, 1 / 3),
      ('run-1', 2, 2, 2 / 3),
      ('run-1', 3, 3, 1.0),
    ]);
  });

  test('completes the run only after every indexed chapter is stored', () async {
    await serviceFor().download(bookId);

    expect(processing.activationsAtEachStage, [0, 0, 0]);
    expect(processing.activations, [('run-1', 3, 3, 3)]);
  });

  test('reports completed when the whole index is stored', () async {
    expect(await serviceFor().download(bookId), WebDownloadOutcome.completed);
    expect(
      source.entries.map((entry) => entry.state),
      everyElement(WebChapterState.stored),
    );
  });

  test('persists chapters in index order regardless of ingest timing', () async {
    fetcher = FakeWebFetcher(
      fetcher.pages,
      delays: {
        chapterUrl(1): const Duration(milliseconds: 30),
        chapterUrl(2): const Duration(milliseconds: 15),
      },
    );

    await serviceFor().download(bookId);

    expect(processing.chapters.map((chapter) => chapter.sortOrder), [0, 1, 2]);
    expect(fetcher.requests.map((url) => url.toString()), [
      chapterUrl(1),
      chapterUrl(2),
      chapterUrl(3),
    ]);
  });

  test('stores each chapter ordinal in its page bounds', () async {
    await serviceFor().download(bookId);

    expect(
      processing.chapters.map(
        (chapter) => (chapter.startPage, chapter.endPage),
      ),
      [(1, 1), (2, 2), (3, 3)],
    );
    expect(processing.blocks.map((block) => block.startPage), [1, 2, 3]);
  });

  test('titles each chapter from the persisted index entry', () async {
    await serviceFor().download(bookId);

    expect(processing.chapters.map((chapter) => chapter.title), [
      'Capítulo 1 do índice',
      'Capítulo 2 do índice',
      'Capítulo 3 do índice',
    ]);
  });

  group('cleaning', () {
    /// A chapter page whose body is built from explicit paragraphs, so a test
    /// controls exactly which lines reach the cleaner.
    String pageOf(List<String> paragraphs) =>
        '<html><body><h1 class="entry-title">Página do capítulo</h1>'
        '<div class="epcontent entry-content">'
        '${paragraphs.map((paragraph) => '<p>$paragraph</p>').join()}'
        '</div></body></html>';

    /// Long enough to clear the recipe's 200-character minimum on its own.
    String body(int ordinal) => 'Texto sintético do capítulo $ordinal. ' * 10;

    void serveSingleChapter(List<String> paragraphs) {
      source = FakeWebSourceRepository([entry(1)]);
      fetcher = FakeWebFetcher({chapterUrl(1): pageOf(paragraphs)});
    }

    String storedText() => processing.chapters.single.cleanText;

    test('strips a stray url line out of the chapter text', () async {
      serveSingleChapter([body(1), 'https://exemplo.com/anuncio', body(1)]);

      await serviceFor().download(bookId);

      expect(storedText(), isNot(contains('https://exemplo.com/anuncio')));
      expect(storedText(), contains('Texto sintético do capítulo 1.'));
    });

    test('strips a bare page-number line out of the chapter text', () async {
      serveSingleChapter([body(1), '247', body(1)]);

      await serviceFor().download(bookId);

      expect(storedText().split('\n'), isNot(contains('247')));
    });

    test('strips control characters out of the chapter text', () async {
      serveSingleChapter(['Texto\u007Flimpo do capítulo.', body(1)]);

      await serviceFor().download(bookId);

      expect(storedText(), contains('Textolimpo do capítulo.'));
      expect(storedText(), isNot(contains('\u007F')));
    });

    test('keeps a short standalone line in the chapter text', () async {
      serveSingleChapter([body(1), '— Sim.', body(1)]);

      await serviceFor().download(bookId);

      expect(storedText().split('\n'), contains('— Sim.'));
    });

    test('keeps a line repeated across every chapter of the book', () async {
      const repeated = 'Traduzido pela equipe do site.';
      source = FakeWebSourceRepository([entry(1), entry(2), entry(3)]);
      fetcher = FakeWebFetcher({
        for (var ordinal = 1; ordinal <= 3; ordinal++)
          chapterUrl(ordinal): pageOf([repeated, body(ordinal)]),
      });

      await serviceFor().download(bookId);

      expect(
        processing.chapters.map(
          (chapter) => chapter.cleanText.split('\n').first,
        ),
        [repeated, repeated, repeated],
      );
    });
  });

  group('chapter failures', () {
    late FakeClock clock;
    late FakeTransport transport;

    /// The queue driven by the real [PoliteWebFetcher], so the bounded
    /// exponential-backoff retry it owns is observable through the transport.
    WebNovelDownloadService politeServiceFor(
      HttpExchange Function(Uri url) respond,
    ) {
      transport = FakeTransport(respond);
      return WebNovelDownloadService(
        books: books,
        source: source,
        processing: processing,
        ingest: ChapterIngest(
          processing: processing,
          chapterId: () => 'chapter-${++nextId}',
          blockId: () => 'block-${++nextId}',
        ),
        fetcher: PoliteWebFetcher(
          send: transport.send,
          clock: clock.call,
          delay: clock.delay,
        ),
        recipes: SiteRecipeRegistry(const [exampleRecipe]),
        clock: () => now,
        runId: () => 'run-1',
      );
    }

    /// Serves every chapter page, except the ones [broken] answers for.
    HttpExchange Function(Uri url) pagesExcept(
      HttpExchange? Function(Uri url) broken,
    ) => (url) {
      final failure = broken(url);
      if (failure != null) {
        return failure;
      }
      final ordinal = int.parse(
        RegExp(r'capitulo-(\d+)').firstMatch(url.toString())!.group(1)!,
      );
      return HttpExchange(
        statusCode: 200,
        headers: const {},
        body: chapterPage(ordinal),
      );
    };

    setUp(() => clock = FakeClock());

    test('retries a transient failure to the bounded attempt count before '
        'marking the chapter failed', () async {
      await politeServiceFor(
        pagesExcept(
          (url) => url.toString() == chapterUrl(2)
              ? const HttpExchange(
                  statusCode: 503,
                  headers: {},
                  body: '',
                )
              : null,
        ),
      ).download(bookId);

      expect(
        transport.requests
            .where((url) => url.toString() == chapterUrl(2))
            .length,
        PoliteWebFetcher.maximumAttempts,
      );
      expect(source.entries[1].state, WebChapterState.failed);
    });

    test('marks a 404 chapter failed without exhausting retries', () async {
      await politeServiceFor(
        pagesExcept(
          (url) => url.toString() == chapterUrl(2)
              ? const HttpExchange(statusCode: 404, headers: {}, body: '')
              : null,
        ),
      ).download(bookId);

      expect(
        transport.requests
            .where((url) => url.toString() == chapterUrl(2))
            .length,
        1,
      );
      expect(source.entries[1].state, WebChapterState.failed);
    });

    test('continues the queue past a failed chapter', () async {
      fetcher = FakeWebFetcher({
        chapterUrl(1): chapterPage(1),
        chapterUrl(3): chapterPage(3),
      });

      await serviceFor().download(bookId);

      expect(source.entries.map((entry) => entry.state), [
        WebChapterState.stored,
        WebChapterState.failed,
        WebChapterState.stored,
      ]);
      expect(processing.chapters.map((chapter) => chapter.sortOrder), [0, 2]);
    });

    test('keeps the book readable with the chapters already stored', () async {
      fetcher = FakeWebFetcher({chapterUrl(2): chapterPage(2)});

      final outcome = await serviceFor().download(bookId);

      expect(outcome, WebDownloadOutcome.paused);
      expect(processing.partialActivations, ['run-1']);
      expect(processing.chapters.map((chapter) => chapter.sortOrder), [1]);
      expect(processing.discards, isEmpty);
      expect(processing.activations, isEmpty);
    });

    test('persists the attempt count and the failure reason per entry', () async {
      fetcher = FakeWebFetcher({chapterUrl(1): chapterPage(1)});

      await serviceFor().download(bookId);

      expect(source.entries[1].attemptCount, 1);
      expect(
        source.entries[1].lastError,
        'Página não encontrada: ${chapterUrl(2)}',
      );
      expect(source.entries[2].attemptCount, 1);
    });

    test('marks a chapter below the minimum length failed and stores no '
        'stub', () async {
      fetcher = FakeWebFetcher({
        chapterUrl(1): chapterPage(1),
        chapterUrl(2):
            '<html><body><div class="epcontent entry-content">'
            '<p>Curto demais.</p></div></body></html>',
        chapterUrl(3): chapterPage(3),
      });

      await serviceFor().download(bookId);

      expect(source.entries[1].state, WebChapterState.failed);
      expect(source.entries[1].lastError, contains('abaixo do mínimo'));
      expect(processing.chapters.map((chapter) => chapter.sortOrder), [0, 2]);
    });

    test('does not advance progress for a failed chapter', () async {
      fetcher = FakeWebFetcher({
        chapterUrl(1): chapterPage(1),
        chapterUrl(3): chapterPage(3),
      });

      await serviceFor().download(bookId);

      expect(processing.progressUpdates, [
        (ProcessingStage.downloading, 1 / 3),
        (ProcessingStage.downloading, 2 / 3),
      ]);
    });
  });

  group('resume and cancel', () {
    test('resumes at the lowest chapter that has no stored text', () async {
      source = FakeWebSourceRepository([
        entry(1, state: WebChapterState.stored),
        entry(2, state: WebChapterState.stored),
        entry(3),
      ]);
      books = FakeBookRepository(
        webBook(activeContentRunId: 'run-0', chapterCount: 2, blockCount: 2),
      );

      final outcome = await serviceFor().download(bookId);

      expect(fetcher.requests.map((url) => url.toString()), [chapterUrl(3)]);
      expect(outcome, WebDownloadOutcome.completed);
    });

    test('issues zero requests for chapters already stored', () async {
      source = FakeWebSourceRepository([
        entry(1, state: WebChapterState.stored),
        entry(2),
        entry(3, state: WebChapterState.stored),
      ]);
      books = FakeBookRepository(
        webBook(activeContentRunId: 'run-0', chapterCount: 2, blockCount: 2),
      );

      await serviceFor().download(bookId);

      expect(fetcher.requests.map((url) => url.toString()), [chapterUrl(2)]);
      expect(processing.chapters.map((chapter) => chapter.sortOrder), [1]);
    });

    test('a resumed run keeps the active run instead of starting a '
        'second one', () async {
      source = FakeWebSourceRepository([
        entry(1, state: WebChapterState.stored),
        entry(2),
        entry(3),
      ]);
      books = FakeBookRepository(
        webBook(activeContentRunId: 'run-0', chapterCount: 1, blockCount: 1),
      );

      await serviceFor().download(bookId);

      expect(processing.createdRuns, isEmpty);
      expect(processing.partialActivations, isEmpty);
      expect(processing.activations, [('run-0', 3, 3, 3)]);
    });

    test('cancel stops further requests and retains stored chapters', () async {
      late WebNovelDownloadService service;
      fetcher = FakeWebFetcher(
        fetcher.pages,
        onFetch: (url) {
          if (url.toString() == chapterUrl(1)) {
            unawaited(service.cancel(bookId));
          }
        },
      );
      service = serviceFor();

      final outcome = await service.download(bookId);

      expect(outcome, WebDownloadOutcome.cancelled);
      expect(fetcher.requests.map((url) => url.toString()), [chapterUrl(1)]);
      expect(source.entries.map((entry) => entry.state), [
        WebChapterState.stored,
        WebChapterState.pending,
        WebChapterState.pending,
      ]);
      expect(processing.discards, isEmpty);
      expect(processing.activations, isEmpty);
    });

    test('a cancelled book resumes later and completes', () async {
      late WebNovelDownloadService service;
      fetcher = FakeWebFetcher(
        fetcher.pages,
        onFetch: (url) {
          if (url.toString() == chapterUrl(1)) {
            unawaited(service.cancel(bookId));
          }
        },
      );
      service = serviceFor();
      await service.download(bookId);

      books = FakeBookRepository(
        webBook(activeContentRunId: 'run-1', chapterCount: 1, blockCount: 1),
      );
      fetcher = FakeWebFetcher({
        for (var ordinal = 1; ordinal <= 3; ordinal++)
          chapterUrl(ordinal): chapterPage(ordinal),
      });

      final outcome = await serviceFor().download(bookId);

      expect(outcome, WebDownloadOutcome.completed);
      expect(fetcher.requests.map((url) => url.toString()), [
        chapterUrl(2),
        chapterUrl(3),
      ]);
      expect(
        source.entries.map((entry) => entry.state),
        everyElement(WebChapterState.stored),
      );
      expect(processing.activations, [('run-1', 3, 3, 3)]);
    });

    test('resume covers a chapter left failed, which has no stored '
        'text', () async {
      source = FakeWebSourceRepository([
        entry(1, state: WebChapterState.stored),
        entry(2, state: WebChapterState.failed),
        entry(3, state: WebChapterState.stored),
      ]);
      books = FakeBookRepository(
        webBook(activeContentRunId: 'run-0', chapterCount: 2, blockCount: 2),
      );

      final outcome = await serviceFor().download(bookId);

      expect(fetcher.requests.map((url) => url.toString()), [chapterUrl(2)]);
      expect(outcome, WebDownloadOutcome.completed);
      expect(
        source.entries.map((entry) => entry.state),
        everyElement(WebChapterState.stored),
      );
    });
  });

  group('unrecognized layout', () {
    /// A page the recipe's content selector does not match at all.
    const unrecognized =
        '<html><body><div class="outro-layout">'
        '<p>Nada que a receita reconheça.</p></div></body></html>';

    test('marks the book unsupported when every chapter fails '
        'extraction', () async {
      fetcher = FakeWebFetcher({
        for (var ordinal = 1; ordinal <= 3; ordinal++)
          chapterUrl(ordinal): unrecognized,
      });
      final service = serviceFor();

      final outcome = await service.download(bookId);

      expect(outcome, WebDownloadOutcome.unsupported);
      expect(processing.discards, [('run-1', BookStatus.unsupported)]);
      expect(
        service.messageFor(bookId),
        'O layout do site não foi reconhecido',
      );
      expect(processing.chapters, isEmpty);
    });

    test('a mix of extraction failures and successes is never '
        'unsupported', () async {
      fetcher = FakeWebFetcher({
        chapterUrl(1): unrecognized,
        chapterUrl(2): chapterPage(2),
        chapterUrl(3): unrecognized,
      });
      final service = serviceFor();

      final outcome = await service.download(bookId);

      expect(outcome, WebDownloadOutcome.paused);
      expect(processing.discards, isEmpty);
      expect(service.messageFor(bookId), isNull);
      expect(processing.chapters.map((chapter) => chapter.sortOrder), [1]);
    });

    test('network-only failures pause instead of marking unsupported', () async {
      fetcher = FakeWebFetcher(const {});
      final service = serviceFor();

      final outcome = await service.download(bookId);

      expect(outcome, WebDownloadOutcome.paused);
      expect(processing.discards, isEmpty);
      expect(service.messageFor(bookId), isNull);
    });

    test('extraction failures mixed with network failures pause', () async {
      fetcher = FakeWebFetcher({
        chapterUrl(1): unrecognized,
        chapterUrl(2): unrecognized,
      });
      final service = serviceFor();

      final outcome = await service.download(bookId);

      expect(outcome, WebDownloadOutcome.paused);
      expect(processing.discards, isEmpty);
      expect(service.messageFor(bookId), isNull);
    });
  });
}
