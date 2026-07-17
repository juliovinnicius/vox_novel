import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';

void main() {
  const selected = PickedPdf(
    sourcePath: '/external/Novel.PDF',
    originalFileName: 'Novel.PDF',
  );
  final now = DateTime.utc(2026, 7, 17);

  test('new PDF produces the exact initial durable book', () async {
    final repository = FakeRepository();
    final storage = FakeStorage();
    final service = ImportBookService(
      repository: repository,
      storage: storage,
      generateId: () => 'book-1',
      clock: () => now,
    );

    final result = await service.importPdf(selected);

    expect(
      result,
      Book(
        id: 'book-1',
        title: 'Novel',
        author: null,
        coverPath: null,
        originalFileName: 'Novel.PDF',
        storedFilePath: '/books/book-1.pdf',
        fileHash: 'hash',
        status: BookStatus.importing,
        processingProgress: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(repository.inserted, result);
    expect(storage.events, ['validate', 'stage', 'commit']);
  });

  test(
    'duplicate preserves identity and metadata and cleans old file last',
    () async {
      final existing = fixture();
      final repository = FakeRepository(existing: existing);
      final storage = FakeStorage();
      final service = ImportBookService(
        repository: repository,
        storage: storage,
        generateId: () => 'unused',
        clock: () => now,
      );

      final result = await service.importPdf(selected);

      expect(
        result,
        existing.copyWith(
          originalFileName: 'Novel.PDF',
          storedFilePath: '/books/book-7.pdf',
          fileHash: 'hash',
          status: BookStatus.importing,
          processingProgress: 0,
          updatedAt: now,
        ),
      );
      expect(repository.replacement?.id, 'book-7');
      expect(storage.events, [
        'validate',
        'stage',
        'backup',
        'commit',
        'discardBackup',
      ]);
      expect(repository.replacementCompletedBeforeCleanup, isTrue);
    },
  );

  for (final point in FailurePoint.values) {
    test(
      '${point.name} failure returns standard failure and compensates',
      () async {
        final existing = point.isDuplicate ? fixture() : null;
        final repository = FakeRepository(
          existing: existing,
          failInsert: point == FailurePoint.repositoryNew,
          failReplace: point == FailurePoint.repositoryDuplicate,
        );
        final storage = FakeStorage(failure: point);
        final service = ImportBookService(
          repository: repository,
          storage: storage,
          generateId: () => 'book-1',
          clock: () => now,
        );

        await expectLater(
          service.importPdf(selected),
          throwsA(
            isA<ImportBookException>().having(
              (_) => ImportBookException.message,
              'message',
              'Não foi possível importar este PDF',
            ),
          ),
        );

        expect(storage.partialActive, isFalse);
        if (existing != null) {
          expect(storage.oldAvailable, isTrue);
        }
        expect(repository.inserted, isNull);
      },
    );
  }
}

enum FailurePoint {
  validation,
  disappearance,
  stage,
  diskFull,
  backup,
  commitNew,
  commitDuplicate,
  repositoryNew,
  repositoryDuplicate,
  cleanup;

  bool get isDuplicate => switch (this) {
    backup || commitDuplicate || repositoryDuplicate || cleanup => true,
    _ => false,
  };
}

final class FakeStorage implements BookFileStorage {
  FakeStorage({this.failure});

  final FailurePoint? failure;
  final events = <String>[];
  bool partialActive = false;
  bool oldAvailable = true;

  void fail(FailurePoint point) {
    if (failure == point) throw StateError(point.name);
  }

  @override
  Future<ValidatedPdf> validateAndHash(PickedPdf source) async {
    events.add('validate');
    fail(FailurePoint.validation);
    if (failure == FailurePoint.disappearance) {
      throw const FileSystemException('source disappeared');
    }
    return const ValidatedPdf(hash: 'hash');
  }

  @override
  Future<StagedBookFile> stageCopy({
    required PickedPdf source,
    required String bookId,
  }) async {
    events.add('stage');
    fail(FailurePoint.stage);
    if (failure == FailurePoint.diskFull) {
      throw const FileSystemException(
        'write failed',
        '',
        OSError('No space left on device', 28),
      );
    }
    partialActive = true;
    return StagedBookFile(
      stagingPath: '/staging/$bookId.pdf',
      finalPath: '/books/$bookId.pdf',
    );
  }

  @override
  Future<BookFileBackup?> backupOwnedFile(String path) async {
    events.add('backup');
    fail(FailurePoint.backup);
    oldAvailable = false;
    return BookFileBackup(originalPath: path, backupPath: '$path.backup');
  }

  @override
  Future<String> commitStage(StagedBookFile staged) async {
    events.add('commit');
    if (failure == FailurePoint.commitNew ||
        failure == FailurePoint.commitDuplicate) {
      throw StateError('commit');
    }
    return staged.finalPath;
  }

  @override
  Future<void> discardStage(StagedBookFile staged) async {
    partialActive = false;
  }

  @override
  Future<void> discardBackup(BookFileBackup backup) async {
    events.add('discardBackup');
    fail(FailurePoint.cleanup);
    oldAvailable = false;
  }

  @override
  Future<void> restoreBackup(BookFileBackup backup) async {
    oldAvailable = true;
  }

  @override
  Future<void> removeOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {
    partialActive = false;
  }

  @override
  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) => throw UnimplementedError();
  @override
  Future<void> discardQuarantine(QuarantinedBookFiles quarantine) =>
      throw UnimplementedError();
  @override
  Future<void> restoreQuarantine(QuarantinedBookFiles quarantine) =>
      throw UnimplementedError();
}

final class FakeRepository implements BookRepository {
  FakeRepository({
    this.existing,
    this.failInsert = false,
    this.failReplace = false,
  });

  final Book? existing;
  final bool failInsert;
  final bool failReplace;
  Book? inserted;
  Replacement? replacement;
  bool replacementCompletedBeforeCleanup = false;

  @override
  Future<Book?> findByHash(String hash) async => existing;

  @override
  Future<void> insert(Book book) async {
    if (failInsert) throw StateError('insert');
    inserted = book;
  }

  @override
  Future<void> replaceImportedFile({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required BookStatus status,
    required double processingProgress,
    required DateTime updatedAt,
  }) async {
    if (failReplace && replacement == null) throw StateError('replace');
    replacement = Replacement(id);
    replacementCompletedBeforeCleanup = true;
  }

  @override
  Future<Book?> findById(String id) async =>
      existing?.id == id ? existing : null;
  @override
  Stream<List<Book>> watchAll() => const Stream.empty();
  @override
  Future<void> deleteById(String id) async {}
  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {}
}

final class Replacement {
  const Replacement(this.id);
  final String id;
}

Book fixture() => Book(
  id: 'book-7',
  title: 'Editado',
  author: 'Autora',
  coverPath: '/books/cover.jpg',
  originalFileName: 'old.pdf',
  storedFilePath: '/books/old.pdf',
  fileHash: 'hash',
  status: BookStatus.ready,
  processingProgress: .8,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 2),
);
