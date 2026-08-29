import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/router/app_router.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
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
import 'package:vox_novel/features/narration/data/services/audio_session_interruptions.dart';
import 'package:vox_novel/features/narration/data/services/narration_media_session.dart';
import 'package:vox_novel/features/narration/data/services/permission_handler_notifications.dart';
import 'package:vox_novel/features/narration/domain/services/audio_focus_monitor.dart';
import 'package:vox_novel/features/narration/domain/services/audio_interruptions.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/domain/services/narration_session.dart';
import 'package:vox_novel/features/narration/domain/services/notification_permission.dart';
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
import 'package:vox_novel/features/web_source/data/repositories/drift_web_source_repository.dart';
import 'package:vox_novel/features/web_source/data/services/polite_web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/import_web_book_service.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_download_service.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_index_resolver.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_cubit.dart';

typedef VisualReaderCubitFactory =
    VisualReaderCubit Function(
      VisualReaderRepository repository,
      DateTime Function() clock,
    );

typedef NarrationCubitFactory = NarrationCubit Function(NarrationSession);

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

/// Hands out Cubits attached to the one application-scoped session.
///
/// This used to arbitrate ownership — closing the previous Cubit before
/// activating the next — because each one owned an engine. Under AD-013 there
/// is a single session, so "only one narration at a time" is structural and
/// this is just an attach point that tracks what to detach on reset.
final class NarrationCubitRegistry {
  NarrationCubitRegistry(this._session, this._factory);

  final NarrationSession _session;
  final NarrationCubitFactory _factory;
  final Set<NarrationCubit> _attached = {};

  Iterable<NarrationCubit> get activeCubits => List.unmodifiable(_attached);

  NarrationCubit create() {
    final cubit = _factory(_session);
    _attached.add(cubit);
    return cubit;
  }

  /// Kept so callers need not know that attaching is now synchronous.
  Future<void> activationFor(NarrationCubit cubit) => Future.value();

  /// Detaches [cubit]. Playback is unaffected: it belongs to the session.
  Future<void> close(NarrationCubit cubit) async {
    if (!_attached.remove(cubit)) return;
    await cubit.close();
  }

  Future<void> closeAll() async {
    await Future.wait([..._attached].map(close));
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
  Future<void> Function()? resumeWebDownloads,
  VisualReaderRepository? visualReaderRepository,
  VisualReaderCubitFactory? visualReaderCubitFactory,
  NarrationRepository? narrationRepository,
  NarrationEngine? narrationEngine,
  NarrationSession? narrationSession,
  AudioInterruptions? audioInterruptions,
  NotificationPermission? notificationPermission,
  Future<void> Function()? startMediaSession,
  NarrationCubitFactory? narrationCubitFactory,
  SiteRecipeRegistry? siteRecipeRegistry,
  WebFetcher? webFetcher,
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
  if (!locator.isRegistered<NarrationSession>()) {
    locator.registerLazySingleton<NarrationSession>(
      () => narrationSession ??
          NarrationSession(
            repository: locator(),
            engine: locator(),
            clock: now,
            notifications:
                notificationPermission ??
                const PermissionHandlerNotifications(),
          ),
      dispose: (session) => session.close(),
    );
  }
  if (!locator.isRegistered<AudioInterruptions>()) {
    locator.registerLazySingleton<AudioInterruptions>(
      () => audioInterruptions ?? AudioSessionInterruptions(),
    );
  }
  if (!locator.isRegistered<AudioFocusMonitor>()) {
    locator.registerLazySingleton<AudioFocusMonitor>(
      () => AudioFocusMonitor(
        interruptions: locator(),
        playback: locator<NarrationSession>(),
      ),
      dispose: (monitor) => monitor.close(),
    );
  }
  if (!locator.isRegistered<NarrationCubitRegistry>()) {
    locator.registerLazySingleton(
      () => NarrationCubitRegistry(
        locator(),
        narrationCubitFactory ??
            (session) => NarrationCubit(session: session),
      ),
      dispose: (registry) => registry.closeAll(),
    );
  }

  if (!locator.isRegistered<SiteRecipeRegistry>()) {
    if (siteRecipeRegistry != null) {
      locator.registerSingleton<SiteRecipeRegistry>(siteRecipeRegistry);
    } else {
      // Composing the container must not block on I/O: the asset read starts
      // here and is awaited by the first web import instead. Awaiting it here
      // deadlocks every widget test, whose fake clock never completes it.
      locator.registerSingletonAsync<SiteRecipeRegistry>(
        () => SiteRecipeRegistry.load(rootBundle),
      );
    }
  }
  if (!locator.isRegistered<WebFetcher>()) {
    locator.registerSingleton<WebFetcher>(webFetcher ?? PoliteWebFetcher());
  }
  if (!locator.isRegistered<WebSourceRepository>()) {
    locator.registerSingleton<WebSourceRepository>(
      DriftWebSourceRepository(locator<AppDatabase>(), clock: now),
    );
  }
  if (!locator.isRegistered<ChapterIngest>()) {
    locator.registerSingleton(
      ChapterIngest(processing: locator(), chapterId: nextId, blockId: nextId),
    );
  }
  // Everything below reads the recipes at construction, so it stays lazy until
  // the first import, by when the asset has been awaited.
  if (!locator.isRegistered<WebNovelIndexResolver>()) {
    locator.registerLazySingleton(
      () => WebNovelIndexResolver(fetcher: locator(), recipes: locator()),
    );
  }
  if (!locator.isRegistered<WebNovelDownloadService>()) {
    locator.registerLazySingleton(
      () => WebNovelDownloadService(
        books: locator(),
        source: locator(),
        processing: locator(),
        ingest: locator(),
        fetcher: locator(),
        recipes: locator(),
        clock: now,
        runId: nextId,
      ),
    );
  }
  if (!locator.isRegistered<ImportWebBookService>()) {
    locator.registerLazySingleton(
      () => ImportWebBookService(
        books: locator(),
        source: locator(),
        resolver: locator(),
        // The import returns as soon as the index is persisted; the queue
        // drains in the background so the book is readable meanwhile.
        startDownload: (bookId) =>
            locator<WebNovelDownloadService>().download(bookId).ignore(),
        generateId: nextId,
        clock: now,
      ),
    );
  }
  if (!locator.isRegistered<ImportWebBookCubit>()) {
    locator.registerSingleton(
      ImportWebBookCubit(
        importBook: (url) async {
          await locator.getAsync<SiteRecipeRegistry>();
          return locator<ImportWebBookService>().import(url);
        },
      ),
      dispose: (cubit) => cubit.close(),
    );
  }

  // A download interrupted by a restart is re-enqueued here, fire and forget:
  // it waits for the recipe asset and reads the library, and awaiting either
  // during composition deadlocks every widget test. Injectable because even
  // unawaited it leaves the queue's throttle timers alive past a widget test's
  // disposal, so a test composing the app for another reason opts out.
  (resumeWebDownloads ?? () => _resumeWebDownloads(locator))().ignore();

  // Fire and forget, for the same reason the resume above is: awaiting real
  // platform initialisation during composition never completes under a widget
  // test's fake clock.
  _bringUpMediaSession(
    locator,
    startMediaSession ?? () => _startNarrationMediaSession(locator),
  ).ignore();

  if (!locator.isRegistered<GoRouter>()) {
    locator.registerSingleton<GoRouter>(
      createAppRouter(
        libraryPageBuilder: (_) => LibraryPage(
          libraryCubit: locator(),
          importBookCubit: locator(),
          textProcessingCubit: locator(),
          importWebBookCubit: locator(),
          cancelWebDownload: (bookId) =>
              locator<WebNovelDownloadService>().cancel(bookId),
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

/// Waits for the recipe asset the download service reads at construction,
/// then re-enqueues every web book left mid-download.
Future<void> _resumeWebDownloads(GetIt locator) async {
  await locator.allReady();
  await locator<WebNovelDownloadService>().resumePending();
}

/// Starts the media session, and reports rather than crashes when the platform
/// refuses. A device that cannot host a foreground service must still narrate
/// inside the app (BGN-10).
Future<void> _bringUpMediaSession(
  GetIt locator,
  Future<void> Function() start,
) async {
  try {
    await start();
  } catch (_) {
    locator<NarrationSession>().reportMediaSessionUnavailable();
  }
}

/// Resolved here rather than at the call site so a test that opts out never
/// builds the real speech engine just to hand it to a no-op.
Future<void> _startNarrationMediaSession(GetIt locator) =>
    startNarrationMediaSession(
      locator<NarrationSession>(),
      locator<AudioFocusMonitor>(),
    );

Future<void> resetDependencies({GetIt? instance}) async {
  final locator = instance ?? GetIt.instance;
  if (locator.isRegistered<ReaderCubitRegistry>()) {
    await locator<ReaderCubitRegistry>().closeAll();
  }
  await locator.reset();
}
