import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';

void main() {
  late GetIt locator;

  setUp(() {
    locator = GetIt.asNewInstance();
  });

  tearDown(() async {
    await resetDependencies(instance: locator);
  });

  test('registers one database, Cubit, and router', () async {
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
      pdfTextExtractor: _Extractor(),
    );

    expect(locator.isRegistered<AppDatabase>(), isTrue);
    expect(locator.isRegistered<AppCubit>(), isTrue);
    expect(locator.isRegistered<GoRouter>(), isTrue);
    expect(locator.isRegistered<BookRepository>(), isTrue);
    expect(locator.isRegistered<PdfPicker>(), isTrue);
    expect(locator.isRegistered<BookFileStorage>(), isTrue);
    expect(locator.isRegistered<ImportBookService>(), isTrue);
    expect(locator.isRegistered<LibraryService>(), isTrue);
    expect(locator.isRegistered<LibraryCubit>(), isTrue);
    expect(locator.isRegistered<ImportBookCubit>(), isTrue);
    expect(locator.isRegistered<PdfTextExtractor>(), isTrue);
    expect(locator.isRegistered<TextProcessingRepository>(), isTrue);
    expect(locator.isRegistered<TextProcessingService>(), isTrue);
    expect(locator.isRegistered<TextProcessingCubit>(), isTrue);
  });

  test(
    'initializes PDF engine once before production extractor registration',
    () async {
      var initializationCalls = 0;

      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase.memory(),
        initializePdfEngine: () async {
          initializationCalls++;
          expect(locator.isRegistered<PdfTextExtractor>(), isFalse);
        },
      );
      final extractor = locator<PdfTextExtractor>();
      await configureDependencies(
        instance: locator,
        initializePdfEngine: () async => initializationCalls++,
      );

      expect(initializationCalls, 1);
      expect(locator<PdfTextExtractor>(), same(extractor));
    },
  );

  test('repeated setup reuses the registered instances', () async {
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
      pdfTextExtractor: _Extractor(),
    );
    final database = locator<AppDatabase>();
    final cubit = locator<AppCubit>();
    final router = locator<GoRouter>();
    final libraryCubit = locator<LibraryCubit>();
    final importCubit = locator<ImportBookCubit>();

    await configureDependencies(
      instance: locator,
      pdfTextExtractor: _Extractor(),
    );

    expect(locator<AppDatabase>(), same(database));
    expect(locator<AppCubit>(), same(cubit));
    expect(locator<GoRouter>(), same(router));
    expect(locator<LibraryCubit>(), same(libraryCubit));
    expect(locator<ImportBookCubit>(), same(importCubit));
  });

  test('reset disposes resources and clears the supplied locator', () async {
    final executor = NativeDatabase.memory();
    await configureDependencies(
      instance: locator,
      databaseExecutor: executor,
      pdfTextExtractor: _Extractor(),
    );
    final cubit = locator<AppCubit>();
    final libraryCubit = locator<LibraryCubit>();
    final importCubit = locator<ImportBookCubit>();
    final processingCubit = locator<TextProcessingCubit>();

    await resetDependencies(instance: locator);

    expect(locator.isRegistered<AppDatabase>(), isFalse);
    expect(locator.isRegistered<AppCubit>(), isFalse);
    expect(locator.isRegistered<GoRouter>(), isFalse);
    expect(cubit.isClosed, isTrue);
    expect(libraryCubit.isClosed, isTrue);
    expect(importCubit.isClosed, isTrue);
    expect(processingCubit.isClosed, isTrue);
    await expectLater(
      executor.runSelect('SELECT 1', const []),
      throwsA(isA<StateError>()),
    );
  });

  test('resolved database uses the injected in-memory executor', () async {
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
      pdfTextExtractor: _Extractor(),
    );

    final result = await locator<AppDatabase>()
        .customSelect('SELECT 1 AS value')
        .getSingle();

    expect(result.read<int>('value'), 1);
  });

  test(
    'composed no-text, corrupt, and cancel paths leave no staging',
    () async {
      final cases =
          <
            ({
              PdfTextExtractor extractor,
              ProcessingOutcome outcome,
              String message,
              domain.BookStatus status,
            })
          >[
            (
              extractor: _NoTextExtractor(),
              outcome: ProcessingOutcome.unsupported,
              message: 'Este PDF não possui texto extraível',
              status: domain.BookStatus.unsupported,
            ),
            (
              extractor: _CorruptExtractor(),
              outcome: ProcessingOutcome.failed,
              message: 'Não foi possível processar este PDF',
              status: domain.BookStatus.failed,
            ),
          ];

      for (final testCase in cases) {
        await configureDependencies(
          instance: locator,
          databaseExecutor: NativeDatabase.memory(),
          pdfTextExtractor: testCase.extractor,
          generateId: () => 'run-id',
        );
        await _seedBook(locator<BookRepository>());

        final result = await locator<TextProcessingService>().process(
          'book-id',
        );

        expect(result.outcome, testCase.outcome);
        expect(result.message, testCase.message);
        expect(
          (await locator<BookRepository>().findById('book-id'))?.status,
          testCase.status,
        );
        await _expectNoProcessingRows(locator<AppDatabase>());
        await resetDependencies(instance: locator);
      }

      final pending = _PendingExtractor();
      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase.memory(),
        pdfTextExtractor: pending,
        generateId: () => 'run-id',
      );
      await _seedBook(locator<BookRepository>());
      final processing = locator<TextProcessingService>().process('book-id');
      await pending.started.future;

      final cancelled = await locator<TextProcessingService>().cancel(
        'book-id',
      );

      expect(cancelled, const ProcessingResult.cancelled());
      expect(pending.cancelledRunId, 'run-id');
      expect(
        await locator<BookRepository>().findById('book-id'),
        isA<domain.Book>()
            .having(
              (book) => book.status,
              'status',
              domain.BookStatus.importing,
            )
            .having((book) => book.processingProgress, 'progress', 0),
      );
      await _expectNoProcessingRows(locator<AppDatabase>());
      expect(await processing, const ProcessingResult.cancelled());
    },
  );

  test(
    'reset cancels active processing and durable staging is empty',
    () async {
      final root = await Directory.systemTemp.createTemp('vox_reset_');
      final databaseFile = File('${root.path}/library.sqlite');
      final pending = _PendingExtractor();
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase(databaseFile),
        supportDirectory: root,
        pdfTextExtractor: pending,
        generateId: () => 'run-id',
      );
      await _seedBook(locator<BookRepository>());
      final appCubit = locator<AppCubit>();
      final libraryCubit = locator<LibraryCubit>();
      final importCubit = locator<ImportBookCubit>();
      final processingCubit = locator<TextProcessingCubit>();
      unawaited(processingCubit.process('book-id'));
      await pending.started.future;

      await resetDependencies(instance: locator);

      expect(pending.cancelledRunId, 'run-id');
      expect(appCubit.isClosed, isTrue);
      expect(libraryCubit.isClosed, isTrue);
      expect(importCubit.isClosed, isTrue);
      expect(processingCubit.isClosed, isTrue);
      final reopened = AppDatabase(NativeDatabase(databaseFile));
      await _expectNoProcessingRows(reopened);
      await reopened.close();
    },
  );
}

Future<void> _seedBook(BookRepository repository) => repository.insert(
  domain.Book(
    id: 'book-id',
    title: 'Livro',
    originalFileName: 'livro.pdf',
    storedFilePath: '/books/livro.pdf',
    fileHash: 'hash',
    status: domain.BookStatus.importing,
    processingProgress: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
);

Future<void> _expectNoProcessingRows(AppDatabase database) async {
  expect(await database.select(database.processingRuns).get(), isEmpty);
  expect(await database.select(database.rawPages).get(), isEmpty);
  expect(await database.select(database.chapters).get(), isEmpty);
  expect(await database.select(database.narrationBlocks).get(), isEmpty);
}

final class _Extractor implements PdfTextExtractor {
  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) =>
      const Stream.empty();

  @override
  Future<void> cancel(String runId) async {}
}

final class _NoTextExtractor implements PdfTextExtractor {
  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) async* {
    yield PdfExtractionOpened(request.runId, 1, 1);
    yield PdfExtractionPage(request.runId, 1, 1, ' \n\t');
    yield PdfExtractionCompleted(request.runId, 1);
  }

  @override
  Future<void> cancel(String runId) async {}
}

final class _CorruptExtractor implements PdfTextExtractor {
  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) async* {
    yield PdfExtractionFailed(request.runId, PdfExtractionFailureKind.corrupt);
  }

  @override
  Future<void> cancel(String runId) async {}
}

final class _PendingExtractor implements PdfTextExtractor {
  final started = Completer<void>();
  final released = Completer<void>();
  String? cancelledRunId;

  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) async* {
    yield PdfExtractionOpened(request.runId, 1, 1);
    if (!started.isCompleted) started.complete();
    await released.future;
  }

  @override
  Future<void> cancel(String runId) async {
    cancelledRunId = runId;
    if (!released.isCompleted) released.complete();
  }
}
