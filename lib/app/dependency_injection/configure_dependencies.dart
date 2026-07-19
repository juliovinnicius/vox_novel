import 'dart:io';

import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/router/app_router.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/import_book/data/services/file_picker_pdf_picker.dart';
import 'package:vox_novel/features/import_book/data/services/local_book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/library/data/repositories/drift_book_repository.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/library/presentation/pages/library_page.dart';
import 'package:vox_novel/features/narration/data/repositories/drift_narration_repository.dart';
import 'package:vox_novel/features/narration/data/services/flutter_tts_narration_engine.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/data/services/pdfrx_pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';
import 'package:vox_novel/features/visual_reader/data/repositories/drift_visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_cubit.dart';
import 'package:vox_novel/features/visual_reader/presentation/pages/reader_page.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/original_pdf_view.dart';

typedef VisualReaderCubitFactory =
    VisualReaderCubit Function(
      VisualReaderRepository repository,
      DateTime Function() clock,
    );

typedef NarrationCubitFactory =
    NarrationCubit Function(
      NarrationRepository repository,
      NarrationEngine engine,
      DateTime Function() clock,
    );

final class ReaderCubitRegistry {
  ReaderCubitRegistry(this._repository, this._clock, this._factory);

  final VisualReaderRepository _repository;
  final DateTime Function() _clock;
  final VisualReaderCubitFactory _factory;
  final Map<VisualReaderCubit, Future<void>?> _active = {};

  Iterable<VisualReaderCubit> get activeCubits =>
      List.unmodifiable(_active.keys);

  VisualReaderCubit create() {
    final cubit = _factory(_repository, _clock);
    _active[cubit] = null;
    return cubit;
  }

  Future<void> close(VisualReaderCubit cubit) {
    final pending = _active[cubit];
    if (pending != null) return pending;
    if (!_active.containsKey(cubit)) return Future.value();
    final future = cubit.close();
    _active[cubit] = future;
    return future.whenComplete(() => _active.remove(cubit));
  }

  Future<void> closeAll() async {
    await Future.wait([..._active.keys].map(close));
  }
}

final class NarrationCubitRegistry {
  NarrationCubitRegistry(
    this._repository,
    this._engine,
    this._clock,
    this._factory,
  );

  final NarrationRepository _repository;
  final NarrationEngine _engine;
  final DateTime Function() _clock;
  final NarrationCubitFactory _factory;
  final Map<NarrationCubit, Future<void>> _activations = {};
  final Map<NarrationCubit, Future<void>> _closures = {};
  Future<void> _ownershipTail = Future.value();
  NarrationCubit? _owner;

  Iterable<NarrationCubit> get activeCubits =>
      List.unmodifiable(_activations.keys);

  NarrationCubit create() {
    final cubit = _factory(_repository, _engine, _clock);
    final activation = _ownershipTail.then((_) async {
      final previous = _owner;
      if (previous != null && !identical(previous, cubit)) {
        await close(previous);
      }
      if (_activations.containsKey(cubit)) _owner = cubit;
    });
    _activations[cubit] = activation;
    _ownershipTail = activation.then<void>((_) {}, onError: (_) {});
    return cubit;
  }

  Future<void> activationFor(NarrationCubit cubit) =>
      _activations[cubit] ?? Future.value();

  Future<void> close(NarrationCubit cubit) {
    final existing = _closures[cubit];
    if (existing != null) return existing;
    final activation = _activations[cubit];
    if (activation == null) return Future.value();
    final closure = () async {
      await activation;
      await cubit.close();
      if (identical(_owner, cubit)) _owner = null;
      _activations.remove(cubit);
      _closures.remove(cubit);
    }();
    _closures[cubit] = closure;
    return closure;
  }

  Future<void> closeAll() async {
    await Future.wait([..._activations.keys].map(close));
  }
}

Future<void> configureDependencies({
  GetIt? instance,
  QueryExecutor? databaseExecutor,
  Directory? supportDirectory,
  PdfPicker? pdfPicker,
  DateTime Function()? clock,
  String Function()? generateId,
  PdfTextExtractor? pdfTextExtractor,
  TextProcessingRepository? textProcessingRepository,
  ProcessingExecutor processingExecutor = isolateProcessingExecutor,
  void Function(int workerIdentity)? onCpuWorkerIsolate,
  Future<void> Function()? initializePdfEngine,
  VisualReaderRepository? visualReaderRepository,
  VisualReaderCubitFactory? visualReaderCubitFactory,
  NarrationRepository? narrationRepository,
  NarrationEngine? narrationEngine,
  NarrationCubitFactory? narrationCubitFactory,
  PdfSurfaceBuilder pdfSurfaceBuilder = buildPdfrxSurface,
}) async {
  final locator = instance ?? GetIt.instance;

  if (!locator.isRegistered<AppDatabase>()) {
    final database = databaseExecutor == null
        ? AppDatabase.defaults()
        : AppDatabase(databaseExecutor);
    locator.registerSingleton<AppDatabase>(
      database,
      dispose: (database) => database.close(),
    );
  }
  final now = clock ?? DateTime.now;
  final nextId = generateId ?? const Uuid().v4;
  if (!locator.isRegistered<BookRepository>()) {
    locator.registerSingleton<BookRepository>(
      DriftBookRepository(locator<AppDatabase>()),
    );
  }
  if (!locator.isRegistered<PdfPicker>()) {
    locator.registerSingleton<PdfPicker>(pdfPicker ?? FilePickerPdfPicker());
  }
  if (!locator.isRegistered<BookFileStorage>()) {
    final directory =
        supportDirectory ??
        (databaseExecutor == null
            ? await getApplicationSupportDirectory()
            : await Directory.systemTemp.createTemp('vox_novel_test_'));
    locator.registerSingleton<BookFileStorage>(
      LocalBookFileStorage(supportDirectory: directory),
    );
  }
  if (!locator.isRegistered<ImportBookService>()) {
    locator.registerSingleton(
      ImportBookService(
        repository: locator(),
        storage: locator(),
        generateId: nextId,
        clock: now,
      ),
    );
  }
  if (!locator.isRegistered<LibraryService>()) {
    locator.registerSingleton(
      LibraryService(repository: locator(), storage: locator(), clock: now),
    );
  }
  if (!locator.isRegistered<LibraryCubit>()) {
    locator.registerSingleton(
      LibraryCubit(repository: locator(), service: locator()),
      dispose: (cubit) => cubit.close(),
    );
  }
  if (!locator.isRegistered<PdfTextExtractor>()) {
    if (pdfTextExtractor == null) {
      await (initializePdfEngine ?? pdfrxFlutterInitialize)();
    }
    locator.registerSingleton<PdfTextExtractor>(
      pdfTextExtractor ?? PdfrxPdfTextExtractor(),
    );
  }
  if (!locator.isRegistered<TextProcessingRepository>()) {
    locator.registerSingleton<TextProcessingRepository>(
      textProcessingRepository ??
          DriftTextProcessingRepository(locator<AppDatabase>()),
    );
  }
  if (!locator.isRegistered<TextProcessingService>()) {
    locator.registerSingleton(
      TextProcessingService(
        books: locator(),
        processing: locator(),
        extractor: locator(),
        cleaner: const TextCleaner(),
        chapterId: nextId,
        blockId: nextId,
        clock: now,
        runId: nextId,
        executor: processingExecutor,
        onCpuWorkerIsolate: onCpuWorkerIsolate,
      ),
    );
  }
  if (!locator.isRegistered<TextProcessingCubit>()) {
    locator.registerSingleton(
      TextProcessingCubit(
        processBook: locator<TextProcessingService>().process,
        cancelBook: locator<TextProcessingService>().cancel,
        closeService: locator<TextProcessingService>().close,
      ),
      dispose: (cubit) => cubit.close(),
    );
  }
  if (!locator.isRegistered<ImportBookCubit>()) {
    locator.registerSingleton(
      ImportBookCubit(
        picker: locator(),
        service: locator(),
        textProcessingCubit: locator(),
      ),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!locator.isRegistered<AppCubit>()) {
    locator.registerSingleton<AppCubit>(
      AppCubit(),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!locator.isRegistered<VisualReaderRepository>()) {
    locator.registerSingleton<VisualReaderRepository>(
      visualReaderRepository ??
          DriftVisualReaderRepository(locator<AppDatabase>()),
    );
  }
  if (!locator.isRegistered<ReaderCubitRegistry>()) {
    locator.registerSingleton(
      ReaderCubitRegistry(
        locator(),
        now,
        visualReaderCubitFactory ??
            (repository, clock) =>
                VisualReaderCubit(repository: repository, clock: clock),
      ),
      dispose: (registry) => registry.closeAll(),
    );
  }
  if (!locator.isRegistered<NarrationRepository>()) {
    if (narrationRepository == null) {
      locator.registerLazySingleton<NarrationRepository>(
        () => DriftNarrationRepository(locator<AppDatabase>()),
      );
    } else {
      locator.registerSingleton<NarrationRepository>(narrationRepository);
    }
  }
  if (!locator.isRegistered<NarrationEngine>()) {
    if (narrationEngine == null) {
      locator.registerLazySingleton<NarrationEngine>(
        FlutterTtsNarrationEngine.new,
        dispose: (engine) => engine.close(),
      );
    } else {
      locator.registerSingleton<NarrationEngine>(
        narrationEngine,
        dispose: (engine) => engine.close(),
      );
    }
  }
  if (!locator.isRegistered<NarrationCubitRegistry>()) {
    locator.registerLazySingleton(
      () => NarrationCubitRegistry(
        locator(),
        locator(),
        now,
        narrationCubitFactory ??
            (repository, engine, clock) => NarrationCubit(
              repository: repository,
              engine: engine,
              clock: clock,
            ),
      ),
      dispose: (registry) => registry.closeAll(),
    );
  }

  if (!locator.isRegistered<GoRouter>()) {
    locator.registerSingleton<GoRouter>(
      createAppRouter(
        libraryPageBuilder: (_) => LibraryPage(
          libraryCubit: locator(),
          importBookCubit: locator(),
          textProcessingCubit: locator(),
        ),
        readerPageBuilder: (_, bookId) {
          final registry = locator<ReaderCubitRegistry>();
          final cubit = registry.create();
          final narrationRegistry = locator<NarrationCubitRegistry>();
          final narrationCubit = narrationRegistry.create();
          return ReaderPage(
            bookId: bookId,
            cubit: cubit,
            closeCubit: registry.close,
            narrationCubit: narrationCubit,
            narrationActivation: narrationRegistry.activationFor(
              narrationCubit,
            ),
            closeNarrationCubit: narrationRegistry.close,
            pdfSurfaceBuilder: pdfSurfaceBuilder,
          );
        },
      ),
      dispose: (router) => router.dispose(),
    );
  }
}

Future<void> resetDependencies({GetIt? instance}) async {
  final locator = instance ?? GetIt.instance;
  if (locator.isRegistered<ReaderCubitRegistry>()) {
    await locator<ReaderCubitRegistry>().closeAll();
  }
  await locator.reset();
}
