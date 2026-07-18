import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/services/reader_position_resolver.dart';

void main() {
  test('settings expose exact defaults and reject every invalid bound', () {
    expect(
      ReaderSettings.defaults(),
      ReaderSettings(
        theme: ReaderTheme.light,
        fontFamily: ReaderFontFamily.sans,
        fontSize: 18,
        lineHeight: 1.5,
      ),
    );
    for (final size in [12, 15, 34]) {
      expect(
        () => ReaderSettings(
          theme: ReaderTheme.light,
          fontFamily: ReaderFontFamily.sans,
          fontSize: size,
          lineHeight: 1.5,
        ),
        throwsA(isA<ReaderValidationException>()),
      );
    }
    expect(
      () => ReaderSettings(
        theme: ReaderTheme.light,
        fontFamily: ReaderFontFamily.sans,
        fontSize: 18,
        lineHeight: 1.4,
      ),
      throwsA(isA<ReaderValidationException>()),
    );
  });

  test('resolver maps blocks, empty chapters, stale IDs and page matches', () {
    final content = _content();
    final resolver = const ReaderPositionResolver();
    final now = DateTime.utc(2026);
    final prior = ReaderPosition(
      bookId: 'book',
      mode: ReaderMode.text,
      chapterId: 'c1',
      blockId: 'b1',
      pdfPage: 1,
      updatedAt: now,
    );
    expect(resolver.textToPdf(content.chapters.first, 'b1'), 2);
    expect(resolver.textToPdf(content.chapters.last, null), 4);
    expect(resolver.pdfToText(content, 2, prior, now).blockId, 'b1');
    expect(resolver.pdfToText(content, 4, prior, now).chapterId, 'c2');
    expect(resolver.pdfToText(content, 9, prior, now), same(prior));
    final stale = ReaderPosition(
      bookId: 'book',
      mode: ReaderMode.text,
      chapterId: 'c1',
      blockId: 'foreign',
      pdfPage: 99,
      updatedAt: now,
    );
    final repaired = resolver.validate(
      content,
      stale,
      pageCount: 5,
      updatedAt: now,
    );
    expect(
      [repaired.chapterId, repaired.blockId, repaired.pdfPage],
      ['c1', 'b1', 1],
    );
  });
}

ReaderBookContent _content() {
  final now = DateTime.utc(2026);
  final book = Book(
    id: 'book',
    title: 'Livro',
    originalFileName: 'a.pdf',
    storedFilePath: '/a.pdf',
    fileHash: 'h',
    status: BookStatus.ready,
    processingProgress: 1,
    activeContentRunId: 'run',
    createdAt: now,
    updatedAt: now,
  );
  final c1 = ChapterDraft(
    id: 'c1',
    title: 'Um',
    sortOrder: 0,
    startPage: 1,
    endPage: 3,
    cleanText: 'Texto',
  );
  final c2 = ChapterDraft(
    id: 'c2',
    title: 'Dois',
    sortOrder: 1,
    startPage: 4,
    endPage: 4,
    cleanText: '',
  );
  final block = NarrationBlockDraft(
    id: 'b1',
    chapterId: 'c1',
    sortOrder: 0,
    originalText: 'Texto',
    normalizedText: 'Texto',
    characterCount: 5,
    startPage: 2,
    endPage: 3,
  );
  return ReaderBookContent(
    book: book,
    chapters: [
      ReaderChapter(chapter: c1, blocks: [block]),
      ReaderChapter(chapter: c2, blocks: const []),
    ],
  );
}
