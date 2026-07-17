import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

final class HeaderFooterProfile {
  const HeaderFooterProfile({required this.headers, required this.footers});
  final Set<String> headers;
  final Set<String> footers;
}

final class TextCleaner {
  const TextCleaner();

  HeaderFooterProfile profile(Iterable<RawPage> pages) {
    final list = pages.toList(growable: false);
    final headers = <String, int>{};
    final footers = <String, int>{};
    for (final page in list) {
      final lines = _normalizedLines(
        page.text,
      ).where((line) => line.isNotEmpty).toList();
      if (lines.isEmpty) continue;
      headers.update(
        _edgeKey(lines.first),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      footers.update(
        _edgeKey(lines.last),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    bool repeated(int count) => count >= 3 && count / list.length >= .6;
    return HeaderFooterProfile(
      headers: {
        for (final entry in headers.entries)
          if (repeated(entry.value)) entry.key,
      },
      footers: {
        for (final entry in footers.entries)
          if (repeated(entry.value)) entry.key,
      },
    );
  }

  CleanPage clean(RawPage page, HeaderFooterProfile profile) {
    final lines = _normalizedLines(page.text);
    final nonEmpty = [
      for (var i = 0; i < lines.length; i++)
        if (lines[i].isNotEmpty) i,
    ];
    if (nonEmpty.isNotEmpty) {
      final first = nonEmpty.first;
      final last = nonEmpty.last;
      if (profile.headers.contains(_edgeKey(lines[first]))) lines[first] = '';
      if (profile.footers.contains(_edgeKey(lines[last]))) lines[last] = '';
    }
    final filtered = <String>[];
    final url = RegExp(r'^https?://\S+$', caseSensitive: false);
    final pageNumber = RegExp(r'^\d+$');
    for (final line in lines) {
      if (url.hasMatch(line) || pageNumber.hasMatch(line)) continue;
      if (line.isEmpty && (filtered.isEmpty || filtered.last.isEmpty)) continue;
      filtered.add(line);
    }
    while (filtered.isNotEmpty && filtered.last.isEmpty) {
      filtered.removeLast();
    }
    final joined = <String>[];
    for (var i = 0; i < filtered.length; i++) {
      final line = filtered[i];
      if (line.isNotEmpty &&
          RegExp(r'\p{L}-$', unicode: true).hasMatch(line) &&
          i + 1 < filtered.length &&
          RegExp(r'^\p{Ll}', unicode: true).hasMatch(filtered[i + 1])) {
        joined.add('${line.substring(0, line.length - 1)}${filtered[++i]}');
      } else {
        joined.add(line);
      }
    }
    return CleanPage(pageNumber: page.pageNumber, text: joined.join('\n'));
  }

  List<String> _normalizedLines(String text) => text
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
      .split('\n')
      .map((line) => line.trim().replaceAll(RegExp(r'[ \t]+'), ' '))
      .toList();

  String _edgeKey(String line) => line.toLowerCase();
}
