import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

void main() {
  group('BookStatus', () {
    for (final status in BookStatus.values) {
      test('${status.name} round-trips through storage', () {
        expect(BookStatus.fromStorage(status.storageValue), status);
        expect(status.storageValue, status.name);
      });
    }
  });

  group('BookSourceType', () {
    for (final sourceType in BookSourceType.values) {
      test('${sourceType.name} round-trips through storage', () {
        expect(BookSourceType.fromStorage(sourceType.storageValue), sourceType);
        expect(sourceType.storageValue, sourceType.name);
      });
    }

    test('rejects an unknown stored value', () {
      expect(
        () => BookSourceType.fromStorage('epub'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Book source identity', () {
    test('defaults to a pdf source with no source reference', () {
      final book = Book(
        id: 'book-1',
        title: 'Título',
        originalFileName: 'original.pdf',
        storedFilePath: '/books/book-1.pdf',
        fileHash: 'abc123',
        status: BookStatus.ready,
        processingProgress: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      expect(book.sourceType, BookSourceType.pdf);
      expect(book.sourceRef, isNull);
    });

    test('accepts a web book with no local file fields', () {
      final book = Book(
        id: 'book-web',
        title: 'Novela',
        sourceType: BookSourceType.web,
        sourceRef: 'https://centralnovel.com/series/minha-novela/',
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      expect(book.sourceType, BookSourceType.web);
      expect(book.sourceRef, 'https://centralnovel.com/series/minha-novela/');
      expect(book.originalFileName, isNull);
      expect(book.storedFilePath, isNull);
      expect(book.fileHash, isNull);
    });

    test('rejects a pdf book without a stored file', () {
      expect(
        () => Book(
          id: 'book-1',
          title: 'Título',
          status: BookStatus.importing,
          processingProgress: 0,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        throwsA(
          isA<TextProcessingValidationException>().having(
            (error) => error.message,
            'message',
            'a pdf book requires a stored file',
          ),
        ),
      );
    });

    test('rejects a web book without a source reference', () {
      expect(
        () => Book(
          id: 'book-web',
          title: 'Novela',
          sourceType: BookSourceType.web,
          status: BookStatus.processing,
          processingProgress: 0,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        throwsA(
          isA<TextProcessingValidationException>().having(
            (error) => error.message,
            'message',
            'a web book requires a source reference',
          ),
        ),
      );
    });

    test('copyWith carries source identity into equality and hashCode', () {
      final book = Book(
        id: 'book-web',
        title: 'Novela',
        sourceType: BookSourceType.web,
        sourceRef: 'https://centralnovel.com/series/a/',
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );

      final renamedSource = book.copyWith(
        sourceRef: 'https://centralnovel.com/series/b/',
      );

      expect(renamedSource.sourceRef, 'https://centralnovel.com/series/b/');
      expect(renamedSource.sourceType, BookSourceType.web);
      expect(renamedSource == book, isFalse);
      expect(renamedSource.hashCode == book.hashCode, isFalse);
      expect(
        book.copyWith(sourceRef: 'https://centralnovel.com/series/a/'),
        book,
      );
    });
  });

  group('Book title', () {
    test('removes the final PDF extension case-insensitively', () {
      expect(Book.titleFromFileName('Novel.PDF'), 'Novel');
    });

    test('uses the exact fallback for a filename with no title', () {
      expect(Book.titleFromFileName('.pdf'), 'Livro sem título');
    });
  });

  group('Book metadata', () {
    test('trims valid title and author', () {
      final metadata = Book.normalizeMetadata(
        title: '  Meu livro  ',
        author: '  Autora  ',
      );

      expect(metadata.title, 'Meu livro');
      expect(metadata.author, 'Autora');
    });

    test('normalizes an empty author to null', () {
      final metadata = Book.normalizeMetadata(
        title: 'Meu livro',
        author: '   ',
      );

      expect(metadata.title, 'Meu livro');
      expect(metadata.author, isNull);
    });

    test('rejects an empty trimmed title with the exact message', () {
      expect(
        () => Book.normalizeMetadata(title: '   ', author: 'Autora'),
        throwsA(
          isA<BookMetadataValidationException>().having(
            (error) => error.message,
            'message',
            'Informe o título',
          ),
        ),
      );
    });
  });

  test('exposes all milestone fields and supports immutable copy equality', () {
    final createdAt = DateTime.utc(2026, 7, 17);
    final updatedAt = DateTime.utc(2026, 7, 18);
    final book = Book(
      id: 'book-1',
      title: 'Título',
      author: 'Autora',
      coverPath: '/books/cover.jpg',
      originalFileName: 'original.pdf',
      storedFilePath: '/books/book-1.pdf',
      fileHash: 'abc123',
      status: BookStatus.importing,
      processingProgress: 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    expect(
      book,
      Book(
        id: 'book-1',
        title: 'Título',
        author: 'Autora',
        coverPath: '/books/cover.jpg',
        originalFileName: 'original.pdf',
        storedFilePath: '/books/book-1.pdf',
        fileHash: 'abc123',
        status: BookStatus.importing,
        processingProgress: 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
    expect(
      book.copyWith(
        title: 'Novo título',
        author: null,
        pageCount: 10,
        chapterCount: 2,
        blockCount: 8,
        processingStage: ProcessingStage.completed,
        activeContentRunId: 'run-1',
      ),
      Book(
        id: 'book-1',
        title: 'Novo título',
        author: null,
        coverPath: '/books/cover.jpg',
        originalFileName: 'original.pdf',
        storedFilePath: '/books/book-1.pdf',
        fileHash: 'abc123',
        status: BookStatus.importing,
        processingProgress: 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
        pageCount: 10,
        chapterCount: 2,
        blockCount: 8,
        processingStage: ProcessingStage.completed,
        activeContentRunId: 'run-1',
      ),
    );
  });

  test('rejects invalid processing progress and counts', () {
    Book make({double progress = 0, int pages = 0}) => Book(
      id: 'book',
      title: 'Book',
      originalFileName: 'book.pdf',
      storedFilePath: '/book.pdf',
      fileHash: 'hash',
      status: BookStatus.importing,
      processingProgress: progress,
      pageCount: pages,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    expect(
      () => make(progress: 1.1),
      throwsA(isA<TextProcessingValidationException>()),
    );
    expect(
      () => make(pages: -1),
      throwsA(isA<TextProcessingValidationException>()),
    );
  });
}
