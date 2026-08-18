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

  test('a downloading web book with one stored chapter is readable content', () {
    final content = ReaderBookContent(
      book: _webBook(status: BookStatus.processing),
      chapters: [_chapter('c1', 0)],
    );

    expect(content.book.status, BookStatus.processing);
    expect(content.chapters.single.chapter.id, 'c1');
  });

  test('a web book whose second chapter failed keeps its hole', () {
    final content = ReaderBookContent(
      book: _webBook(status: BookStatus.processing),
      chapters: [_chapter('c1', 0), _chapter('c3', 2)],
    );

    expect(
      content.chapters.map((value) => value.chapter.sortOrder),
      [0, 2],
    );
  });

  test('content rejects duplicate and out-of-order chapter sort orders', () {
    for (final orders in [
      [0, 0],
      [1, 0],
      [0, 2, 1],
    ]) {
      expect(
        () => ReaderBookContent(
          book: _webBook(status: BookStatus.processing),
          chapters: [
            for (var i = 0; i < orders.length; i++)
              _chapter('c$i', orders[i]),
          ],
        ),
        throwsA(isA<ReaderValidationException>()),
        reason: 'orders $orders must be rejected',
      );
    }
  });

  test('a processing pdf book is never readable content', () {
    final now = DateTime.utc(2026);
    expect(
      () => ReaderBookContent(
        book: Book(
          id: 'book',
          title: 'Livro',
          originalFileName: 'a.pdf',
          storedFilePath: '/a.pdf',
          fileHash: 'h',
          status: BookStatus.processing,
          processingProgress: 0.5,
          activeContentRunId: 'run',
          createdAt: now,
          updatedAt: now,
        ),
        chapters: [_chapter('c1', 0)],
      ),
      throwsA(isA<ReaderValidationException>()),
    );
  });

  test('a web book without an active run is never readable content', () {
    expect(
      () => ReaderBookContent(
        book: _webBook(status: BookStatus.processing, runId: null),
        chapters: [_chapter('c1', 0)],
      ),
      throwsA(isA<ReaderValidationException>()),
    );
  });

  test('a position resumes onto the right chapter across a hole', () {
    final content = ReaderBookContent(
      book: _webBook(status: BookStatus.processing),
      chapters: [
        _chapter('c1', 0),
        _chapter('c3', 2, blockId: 'b3'),
      ],
    );
    final now = DateTime.utc(2026);
    final saved = ReaderPosition(
      bookId: 'book',
      mode: ReaderMode.text,
      chapterId: 'c3',
      blockId: 'b3',
      pdfPage: 3,
      updatedAt: now,
    );

    final resolved = const ReaderPositionResolver().validate(
      content,
      saved,
      pageCount: 3,
      updatedAt: now,
    );

    expect([resolved.chapterId, resolved.blockId], ['c3', 'b3']);
  });
}

Book _webBook({required BookStatus status, String? runId = 'run'}) {
  final now = DateTime.utc(2026);
  return Book(
    id: 'book',
    title: 'Obra',
    sourceType: BookSourceType.web,
    sourceRef: 'https://exemplo.com/series/obra/',
    status: status,
    processingProgress: 0.5,
    activeContentRunId: runId,
    createdAt: now,
    updatedAt: now,
  );
}

ReaderChapter _chapter(String id, int sortOrder, {String? blockId}) =>
    ReaderChapter(
      chapter: ChapterDraft(
        id: id,
        title: 'Capítulo ${sortOrder + 1}',
        sortOrder: sortOrder,
        startPage: sortOrder + 1,
        endPage: sortOrder + 1,
        cleanText: 'Texto',
      ),
      blocks: blockId == null
          ? const []
          : [
              NarrationBlockDraft(
                id: blockId,
                chapterId: id,
                sortOrder: 0,
                originalText: 'Texto',
                normalizedText: 'Texto',
                characterCount: 5,
                startPage: sortOrder + 1,
                endPage: sortOrder + 1,
              ),
            ],
    );

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
