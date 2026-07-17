import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/services/library_service.dart';

void main() {
  final now = DateTime.utc(2026, 7, 17);

  test('valid metadata persists exact trimmed values and timestamp', () async {
    final repository = FakeLibraryRepository(book: fixture());
    final service = LibraryService(
      repository: repository,
      storage: FakeLibraryStorage(),
      clock: () => now,
    );

    final result = await service.updateMetadata(
      id: 'book-1',
      title: '  Novo título  ',
      author: '  Autora nova  ',
    );

    expect(result.success, isTrue);
    expect(repository.metadata, ('Novo título', 'Autora nova', now));
  });

  test('empty title fails exactly before repository mutation', () async {
    final repository = FakeLibraryRepository(book: fixture());
    final service = LibraryService(
      repository: repository,
      storage: FakeLibraryStorage(),
      clock: () => now,
    );

    final result = await service.updateMetadata(
      id: 'book-1',
      title: '   ',
      author: 'Autora',
    );

    expect(result.success, isFalse);
    expect(result.message, 'Informe o título');
    expect(repository.metadata, isNull);
  });

  test(
    'repository edit failure returns exact save error and preserves values',
    () async {
      final original = fixture();
      final repository = FakeLibraryRepository(
        book: original,
        failMetadata: true,
      );
      final service = LibraryService(
        repository: repository,
        storage: FakeLibraryStorage(),
        clock: () => now,
      );

      final result = await service.updateMetadata(
        id: original.id,
        title: 'Novo',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Não foi possível salvar as alterações');
      expect(repository.book, original);
    },
  );

  test(
    'successful deletion quarantines files before row and removes trash',
    () async {
      final storage = FakeLibraryStorage();
      final repository = FakeLibraryRepository(
        book: fixture(),
        isQuarantined: () => storage.quarantined,
      );
      final service = LibraryService(
        repository: repository,
        storage: storage,
        clock: () => now,
      );

      final result = await service.deleteBook(fixture());

      expect(result.success, isTrue);
      expect(storage.events, ['quarantine', 'discard']);
      expect(repository.book, isNull);
      expect(repository.deleteObservedQuarantine, isTrue);
    },
  );

  test('quarantine failure never mutates the row or external path', () async {
    final original = fixture(storedFilePath: '/external/book.pdf');
    final repository = FakeLibraryRepository(book: original);
    final storage = FakeLibraryStorage(failQuarantine: true);
    final service = LibraryService(
      repository: repository,
      storage: storage,
      clock: () => now,
    );

    final result = await service.deleteBook(original);

    expect(result.success, isFalse);
    expect(result.message, 'Não foi possível excluir o livro');
    expect(repository.book, original);
    expect(repository.deleteCalls, 0);
    expect(storage.externalRemoved, isFalse);
  });

  test('repository deletion failure restores exact record and files', () async {
    final original = fixture();
    final repository = FakeLibraryRepository(
      book: original,
      failDeleteAfterRemoval: true,
    );
    final storage = FakeLibraryStorage();
    final service = LibraryService(
      repository: repository,
      storage: storage,
      clock: () => now,
    );

    final result = await service.deleteBook(original);

    expect(result.success, isFalse);
    expect(result.message, 'Não foi possível excluir o livro');
    expect(repository.book, original);
    expect(storage.restored, isTrue);
  });

  test(
    'post-commit cleanup failure keeps successful durable deletion',
    () async {
      final repository = FakeLibraryRepository(book: fixture());
      final storage = FakeLibraryStorage(failDiscard: true);
      final service = LibraryService(
        repository: repository,
        storage: storage,
        clock: () => now,
      );

      final result = await service.deleteBook(fixture());

      expect(result.success, isTrue);
      expect(repository.book, isNull);
      expect(storage.quarantined, isTrue);
    },
  );
}

final class FakeLibraryStorage implements BookFileStorage {
  FakeLibraryStorage({this.failQuarantine = false, this.failDiscard = false});

  final bool failQuarantine;
  final bool failDiscard;
  final events = <String>[];
  bool quarantined = false;
  bool restored = false;
  bool externalRemoved = false;

  @override
  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {
    events.add('quarantine');
    if (failQuarantine) throw const UnsafeBookPathException('/external');
    quarantined = true;
    return QuarantinedBookFiles([
      BookFileBackup(originalPath: pdfPath, backupPath: '$pdfPath.trash'),
      if (coverPath != null)
        BookFileBackup(originalPath: coverPath, backupPath: '$coverPath.trash'),
    ]);
  }

  @override
  Future<void> discardQuarantine(QuarantinedBookFiles quarantine) async {
    events.add('discard');
    if (failDiscard) throw StateError('cleanup');
    quarantined = false;
  }

  @override
  Future<void> restoreQuarantine(QuarantinedBookFiles quarantine) async {
    restored = true;
    quarantined = false;
  }

  @override
  Future<BookFileBackup?> backupOwnedFile(String path) =>
      throw UnimplementedError();
  @override
  Future<String> commitStage(StagedBookFile staged) =>
      throw UnimplementedError();
  @override
  Future<void> discardBackup(BookFileBackup backup) =>
      throw UnimplementedError();
  @override
  Future<void> discardStage(StagedBookFile staged) =>
      throw UnimplementedError();
  @override
  Future<void> removeOwnedFiles({required String pdfPath, String? coverPath}) =>
      throw UnimplementedError();
  @override
  Future<void> restoreBackup(BookFileBackup backup) =>
      throw UnimplementedError();
  @override
  Future<StagedBookFile> stageCopy({
    required PickedPdf source,
    required String bookId,
  }) => throw UnimplementedError();
  @override
  Future<ValidatedPdf> validateAndHash(PickedPdf source) =>
      throw UnimplementedError();
}

final class FakeLibraryRepository implements BookRepository {
  FakeLibraryRepository({
    required this.book,
    this.failMetadata = false,
    this.failDeleteAfterRemoval = false,
    this.isQuarantined,
  });

  Book? book;
  final bool failMetadata;
  final bool failDeleteAfterRemoval;
  final bool Function()? isQuarantined;
  (String, String?, DateTime)? metadata;
  int deleteCalls = 0;
  bool deleteObservedQuarantine = false;

  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {
    if (failMetadata) throw StateError('metadata');
    metadata = (title, author, updatedAt);
    book = book?.copyWith(title: title, author: author, updatedAt: updatedAt);
  }

  @override
  Future<void> deleteById(String id) async {
    deleteCalls++;
    deleteObservedQuarantine = isQuarantined?.call() ?? false;
    book = null;
    if (failDeleteAfterRemoval) throw StateError('delete');
  }

  @override
  Future<Book?> findById(String id) async => book?.id == id ? book : null;
  @override
  Future<void> insert(Book value) async => book = value;
  @override
  Future<Book?> findByHash(String hash) async => null;
  @override
  Stream<List<Book>> watchAll() => const Stream.empty();
  @override
  Future<void> replaceImportedFile({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required BookStatus status,
    required double processingProgress,
    required DateTime updatedAt,
  }) async {}
}

Book fixture({String storedFilePath = '/books/book.pdf'}) => Book(
  id: 'book-1',
  title: 'Título',
  author: 'Autora',
  coverPath: '/books/cover.jpg',
  originalFileName: 'book.pdf',
  storedFilePath: storedFilePath,
  fileHash: 'hash',
  status: BookStatus.ready,
  processingProgress: 1,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 2),
);
