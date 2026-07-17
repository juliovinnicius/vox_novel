import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_state.dart';

void main() {
  test(
    'starts empty in list layout and streams immutable ordered books',
    () async {
      final repository = _Repository();
      final cubit = _cubit(repository);
      expect(cubit.state.layout, LibraryLayout.list);
      expect(cubit.state.books, isEmpty);
      cubit.start();
      expect(cubit.state.loading, isTrue);
      repository.controller.add([_book('2'), _book('1')]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.books.map((book) => book.id), ['2', '1']);
      expect(() => cubit.state.books.add(_book('3')), throwsUnsupportedError);
    },
  );

  test('layout changes preserve exact book identity and order', () async {
    final repository = _Repository();
    final cubit = _cubit(repository)..start();
    final books = [_book('2'), _book('1')];
    repository.controller.add(books);
    await Future<void>.delayed(Duration.zero);
    cubit.showGrid();
    expect(cubit.state.layout, LibraryLayout.grid);
    expect(cubit.state.books, books);
    cubit.showList();
    expect(cubit.state.layout, LibraryLayout.list);
    expect(cubit.state.books, books);
    expect(_cubit(repository).state.layout, LibraryLayout.list);
  });

  test('stream and service errors preserve the last collection', () async {
    final repository = _Repository();
    final storage = _Storage();
    final cubit = _cubit(repository, storage: storage)..start();
    final books = [_book('1')];
    repository.controller.add(books);
    await Future<void>.delayed(Duration.zero);
    repository.controller.addError(Exception());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.books, books);
    expect(cubit.state.errorMessage, LibraryCubit.loadError);
    repository.fail = true;
    await cubit.updateMetadata(book: books.single, title: 'Title');
    expect(cubit.state.books, books);
    expect(cubit.state.errorMessage, LibraryService.saveError);
    storage.fail = true;
    await cubit.deleteBook(books.single);
    expect(cubit.state.books, books);
    expect(cubit.state.errorMessage, LibraryService.deleteError);
  });

  test('close cancels the repository subscription', () async {
    final repository = _Repository();
    final cubit = _cubit(repository)..start();
    await cubit.close();
    expect(repository.controller.hasListener, isFalse);
  });
}

LibraryCubit _cubit(_Repository repository, {_Storage? storage}) =>
    LibraryCubit(
      repository: repository,
      service: LibraryService(
        repository: repository,
        storage: storage ?? _Storage(),
        clock: () => DateTime(2026),
      ),
    );

Book _book(String id) => Book(
  id: id,
  title: 'Book $id',
  originalFileName: '$id.pdf',
  storedFilePath: '/$id.pdf',
  fileHash: id,
  status: BookStatus.importing,
  processingProgress: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final class _Repository implements BookRepository {
  final controller = StreamController<List<Book>>.broadcast();
  bool fail = false;
  @override
  Stream<List<Book>> watchAll() => controller.stream;
  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {
    if (fail) throw Exception();
  }

  @override
  Future<void> deleteById(String id) async {}
  @override
  Future<Book?> findById(String id) async => null;
  @override
  Future<Book?> findByHash(String hash) async => null;
  @override
  Future<void> insert(Book book) async {}
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

final class _Storage implements BookFileStorage {
  bool fail = false;
  @override
  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {
    if (fail) throw Exception();
    return const QuarantinedBookFiles([]);
  }

  @override
  Future<void> discardQuarantine(QuarantinedBookFiles quarantine) async {}
  @override
  Future<void> restoreQuarantine(QuarantinedBookFiles quarantine) async {}
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
  Future<StagedBookFile> stageCopy({required source, required String bookId}) =>
      throw UnimplementedError();
  @override
  Future<ValidatedPdf> validateAndHash(source) => throw UnimplementedError();
}
