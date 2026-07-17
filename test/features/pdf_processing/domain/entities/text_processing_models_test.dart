import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

void main() {
  test('stages expose exact labels and bounds', () {
    expect(ProcessingStage.values.map((e) => e.label), [
      'Extraindo texto',
      'Limpando',
      'Detectando capítulos',
      'Preparando narração',
      'Concluído',
      'Concluído',
    ]);
    expect(ProcessingStage.extracting.minimumProgress, 0);
    expect(ProcessingStage.extracting.maximumProgress, .4);
    expect(ProcessingStage.cleaning.minimumProgress, .4);
    expect(ProcessingStage.cleaning.maximumProgress, .6);
    expect(ProcessingStage.detectingChapters.maximumProgress, .75);
    expect(ProcessingStage.buildingBlocks.maximumProgress, .95);
    expect(ProcessingStage.completed.maximumProgress, 1);
  });

  test('raw and clean pages preserve exact immutable payloads', () {
    expect(RawPage(pageNumber: 1, text: ''), RawPage(pageNumber: 1, text: ''));
    expect(
      CleanPage(pageNumber: 2, text: 'texto'),
      CleanPage(pageNumber: 2, text: 'texto'),
    );
  });

  test('chapter exposes every named field with value equality', () {
    final chapter = ChapterDraft(
      id: 'c1',
      title: 'Capítulo 1',
      sortOrder: 0,
      startPage: 1,
      endPage: 2,
      cleanText: 'Texto',
    );
    expect(
      chapter,
      ChapterDraft(
        id: 'c1',
        title: 'Capítulo 1',
        sortOrder: 0,
        startPage: 1,
        endPage: 2,
        cleanText: 'Texto',
      ),
    );
  });

  test('block exposes every named field with value equality', () {
    final block = NarrationBlockDraft(
      id: 'b1',
      chapterId: 'c1',
      sortOrder: 0,
      originalText: 'Olá',
      normalizedText: 'Olá',
      characterCount: 3,
      startPage: 1,
      endPage: 1,
    );
    expect(
      block,
      NarrationBlockDraft(
        id: 'b1',
        chapterId: 'c1',
        sortOrder: 0,
        originalText: 'Olá',
        normalizedText: 'Olá',
        characterCount: 3,
        startPage: 1,
        endPage: 1,
      ),
    );
  });

  test('rejects non-positive pages', () {
    expect(
      () => RawPage(pageNumber: 0, text: ''),
      throwsA(isA<TextProcessingValidationException>()),
    );
  });

  test('rejects invalid chapter identity, order and range', () {
    expect(
      () => ChapterDraft(
        id: '',
        title: 'x',
        sortOrder: 0,
        startPage: 1,
        endPage: 1,
        cleanText: '',
      ),
      throwsA(isA<TextProcessingValidationException>()),
    );
    expect(
      () => ChapterDraft(
        id: 'c',
        title: 'x',
        sortOrder: -1,
        startPage: 1,
        endPage: 1,
        cleanText: '',
      ),
      throwsA(isA<TextProcessingValidationException>()),
    );
    expect(
      () => ChapterDraft(
        id: 'c',
        title: 'x',
        sortOrder: 0,
        startPage: 2,
        endPage: 1,
        cleanText: '',
      ),
      throwsA(isA<TextProcessingValidationException>()),
    );
  });

  test('rejects inconsistent block text, count, order and range', () {
    NarrationBlockDraft make({
      int order = 0,
      String normalized = 'abc',
      int count = 3,
      int end = 1,
    }) => NarrationBlockDraft(
      id: 'b',
      chapterId: 'c',
      sortOrder: order,
      originalText: 'abc',
      normalizedText: normalized,
      characterCount: count,
      startPage: 1,
      endPage: end,
    );
    expect(
      () => make(order: -1),
      throwsA(isA<TextProcessingValidationException>()),
    );
    expect(
      () => make(normalized: 'x'),
      throwsA(isA<TextProcessingValidationException>()),
    );
    expect(
      () => make(count: 2),
      throwsA(isA<TextProcessingValidationException>()),
    );
    expect(
      () => make(end: 0),
      throwsA(isA<TextProcessingValidationException>()),
    );
  });
}
