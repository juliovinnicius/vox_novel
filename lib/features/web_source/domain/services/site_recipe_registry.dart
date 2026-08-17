import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:vox_novel/features/web_source/domain/entities/site_recipe.dart';

const String siteRecipesAssetPath = 'assets/site_recipes.json';

/// Loads the per-domain recipes and looks one up by host.
final class SiteRecipeRegistry {
  SiteRecipeRegistry(List<SiteRecipe> recipes)
    : _byDomain = {
        for (final recipe in recipes) recipe.domain.toLowerCase(): recipe,
      };

  factory SiteRecipeRegistry.fromJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw SiteRecipeValidationException(
        'Receitas de site inválidas: ${error.message}',
      );
    }
    if (decoded is! List) {
      throw const SiteRecipeValidationException(
        'Receitas de site inválidas: esperado uma lista de receitas',
      );
    }
    return SiteRecipeRegistry([
      for (final entry in decoded)
        if (entry is Map<String, Object?>)
          SiteRecipe.fromJson(entry)
        else
          throw const SiteRecipeValidationException(
            'Receitas de site inválidas: esperado uma lista de receitas',
          ),
    ]);
  }

  static Future<SiteRecipeRegistry> load(AssetBundle bundle) async {
    return SiteRecipeRegistry.fromJson(
      await bundle.loadString(siteRecipesAssetPath),
    );
  }

  final Map<String, SiteRecipe> _byDomain;

  Iterable<SiteRecipe> get recipes => _byDomain.values;

  SiteRecipe? forHost(String host) => _byDomain[host.toLowerCase()];
}
