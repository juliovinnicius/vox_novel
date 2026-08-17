import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, Object?> validRecipe() => {
    'domain': 'exemplo.com',
    'seriesPathPrefix': '/series/',
    'seriesLinkSelector': "a[itemprop=item][href*='/series/']",
    'chapterIndexSelector': 'div.eplister li > a',
    'chapterIndexTitleSelector': 'div.epl-title',
    'chapterIndexOrder': 'descending',
    'chapterTitleSelector': 'h1.entry-title',
    'contentSelector': 'div.epcontent.entry-content',
    'paragraphSelector': 'p',
    'nextChapterSelector': 'a[rel=next]',
    'disallowedPathPatterns': ['/pdf/'],
    'minimumChapterCharacters': 200,
  };

  group('ChapterIndexOrder', () {
    for (final order in ChapterIndexOrder.values) {
      test('${order.name} round-trips through storage', () {
        expect(ChapterIndexOrder.fromStorage(order.storageValue), order);
      });
    }
  });

  test('parses every designed field of a recipe', () {
    final registry = SiteRecipeRegistry.fromJson(jsonEncode([validRecipe()]));

    final recipe = registry.forHost('exemplo.com')!;
    expect(
      [
        recipe.domain,
        recipe.seriesPathPrefix,
        recipe.seriesLinkSelector,
        recipe.chapterIndexSelector,
        recipe.chapterIndexTitleSelector,
        recipe.chapterIndexOrder,
        recipe.chapterTitleSelector,
        recipe.contentSelector,
        recipe.paragraphSelector,
        recipe.nextChapterSelector,
        recipe.disallowedPathPatterns,
        recipe.minimumChapterCharacters,
      ],
      [
        'exemplo.com',
        '/series/',
        "a[itemprop=item][href*='/series/']",
        'div.eplister li > a',
        'div.epl-title',
        ChapterIndexOrder.descending,
        'h1.entry-title',
        'div.epcontent.entry-content',
        'p',
        'a[rel=next]',
        ['/pdf/'],
        200,
      ],
    );
  });

  test('a recipe missing a required field is rejected naming it', () {
    for (final field in [
      'domain',
      'seriesPathPrefix',
      'seriesLinkSelector',
      'chapterIndexSelector',
      'chapterIndexTitleSelector',
      'chapterIndexOrder',
      'chapterTitleSelector',
      'contentSelector',
      'paragraphSelector',
      'nextChapterSelector',
      'disallowedPathPatterns',
      'minimumChapterCharacters',
    ]) {
      final incomplete = validRecipe()..remove(field);

      expect(
        () => SiteRecipeRegistry.fromJson(jsonEncode([incomplete])),
        throwsA(
          isA<SiteRecipeValidationException>().having(
            (error) => error.message,
            'message for $field',
            contains('"$field"'),
          ),
        ),
        reason: 'missing $field must be named in the rejection',
      );
    }
  });

  test('an unusable chapterIndexOrder is rejected naming the field', () {
    final invalid = validRecipe()..['chapterIndexOrder'] = 'sideways';

    expect(
      () => SiteRecipeRegistry.fromJson(jsonEncode([invalid])),
      throwsA(
        isA<SiteRecipeValidationException>().having(
          (error) => error.message,
          'message',
          contains('"chapterIndexOrder"'),
        ),
      ),
    );
  });

  test('lookup is case-insensitive and unknown hosts return null', () {
    final registry = SiteRecipeRegistry.fromJson(jsonEncode([validRecipe()]));

    expect(registry.forHost('exemplo.com')?.domain, 'exemplo.com');
    expect(registry.forHost('EXEMPLO.COM')?.domain, 'exemplo.com');
    expect(registry.forHost('outro.com'), isNull);
  });

  test('disallows the recipe restricted paths only', () {
    final recipe = SiteRecipeRegistry.fromJson(
      jsonEncode([
        validRecipe()
          ..['disallowedPathPatterns'] = ['/pdf/', '/search/', '/?s='],
      ]),
    ).forHost('exemplo.com')!;

    expect(recipe.disallows('/serie/capitulo-1/pdf/'), isTrue);
    expect(recipe.disallows('/search/algo'), isTrue);
    expect(recipe.disallows('/?s=algo'), isTrue);
    expect(recipe.disallows('/series/minha-novela/'), isFalse);
  });

  test('the shipped centralnovel recipe matches the verified selectors',
      () async {
    final registry = await SiteRecipeRegistry.load(rootBundle);

    final recipe = registry.forHost('centralnovel.com')!;
    expect(
      [
        recipe.domain,
        recipe.seriesPathPrefix,
        recipe.seriesLinkSelector,
        recipe.chapterIndexSelector,
        recipe.chapterIndexTitleSelector,
        recipe.chapterIndexOrder,
        recipe.chapterTitleSelector,
        recipe.contentSelector,
        recipe.paragraphSelector,
        recipe.nextChapterSelector,
        recipe.disallowedPathPatterns,
        recipe.minimumChapterCharacters,
      ],
      [
        'centralnovel.com',
        '/series/',
        "a[itemprop=item][href*='/series/']",
        'div.eplister li > a',
        'div.epl-title',
        ChapterIndexOrder.descending,
        'h1.entry-title',
        'div.epcontent.entry-content',
        'p',
        'a[rel=next]',
        ['/pdf/', '/search/', '/?s='],
        200,
      ],
    );
  });

  test('the shipped index selector is a direct-child selector', () async {
    final registry = await SiteRecipeRegistry.load(rootBundle);

    // A descendant selector would harvest the sibling div.epl-pdf > a.dlpdf
    // links, which robots.txt disallows.
    expect(registry.forHost('centralnovel.com')!.chapterIndexSelector, 'div.eplister li > a');
  });

  test('a malformed recipe document is rejected', () {
    expect(
      () => SiteRecipeRegistry.fromJson('{"domain": "exemplo.com"}'),
      throwsA(isA<SiteRecipeValidationException>()),
    );
  });
}
