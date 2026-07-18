import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_state.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_state.dart';

void main() {
  const selected = PickedPdf(
    sourcePath: '/source.pdf',
    originalFileName: 'A.pdf',
  );

  test('starts idle without a message', () {
    final cubit = _cubit(_Picker(null));
    expect(cubit.state, const ImportBookState());
  });

  test('starts the exact returned book and completes back at idle', () async {
    final processing = _Processing();
    final cubit = _cubit(_Picker(selected), processing: processing);
    final states = <ImportBookState>[];
    final subscription = cubit.stream.listen(states.add);
    await cubit.importPdf();
    await Future<void>.delayed(Duration.zero);
    expect(states, const [
      ImportBookState(status: ImportBookStatus.selecting),
      ImportBookState(status: ImportBookStatus.importing),
      ImportBookState(status: ImportBookStatus.processing),
      ImportBookState(),
    ]);
    expect(processing.processedBookIds, ['id']);
    await subscription.cancel();
  });

  for (final result in [
    const ProcessingResult.cancelled(),
    const ProcessingResult.unsupported('Este PDF não possui texto extraível'),
    const ProcessingResult.failed('Não foi possível processar este PDF'),
  ]) {
    test('processing ${result.outcome.name} exposes only its exact message', () async {
      final processing = _Processing(result: result);
      final cubit = _cubit(_Picker(selected), processing: processing);

      await cubit.importPdf();

      expect(cubit.state, const ImportBookState());
      expect(
        processing.cubit.state.message,
        switch (result.outcome) {
          ProcessingOutcome.cancelled => 'Processamento cancelado',
          ProcessingOutcome.unsupported ||
          ProcessingOutcome.failed => result.message,
          ProcessingOutcome.completed => null,
        },
      );
    });
  }

  test('cancellation returns from selecting to idle without error', () async {
    final cubit = _cubit(_Picker(null));
    expectLater(
      cubit.stream,
      emitsInOrder(const [
        ImportBookState(status: ImportBookStatus.selecting),
        ImportBookState(),
      ]),
    );
    await cubit.importPdf();
  });

  test(
    'picker and import failures expose the exact standard message',
    () async {
      for (final picker in [_Picker.failure(), _Picker(selected)]) {
        final processing = _Processing();
        final cubit = _cubit(
          picker,
          failImport: picker.value != null,
          processing: processing,
        );
        await cubit.importPdf();
        expect(cubit.state.status, ImportBookStatus.idle);
        expect(cubit.state.errorMessage, 'Não foi possível importar este PDF');
        expect(processing.processedBookIds, isEmpty);
      }
    },
  );

  test('ignores a second request while selection is pending', () async {
    final completer = Completer<PickedPdf?>();
    final picker = _Picker.pending(completer.future);
    final cubit = _cubit(picker);
    final first = cubit.importPdf();
    expect(cubit.state.status, ImportBookStatus.selecting);
    await cubit.importPdf();
    expect(picker.calls, 1);
    completer.complete(null);
    await first;
  });

  test('ignores a second request while import is pending', () async {
    final storage = _Storage()..pending = Completer<void>();
    final picker = _Picker(selected);
    final cubit = _cubit(picker, storage: storage);
    final first = cubit.importPdf();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ImportBookStatus.importing);
    await cubit.importPdf();
    expect(picker.calls, 1);
    expect(cubit.state.status, ImportBookStatus.importing);
    storage.pending!.complete();
    await first;
  });

  test('pending processing remains readable and ignores a second import', () async {
    final processing = _Processing(pending: Completer<ProcessingResult>());
    final picker = _Picker(selected);
    final cubit = _cubit(picker, processing: processing);
    final first = cubit.importPdf();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, ImportBookStatus.processing);
    await cubit.importPdf();
    expect(picker.calls, 1);
    expect(processing.processedBookIds, ['id']);

    processing.pending!.complete(const ProcessingResult.completed());
    await first;
    expect(cubit.state, const ImportBookState());
  });
}

ImportBookCubit _cubit(
  _Picker picker, {
  bool failImport = false,
  _Storage? storage,
  _Processing? processing,
}) {
  final actualStorage = storage ?? _Storage();
  actualStorage.fail = failImport;
  return ImportBookCubit(
    picker: picker,
    service: ImportBookService(
      repository: _Repository(),
      storage: actualStorage,
      generateId: () => 'id',
      clock: () => DateTime(2026),
    ),
    textProcessingCubit: processing?.cubit,
  );
}

final class _Processing {
  _Processing({
    this.result = const ProcessingResult.completed(),
    this.pending,
  }) {
    cubit = TextProcessingCubit(
      processBook: (bookId) {
        processedBookIds.add(bookId);
        return pending?.future ?? Future.value(result);
      },
      cancelBook: (_) async => const ProcessingResult.cancelled(),
      closeService: () async {},
    );
  }

  final ProcessingResult result;
  final Completer<ProcessingResult>? pending;
  final processedBookIds = <String>[];
  late final TextProcessingCubit cubit;
}

final class _Picker implements PdfPicker {
  _Picker(this.value) : error = false, pending = null;
  _Picker.failure() : value = null, error = true, pending = null;
  _Picker.pending(this.pending) : value = null, error = false;
  final PickedPdf? value;
  final bool error;
  final Future<PickedPdf?>? pending;
  int calls = 0;
  @override
  Future<PickedPdf?> pickPdf() async {
    calls++;
    if (error) {
      throw const PdfPickerException(PdfPickerFailureKind.invalidSelection);
    }
    return pending ?? value;
  }
}

final class _Storage implements BookFileStorage {
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<ValidatedPdf> validateAndHash(PickedPdf selected) async {
    if (fail) throw Exception();
    await pending?.future;
    return const ValidatedPdf(hash: 'hash');
  }

  @override
  Future<StagedBookFile> stageCopy({
    required PickedPdf source,
    required String bookId,
  }) async =>
      const StagedBookFile(stagingPath: '/stage', finalPath: '/book.pdf');
  @override
  Future<String> commitStage(StagedBookFile staged) async => '/book.pdf';
  @override
  Future<void> discardStage(StagedBookFile staged) async {}
  @override
  Future<BookFileBackup?> backupOwnedFile(String path) async => null;
  @override
  Future<void> discardBackup(BookFileBackup backup) async {}
  @override
  Future<void> restoreBackup(BookFileBackup backup) async {}
  @override
  Future<void> removeOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {}
  @override
  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) => throw UnimplementedError();
  @override
  Future<void> discardQuarantine(QuarantinedBookFiles files) =>
      throw UnimplementedError();
  @override
  Future<void> restoreQuarantine(QuarantinedBookFiles files) =>
      throw UnimplementedError();
}

final class _Repository implements BookRepository {
  @override
  Future<Book?> findByHash(String hash) async => null;
  @override
  Future<void> insert(Book book) async {}
  @override
  Stream<List<Book>> watchAll() => const Stream.empty();
  @override
  Future<Book?> findById(String id) async => null;
  @override
  Future<void> deleteById(String id) async {}
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
  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {}
}
