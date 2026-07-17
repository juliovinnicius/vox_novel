enum ProcessingStage {
  extracting('Extraindo texto', 0, 0.40),
  cleaning('Limpando', 0.40, 0.60),
  detectingChapters('Detectando capítulos', 0.60, 0.75),
  buildingBlocks('Preparando narração', 0.75, 0.95),
  completing('Concluído', 0.95, 1),
  completed('Concluído', 1, 1);

  const ProcessingStage(this.label, this.minimumProgress, this.maximumProgress);
  final String label;
  final double minimumProgress;
  final double maximumProgress;
}

final class TextProcessingValidationException implements Exception {
  const TextProcessingValidationException(this.message);
  final String message;
}

void _positivePage(int value, String name) {
  if (value < 1)
    throw TextProcessingValidationException('$name must be positive');
}

final class RawPage {
  RawPage({required this.pageNumber, required this.text}) {
    _positivePage(pageNumber, 'pageNumber');
  }
  final int pageNumber;
  final String text;
  @override
  bool operator ==(Object other) =>
      other is RawPage && other.pageNumber == pageNumber && other.text == text;
  @override
  int get hashCode => Object.hash(pageNumber, text);
}

final class CleanPage {
  CleanPage({required this.pageNumber, required this.text}) {
    _positivePage(pageNumber, 'pageNumber');
  }
  final int pageNumber;
  final String text;
  @override
  bool operator ==(Object other) =>
      other is CleanPage &&
      other.pageNumber == pageNumber &&
      other.text == text;
  @override
  int get hashCode => Object.hash(pageNumber, text);
}

final class ChapterDraft {
  ChapterDraft({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.startPage,
    required this.endPage,
    required this.cleanText,
  }) {
    if (id.isEmpty || title.isEmpty || sortOrder < 0) {
      throw const TextProcessingValidationException('invalid chapter identity');
    }
    _positivePage(startPage, 'startPage');
    if (endPage < startPage) {
      throw const TextProcessingValidationException(
        'invalid chapter page range',
      );
    }
  }
  final String id;
  final String title;
  final int sortOrder;
  final int startPage;
  final int endPage;
  final String cleanText;
  @override
  bool operator ==(Object other) =>
      other is ChapterDraft &&
      other.id == id &&
      other.title == title &&
      other.sortOrder == sortOrder &&
      other.startPage == startPage &&
      other.endPage == endPage &&
      other.cleanText == cleanText;
  @override
  int get hashCode =>
      Object.hash(id, title, sortOrder, startPage, endPage, cleanText);
}

final class NarrationBlockDraft {
  NarrationBlockDraft({
    required this.id,
    required this.chapterId,
    required this.sortOrder,
    required this.originalText,
    required this.normalizedText,
    required this.characterCount,
    required this.startPage,
    required this.endPage,
  }) {
    if (id.isEmpty ||
        chapterId.isEmpty ||
        sortOrder < 0 ||
        characterCount != originalText.runes.length ||
        normalizedText != originalText) {
      throw const TextProcessingValidationException('invalid narration block');
    }
    _positivePage(startPage, 'startPage');
    if (endPage < startPage) {
      throw const TextProcessingValidationException('invalid block page range');
    }
  }
  final String id;
  final String chapterId;
  final int sortOrder;
  final String originalText;
  final String normalizedText;
  final int characterCount;
  final int startPage;
  final int endPage;
  @override
  bool operator ==(Object other) =>
      other is NarrationBlockDraft &&
      other.id == id &&
      other.chapterId == chapterId &&
      other.sortOrder == sortOrder &&
      other.originalText == originalText &&
      other.normalizedText == normalizedText &&
      other.characterCount == characterCount &&
      other.startPage == startPage &&
      other.endPage == endPage;
  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    sortOrder,
    originalText,
    normalizedText,
    characterCount,
    startPage,
    endPage,
  );
}
