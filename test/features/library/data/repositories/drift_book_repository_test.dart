import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart' show AppDatabase;
import 'package:vox_novel/features/library/data/repositories/drift_book_repository.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

void main() {
  late AppDatabase database;
  late DriftBookRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftBookRepository(database);
  });

  tearDown(() => database.close());

  test(
    'watchAll emits every book once in deterministic newest-first order',
    () async {
      final newest = fixture(
        id: 'book-b',
        hash: 'hash-b',
        updatedAt: DateTime.utc(2026, 7, 18),
      );
      final tieFirst = fixture(
        id: 'book-a',
        hash: 'hash-a',
        updatedAt: DateTime.utc(2026, 7, 17),
      );
      final tieSecond = fixture(
        id: 'book-c',
        hash: 'hash-c',
        updatedAt: DateTime.utc(2026, 7, 17),
      );
      await repository.insert(tieSecond);
      await repository.insert(newest);
      await repository.insert(tieFirst);

      final books = await repository.watchAll().first;

      expect(books, [newest, tieFirst, tieSecond]);
      expect(books.map((book) => book.id).toSet().length, 3);
    },
  );

  test('finds exact domain values by ID and hash or returns null', () async {
    final book = fixture(id: 'book-1', hash: 'hash-1');
    await repository.insert(book);

    expect(await repository.findById('book-1'), book);
    expect(await repository.findByHash('hash-1'), book);
    expect(await repository.findById('missing'), isNull);
    expect(await repository.findByHash('missing'), isNull);
  });

  test('insert persists every named field', () async {
    final book = fixture(
      id: 'book-1',
      hash: 'hash-1',
      title: 'Título',
      author: 'Autora',
      coverPath: '/books/cover.jpg',
    );

    await repository.insert(book);

    expect(await repository.findById(book.id), book);
  });

  test(
    'replacement preserves identity and metadata while updating import fields',
    () async {
      final original = fixture(
        id: 'book-1',
        hash: 'old-hash',
        title: 'Título editado',
        author: 'Autora',
        coverPath: '/books/cover.jpg',
      );
      await repository.insert(original);
      final replacementTime = DateTime.utc(2026, 7, 19);

      await repository.replaceImportedFile(
        id: original.id,
        originalFileName: 'replacement.pdf',
        storedFilePath: '/books/replacement.pdf',
        fileHash: 'new-hash',
        status: BookStatus.importing,
        processingProgress: 0,
        updatedAt: replacementTime,
      );

      expect(
        await repository.findById(original.id),
        original.copyWith(
          originalFileName: 'replacement.pdf',
          storedFilePath: '/books/replacement.pdf',
          fileHash: 'new-hash',
          status: BookStatus.importing,
          processingProgress: 0,
          updatedAt: replacementTime,
        ),
      );
    },
  );

  test(
    'metadata update trims values and changes only metadata and updatedAt',
    () async {
      final original = fixture(id: 'book-1', hash: 'hash-1');
      await repository.insert(original);
      final updateTime = DateTime.utc(2026, 7, 19);

      await repository.updateMetadata(
        id: original.id,
        title: '  Novo título  ',
        author: '   ',
        updatedAt: updateTime,
      );

      expect(
        await repository.findById(original.id),
        original.copyWith(
          title: 'Novo título',
          author: null,
          updatedAt: updateTime,
        ),
      );
    },
  );

  test('delete removes exactly the requested record', () async {
    final first = fixture(id: 'book-1', hash: 'hash-1');
    final second = fixture(id: 'book-2', hash: 'hash-2');
    await repository.insert(first);
    await repository.insert(second);

    await repository.deleteById(first.id);

    expect(await repository.findById(first.id), isNull);
    expect(await repository.findById(second.id), second);
  });

  test(
    'failed replacement rolls back without an intermediate stream emission',
    () async {
      final first = fixture(id: 'book-1', hash: 'hash-1');
      final second = fixture(id: 'book-2', hash: 'hash-2');
      await repository.insert(first);
      await repository.insert(second);
      final emissions = <List<Book>>[];
      final subscription = repository.watchAll().listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions, hasLength(1));

      await expectLater(
        repository.replaceImportedFile(
          id: first.id,
          originalFileName: 'replacement.pdf',
          storedFilePath: '/books/replacement.pdf',
          fileHash: second.fileHash,
          status: BookStatus.importing,
          processingProgress: 0,
          updatedAt: DateTime.utc(2026, 7, 19),
        ),
        throwsA(anything),
      );
      await pumpEventQueue();

      expect(emissions, hasLength(1));
      expect(await repository.findById(first.id), first);
    },
  );

  test(
    'each import edit replacement and deletion emits one ordered unique collection',
    () async {
      final older = fixture(
        id: 'older',
        hash: 'older-hash',
        updatedAt: DateTime.utc(2026, 7, 16),
      );
      final imported = fixture(
        id: 'imported',
        hash: 'imported-hash',
        updatedAt: DateTime.utc(2026, 7, 17),
      );
      await repository.insert(older);
      final emissions = <List<Book>>[];
      final subscription = repository.watchAll().listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions, [
        [older],
      ]);

      await repository.insert(imported);
      await pumpEventQueue();
      expect(emissions, [
        [older],
        [imported, older],
      ]);

      final editedAt = DateTime.utc(2026, 7, 18);
      await repository.updateMetadata(
        id: older.id,
        title: 'Edited',
        author: null,
        updatedAt: editedAt,
      );
      await pumpEventQueue();
      expect(emissions, [
        [older],
        [imported, older],
        [older.copyWith(title: 'Edited', updatedAt: editedAt), imported],
      ]);

      final replacedAt = DateTime.utc(2026, 7, 19);
      await repository.replaceImportedFile(
        id: imported.id,
        originalFileName: 'replacement.pdf',
        storedFilePath: '/books/replacement.pdf',
        fileHash: 'replacement-hash',
        status: BookStatus.importing,
        processingProgress: 0,
        updatedAt: replacedAt,
      );
      await pumpEventQueue();
      expect(emissions, hasLength(4));
      expect(emissions.last.map((book) => book.id), ['imported', 'older']);
      expect(emissions.last.map((book) => book.id).toSet(), {
        'imported',
        'older',
      });

      await repository.deleteById(imported.id);
      await pumpEventQueue();
      expect(emissions, hasLength(5));
      expect(emissions.last, [
        older.copyWith(title: 'Edited', updatedAt: editedAt),
      ]);
    },
  );
}

Book fixture({
  required String id,
  required String hash,
  String title = 'Livro',
  String? author,
  String? coverPath,
  DateTime? updatedAt,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    coverPath: coverPath,
    originalFileName: '$id.pdf',
    storedFilePath: '/books/$id.pdf',
    fileHash: hash,
    status: BookStatus.ready,
    processingProgress: 0.5,
    createdAt: DateTime.utc(2026, 7, 16),
    updatedAt: updatedAt ?? DateTime.utc(2026, 7, 17),
  );
}
