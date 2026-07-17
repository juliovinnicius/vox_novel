import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

enum BookStatus {
  importing,
  processing,
  ready,
  failed,
  unsupported;

  static BookStatus fromStorage(String value) {
    return BookStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => throw FormatException('Unknown book status: $value'),
    );
  }

  String get storageValue => name;
}

final class Book {
  Book({
    required this.id,
    required this.title,
    required this.originalFileName,
    required this.storedFilePath,
    required this.fileHash,
    required this.status,
    required this.processingProgress,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.coverPath,
    this.pageCount = 0,
    this.chapterCount = 0,
    this.blockCount = 0,
    this.processingStage,
    this.activeContentRunId,
  }) {
    if (processingProgress < 0 ||
        processingProgress > 1 ||
        pageCount < 0 ||
        chapterCount < 0 ||
        blockCount < 0) {
      throw const TextProcessingValidationException(
        'invalid book processing values',
      );
    }
  }

  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String originalFileName;
  final String storedFilePath;
  final String fileHash;
  final BookStatus status;
  final double processingProgress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pageCount;
  final int chapterCount;
  final int blockCount;
  final ProcessingStage? processingStage;
  final String? activeContentRunId;

  static String titleFromFileName(String fileName) {
    final withoutExtension = fileName.toLowerCase().endsWith('.pdf')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    final title = withoutExtension.trim();
    return title.isEmpty ? 'Livro sem título' : title;
  }

  static BookMetadata normalizeMetadata({
    required String title,
    String? author,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const BookMetadataValidationException('Informe o título');
    }
    final normalizedAuthor = author?.trim();
    return BookMetadata(
      title: normalizedTitle,
      author: normalizedAuthor == null || normalizedAuthor.isEmpty
          ? null
          : normalizedAuthor,
    );
  }

  Book copyWith({
    String? id,
    String? title,
    Object? author = _unset,
    Object? coverPath = _unset,
    String? originalFileName,
    String? storedFilePath,
    String? fileHash,
    BookStatus? status,
    double? processingProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pageCount,
    int? chapterCount,
    int? blockCount,
    Object? processingStage = _unset,
    Object? activeContentRunId = _unset,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: identical(author, _unset) ? this.author : author as String?,
      coverPath: identical(coverPath, _unset)
          ? this.coverPath
          : coverPath as String?,
      originalFileName: originalFileName ?? this.originalFileName,
      storedFilePath: storedFilePath ?? this.storedFilePath,
      fileHash: fileHash ?? this.fileHash,
      status: status ?? this.status,
      processingProgress: processingProgress ?? this.processingProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pageCount: pageCount ?? this.pageCount,
      chapterCount: chapterCount ?? this.chapterCount,
      blockCount: blockCount ?? this.blockCount,
      processingStage: identical(processingStage, _unset)
          ? this.processingStage
          : processingStage as ProcessingStage?,
      activeContentRunId: identical(activeContentRunId, _unset)
          ? this.activeContentRunId
          : activeContentRunId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Book &&
            other.id == id &&
            other.title == title &&
            other.author == author &&
            other.coverPath == coverPath &&
            other.originalFileName == originalFileName &&
            other.storedFilePath == storedFilePath &&
            other.fileHash == fileHash &&
            other.status == status &&
            other.processingProgress == processingProgress &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt &&
            other.pageCount == pageCount &&
            other.chapterCount == chapterCount &&
            other.blockCount == blockCount &&
            other.processingStage == processingStage &&
            other.activeContentRunId == activeContentRunId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    coverPath,
    originalFileName,
    storedFilePath,
    fileHash,
    status,
    processingProgress,
    createdAt,
    updatedAt,
    pageCount,
    chapterCount,
    blockCount,
    processingStage,
    activeContentRunId,
  );
}

final class BookMetadata {
  const BookMetadata({required this.title, required this.author});

  final String title;
  final String? author;
}

final class BookMetadataValidationException implements Exception {
  const BookMetadataValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

const Object _unset = Object();
