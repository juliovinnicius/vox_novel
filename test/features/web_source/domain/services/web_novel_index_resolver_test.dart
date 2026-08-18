import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
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

/// A hand-written fetcher fake. It serves stored fixtures and records every
/// URL it was asked for, so "rejected before any request" is observable.
final class FakeWebFetcher implements WebFetcher {
  FakeWebFetcher(this.pages, {this.failure});

  final Map<String, String> pages;
  final WebFetchFailed? failure;
  final List<Uri> requests = [];

  @override
  Future<WebFetchResult> fetch(Uri url) async {
    requests.add(url);
    if (failure != null) {
      return failure!;
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

void main() {
  const seriesUrl = 'https://exemplo.com/series/obra-sintetica/';
  const chapterUrl = 'https://exemplo.com/obra-sintetica-capitulo-1/';
  final seriesPage = File(
    'test/fixtures/web_series_index.html',
  ).readAsStringSync();
  final chapterPage = File(
    'test/fixtures/web_chapter.html',
  ).readAsStringSync();

  late FakeWebFetcher fetcher;

  WebNovelIndexResolver resolverFor(FakeWebFetcher target) =>
      WebNovelIndexResolver(
        fetcher: target,
        recipes: SiteRecipeRegistry(const [exampleRecipe]),
      );

  setUp(() {
    fetcher = FakeWebFetcher({
      seriesUrl: seriesPage,
      chapterUrl: chapterPage,
    });
  });

  Future<WebNovelIndexResult> resolve(String url) =>
      resolverFor(fetcher).resolve(Uri.parse(url));

  List<String> urlsOf(WebNovelIndex index) =>
      [for (final chapter in index.chapters) chapter.url];

  test('resolves a series url directly into its ordered index', () async {
    final result = await resolve(seriesUrl) as WebNovelIndexResolved;

    expect(fetcher.requests.map((url) => url.toString()), [seriesUrl]);
    expect(result.index.seriesUrl.toString(), seriesUrl);
    expect(result.index.title, 'Obra sintética');
    expect(urlsOf(result.index), [
      'https://exemplo.com/obra-sintetica-capitulo-1/',
      'https://exemplo.com/obra-sintetica-capitulo-2/',
      'https://exemplo.com/obra-sintetica-capitulo-3/',
      'https://exemplo.com/obra-sintetica-capitulo-4/',
    ]);
    expect([for (final chapter in result.index.chapters) chapter.sortOrder], [
      1,
      2,
      3,
      4,
    ]);
  });

  test('resolves a chapter url through the breadcrumb series link', () async {
    final result = await resolve(chapterUrl) as WebNovelIndexResolved;

    expect(fetcher.requests.map((url) => url.toString()), [
      chapterUrl,
      seriesUrl,
    ]);
    expect(result.index.seriesUrl.toString(), seriesUrl);
  });

  test('a chapter url and its series url produce identical indexes', () async {
    final fromChapter = await resolve(chapterUrl) as WebNovelIndexResolved;
    final fromSeries = await resolve(seriesUrl) as WebNovelIndexResolved;

    expect(fromChapter.index.chapters, fromSeries.index.chapters);
    expect(fromChapter.index.seriesUrl, fromSeries.index.seriesUrl);
    expect(fromChapter.index.title, fromSeries.index.title);
  });

  test('a leading www. and host casing resolve to the same recipe and the '
      'same canonical series url', () async {
    final result =
        await resolve('https://WWW.Exemplo.com/series/obra-sintetica/')
            as WebNovelIndexResolved;

    expect(fetcher.requests.map((url) => url.toString()), [seriesUrl]);
    expect(result.index.seriesUrl.toString(), seriesUrl);
  });

  test('a non-absolute url is rejected before any request', () async {
    final result = await resolve('/series/obra-sintetica/');

    expect(fetcher.requests, isEmpty);
    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.invalidUrl,
    );
    expect(result.message, 'Informe uma URL válida');
  });

  test('a non-http scheme is rejected before any request', () async {
    final result = await resolve('ftp://exemplo.com/series/obra-sintetica/');

    expect(fetcher.requests, isEmpty);
    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.invalidUrl,
    );
  });

  test('an unknown host is rejected naming the domain, before any '
      'request', () async {
    final result = await resolve('https://desconhecido.com/series/obra/');

    expect(fetcher.requests, isEmpty);
    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.unsupportedDomain,
    );
    expect(result.message, 'Site não suportado: desconhecido.com');
  });

  test('a disallowed path is rejected naming the restriction, before any '
      'request', () async {
    final result = await resolve('$chapterUrl' 'pdf/');

    expect(fetcher.requests, isEmpty);
    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.disallowedPath,
    );
    expect(result.message, 'Este endereço não é permitido pelo site');
  });

  test('a disallowed search query is rejected before any request', () async {
    final result = await resolve('https://exemplo.com/?s=obra');

    expect(fetcher.requests, isEmpty);
    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.disallowedPath,
    );
  });

  test('a breadcrumb leaving the recipe domain is rejected before it is '
      'fetched', () async {
    final offDomain = FakeWebFetcher({
      chapterUrl:
          '<html><body><a itemprop="item" '
          'href="https://outrosite.com/series/obra/">Obra</a></body></html>',
    });

    final result = await resolverFor(offDomain).resolve(Uri.parse(chapterUrl));

    expect(offDomain.requests.map((url) => url.toString()), [chapterUrl]);
    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.unsupportedDomain,
    );
    expect(result.message, 'Site não suportado: outrosite.com');
  });

  test('an empty index surfaces the unsupported outcome', () async {
    final empty = FakeWebFetcher({
      seriesUrl: '<html><body><div class="eplister"><ul></ul></div>'
          '</body></html>',
    });

    final result = await resolverFor(empty).resolve(Uri.parse(seriesUrl));

    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.unsupported,
    );
    expect(result.message, 'Nenhum capítulo encontrado');
  });

  test('a network failure surfaces the fetch message without an index', () async {
    final offline = FakeWebFetcher(
      const {},
      failure: const WebFetchFailed(
        WebFetchFailureKind.network,
        'Falha de rede ao acessar $seriesUrl',
      ),
    );

    final result = await resolverFor(offline).resolve(Uri.parse(seriesUrl));

    expect(
      (result as WebNovelIndexRejected).reason,
      WebNovelIndexRejection.network,
    );
    expect(result.message, 'Falha de rede ao acessar $seriesUrl');
  });
}
