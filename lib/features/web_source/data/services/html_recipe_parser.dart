import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';

sealed class ChapterParseResult {
  const ChapterParseResult();
}

final class ChapterParsed extends ChapterParseResult {
  const ChapterParsed({required this.title, required this.text});

  final String title;
  final String text;
}

/// The page was fetched but the recipe recognized no chapter in it.
///
/// The queue records this as a failed entry and never stores a stub chapter.
final class ChapterParseFailed extends ChapterParseResult {
  const ChapterParseFailed(this.message);

  final String message;
}

sealed class ChapterIndexParseResult {
  const ChapterIndexParseResult();
}

final class ChapterIndexParsed extends ChapterIndexParseResult {
  const ChapterIndexParsed(this.chapters);

  /// Deduplicated and ordered oldest-first, with `sortOrder` starting at 1.
  final List<WebChapterRef> chapters;
}

/// The index was recognized but could not be trusted, so importing it would
/// silently ship a book with missing chapters.
final class ChapterIndexParseFailed extends ChapterIndexParseResult {
  const ChapterIndexParseFailed(this.message);

  final String message;
}

/// Recipe-driven extraction over a site's static HTML.
final class HtmlRecipeParser {
  const HtmlRecipeParser();

  /// Extracts a chapter's title and body text from [html] using [recipe].
  ///
  /// Only content inside the recipe's container is considered, so navigation,
  /// comments, and ads outside it never reach the narration pipeline.
  ChapterParseResult parseChapter(String html, SiteRecipe recipe) {
    final document = html_parser.parse(html);

    final container = document.querySelector(recipe.contentSelector);
    if (container == null) {
      return ChapterParseFailed(
        'Conteúdo do capítulo não encontrado pelo seletor '
        '"${recipe.contentSelector}"',
      );
    }

    final paragraphs = [
      for (final paragraph in container.querySelectorAll(
        recipe.paragraphSelector,
      ))
        _collapse(paragraph.text),
    ]..removeWhere((paragraph) => paragraph.isEmpty);

    final text = paragraphs.join('\n\n');
    if (text.length < recipe.minimumChapterCharacters) {
      return ChapterParseFailed(
        'Texto extraído com ${text.length} caracteres, abaixo do mínimo de '
        '${recipe.minimumChapterCharacters} do site',
      );
    }

    return ChapterParsed(
      title: _title(document, recipe),
      text: text,
    );
  }

  /// Extracts the ordered chapter index of a series page from [html].
  ///
  /// Relative hrefs are resolved against [base]. The index a site lists is
  /// authoritative, so a selector that reads fewer chapters than the page
  /// actually lists fails loudly instead of returning a short list.
  ChapterIndexParseResult parseChapterIndex(
    String html,
    SiteRecipe recipe, {
    required Uri base,
  }) {
    final document = html_parser.parse(html);
    final anchors = document.querySelectorAll(recipe.chapterIndexSelector);

    // Each list item pairs its chapter link with a sibling link to the
    // robots-disallowed download path. Counting those siblings is how a
    // list-item variant the selector failed to match becomes visible.
    final companions = document
        .querySelectorAll('a[href]')
        .where((anchor) => _disallowed(anchor, recipe, base))
        .length;
    if (companions > 0 && companions != anchors.length) {
      return ChapterIndexParseFailed(
        'Índice incompleto: o seletor "${recipe.chapterIndexSelector}" leu '
        '${anchors.length} capítulos, mas a lista tem $companions itens',
      );
    }

    final byUrl = <String, String>{};
    for (final anchor in anchors) {
      final href = anchor.attributes['href']?.trim();
      if (href == null || href.isEmpty) {
        continue;
      }
      byUrl.putIfAbsent(
        base.resolve(href).toString(),
        () => _indexTitle(anchor, recipe),
      );
    }

    final entries = byUrl.entries.toList();
    final ordered = recipe.chapterIndexOrder == ChapterIndexOrder.descending
        ? entries.reversed.toList()
        : entries;

    return ChapterIndexParsed([
      for (var position = 0; position < ordered.length; position++)
        WebChapterRef(
          url: ordered[position].key,
          title: ordered[position].value,
          sortOrder: position + 1,
        ),
    ]);
  }

  static bool _disallowed(Element anchor, SiteRecipe recipe, Uri base) {
    final target = base.resolve(anchor.attributes['href']!);
    final path = target.hasQuery ? '${target.path}?${target.query}' : target.path;
    return recipe.disallows(path);
  }

  static String _indexTitle(Element anchor, SiteRecipe recipe) {
    final element = anchor.querySelector(recipe.chapterIndexTitleSelector);
    return _collapse((element ?? anchor).text);
  }

  static String _title(Document document, SiteRecipe recipe) {
    final element = document.querySelector(recipe.chapterTitleSelector);
    return element == null ? '' : _collapse(element.text);
  }

  static String _collapse(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
