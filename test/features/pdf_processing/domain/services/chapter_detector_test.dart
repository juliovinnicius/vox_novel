import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/chapter_detector.dart';

void main() {
  ChapterDetector detector() {
    var next = 0;
    return ChapterDetector(idGenerator: () => 'chapter-${next++}');
  }

  test('detects every Portuguese and English numeric heading', () {
    final subject = detector()
      ..addPage(
        CleanPage(
          pageNumber: 1,
          text: 'Capítulo 1\nA\nCAPITULO 2\nB\nChapter 3\nC\nVolume 4\nD',
        ),
      );
    expect(subject.finish('Livro').map((e) => e.title), [
      'Capítulo 1',
      'CAPITULO 2',
      'Chapter 3',
      'Volume 4',
    ]);
  });
  test('detects named Portuguese headings case-insensitively', () {
    final subject = detector()
      ..addPage(
        CleanPage(
          pageNumber: 1,
          text: 'Prólogo\nA\nPROLOGO\nB\nEpílogo\nC\nEPILOGO\nD\nExtra\nE',
        ),
      );
    expect(subject.finish('Livro').map((e) => e.title), [
      'Prólogo',
      'PROLOGO',
      'Epílogo',
      'EPILOGO',
      'Extra',
    ]);
  });
  test('detects simplified-Chinese numeric heading', () {
    final subject = detector()
      ..addPage(CleanPage(pageNumber: 1, text: '第12章\n正文'));
    expect(subject.finish('Livro').single.title, '第12章');
    expect(subject.finish('Livro').single.cleanText, '正文');
  });
  test('creates exact preamble Início before first heading', () {
    final subject = detector()
      ..addPage(
        CleanPage(pageNumber: 2, text: 'Prefácio livre\nCapítulo 1\nCorpo'),
      );
    final chapters = subject.finish('Livro');
    expect(chapters.map((e) => e.title), ['Início', 'Capítulo 1']);
    expect(chapters.first.cleanText, 'Prefácio livre');
  });
  test('creates one book-titled fallback when no heading exists', () {
    final subject = detector()
      ..addPage(CleanPage(pageNumber: 1, text: 'Primeira'))
      ..addPage(CleanPage(pageNumber: 2, text: 'Segunda'));
    final chapter = subject.finish('Meu Livro').single;
    expect(chapter.title, 'Meu Livro');
    expect(chapter.cleanText, 'Primeira\nSegunda');
    expect([chapter.startPage, chapter.endPage], [1, 2]);
  });
  test('retains consecutive and final empty chapters', () {
    final subject = detector()
      ..addPage(CleanPage(pageNumber: 1, text: 'Capítulo 1\nCapítulo 2'));
    final chapters = subject.finish('Livro');
    expect(chapters.map((e) => e.cleanText), ['', '']);
  });
  test('chapter-like narrative lines remain body text', () {
    final subject = detector()
      ..addPage(
        CleanPage(pageNumber: 1, text: 'Capítulo 1 começou assim.\nNada mais'),
      );
    expect(
      subject.finish('Livro').single.cleanText,
      'Capítulo 1 começou assim.\nNada mais',
    );
  });
  test('assigns stable unique IDs and contiguous zero-based order', () {
    final subject = detector()
      ..addPage(CleanPage(pageNumber: 1, text: 'Chapter 1\nA\nChapter 2\nB'));
    final chapters = subject.finish('Livro');
    expect(chapters.map((e) => e.id), ['chapter-0', 'chapter-1']);
    expect(chapters.map((e) => e.sortOrder), [0, 1]);
  });
  test('tracks exact source page ranges and body', () {
    final subject = detector()
      ..addPage(CleanPage(pageNumber: 3, text: 'Chapter 1\nA'))
      ..addPage(CleanPage(pageNumber: 4, text: 'B'))
      ..addPage(CleanPage(pageNumber: 5, text: 'Chapter 2\nC'));
    final chapters = subject.finish('Livro');
    expect(
      [chapters[0].startPage, chapters[0].endPage, chapters[0].cleanText],
      [3, 4, 'A\nB'],
    );
    expect(
      [chapters[1].startPage, chapters[1].endPage, chapters[1].cleanText],
      [5, 5, 'C'],
    );
  });
}
