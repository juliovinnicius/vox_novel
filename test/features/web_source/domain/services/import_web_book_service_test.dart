import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/import_web_book_service.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';
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

/// A series page the recipe recognizes but that lists no chapter at all.
const String emptySeriesPage =
    '<html><body><h1 class="entry-title">Obra sem capítulos</h1>'
    '<div class="eplister"><ul></ul></div></body></html>';

final class FakeWebFetcher implements WebFetcher {
  FakeWebFetcher(this.pages, {this.failure});

  final Map<String, String> pages;
  final WebFetchFailed? failure;
  final List<Uri> requests = [];

  @override
  Future<WebFetchResult> fetch(Uri url) async {
    requests.add(url);
    if (failure != null) return failure!;
    final body = pages[url.toString()];
    return body == null
        ? WebFetchFailed(
            WebFetchFailureKind.notFound,
            'Página não encontrada: $url',
          )
        : WebFetchSucceeded(url: url, body: body);
  }
}

final class FakeBookRepository implements BookRepository {
  final List<Book> books = [];
  final List<String> deleted = [];
  bool failInsert = false;

  @override
  Future<Book?> findById(String id) async =>
      books.where((book) => book.id == id).firstOrNull;

  @override
  Future<Book?> findBySourceRef(String sourceRef) async =>
      books.where((book) => book.sourceRef == sourceRef).firstOrNull;

  @override
  Future<void> insert(Book book) async {
    if (failInsert) throw StateError('insert failed');
    books.add(book);
  }

  @override
  Future<void> deleteById(String id) async {
    deleted.add(id);
    books.removeWhere((book) => book.id == id);
  }

  @override
  Stream<List<Book>> watchAll() => throw UnimplementedError();
  @override
  Future<Book?> findByHash(String hash) => throw UnimplementedError();
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
}

final class FakeWebSourceRepository implements WebSourceRepository {
  final List<(String bookId, List<WebChapterRef> chapters)> replacements = [];
  bool failReplace = false;

  @override
  Future<void> replaceIndex(String bookId, List<WebChapterRef> chapters) async {
    if (failReplace) throw StateError('replaceIndex failed');
    replacements.add((bookId, chapters));
  }

  @override
  Future<List<WebChapterEntry>> pending(String bookId) =>
      throw UnimplementedError();
  @override
  Future<List<WebChapterEntry>> failed(String bookId) =>
      throw UnimplementedError();
  @override
  Future<WebChapterCounts> counts(String bookId) => throw UnimplementedError();
  @override
  Future<Set<String>> knownUrls(String bookId) => throw UnimplementedError();
  @override
  Future<int> appendNew(String bookId, List<WebChapterRef> chapters) =>
      throw UnimplementedError();
  @override
  Future<void> markStored(String bookId, int sortOrder, DateTime at) =>
      throw UnimplementedError();
  @override
  Future<void> markFailed(
    String bookId,
    int sortOrder,
    String reason,
    DateTime at,
  ) => throw UnimplementedError();
}

void main() {
  const seriesUrl = 'https://exemplo.com/series/obra-sintetica/';
  const chapterUrl = 'https://exemplo.com/obra-sintetica-capitulo-1/';
  final seriesPage = File(
    'test/fixtures/web_series_index.html',
  ).readAsStringSync();
  final chapterPage = File(
    'test/fixtures/web_chapter.html',
  ).readAsStringSync();
  final createdAt = DateTime.utc(2026, 8, 18, 10);

  late FakeWebFetcher fetcher;
  late FakeBookRepository books;
  late FakeWebSourceRepository source;
  late List<String> downloads;
  late int nextId;

  ImportWebBookService serviceFor(FakeWebFetcher target) =>
      ImportWebBookService(
        books: books,
        source: source,
        resolver: WebNovelIndexResolver(
          fetcher: target,
          recipes: SiteRecipeRegistry(const [exampleRecipe]),
        ),
        startDownload: downloads.add,
        generateId: () => 'book-${++nextId}',
        clock: () => createdAt,
      );

  setUp(() {
    fetcher = FakeWebFetcher({
      seriesUrl: seriesPage,
      chapterUrl: chapterPage,
    });
    books = FakeBookRepository();
    source = FakeWebSourceRepository();
    downloads = [];
    nextId = 0;
  });

  Future<ImportWebBookResult> import(String url) =>
      serviceFor(fetcher).import(url);

  test('a series url creates a web book carrying the series title and the '
      'canonical series url as its source reference', () async {
    final result = await import(seriesUrl) as WebBookImported;

    expect(result.created, isTrue);
    expect(result.book.title, 'Obra sintética');
    expect(result.book.sourceType, BookSourceType.web);
    expect(result.book.sourceRef, seriesUrl);
    expect(result.book.status, BookStatus.processing);
    expect(result.book.processingProgress, 0);
    expect(result.book.storedFilePath, isNull);
    expect(books.books.single.id, result.book.id);
  });

  test('the persisted index holds every chapter of the series page in source '
      'order', () async {
    final result = await import(seriesUrl) as WebBookImported;

    final (bookId, chapters) = source.replacements.single;
    expect(bookId, result.book.id);
    expect([for (final chapter in chapters) chapter.url], [
      'https://exemplo.com/obra-sintetica-capitulo-1/',
      'https://exemplo.com/obra-sintetica-capitulo-2/',
      'https://exemplo.com/obra-sintetica-capitulo-3/',
      'https://exemplo.com/obra-sintetica-capitulo-4/',
    ]);
    expect([for (final chapter in chapters) chapter.sortOrder], [1, 2, 3, 4]);
    expect(result.book.pageCount, 4);
  });

  test('a chapter url imports the same book the series url would', () async {
    final fromChapter = await import(chapterUrl) as WebBookImported;
    final indexed = source.replacements.single.$2;

    expect(fromChapter.book.sourceRef, seriesUrl);
    expect(fromChapter.book.title, 'Obra sintética');
    expect([for (final chapter in indexed) chapter.url], [
      'https://exemplo.com/obra-sintetica-capitulo-1/',
      'https://exemplo.com/obra-sintetica-capitulo-2/',
      'https://exemplo.com/obra-sintetica-capitulo-3/',
      'https://exemplo.com/obra-sintetica-capitulo-4/',
    ]);
  });

  test('an unsupported domain is rejected with a message naming it and '
      'creates no book', () async {
    final result =
        await import('https://outrosite.com/series/x/') as WebBookImportRejected;

    expect(result.reason, ImportWebBookRejection.unsupportedDomain);
    expect(result.message, 'Site não suportado: outrosite.com');
    expect(books.books, isEmpty);
    expect(source.replacements, isEmpty);
    expect(fetcher.requests, isEmpty);
  });

  test('text that is not an absolute http url is rejected and creates no '
      'book', () async {
    final result = await import('nem sequer uma url') as WebBookImportRejected;

    expect(result.reason, ImportWebBookRejection.invalidUrl);
    expect(result.message, 'Informe uma URL válida');
    expect(books.books, isEmpty);
    expect(fetcher.requests, isEmpty);
  });

  test('a path the recipe disallows is rejected and creates no book', () async {
    final result =
        await import('$chapterUrl' 'pdf/') as WebBookImportRejected;

    expect(result.reason, ImportWebBookRejection.disallowedPath);
    expect(result.message, 'Este endereço não é permitido pelo site');
    expect(books.books, isEmpty);
    expect(fetcher.requests, isEmpty);
  });

  test('re-importing the same series resolves to the existing book and '
      'inserts no second row', () async {
    final first = await import(seriesUrl) as WebBookImported;
    final second = await import(chapterUrl) as WebBookImported;

    expect(second.created, isFalse);
    expect(second.book.id, first.book.id);
    expect(books.books.length, 1);
    expect(source.replacements.length, 1);
  });

  test('a series page with zero chapters is rejected as unsupported and '
      'creates no book', () async {
    final empty = FakeWebFetcher({seriesUrl: emptySeriesPage});

    final result =
        await serviceFor(empty).import(seriesUrl) as WebBookImportRejected;

    expect(result.reason, ImportWebBookRejection.unsupported);
    expect(result.message, 'Nenhum capítulo encontrado');
    expect(books.books, isEmpty);
  });

  test('a network failure during import leaves no book behind', () async {
    final offline = FakeWebFetcher(
      const {},
      failure: const WebFetchFailed(
        WebFetchFailureKind.network,
        'Sem conexão com a internet',
      ),
    );

    final result =
        await serviceFor(offline).import(seriesUrl) as WebBookImportRejected;

    expect(result.reason, ImportWebBookRejection.network);
    expect(result.message, 'Sem conexão com a internet');
    expect(books.books, isEmpty);
    expect(source.replacements, isEmpty);
  });

  test('a failure while persisting the index removes the book it had already '
      'inserted', () async {
    source.failReplace = true;

    final result = await import(seriesUrl) as WebBookImportRejected;

    expect(result.reason, ImportWebBookRejection.storage);
    expect(result.message, ImportWebBookService.storageMessage);
    expect(books.books, isEmpty);
    expect(books.deleted, ['book-1']);
  });

  test('a successful import hands the book to the download service and a '
      'rejected one does not', () async {
    final imported = await import(seriesUrl) as WebBookImported;
    expect(downloads, [imported.book.id]);

    await import('https://outrosite.com/series/x/');
    expect(downloads, [imported.book.id]);
  });
}
