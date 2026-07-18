import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

enum ReaderTheme { light, sepia, dark }

enum ReaderFontFamily { sans, serif }

enum ReaderMode { text, pdf }

final class ReaderValidationException implements Exception {
  const ReaderValidationException(this.message);
  final String message;
}

final class ReaderSettings {
  ReaderSettings({
    required this.theme,
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
  }) {
    if (fontSize < 14 ||
        fontSize > 32 ||
        fontSize.isOdd ||
        !const [1.2, 1.5, 1.8, 2.0].contains(lineHeight)) {
      throw const ReaderValidationException('invalid reader settings');
    }
  }
  ReaderSettings.defaults()
    : this(
        theme: ReaderTheme.light,
        fontFamily: ReaderFontFamily.sans,
        fontSize: 18,
        lineHeight: 1.5,
      );
  final ReaderTheme theme;
  final ReaderFontFamily fontFamily;
  final int fontSize;
  final double lineHeight;
  ReaderSettings copyWith({
    ReaderTheme? theme,
    ReaderFontFamily? fontFamily,
    int? fontSize,
    double? lineHeight,
  }) => ReaderSettings(
    theme: theme ?? this.theme,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
  );
  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.theme == theme &&
      other.fontFamily == fontFamily &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight;
  @override
  int get hashCode => Object.hash(theme, fontFamily, fontSize, lineHeight);
}

final class ReaderPosition {
  ReaderPosition({
    required this.bookId,
    required this.mode,
    required this.chapterId,
    required this.blockId,
    required this.pdfPage,
    required this.updatedAt,
  }) {
    if (bookId.isEmpty || pdfPage < 1 || blockId != null && chapterId == null) {
      throw const ReaderValidationException('invalid reader position');
    }
  }
  final String bookId;
  final ReaderMode mode;
  final String? chapterId;
  final String? blockId;
  final int pdfPage;
  final DateTime updatedAt;
  ReaderPosition copyWith({
    ReaderMode? mode,
    Object? chapterId = _unset,
    Object? blockId = _unset,
    int? pdfPage,
    DateTime? updatedAt,
  }) => ReaderPosition(
    bookId: bookId,
    mode: mode ?? this.mode,
    chapterId: identical(chapterId, _unset)
        ? this.chapterId
        : chapterId as String?,
    blockId: identical(blockId, _unset) ? this.blockId : blockId as String?,
    pdfPage: pdfPage ?? this.pdfPage,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

final class ReaderChapter {
  ReaderChapter({
    required this.chapter,
    required List<NarrationBlockDraft> blocks,
  }) : blocks = List.unmodifiable(blocks) {
    for (var i = 0; i < this.blocks.length; i++) {
      if (this.blocks[i].chapterId != chapter.id ||
          this.blocks[i].sortOrder != i) {
        throw const ReaderValidationException('invalid reader block order');
      }
    }
  }
  final ChapterDraft chapter;
  final List<NarrationBlockDraft> blocks;
}

final class ReaderBookContent {
  ReaderBookContent({required this.book, required List<ReaderChapter> chapters})
    : chapters = List.unmodifiable(chapters) {
    if (book.status != BookStatus.ready || book.activeContentRunId == null) {
      throw const ReaderValidationException('invalid active reader book');
    }
    for (var i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].chapter.sortOrder != i) {
        throw const ReaderValidationException('invalid reader chapter order');
      }
    }
  }
  final Book book;
  final List<ReaderChapter> chapters;
}

const Object _unset = Object();
