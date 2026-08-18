import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/web_source/domain/services/import_web_book_service.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_cubit.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_state.dart';

/// The message every rejection reason must render, so the dialog can tell
/// them apart.
const Map<ImportWebBookRejection, String> messages = {
  ImportWebBookRejection.invalidUrl: 'Informe uma URL válida',
  ImportWebBookRejection.unsupportedDomain: 'Site não suportado: outro.com',
  ImportWebBookRejection.disallowedPath:
      'Este endereço não é permitido pelo site',
  ImportWebBookRejection.network: 'Sem conexão com a internet',
  ImportWebBookRejection.unsupported: 'Nenhum capítulo encontrado',
  ImportWebBookRejection.storage: ImportWebBookService.storageMessage,
};

/// A stand-in for the import service that reports a scripted outcome and
/// counts how many imports were actually started.
final class FakeImport {
  FakeImport({this.result, this.error});

  final ImportWebBookResult? result;
  final Object? error;
  final List<String> submitted = [];
  Completer<void>? gate;

  Future<ImportWebBookResult> call(String url) async {
    submitted.add(url);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return result!;
  }
}

Book webBook(String id) => Book(
  id: id,
  title: 'Obra sintética',
  sourceType: BookSourceType.web,
  sourceRef: 'https://exemplo.com/series/obra-sintetica/',
  status: BookStatus.processing,
  processingProgress: 0,
  createdAt: DateTime.utc(2026, 8, 18),
  updatedAt: DateTime.utc(2026, 8, 18),
);

void main() {
  const url = 'https://exemplo.com/series/obra-sintetica/';

  test('starts idle with no message and no imported book', () {
    final cubit = ImportWebBookCubit(importBook: FakeImport().call);

    expect(cubit.state, const ImportWebBookState());
  });

  test('a successful submission goes idle to submitting to success carrying '
      'the imported book id', () async {
    final cubit = ImportWebBookCubit(
      importBook: FakeImport(
        result: WebBookImported(webBook('book-1'), created: true),
      ).call,
    );
    final states = <ImportWebBookState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.submit(url);
    await Future<void>.delayed(Duration.zero);

    expect(states, const [
      ImportWebBookState(status: ImportWebBookStatus.submitting),
      ImportWebBookState(
        status: ImportWebBookStatus.success,
        importedBookId: 'book-1',
      ),
    ]);
    await subscription.cancel();
  });

  for (final entry in messages.entries) {
    test('a ${entry.key.name} rejection returns to idle showing only its own '
        'message', () async {
      final cubit = ImportWebBookCubit(
        importBook: FakeImport(
          result: WebBookImportRejected(entry.key, entry.value),
        ).call,
      );
      final states = <ImportWebBookState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.submit(url);
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        const ImportWebBookState(status: ImportWebBookStatus.submitting),
        ImportWebBookState(errorMessage: entry.value),
      ]);
      expect(cubit.state.importedBookId, isNull);
      await subscription.cancel();
    });
  }

  test('every rejection reason renders a message distinct from the others', () {
    expect(messages.values.toSet().length, messages.length);
  });

  test('submitting again while an import is in flight starts only one import',
      () async {
    final service = FakeImport(
      result: WebBookImported(webBook('book-1'), created: true),
    )..gate = Completer<void>();
    final cubit = ImportWebBookCubit(importBook: service.call);

    final first = cubit.submit(url);
    await cubit.submit(url);

    expect(service.submitted, [url]);
    expect(cubit.state.status, ImportWebBookStatus.submitting);
    service.gate!.complete();
    await first;
    expect(service.submitted, [url]);
    expect(cubit.state.status, ImportWebBookStatus.success);
  });

  test('an unexpected failure exposes the standard import message', () async {
    final cubit = ImportWebBookCubit(
      importBook: FakeImport(error: StateError('boom')).call,
    );

    await cubit.submit(url);

    expect(
      cubit.state,
      const ImportWebBookState(
        errorMessage: ImportWebBookCubit.failureMessage,
      ),
    );
  });

  test('clearing the message returns the cubit to idle', () async {
    final cubit = ImportWebBookCubit(
      importBook: FakeImport(
        result: const WebBookImportRejected(
          ImportWebBookRejection.network,
          'Sem conexão com a internet',
        ),
      ).call,
    );
    await cubit.submit(url);

    cubit.clearMessage();

    expect(cubit.state, const ImportWebBookState());
  });
}
