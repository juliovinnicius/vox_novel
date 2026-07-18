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
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/data/services/pdfrx_pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/chapter_detector.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/narration_block_splitter.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';

Future<void> configureDependencies({
  GetIt? instance,
  QueryExecutor? databaseExecutor,
  Directory? supportDirectory,
  PdfPicker? pdfPicker,
  DateTime Function()? clock,
  String Function()? generateId,
  PdfTextExtractor? pdfTextExtractor,
  TextProcessingRepository? textProcessingRepository,
  Future<void> Function()? initializePdfEngine,
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
        chapterDetector: () => ChapterDetector(idGenerator: nextId),
        blockSplitter: () => NarrationBlockSplitter(nextId),
        clock: now,
        runId: nextId,
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

  if (!locator.isRegistered<GoRouter>()) {
    locator.registerSingleton<GoRouter>(
      createAppRouter(
        libraryPageBuilder: (_) => LibraryPage(
          libraryCubit: locator(),
          importBookCubit: locator(),
          textProcessingCubit: locator(),
        ),
      ),
      dispose: (router) => router.dispose(),
    );
  }
}

Future<void> resetDependencies({GetIt? instance}) {
  return (instance ?? GetIt.instance).reset();
}
