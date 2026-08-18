import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/web_source/data/services/html_recipe_parser.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';

SiteRecipe recipeWith({
  int minimumChapterCharacters = 200,
  ChapterIndexOrder chapterIndexOrder = ChapterIndexOrder.descending,
}) => SiteRecipe(
  domain: 'exemplo.com',
  seriesPathPrefix: '/series/',
  seriesLinkSelector: "a[itemprop=item][href*='/series/']",
  chapterIndexSelector: 'div.eplister li > a',
  chapterIndexTitleSelector: 'div.epl-title',
  chapterIndexOrder: chapterIndexOrder,
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

  group('chapter index', () {
    final index = File('test/fixtures/web_series_index.html').readAsStringSync();
    final seriesUrl = Uri.parse('https://exemplo.com/series/obra-sintetica/');
    const chapterUrl = 'https://exemplo.com/obra-sintetica-capitulo-';

    List<WebChapterRef> parse(
      String html, {
      ChapterIndexOrder order = ChapterIndexOrder.descending,
    }) {
      final result = parser.parseChapterIndex(
        html,
        recipeWith(chapterIndexOrder: order),
        base: seriesUrl,
      );
      return (result as ChapterIndexParsed).chapters;
    }

    /// A list item shaped like the site's: chapter anchor as a direct child,
    /// download anchor in a sibling container.
    String listItem(String href, {String variantClass = ''}) =>
        '<li class="$variantClass"><a href="$href">'
        '<div class="epl-title">Título de $href</div></a>'
        '<div class="epl-pdf"><a class="dlpdf" href="${href}pdf/">PDF</a></div>'
        '</li>';

    String listPage(String items) =>
        '<html><body><div class="eplister"><ul>$items</ul></div></body></html>';

    test('reads every chapter the page lists and nothing else', () {
      final chapters = parse(index);

      expect(chapters.map((chapter) => chapter.url), [
        '${chapterUrl}1/',
        '${chapterUrl}2/',
        '${chapterUrl}3/',
        '${chapterUrl}4/',
      ]);
    });

    test('never lets a disallowed download url into the index', () {
      final chapters = parse(index);

      expect(
        chapters.where((chapter) => chapter.url.contains('/pdf/')),
        isEmpty,
      );
    });

    test('includes the list item carrying the variant class', () {
      final chapters = parse(index);

      expect(
        chapters.map((chapter) => chapter.url),
        contains('${chapterUrl}1/'),
      );
    });

    test('reverses a descending index so sortOrder 1 is the oldest chapter', () {
      final chapters = parse(index);

      expect(chapters.first.sortOrder, 1);
      expect(chapters.first.url, '${chapterUrl}1/');
      expect(chapters.last.sortOrder, 4);
      expect(chapters.last.url, '${chapterUrl}4/');
    });

    test('keeps document order for an ascending index', () {
      final chapters = parse(index, order: ChapterIndexOrder.ascending);

      expect(chapters.first.url, '${chapterUrl}4/');
      expect(chapters.last.url, '${chapterUrl}1/');
    });

    test('takes each chapter title from the index title selector', () {
      final chapters = parse(index);

      expect(chapters.map((chapter) => chapter.title), [
        'O primeiro capítulo sintético',
        'O segundo capítulo sintético',
        'O terceiro capítulo sintético',
        'O quarto capítulo sintético',
      ]);
    });

    test('collapses a repeated url to one contiguous entry', () {
      final chapters = parse(
        listPage([
          listItem('https://exemplo.com/capitulo-a/'),
          listItem('https://exemplo.com/capitulo-b/'),
          listItem('https://exemplo.com/capitulo-a/'),
        ].join()),
        order: ChapterIndexOrder.ascending,
      );

      expect(chapters.map((chapter) => chapter.url), [
        'https://exemplo.com/capitulo-a/',
        'https://exemplo.com/capitulo-b/',
      ]);
      expect(chapters.map((chapter) => chapter.sortOrder), [1, 2]);
    });

    test('fails loudly when the selector reads fewer chapters than the page '
        'lists', () {
      final result = parser.parseChapterIndex(
        listPage([
          listItem('https://exemplo.com/capitulo-a/'),
          // A variant item whose anchor is not a direct child of the li, so
          // the recipe selector misses it.
          '<li><span><a href="https://exemplo.com/capitulo-b/">'
              '<div class="epl-title">B</div></a></span>'
              '<div class="epl-pdf">'
              '<a class="dlpdf" href="https://exemplo.com/capitulo-b/pdf/">'
              'PDF</a></div></li>',
          listItem('https://exemplo.com/capitulo-c/'),
        ].join()),
        recipeWith(),
        base: seriesUrl,
      );

      expect(result, isA<ChapterIndexParseFailed>());
      expect((result as ChapterIndexParseFailed).message, contains('2'));
      expect(result.message, contains('3'));
    });

    test('reads an empty index from a page that lists no chapters', () {
      expect(parse(listPage('')), isEmpty);
    });

    test('resolves a relative chapter href against the series url', () {
      final chapters = parse(
        listPage(listItem('/obra-sintetica-capitulo-9/')),
        order: ChapterIndexOrder.ascending,
      );

      expect(chapters.single.url, '${chapterUrl}9/');
    });
  });
}
