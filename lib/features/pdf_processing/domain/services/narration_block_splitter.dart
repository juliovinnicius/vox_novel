import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/chapter_detector.dart';

final class NarrationBlockSplitter {
  NarrationBlockSplitter(this.idGenerator, {this.maximumCharacters = 3000});

  final ProcessingIdGenerator idGenerator;
  final int maximumCharacters;

  Iterable<NarrationBlockDraft> split(ChapterDraft chapter) sync* {
    var order = 0;
    for (final paragraph in chapter.cleanText.split(RegExp(r'\n\s*\n'))) {
      var remaining = paragraph.trim();
      if (remaining.isEmpty) continue;
      while (remaining.runes.length > maximumCharacters) {
        final runes = remaining.runes.toList();
        var cut = _lastSentenceBoundary(runes);
        cut = cut == 0 ? _lastWhitespace(runes) : cut;
        if (cut == 0) cut = maximumCharacters;
        final text = String.fromCharCodes(runes.take(cut)).trimRight();
        yield _block(chapter, order++, text);
        remaining = String.fromCharCodes(runes.skip(cut)).trimLeft();
      }
      if (remaining.isNotEmpty) yield _block(chapter, order++, remaining);
    }
  }

  int _lastSentenceBoundary(List<int> runes) {
    const endings = {0x2e, 0x21, 0x3f, 0x3002, 0xff01, 0xff1f};
    var cut = 0;
    for (var i = 0; i < maximumCharacters; i++) {
      if (endings.contains(runes[i])) cut = i + 1;
    }
    return cut;
  }

  int _lastWhitespace(List<int> runes) {
    var cut = 0;
    for (var i = 0; i < maximumCharacters; i++) {
      if (String.fromCharCode(runes[i]).trim().isEmpty) cut = i;
    }
    return cut;
  }

  NarrationBlockDraft _block(ChapterDraft chapter, int order, String text) =>
      NarrationBlockDraft(
    id: idGenerator(),
        chapterId: chapter.id,
        sortOrder: order,
        originalText: text,
        normalizedText: text,
        characterCount: text.runes.length,
        startPage: chapter.startPage,
        endPage: chapter.endPage,
      );
}
