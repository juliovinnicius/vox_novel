import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/library/presentation/pages/library_page.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';

void main() {
  testWidgets('shows exact empty state, title and accessible import action', (
    tester,
  ) async {
    final fixture = _Fixture();
    await tester.pumpWidget(fixture.app());
    fixture.repository.controller.add([]);
    await tester.pump();
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Sua biblioteca está vazia'), findsOneWidget);
    expect(find.text('Importar PDF'), findsOneWidget);
  });

  testWidgets('renders same ordered books in list and two-column grid', (
    tester,
  ) async {
    final fixture = _Fixture();
    await tester.pumpWidget(fixture.app());
    fixture.repository.controller.add([_book('2'), _book('1')]);
    await tester.pump();
    expect(find.byKey(const ValueKey('2')), findsOneWidget);
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
    await tester.tap(find.byTooltip('Visualização em grade'));
    await tester.pump();
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(find.byKey(const ValueKey('2')), findsOneWidget);
    expect(find.byKey(const ValueKey('1')), findsOneWidget);
  });

  testWidgets('routes the exact ready book through the injected callback', (
    tester,
  ) async {
    final fixture = _Fixture();
    Book? opened;
    await tester.pumpWidget(fixture.app(onOpenBook: (book) => opened = book));
    final ready = _book('ready', status: BookStatus.ready);
    fixture.repository.controller.add([ready]);
    await tester.pump();

    await tester.tap(find.byTooltip('Abrir Book ready'));
    expect(opened, same(ready));
  });

  testWidgets('pending import shows indicator and disables import action', (
    tester,
  ) async {
    final fixture = _Fixture()..pending = Completer<void>();
    await tester.pumpWidget(fixture.app());
    fixture.repository.controller.add([]);
    await tester.pump();
    await tester.tap(find.text('Importar PDF'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final button = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(button.onPressed, isNull);
    fixture.pending!.complete();
    await tester.pump();
  });

  for (final grid in [false, true]) {
    testWidgets(
      '${grid ? 'grid' : 'list'} routes exact processing book cancel',
      (tester) async {
        final pending = Completer<ProcessingResult>();
        final fixture = _Fixture(processBook: (_) => pending.future);
        await tester.pumpWidget(fixture.app());
        fixture.repository.controller.add([
          _book(
            '2',
            status: BookStatus.processing,
            stage: ProcessingStage.extracting,
          ),
        ]);
        unawaited(fixture.processingCubit.process('2'));
        await tester.pump();
        if (grid) {
          await tester.tap(find.byTooltip('Visualização em grade'));
          await tester.pump();
        }

        await tester.tap(find.byTooltip('Cancelar processamento de Book 2'));
        await tester.pump();

        expect(fixture.cancelledBookIds, ['2']);
        expect(find.text('Processamento cancelado'), findsOneWidget);
        pending.complete(const ProcessingResult.cancelled());
        await _drainAsyncCubit(tester);
      },
    );
  }

  for (final result in [
    const ProcessingResult.unsupported('Este PDF não possui texto extraível'),
    const ProcessingResult.failed('Não foi possível processar este PDF'),
  ]) {
    testWidgets('shows processing ${result.outcome.name} feedback once', (
      tester,
    ) async {
      final fixture = _Fixture(processBook: (_) async => result);
      await tester.pumpWidget(fixture.app());

      unawaited(fixture.processingCubit.process('2'));
      await _drainAsyncCubit(tester);

      expect(find.text(result.message!), findsOneWidget);
      expect(fixture.processingCubit.state.message, isNull);
      await tester.pump();
      expect(find.text(result.message!), findsOneWidget);
    });
  }

  testWidgets(
    'pending processing remains frame-responsive and disables import',
    (tester) async {
      final pending = Completer<ProcessingResult>();
      final fixture = _Fixture(processBook: (_) => pending.future);
      await tester.pumpWidget(fixture.app());

      fixture.processingCubit.process('2');
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final button = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Biblioteca'), findsOneWidget);
      pending.complete(const ProcessingResult.completed());
      await _drainAsyncCubit(tester);
    },
  );
}

Future<void> _drainAsyncCubit(WidgetTester tester) async {
  for (var turn = 0; turn < 6; turn++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

final class _Fixture {
  _Fixture({ProcessBook? processBook})
    : _processBook =
          processBook ?? ((_) async => const ProcessingResult.completed()) {
    processingCubit = TextProcessingCubit(
      processBook: _processBook,
      cancelBook: (bookId) async {
        cancelledBookIds.add(bookId);
        return const ProcessingResult.cancelled();
      },
      closeService: () async {},
    );
  }

  final repository = _Repository();
  final ProcessBook _processBook;
  final cancelledBookIds = <String>[];
  late final TextProcessingCubit processingCubit;
  Completer<void>? pending;
  Widget app({ValueChanged<Book>? onOpenBook}) {
    final storage = _Storage(() => pending?.future);
    return MaterialApp(
      home: LibraryPage(
        libraryCubit: LibraryCubit(
          repository: repository,
          service: LibraryService(
            repository: repository,
            storage: storage,
            clock: () => DateTime(2026),
          ),
        ),
        importBookCubit: ImportBookCubit(
          picker: _Picker(),
          service: ImportBookService(
            repository: repository,
            storage: storage,
            generateId: () => 'new',
            clock: () => DateTime(2026),
          ),
        ),
        textProcessingCubit: processingCubit,
        onOpenBook: onOpenBook,
      ),
    );
  }
}

Book _book(
  String id, {
  BookStatus status = BookStatus.importing,
  ProcessingStage? stage,
}) => Book(
  id: id,
  title: 'Book $id',
  originalFileName: '$id.pdf',
  storedFilePath: '/$id.pdf',
  fileHash: id,
  status: status,
  processingProgress: 0,
  processingStage: stage,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final class _Picker implements PdfPicker {
  @override
  Future<PickedPdf?> pickPdf() async =>
      const PickedPdf(sourcePath: '/source.pdf', originalFileName: 'new.pdf');
}

final class _Repository implements BookRepository {
  final controller = StreamController<List<Book>>.broadcast();
  @override
  Stream<List<Book>> watchAll() => controller.stream;
  @override
  Future<Book?> findByHash(String hash) async => null;
  @override
  Future<Book?> findById(String id) async => null;
  @override
  Future<void> insert(Book book) async {}
  @override
  Future<void> deleteById(String id) async {}
  @override
  Future<void> updateMetadata({
    required String id,
    required String title,
    required String? author,
    required DateTime updatedAt,
  }) async {}
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
  _Storage(this.wait);
  final Future<void>? Function() wait;
  @override
  Future<ValidatedPdf> validateAndHash(PickedPdf source) async {
    await wait();
    return const ValidatedPdf(hash: 'new');
  }

  @override
  Future<StagedBookFile> stageCopy({
    required PickedPdf source,
    required String bookId,
  }) async => const StagedBookFile(stagingPath: '/s', finalPath: '/f');
  @override
  Future<String> commitStage(StagedBookFile staged) async => '/f';
  @override
  Future<void> discardStage(StagedBookFile staged) async {}
  @override
  Future<BookFileBackup?> backupOwnedFile(String path) async => null;
  @override
  Future<void> restoreBackup(BookFileBackup backup) async {}
  @override
  Future<void> discardBackup(BookFileBackup backup) async {}
  @override
  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async => const QuarantinedBookFiles([]);
  @override
  Future<void> restoreQuarantine(QuarantinedBookFiles quarantine) async {}
  @override
  Future<void> discardQuarantine(QuarantinedBookFiles quarantine) async {}
  @override
  Future<void> removeOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {}
}
