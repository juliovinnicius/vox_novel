import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/web_source/data/services/html_recipe_parser.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';

SiteRecipe recipeWith({int minimumChapterCharacters = 200}) => SiteRecipe(
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
  disallowedPathPatterns: const ['/pdf/', '/search/', '/?s='],
  minimumChapterCharacters: minimumChapterCharacters,
);

/// A minimal page carrying only the recipe's container, for the length rules.
String pageWithBody(String body) =>
    '<html><body><h1 class="entry-title">Título sintético</h1>'
    '<div class="epcontent entry-content">$body</div></body></html>';

void main() {
  const parser = HtmlRecipeParser();
  final fixture = File('test/fixtures/web_chapter.html').readAsStringSync();

  test('extracts the chapter title through the recipe selector', () {
    final result = parser.parseChapter(fixture, recipeWith()) as ChapterParsed;

    expect(result.title, 'Capítulo 1 - O começo sintético');
  });

  test('joins the container paragraphs in document order', () {
    final result = parser.parseChapter(fixture, recipeWith()) as ChapterParsed;

    expect(result.text, [
      'Parágrafo um da fixture sintética, escrito apenas para exercitar os '
          'seletores da receita.',
      'Parágrafo dois com ênfase e uma quebra de linha no HTML que deve ser '
          'normalizada.',
      'Parágrafo três, aninhado dentro do contêiner de conteúdo.',
      'Parágrafo quatro encerra o capítulo sintético.',
    ].join('\n\n'));
  });

  test('excludes navigation, ads, comments and footer outside the container', () {
    final result = parser.parseChapter(fixture, recipeWith()) as ChapterParsed;

    expect(result.text, isNot(contains('menu sintético')));
    expect(result.text, isNot(contains('Anúncio')));
    expect(result.text, isNot(contains('Próximo capítulo')));
    expect(result.text, isNot(contains('Comentário')));
    expect(result.text, isNot(contains('Rodapé')));
  });

  test('fails extraction when the content container is absent, naming the '
      'selector', () {
    final result = parser.parseChapter(
      '<html><body><h1 class="entry-title">Título</h1>'
      '<div class="outro"><p>Texto fora do contêiner da receita.</p></div>'
      '</body></html>',
      recipeWith(),
    );

    expect(result, isA<ChapterParseFailed>());
    expect(
      (result as ChapterParseFailed).message,
      contains('div.epcontent.entry-content'),
    );
  });

  test('fails extraction when the container holds no paragraph text', () {
    final result = parser.parseChapter(
      pageWithBody('<p>   </p><div class="wrapper"></div>'),
      recipeWith(),
    );

    expect(result, isA<ChapterParseFailed>());
  });

  test('fails extraction when the text is shorter than the recipe minimum', () {
    final result = parser.parseChapter(
      pageWithBody('<p>${'a' * 199}</p>'),
      recipeWith(),
    );

    expect(result, isA<ChapterParseFailed>());
  });

  test('parses text of exactly the recipe minimum length', () {
    final result = parser.parseChapter(
      pageWithBody('<p>${'a' * 200}</p>'),
      recipeWith(),
    );

    expect(result, isA<ChapterParsed>());
    expect((result as ChapterParsed).text, 'a' * 200);
  });
}
