import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/narration_block_splitter.dart';

void main() {
  ChapterDraft chapter(String text) => ChapterDraft(
    id: 'chapter',
    title: 'Chapter 1',
    sortOrder: 0,
    startPage: 2,
    endPage: 4,
    cleanText: text,
  );
  NarrationBlockSplitter splitter({int max = 3000}) {
    var id = 0;
    return NarrationBlockSplitter(
      () => 'block-${id++}',
      maximumCharacters: max,
    );
  }

  test('one short paragraph creates one exact block', () {
    final block = splitter().split(chapter('  Texto curto  ')).single;
    expect(block.originalText, 'Texto curto');
    expect(block.normalizedText, 'Texto curto');
    expect(block.characterCount, 11);
  });
  test('non-empty paragraphs create blocks in paragraph order', () {
    final blocks = splitter().split(chapter('Primeiro\n\n \nSegundo')).toList();
    expect(blocks.map((e) => e.originalText), ['Primeiro', 'Segundo']);
    expect(blocks.map((e) => e.sortOrder), [0, 1]);
  });
  test('splits at the last English sentence boundary before limit', () {
    expect(
      splitter(
        max: 12,
      ).split(chapter('First. Second part')).map((e) => e.originalText),
      ['First.', 'Second part'],
    );
  });
  test('recognizes Portuguese question and exclamation boundaries', () {
    expect(
      splitter(
        max: 14,
      ).split(chapter('Olá! Tudo bem? Depois')).map((e) => e.originalText),
      ['Olá! Tudo bem?', 'Depois'],
    );
  });
  test('recognizes CJK sentence boundaries', () {
    expect(
      splitter(
        max: 7,
      ).split(chapter('第一句。第二句！第三句？')).map((e) => e.originalText),
      ['第一句。', '第二句！', '第三句？'],
    );
  });
  test('falls back to the last whitespace', () {
    expect(
      splitter(
        max: 10,
      ).split(chapter('abc def ghi')).map((e) => e.originalText),
      ['abc def', 'ghi'],
    );
  });
  test('falls back to the exact hard limit without whitespace', () {
    final blocks = splitter(max: 5).split(chapter('abcdefghijk')).toList();
    expect(blocks.map((e) => e.originalText), ['abcde', 'fghij', 'k']);
    expect(blocks.every((e) => e.characterCount <= 5), isTrue);
  });
  test('counts multilingual Unicode characters rather than code units', () {
    final blocks = splitter(max: 3).split(chapter('😀😀😀😀')).toList();
    expect(blocks.map((e) => e.originalText), ['😀😀😀', '😀']);
    expect(blocks.map((e) => e.characterCount), [3, 1]);
  });
  test('concatenation reconstructs every non-whitespace source character', () {
    const source = 'Uma frase. Outra frase longa\n\n最后一句。Fim';
    final output = splitter(
      max: 10,
    ).split(chapter(source)).map((e) => e.originalText).join();
    expect(
      output.replaceAll(RegExp(r'\s'), ''),
      source.replaceAll(RegExp(r'\s'), ''),
    );
  });
  test('asserts exact IDs, chapter, order, text fields and page range', () {
    final blocks = splitter().split(chapter('A\n\nB')).toList();
    expect(blocks.map((e) => e.id), ['block-0', 'block-1']);
    expect(blocks.map((e) => e.chapterId), ['chapter', 'chapter']);
    expect(blocks.map((e) => e.sortOrder), [0, 1]);
    expect(
      blocks.map(
        (e) => [
          e.originalText,
          e.normalizedText,
          e.characterCount,
          e.startPage,
          e.endPage,
        ],
      ),
      [
        ['A', 'A', 1, 2, 4],
        ['B', 'B', 1, 2, 4],
      ],
    );
  });
  test('empty and whitespace-only chapters create zero blocks', () {
    expect(splitter().split(chapter(' \n\n ')), isEmpty);
  });
}
