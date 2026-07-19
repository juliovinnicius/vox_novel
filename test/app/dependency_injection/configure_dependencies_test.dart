import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';
import 'package:vox_novel/core/database/app_database.dart' hide ReaderPosition;
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';
import 'package:vox_novel/features/visual_reader/data/repositories/drift_visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_cubit.dart';

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
    expect(locator.isRegistered<VisualReaderRepository>(), isTrue);
    expect(locator.isRegistered<ReaderCubitRegistry>(), isTrue);
    expect(locator.isRegistered<NarrationRepository>(), isTrue);
    expect(locator.isRegistered<NarrationEngine>(), isTrue);
    expect(locator.isRegistered<NarrationCubitRegistry>(), isTrue);
    expect(
      locator<VisualReaderRepository>(),
      isA<DriftVisualReaderRepository>(),
    );
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
    final readerRepository = locator<VisualReaderRepository>();

    await configureDependencies(
      instance: locator,
      pdfTextExtractor: _Extractor(),
    );

    expect(locator<AppDatabase>(), same(database));
    expect(locator<AppCubit>(), same(cubit));
    expect(locator<GoRouter>(), same(router));
    expect(locator<LibraryCubit>(), same(libraryCubit));
    expect(locator<ImportBookCubit>(), same(importCubit));
    expect(locator<VisualReaderRepository>(), same(readerRepository));
  });

  test(
    'reader registry creates and closes one Cubit per route scope',
    () async {
      final repository = _ReaderRepository();
      final created = <VisualReaderCubit>[];
      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase.memory(),
        pdfTextExtractor: _Extractor(),
        visualReaderRepository: repository,
        visualReaderCubitFactory: (repository, clock) {
          final cubit = VisualReaderCubit(repository: repository, clock: clock);
          created.add(cubit);
          return cubit;
        },
      );
      final registry = locator<ReaderCubitRegistry>();
      final first = registry.create();
      final second = registry.create();
      await first.load('book-id');
      await second.load('book-id');

      expect(repository.loadCalls, 2);
      expect(created, [same(first), same(second)]);
      expect(registry.activeCubits, hasLength(2));

      await registry.close(first);
      await registry.close(second);
      expect(first.isClosed, isTrue);
      expect(second.isClosed, isTrue);
      expect(registry.activeCubits, isEmpty);
    },
  );

  test('reset awaits the latest pending reader write', () async {
    final repository = _ReaderRepository(pendingSave: Completer<void>());
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
      pdfTextExtractor: _Extractor(),
      visualReaderRepository: repository,
    );
    final cubit = locator<ReaderCubitRegistry>().create();
    await cubit.load('book-id');
    cubit.nextChapter();
    await Future<void>.delayed(Duration.zero);

    var resetCompleted = false;
    final reset = resetDependencies(
      instance: locator,
    ).then((_) => resetCompleted = true);
    await Future<void>.delayed(Duration.zero);
    expect(resetCompleted, isFalse);

    repository.pendingSave!.complete();
    await reset;
    expect(resetCompleted, isTrue);
    expect(cubit.isClosed, isTrue);
    expect(locator.isRegistered<AppDatabase>(), isFalse);
  });

  test(
    'narration uses singleton dependencies and one Cubit per route',
    () async {
      final engine = _NarrationEngine();
      final repository = _NarrationRepository();
      final created = <NarrationCubit>[];
      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase.memory(),
        pdfTextExtractor: _Extractor(),
        narrationEngine: engine,
        narrationRepository: repository,
        narrationCubitFactory: (repository, engine, clock) {
          final cubit = NarrationCubit(
            repository: repository,
            engine: engine,
            clock: clock,
          );
          created.add(cubit);
          return cubit;
        },
      );

      final registry = locator<NarrationCubitRegistry>();
      final first = registry.create();
      await registry.activationFor(first);
      final second = registry.create();
      await registry.activationFor(second);

      expect(locator<NarrationEngine>(), same(engine));
      expect(locator<NarrationRepository>(), same(repository));
      expect(created, [same(first), same(second)]);
      expect(first, isNot(same(second)));
      expect(first.isClosed, isTrue);
      expect(registry.activeCubits, [same(second)]);
    },
  );

  test(
    'narration ownership waits prior stop and progress before activation',
    () async {
      final stop = Completer<void>();
      final engine = _NarrationEngine(stopGate: stop);
      final repository = _NarrationRepository();
      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase.memory(),
        pdfTextExtractor: _Extractor(),
        narrationEngine: engine,
        narrationRepository: repository,
      );
      final registry = locator<NarrationCubitRegistry>();
      final first = registry.create();
      await registry.activationFor(first);
      await first.load(_ReaderRepository().content);
      unawaited(first.play());
      await Future<void>.delayed(Duration.zero);

      final second = registry.create();
      var activated = false;
      final activation = registry
          .activationFor(second)
          .then((_) => activated = true);
      await Future<void>.delayed(Duration.zero);
      expect(engine.stopCalls, 1);
      expect(activated, isFalse);
      expect(first.isClosed, isFalse);

      stop.complete();
      await activation;
      expect(first.isClosed, isTrue);
      expect(repository.progress?.blockId, 'one-block');
      expect(activated, isTrue);
    },
  );

  test(
    'reset awaits narration save before engine and database close',
    () async {
      final save = Completer<void>();
      final engine = _NarrationEngine();
      final repository = _NarrationRepository(save: save);
      final executor = NativeDatabase.memory();
      await configureDependencies(
        instance: locator,
        databaseExecutor: executor,
        pdfTextExtractor: _Extractor(),
        narrationEngine: engine,
        narrationRepository: repository,
      );
      final registry = locator<NarrationCubitRegistry>();
      final cubit = registry.create();
      await registry.activationFor(cubit);
      await cubit.load(_ReaderRepository().content);

      var completed = false;
      final reset = resetDependencies(
        instance: locator,
      ).then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(engine.closed, isFalse);

      save.complete();
      await reset;
      expect(completed, isTrue);
      expect(engine.closed, isTrue);
      await expectLater(
        executor.runSelect('SELECT 1', const []),
        throwsA(isA<StateError>()),
      );
    },
  );

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
    'production composition keeps CPU work off the caller isolate',
    () async {
      final caller = Isolate.current.hashCode;
      final workers = <int>[];
      await configureDependencies(
        instance: locator,
        databaseExecutor: NativeDatabase.memory(),
        pdfTextExtractor: _SelectableTextExtractor(),
        onCpuWorkerIsolate: workers.add,
      );
      await _seedBook(locator<BookRepository>());

      expect(
        await locator<TextProcessingService>().process('book-id'),
        const ProcessingResult.completed(),
      );
      expect(workers, isNotEmpty);
      expect(workers.every((identity) => identity != caller), isTrue);
    },
  );

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

final class _ReaderRepository implements VisualReaderRepository {
  _ReaderRepository({this.pendingSave});

  final Completer<void>? pendingSave;
  var loadCalls = 0;

  ReaderBookContent get content {
    ReaderChapter chapter(String id, int order) {
      final text = 'Texto $order';
      final draft = ChapterDraft(
        id: id,
        title: 'Capítulo $order',
        sortOrder: order,
        startPage: order + 1,
        endPage: order + 1,
        cleanText: text,
      );
      return ReaderChapter(
        chapter: draft,
        blocks: [
          NarrationBlockDraft(
            id: '$id-block',
            chapterId: id,
            sortOrder: 0,
            originalText: text,
            normalizedText: text,
            characterCount: text.runes.length,
            startPage: order + 1,
            endPage: order + 1,
          ),
        ],
      );
    }

    return ReaderBookContent(
      book: domain.Book(
        id: 'book-id',
        title: 'Livro',
        originalFileName: 'livro.pdf',
        storedFilePath: '/books/livro.pdf',
        fileHash: 'reader-hash',
        status: domain.BookStatus.ready,
        processingProgress: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        pageCount: 2,
        chapterCount: 2,
        blockCount: 2,
        activeContentRunId: 'run-id',
      ),
      chapters: [chapter('one', 0), chapter('two', 1)],
    );
  }

  @override
  Future<ReaderBookContent?> loadContent(String bookId) async {
    loadCalls++;
    return bookId == 'book-id' ? content : null;
  }

  @override
  Future<ReaderPosition?> loadPosition(String bookId) async => null;

  @override
  Future<ReaderSettings> loadSettings() async => ReaderSettings.defaults();

  @override
  Future<void> savePosition(ReaderPosition position) =>
      pendingSave?.future ?? Future.value();

  @override
  Future<void> saveSettings(ReaderSettings settings) async {}
}

final class _NarrationEngine implements NarrationEngine {
  _NarrationEngine({this.stopGate});

  final Completer<void>? stopGate;
  final pendingSpeech = Completer<void>();
  var stopCalls = 0;
  var closed = false;

  @override
  Future<List<NarrationVoice>> initialize() async => [
    NarrationVoice(name: 'Ana', locale: 'pt-BR'),
  ];
  @override
  Future<void> configure(NarrationVoice voice, double rate) async {}
  @override
  Future<void> speak(String text) => pendingSpeech.future;
  @override
  Future<void> stop() {
    stopCalls++;
    return stopGate?.future ?? Future.value();
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

final class _NarrationRepository implements NarrationRepository {
  _NarrationRepository({this.save});

  final Completer<void>? save;
  NarrationProgress? progress;

  @override
  Future<NarrationSettings> loadGlobalSettings() async =>
      NarrationSettings.defaults();
  @override
  Future<void> saveGlobalSettings(NarrationSettings settings) async {}
  @override
  Future<BookNarrationOverride?> loadBookOverride(String bookId) async => null;
  @override
  Future<void> saveBookOverride(BookNarrationOverride override) async {}
  @override
  Future<void> deleteBookOverride(String bookId) async {}
  @override
  Future<NarrationProgress?> loadProgress(String bookId) async => progress;
  @override
  Future<void> saveProgress(NarrationProgress value) async {
    progress = value;
    await save?.future;
  }
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

final class _SelectableTextExtractor implements PdfTextExtractor {
  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) async* {
    yield PdfExtractionOpened(request.runId, 1, 1);
    yield PdfExtractionPage(request.runId, 1, 1, 'Capítulo 1\nTexto.');
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
