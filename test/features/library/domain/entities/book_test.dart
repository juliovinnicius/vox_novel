import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

void main() {
  group('BookStatus', () {
    for (final status in BookStatus.values) {
      test('${status.name} round-trips through storage', () {
        expect(BookStatus.fromStorage(status.storageValue), status);
        expect(status.storageValue, status.name);
      });
    }
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
      book.copyWith(title: 'Novo título', author: null),
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
      ),
    );
  });
}
