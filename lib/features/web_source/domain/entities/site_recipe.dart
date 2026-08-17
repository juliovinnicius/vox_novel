enum ChapterIndexOrder {
  ascending,
  descending;

  static ChapterIndexOrder fromStorage(String value) {
    return ChapterIndexOrder.values.firstWhere(
      (order) => order.name == value,
      orElse: () =>
          throw FormatException('Unknown chapter index order: $value'),
    );
  }

  String get storageValue => name;
}

final class SiteRecipeValidationException implements Exception {
  const SiteRecipeValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Per-domain extraction configuration. Supporting another translation site is
/// a new entry in `assets/site_recipes.json`, not a code change.
final class SiteRecipe {
  const SiteRecipe({
    required this.domain,
    required this.seriesPathPrefix,
    required this.seriesLinkSelector,
    required this.chapterIndexSelector,
    required this.chapterIndexTitleSelector,
    required this.chapterIndexOrder,
    required this.chapterTitleSelector,
    required this.contentSelector,
    required this.paragraphSelector,
    required this.nextChapterSelector,
    required this.disallowedPathPatterns,
    required this.minimumChapterCharacters,
  });

  factory SiteRecipe.fromJson(Map<String, Object?> json) {
    return SiteRecipe(
      domain: _string(json, 'domain'),
      seriesPathPrefix: _string(json, 'seriesPathPrefix'),
      seriesLinkSelector: _string(json, 'seriesLinkSelector'),
      chapterIndexSelector: _string(json, 'chapterIndexSelector'),
      chapterIndexTitleSelector: _string(json, 'chapterIndexTitleSelector'),
      chapterIndexOrder: _order(json, 'chapterIndexOrder'),
      chapterTitleSelector: _string(json, 'chapterTitleSelector'),
      contentSelector: _string(json, 'contentSelector'),
      paragraphSelector: _string(json, 'paragraphSelector'),
      nextChapterSelector: _string(json, 'nextChapterSelector'),
      disallowedPathPatterns: _strings(json, 'disallowedPathPatterns'),
      minimumChapterCharacters: _positiveInt(json, 'minimumChapterCharacters'),
    );
  }

  final String domain;
  final String seriesPathPrefix;
  final String seriesLinkSelector;
  final String chapterIndexSelector;
  final String chapterIndexTitleSelector;
  final ChapterIndexOrder chapterIndexOrder;
  final String chapterTitleSelector;
  final String contentSelector;
  final String paragraphSelector;
  final String nextChapterSelector;
  final List<String> disallowedPathPatterns;
  final int minimumChapterCharacters;

  /// Whether [path] (with its query string, if any) matches a pattern the
  /// site's `robots.txt` disallows.
  bool disallows(String path) =>
      disallowedPathPatterns.any(path.contains);

  static String _string(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! String || value.trim().isEmpty) {
      throw SiteRecipeValidationException(
        'Receita de site inválida: campo "$field" ausente ou vazio',
      );
    }
    return value;
  }

  static List<String> _strings(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! List || value.any((entry) => entry is! String)) {
      throw SiteRecipeValidationException(
        'Receita de site inválida: campo "$field" ausente ou vazio',
      );
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  static int _positiveInt(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! int || value <= 0) {
      throw SiteRecipeValidationException(
        'Receita de site inválida: campo "$field" ausente ou vazio',
      );
    }
    return value;
  }

  static ChapterIndexOrder _order(Map<String, Object?> json, String field) {
    final value = _string(json, field);
    try {
      return ChapterIndexOrder.fromStorage(value);
    } on FormatException {
      throw SiteRecipeValidationException(
        'Receita de site inválida: campo "$field" ausente ou vazio',
      );
    }
  }
}
