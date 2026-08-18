import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';

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

  static String _title(Document document, SiteRecipe recipe) {
    final element = document.querySelector(recipe.chapterTitleSelector);
    return element == null ? '' : _collapse(element.text);
  }

  static String _collapse(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
