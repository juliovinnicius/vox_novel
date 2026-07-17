import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('fresh schema persists every designed field', () async {
    final createdAt = DateTime.utc(2026, 7, 17);
    final updatedAt = DateTime.utc(2026, 7, 18);

    await database.into(database.books).insert(
      BooksCompanion.insert(
        id: 'book-1',
        title: 'Título',
        author: const Value('Autora'),
        coverPath: const Value('/books/cover.jpg'),
        originalFileName: 'original.pdf',
        storedFilePath: '/books/book-1.pdf',
        fileHash: 'hash-1',
        status: BookStatus.importing,
        processingProgress: 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );

    final row = await database.select(database.books).getSingle();

    expect(row.id, 'book-1');
    expect(row.title, 'Título');
    expect(row.author, 'Autora');
    expect(row.coverPath, '/books/cover.jpg');
    expect(row.originalFileName, 'original.pdf');
    expect(row.storedFilePath, '/books/book-1.pdf');
    expect(row.fileHash, 'hash-1');
    expect(row.status, BookStatus.importing);
    expect(row.processingProgress, 0);
    expect(row.createdAt, createdAt);
    expect(row.updatedAt, updatedAt);
  });

  for (final status in BookStatus.values) {
    test('persists and reads ${status.name} exactly', () async {
      await database.into(database.books).insert(
        BooksCompanion.insert(
          id: 'book-${status.name}',
          title: 'Livro',
          originalFileName: 'livro.pdf',
          storedFilePath: '/books/${status.name}.pdf',
          fileHash: 'hash-${status.name}',
          status: status,
          processingProgress: 0,
          createdAt: DateTime.utc(2026, 7, 17),
          updatedAt: DateTime.utc(2026, 7, 17),
        ),
      );

      final row = await database.select(database.books).getSingle();

      expect(row.status, status);
    });
  }

  test('rejects duplicate file hashes', () async {
    BooksCompanion companion(String id) => BooksCompanion.insert(
      id: id,
      title: 'Livro',
      originalFileName: '$id.pdf',
      storedFilePath: '/books/$id.pdf',
      fileHash: 'same-hash',
      status: BookStatus.importing,
      processingProgress: 0,
      createdAt: DateTime.utc(2026, 7, 17),
      updatedAt: DateTime.utc(2026, 7, 17),
    );

    await database.into(database.books).insert(companion('book-1'));

    expect(
      database.into(database.books).insert(companion('book-2')),
      throwsA(isA<SqliteException>()),
    );
  });
}
