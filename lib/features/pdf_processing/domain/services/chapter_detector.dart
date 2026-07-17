import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

typedef ProcessingIdGenerator = String Function();

final class ChapterDetector {
  ChapterDetector({required ProcessingIdGenerator idGenerator})
    // Named injection is part of the public domain-service API.
    // ignore: prefer_initializing_formals
    : _idGenerator = idGenerator;

  final ProcessingIdGenerator _idGenerator;
  final List<CleanPage> _pages = [];

  void addPage(CleanPage page) => _pages.add(page);

  List<ChapterDraft> finish(String fallbackTitle) {
    final chapters = <_MutableChapter>[];
    _MutableChapter? current;
    _MutableChapter? preamble;
    var foundHeading = false;
    for (final page in _pages) {
      for (final line in page.text.split('\n')) {
        final trimmed = line.trim();
        if (_isHeading(trimmed)) {
          foundHeading = true;
          if (preamble != null && preamble.lines.isNotEmpty) {
            chapters.add(preamble);
            preamble = null;
          }
          if (current != null) chapters.add(current);
          current = _MutableChapter(trimmed, page.pageNumber);
        } else if (current == null) {
          (preamble ??= _MutableChapter('Início', page.pageNumber))
            ..lines.add(line)
            ..endPage = page.pageNumber;
        } else {
          current.lines.add(line);
          current.endPage = page.pageNumber;
        }
      }
    }
    if (!foundHeading) {
      final text = _pages.map((page) => page.text).join('\n');
      final first = _pages.isEmpty ? 1 : _pages.first.pageNumber;
      final last = _pages.isEmpty ? 1 : _pages.last.pageNumber;
      return [
        ChapterDraft(
          id: _idGenerator(),
          title: fallbackTitle,
          sortOrder: 0,
          startPage: first,
          endPage: last,
          cleanText: text,
        ),
      ];
    }
    if (preamble != null &&
        preamble.lines.any((line) => line.trim().isNotEmpty)) {
      chapters.add(preamble);
    }
    if (current != null) chapters.add(current);
    return [
      for (var i = 0; i < chapters.length; i++)
        ChapterDraft(
          id: _idGenerator(),
          title: chapters[i].title,
          sortOrder: i,
          startPage: chapters[i].startPage,
          endPage: chapters[i].endPage,
          cleanText: _trimBlankEdges(chapters[i].lines).join('\n'),
        ),
    ];
  }

  bool _isHeading(String line) => RegExp(
    r'^(?:(?:capítulo|capitulo|chapter|volume)\s+\d+|prólogo|prologo|epílogo|epilogo|extra|第\d+章)$',
    caseSensitive: false,
    unicode: true,
  ).hasMatch(line);

  List<String> _trimBlankEdges(List<String> source) {
    var start = 0;
    var end = source.length;
    while (start < end && source[start].trim().isEmpty) {
      start++;
    }
    while (end > start && source[end - 1].trim().isEmpty) {
      end--;
    }
    return source.sublist(start, end);
  }
}

final class _MutableChapter {
  _MutableChapter(this.title, this.startPage) : endPage = startPage;
  final String title;
  final int startPage;
  int endPage;
  final List<String> lines = [];
}
