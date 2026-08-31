import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
import 'package:vox_novel/features/library/data/repositories/drift_book_repository.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/data/repositories/drift_narration_repository.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_session.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/visual_reader/data/repositories/drift_visual_reader_repository.dart';
import 'package:vox_novel/features/web_source/data/repositories/drift_web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/import_web_book_service.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_download_service.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_index_resolver.dart';

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

const String seriesUrl = 'https://exemplo.com/series/obra-sintetica/';

String chapterUrl(int ordinal) =>
    'https://exemplo.com/obra-sintetica-capitulo-$ordinal/';

/// A chapter page long enough to clear the recipe's minimum length.
String chapterPage(int ordinal) =>
    '<html><body><h1 class="entry-title">Capítulo $ordinal</h1>'
    '<div class="epcontent entry-content"><p>'
    '${'Texto sintético do capítulo $ordinal. ' * 8}'
    '</p></div></body></html>';

/// A hand-written fetcher over stored fixtures. It never touches the network.
final class FakeWebFetcher implements WebFetcher {
  FakeWebFetcher(this.pages, {this.onFetch, this.missing = const {}});

  final Map<String, String> pages;
  final Set<String> missing;

  /// Runs before the response is produced, so a test can act mid-download.
  final void Function(Uri url)? onFetch;
  final List<Uri> requests = [];

  @override
  Future<WebFetchResult> fetch(Uri url) async {
    requests.add(url);
    onFetch?.call(url);
    final key = url.toString();
    if (missing.contains(key)) {
      return WebFetchFailed(WebFetchFailureKind.notFound, 'Não encontrado');
    }
    final body = pages[key];
    return body == null
        ? WebFetchFailed(WebFetchFailureKind.notFound, 'Não encontrado')
        : WebFetchSucceeded(url: url, body: body);
  }
}

/// A fetcher that fails the test if anything asks it for a page.
final class ForbiddenWebFetcher implements WebFetcher {
  @override
  Future<WebFetchResult> fetch(Uri url) async {
    fail('An offline read must not request $url');
  }
}

final class FakeEngine implements NarrationEngine {
  final spoken = <String>[];

  @override
  Future<List<NarrationVoice>> initialize() async => [
    NarrationVoice(name: 'Ana', locale: 'pt-BR'),
  ];
  @override
  Future<void> configure(NarrationVoice voice, double rate) async {}
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
  @override
  Future<void> close() async {}
}

/// Counts every generated id in the process, so a harness rebuilt after a
/// restart never re-issues an id the previous one persisted.
int _generatedIds = 0;

/// Everything the web flow needs, composed over one open database.
final class Harness {
  Harness(this.database, this.fetcher) {
    books = DriftBookRepository(database);
    source = DriftWebSourceRepository(database, clock: _clock);
    processing = DriftTextProcessingRepository(database);
    reader = DriftVisualReaderRepository(database);
    downloads = WebNovelDownloadService(
      books: books,
      source: source,
      processing: processing,
      ingest: ChapterIngest(
        processing: processing,
        chapterId: _nextId,
        blockId: _nextId,
      ),
      fetcher: fetcher,
      recipes: SiteRecipeRegistry(const [exampleRecipe]),
      clock: _clock,
      runId: _nextId,
    );
    importer = ImportWebBookService(
      books: books,
      source: source,
      resolver: WebNovelIndexResolver(
        fetcher: fetcher,
        recipes: SiteRecipeRegistry(const [exampleRecipe]),
      ),
      startDownload: startedDownloads.add,
      generateId: _nextId,
      clock: _clock,
    );
  }

  final AppDatabase database;
  final WebFetcher fetcher;
  final List<String> startedDownloads = [];
  late final DriftBookRepository books;
  late final WebSourceRepository source;
  late final DriftTextProcessingRepository processing;
  late final DriftVisualReaderRepository reader;
  late final WebNovelDownloadService downloads;
  late final ImportWebBookService importer;

  /// Ids are unique across restarts, as the production UUID generator is.
  String _nextId() => 'id-${++_generatedIds}';
  DateTime _clock() => DateTime.utc(2026, 8, 18, 9);

  NarrationCubit narration(FakeEngine engine) => NarrationCubit(
    session: NarrationSession(
      repository: DriftNarrationRepository(database),
      engine: engine,
      clock: _clock,
      loadContent: reader.loadContent,
    ),
  );
}

void main() {
  final seriesPage = File(
    'test/fixtures/web_series_index.html',
  ).readAsStringSync();
  final chapterOnePage = File(
    'test/fixtures/web_chapter.html',
  ).readAsStringSync();

  late Directory directory;
  late File file;
  late AppDatabase database;

  Map<String, String> allPages() => {
    seriesUrl: seriesPage,
    chapterUrl(1): chapterOnePage,
    for (var ordinal = 2; ordinal <= 4; ordinal++)
      chapterUrl(ordinal): chapterPage(ordinal),
  };

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('web_source_');
    file = File('${directory.path}/library.sqlite');
    database = AppDatabase(NativeDatabase(file));
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  /// Reopens the database on the same file, as an app restart would.
  Harness restart(WebFetcher fetcher) {
    database = AppDatabase(NativeDatabase(file));
    return Harness(database, fetcher);
  }

  /// Imports the series and downloads it until [stopAfter] chapters are
  /// stored, cancelling the queue there.
  Future<String> importAndDownload(
    Harness harness, {
    required int stopAfter,
  }) async {
    final imported =
        await harness.importer.import(chapterUrl(1)) as WebBookImported;
    if (stopAfter > 0) await harness.downloads.download(imported.book.id);
    return imported.book.id;
  }

  test('an import from a chapter url persists the whole series index', () async {
    final fetcher = FakeWebFetcher(allPages());
    final harness = Harness(database, fetcher);

    final imported =
        await harness.importer.import(chapterUrl(1)) as WebBookImported;

    final stored = await harness.books.findById(imported.book.id);
    expect(stored?.title, 'Obra sintética');
    expect(stored?.sourceType, BookSourceType.web);
    expect(stored?.sourceRef, seriesUrl);
    expect(stored?.status, BookStatus.processing);
    expect(stored?.pageCount, 4);
    expect(stored?.storedFilePath, isNull);
    expect(
      await harness.source.counts(imported.book.id),
      const WebChapterCounts(total: 4, stored: 0, failed: 0),
    );
    expect(
      (await harness.source.pending(
        imported.book.id,
      )).map((entry) => entry.url),
      [chapterUrl(1), chapterUrl(2), chapterUrl(3), chapterUrl(4)],
    );
    expect(harness.startedDownloads, [imported.book.id]);
  });

  test('a book is readable and narratable while its queue still has pending '
      'chapters', () async {
    late Harness harness;
    // Cancel once the second chapter has been requested, so two chapters are
    // stored and two stay pending.
    final fetcher = FakeWebFetcher(
      allPages(),
      onFetch: (url) {
        // Cancelling during the second chapter's fetch still stores it and
        // stops the pass before the third, leaving two chapters pending.
        if (url.toString() == chapterUrl(2)) {
          harness.downloads.cancel(harness.startedDownloads.single);
        }
      },
    );
    harness = Harness(database, fetcher);

    final bookId = await importAndDownload(harness, stopAfter: 2);

    final book = await harness.books.findById(bookId);
    expect(book?.status, BookStatus.processing);
    expect(book?.chapterCount, 2);
    final content = await harness.reader.loadContent(bookId);
    expect(content, isNotNull);
    expect(content!.chapters.map((item) => item.chapter.sortOrder), [0, 1]);
    expect(
      content.chapters.first.chapter.title,
      'O primeiro capítulo sintético',
    );

    final engine = FakeEngine();
    final cubit = harness.narration(engine);
    addTearDown(cubit.close);
    await cubit.load(content);
    expect(cubit.state.status, NarrationStatus.ready);
    await cubit.play();

    expect(engine.spoken, isNotEmpty);
    expect(engine.spoken.first, contains('Parágrafo um'));
    // The queue ended on a chapter that has not downloaded yet, so the book
    // has not ended.
    expect(cubit.state.status, NarrationStatus.awaitingDownload);
    expect(
      (await harness.source.counts(bookId)).stored,
      2,
    );
  });

  test('a restart resumes the queue without re-fetching stored chapters',
      () async {
    late Harness first;
    final stopping = FakeWebFetcher(
      allPages(),
      onFetch: (url) {
        if (url.toString() == chapterUrl(2)) {
          first.downloads.cancel(first.startedDownloads.single);
        }
      },
    );
    first = Harness(database, stopping);
    final bookId = await importAndDownload(first, stopAfter: 2);
    await database.close();

    final resumed = FakeWebFetcher(allPages());
    final second = restart(resumed);
    final outcome = await second.downloads.download(bookId);

    expect(outcome, WebDownloadOutcome.completed);
    expect(resumed.requests.map((url) => url.toString()), [
      chapterUrl(3),
      chapterUrl(4),
    ]);
    expect(
      await second.source.counts(bookId),
      const WebChapterCounts(total: 4, stored: 4, failed: 0),
    );
    final book = await second.books.findById(bookId);
    expect(book?.status, BookStatus.ready);
    expect(book?.chapterCount, 4);
  });

  test('a completed book reads and narrates with no request at all', () async {
    final fetcher = FakeWebFetcher(allPages());
    final harness = Harness(database, fetcher);
    final bookId = await importAndDownload(harness, stopAfter: 4);
    await database.close();

    final offline = restart(ForbiddenWebFetcher());
    final content = await offline.reader.loadContent(bookId);

    expect(content, isNotNull);
    expect(content!.book.status, BookStatus.ready);
    expect(content.chapters.map((item) => item.chapter.sortOrder), [0, 1, 2, 3]);
    final engine = FakeEngine();
    final cubit = offline.narration(engine);
    addTearDown(cubit.close);
    await cubit.load(content);
    await cubit.play();

    expect(cubit.state.status, NarrationStatus.completed);
    expect(engine.spoken, isNotEmpty);
  });

  test('a chapter that 404s leaves a hole the reader still opens', () async {
    final fetcher = FakeWebFetcher(allPages(), missing: {chapterUrl(2)});
    final harness = Harness(database, fetcher);

    final bookId = await importAndDownload(harness, stopAfter: 4);

    expect(
      await harness.source.counts(bookId),
      const WebChapterCounts(total: 4, stored: 3, failed: 1),
    );
    final book = await harness.books.findById(bookId);
    expect(book?.status, BookStatus.processing);
    final content = await harness.reader.loadContent(bookId);
    expect(content!.chapters.map((item) => item.chapter.sortOrder), [0, 2, 3]);
  });
}
