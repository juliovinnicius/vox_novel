import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

final class ReaderPositionResolver {
  const ReaderPositionResolver();

  ReaderPosition fallback(ReaderBookContent content, DateTime updatedAt) {
    final chapter = content.chapters.firstOrNull;
    return ReaderPosition(
      bookId: content.book.id,
      mode: ReaderMode.text,
      chapterId: chapter?.chapter.id,
      blockId: chapter?.blocks.firstOrNull?.id,
      pdfPage: 1,
      updatedAt: updatedAt,
    );
  }

  ReaderPosition validate(
    ReaderBookContent content,
    ReaderPosition position, {
    required int pageCount,
    required DateTime updatedAt,
  }) {
    final chapter = content.chapters
        .where((c) => c.chapter.id == position.chapterId)
        .firstOrNull;
    final block = chapter?.blocks
        .where((b) => b.id == position.blockId)
        .firstOrNull;
    if (position.bookId != content.book.id ||
        chapter == null ||
        position.blockId != null && block == null) {
      return fallback(content, updatedAt);
    }
    return position.copyWith(
      pdfPage: position.pdfPage.clamp(1, pageCount < 1 ? 1 : pageCount),
    );
  }

  int textToPdf(ReaderChapter chapter, String? blockId) =>
      chapter.blocks.where((b) => b.id == blockId).firstOrNull?.startPage ??
      chapter.chapter.startPage;

  ReaderPosition pdfToText(
    ReaderBookContent content,
    int page,
    ReaderPosition prior,
    DateTime updatedAt,
  ) {
    for (final chapter in content.chapters) {
      if (page < chapter.chapter.startPage || page > chapter.chapter.endPage) {
        continue;
      }
      final block = chapter.blocks
          .where((b) => page >= b.startPage && page <= b.endPage)
          .firstOrNull;
      return ReaderPosition(
        bookId: content.book.id,
        mode: ReaderMode.text,
        chapterId: chapter.chapter.id,
        blockId: block?.id,
        pdfPage: page,
        updatedAt: updatedAt,
      );
    }
    return prior;
  }
}
