import 'package:vox_novel/features/web_source/data/services/html_recipe_parser.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';

/// The chapter index of a series, as the site lists it.
final class WebNovelIndex {
  const WebNovelIndex({
    required this.seriesUrl,
    required this.title,
    required this.chapters,
  });

  /// The canonical series URL — the web equivalent of a PDF's file hash.
  final Uri seriesUrl;
  final String title;

  /// Ordered oldest-first, deduplicated, `sortOrder` starting at 1.
  final List<WebChapterRef> chapters;
}

/// Why a submitted URL did not produce an index. Each reason carries its own
/// user-facing message so the import flow can tell them apart.
enum WebNovelIndexRejection {
  invalidUrl,
  unsupportedDomain,
  disallowedPath,
  network,
  unsupported,
}

// SPEC_DEVIATION: design.md declares `Future<WebNovelIndex> resolve(Uri)`,
// which can only report a rejection by throwing.
// Reason: the import flow must distinguish every rejection reason to render a
// distinct message, and the sibling web_source components (`WebFetchResult`,
// `ChapterParseResult`) already report outcomes through sealed results.
sealed class WebNovelIndexResult {
  const WebNovelIndexResult();
}

final class WebNovelIndexResolved extends WebNovelIndexResult {
  const WebNovelIndexResolved(this.index);

  final WebNovelIndex index;
}

final class WebNovelIndexRejected extends WebNovelIndexResult {
  const WebNovelIndexRejected(this.reason, this.message);

  final WebNovelIndexRejection reason;
  final String message;
}

/// Normalizes any supported URL to its series URL and reads the chapter index.
///
/// Every rejection that can be decided from the URL alone is decided before a
/// request is issued, so an unsupported site is never contacted.
final class WebNovelIndexResolver {
  const WebNovelIndexResolver({
    required WebFetcher fetcher,
    required SiteRecipeRegistry recipes,
    HtmlRecipeParser parser = const HtmlRecipeParser(),
  }) : // Public dependency names intentionally omit private implementation
       // prefixes while preserving named constructor injection.
       // ignore: prefer_initializing_formals
       _fetcher = fetcher,
       // ignore: prefer_initializing_formals
       _recipes = recipes,
       // ignore: prefer_initializing_formals
       _parser = parser;

  final WebFetcher _fetcher;
  final SiteRecipeRegistry _recipes;
  final HtmlRecipeParser _parser;

  Future<WebNovelIndexResult> resolve(Uri submitted) async {
    final rejection = _rejectionFor(submitted);
    if (rejection != null) {
      return rejection;
    }
    final recipe = _recipeFor(submitted)!;
    final url = _canonical(submitted);
    return url.path.startsWith(recipe.seriesPathPrefix)
        ? _fromSeriesPage(url, recipe)
        : _fromChapterPage(url, recipe);
  }

  Future<WebNovelIndexResult> _fromChapterPage(
    Uri chapterUrl,
    SiteRecipe recipe,
  ) async {
    final page = await _fetcher.fetch(chapterUrl);
    if (page is WebFetchFailed) {
      return WebNovelIndexRejected(
        WebNovelIndexRejection.network,
        page.message,
      );
    }
    final body = (page as WebFetchSucceeded).body;
    final href = _parser.parseSeriesLink(body, recipe);
    if (href == null) {
      return const WebNovelIndexRejected(
        WebNovelIndexRejection.unsupported,
        'Não foi possível localizar a obra a partir deste capítulo',
      );
    }
    final seriesUrl = page.url.resolve(href);
    final rejection = _rejectionFor(seriesUrl);
    if (rejection != null) {
      return rejection;
    }
    return _fromSeriesPage(_canonical(seriesUrl), _recipeFor(seriesUrl)!);
  }

  Future<WebNovelIndexResult> _fromSeriesPage(
    Uri seriesUrl,
    SiteRecipe recipe,
  ) async {
    final page = await _fetcher.fetch(seriesUrl);
    if (page is WebFetchFailed) {
      return WebNovelIndexRejected(
        WebNovelIndexRejection.network,
        page.message,
      );
    }
    final parsed = _parser.parseChapterIndex(
      (page as WebFetchSucceeded).body,
      recipe,
      base: seriesUrl,
    );
    switch (parsed) {
      case ChapterIndexParseFailed(:final message):
        return WebNovelIndexRejected(
          WebNovelIndexRejection.unsupported,
          message,
        );
      case ChapterIndexParsed(:final title, :final chapters):
        if (chapters.isEmpty) {
          return const WebNovelIndexRejected(
            WebNovelIndexRejection.unsupported,
            'Nenhum capítulo encontrado',
          );
        }
        return WebNovelIndexResolved(
          WebNovelIndex(
            seriesUrl: seriesUrl,
            title: title,
            chapters: chapters,
          ),
        );
    }
  }

  /// The rejection [url] earns from its form alone, or `null` when it may be
  /// fetched.
  WebNovelIndexRejected? _rejectionFor(Uri url) {
    if (!url.isAbsolute ||
        !const {'http', 'https'}.contains(url.scheme.toLowerCase()) ||
        url.host.isEmpty) {
      return const WebNovelIndexRejected(
        WebNovelIndexRejection.invalidUrl,
        'Informe uma URL válida',
      );
    }
    final recipe = _recipeFor(url);
    if (recipe == null) {
      return WebNovelIndexRejected(
        WebNovelIndexRejection.unsupportedDomain,
        'Site não suportado: ${_canonicalHost(url.host)}',
      );
    }
    if (recipe.disallows(_pathAndQuery(url))) {
      return const WebNovelIndexRejected(
        WebNovelIndexRejection.disallowedPath,
        'Este endereço não é permitido pelo site',
      );
    }
    return null;
  }

  SiteRecipe? _recipeFor(Uri url) => _recipes.forHost(_canonicalHost(url.host));

  /// The stable identity of [url]: lower-case scheme and host, no leading
  /// `www.`, and no query or fragment.
  static Uri _canonical(Uri url) => Uri(
    scheme: url.scheme.toLowerCase(),
    host: _canonicalHost(url.host),
    port: url.hasPort ? url.port : null,
    path: url.path,
  );

  static String _canonicalHost(String host) {
    final lower = host.toLowerCase();
    return lower.startsWith('www.') ? lower.substring(4) : lower;
  }

  static String _pathAndQuery(Uri url) =>
      url.hasQuery ? '${url.path}?${url.query}' : url.path;
}
