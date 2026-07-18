import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/app_state.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';
import 'package:vox_novel/app/router/app_router.dart';
import 'package:vox_novel/core/database/app_database.dart' hide RawPage;
import 'package:vox_novel/features/import_book/data/services/local_book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/library/data/repositories/drift_book_repository.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart' as domain;
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_state.dart';
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/main.dart' as application;

void main() {
  testWidgets('application smoke test renders one Biblioteca', (tester) async {
    final router = createAppRouter();
    final cubit = AppCubit();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(VoxNovelApp(router: router, appCubit: cubit));

    expect(find.text('Biblioteca'), findsOneWidget);
  });

  testWidgets('bootstrap awaits dependencies before returning the app', (
    tester,
  ) async {
    final locator = GetIt.asNewInstance();
    final allowConfiguration = Completer<void>();
    var applicationCreated = false;
    addTearDown(() => resetDependencies(instance: locator));

    final applicationFuture = application
        .createApplication(
          instance: locator,
          databaseExecutor: NativeDatabase.memory(),
          supportDirectory: Directory.systemTemp,
          configure:
              ({
                required instance,
                databaseExecutor,
                Directory? supportDirectory,
                PdfPicker? pdfPicker,
                DateTime Function()? clock,
                String Function()? generateId,
              }) async {
                await allowConfiguration.future;
                await configureDependencies(
                  instance: instance,
                  databaseExecutor: databaseExecutor,
                  supportDirectory: supportDirectory,
                  pdfPicker: pdfPicker,
                  clock: clock,
                  generateId: generateId,
                );
              },
        )
        .then((app) {
          applicationCreated = true;
          return app;
        });

    await tester.pump();
    expect(applicationCreated, isFalse);

    allowConfiguration.complete();
    final app = await applicationFuture;

    expect(locator.isRegistered<AppDatabase>(), isTrue);
    expect(locator.isRegistered<AppCubit>(), isTrue);
    expect(locator.isRegistered<GoRouter>(), isTrue);
    expect(locator<AppCubit>().state.status, AppStatus.ready);

    expect(app.router, same(locator<GoRouter>()));
  });

  testWidgets('root imports, edits and completely deletes a durable book', (
    tester,
  ) async {
    final locator = GetIt.asNewInstance();
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('vox_novel_root_'),
    );
    final source = File('${root!.path}/fixture.pdf');
    await tester.runAsync(() => source.writeAsBytes([1, 2, 3]));
    addTearDown(() async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await resetDependencies(instance: locator);
      if (await root.exists()) await root.delete(recursive: true);
    });

    final app = await application.createApplication(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
      supportDirectory: root,
      pdfPicker: _FixturePicker(source.path),
      clock: () => DateTime(2026),
      generateId: () => 'book-id',
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.runAsync(() => locator<ImportBookCubit>().importPdf());
    await tester.pump();
    expect(find.text('fixture'), findsOneWidget);
    expect(File('${root.path}/books/book-id.pdf').existsSync(), isTrue);
    final cover = File('${root.path}/books/book-id.jpg');
    await tester.runAsync(() => cover.writeAsBytes([4, 5, 6]));
    await tester.runAsync(
      () =>
          (locator<AppDatabase>().update(locator<AppDatabase>().books)
                ..where((row) => row.id.equals('book-id')))
              .write(BooksCompanion(coverPath: Value(cover.path))),
    );
    await tester.pump();

    final book = await tester.runAsync(
      () => locator<BookRepository>().findById('book-id'),
    );
    await tester.tap(find.byTooltip('Editar fixture'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Discarded edit');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => locator<BookRepository>().findById('book-id'),
      ),
      book,
    );

    await tester.tap(find.byTooltip('Excluir fixture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(
        () => locator<BookRepository>().findById('book-id'),
      ),
      book,
    );
    expect(
      await tester.runAsync(
        () => File('${root.path}/books/book-id.pdf').readAsBytes(),
      ),
      [1, 2, 3],
    );
    expect(await tester.runAsync(cover.readAsBytes), [4, 5, 6]);

    await tester.runAsync(
      () => locator<LibraryCubit>().updateMetadata(
        book: book!,
        title: '  Renomeado  ',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Renomeado'), findsOneWidget);

    final renamed = await tester.runAsync(
      () => locator<BookRepository>().findById('book-id'),
    );
    await tester.runAsync(() => locator<LibraryCubit>().deleteBook(renamed!));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.text('Sua biblioteca está vazia'), findsOneWidget);
    expect(File('${root.path}/books/book-id.pdf').existsSync(), isFalse);
    expect(cover.existsSync(), isFalse);
  });

  test('cleanup failure is compensated durably across restart', () async {
    final root = await Directory.systemTemp.createTemp('vox_novel_delete_');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final databaseFile = File('${root.path}/library.sqlite');
    var database = AppDatabase(NativeDatabase(databaseFile));
    var repository = DriftBookRepository(database);
    final pdf = File('${root.path}/books/book.pdf');
    final cover = File('${root.path}/books/cover.jpg');
    await pdf.create(recursive: true);
    await cover.create(recursive: true);
    await pdf.writeAsBytes([1]);
    await cover.writeAsBytes([2]);
    final seedBook = domain.Book(
      id: 'book-id',
      title: 'Título',
      author: 'Autora',
      coverPath: cover.path,
      originalFileName: 'book.pdf',
      storedFilePath: pdf.path,
      fileHash: 'hash',
      status: domain.BookStatus.importing,
      processingProgress: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await repository.insert(seedBook);
    final processing = DriftTextProcessingRepository(database);
    final now = DateTime.utc(2026);
    await processing.createRun(
      bookId: seedBook.id,
      runId: 'run-1',
      startedAt: now,
    );
    await processing.stageRawPage('run-1', RawPage(pageNumber: 1, text: 'Raw'));
    await processing.stageCleanPage(
      'run-1',
      CleanPage(pageNumber: 1, text: 'Texto.'),
    );
    await processing.stageChaptersAndBlocks(
      runId: 'run-1',
      bookId: seedBook.id,
      chapters: [
        ChapterDraft(
          id: 'chapter-1',
          title: 'Capítulo 1',
          sortOrder: 0,
          startPage: 1,
          endPage: 1,
          cleanText: 'Texto.',
        ),
      ],
      blocks: [
        NarrationBlockDraft(
          id: 'block-1',
          chapterId: 'chapter-1',
          sortOrder: 0,
          originalText: 'Texto.',
          normalizedText: 'Texto.',
          characterCount: 6,
          startPage: 1,
          endPage: 1,
        ),
      ],
      createdAt: now,
    );
    await processing.activateRun(
      runId: 'run-1',
      pageCount: 1,
      chapterCount: 1,
      blockCount: 1,
      completedAt: now,
    );
    final book = (await repository.findById(seedBook.id))!;
    final failingStorage = LocalBookFileStorage(
      supportDirectory: root,
      deleteFile: (_) async => throw const FileSystemException('disk failure'),
    );

    final failed = await LibraryService(
      repository: repository,
      storage: failingStorage,
      clock: () => DateTime.utc(2026),
    ).deleteBook(book);

    expect(failed.success, isFalse);
    expect(failed.message, 'Não foi possível excluir o livro');
    await database.close();
    database = AppDatabase(NativeDatabase(databaseFile));
    repository = DriftBookRepository(database);
    expect(await repository.findById(book.id), book);
    final restoredPage = await database.select(database.rawPages).getSingle();
    final restoredChapter = await database
        .select(database.chapters)
        .getSingle();
    final restoredBlock = await database
        .select(database.narrationBlocks)
        .getSingle();
    expect([restoredPage.rawText, restoredPage.cleanText], ['Raw', 'Texto.']);
    expect(
      [restoredChapter.id, restoredChapter.title, restoredChapter.cleanText],
      ['chapter-1', 'Capítulo 1', 'Texto.'],
    );
    expect(
      [
        restoredBlock.id,
        restoredBlock.originalText,
        restoredBlock.normalizedText,
        restoredBlock.characterCount,
      ],
      ['block-1', 'Texto.', 'Texto.', 6],
    );
    expect(await pdf.readAsBytes(), [1]);
    expect(await cover.readAsBytes(), [2]);

    final deleted = await LibraryService(
      repository: repository,
      storage: LocalBookFileStorage(supportDirectory: root),
      clock: () => DateTime.utc(2026),
    ).deleteBook(book);

    expect(deleted.success, isTrue);
    await database.close();
    database = AppDatabase(NativeDatabase(databaseFile));
    repository = DriftBookRepository(database);
    expect(await repository.findById(book.id), isNull);
    expect(await database.select(database.processingRuns).get(), isEmpty);
    expect(await database.select(database.rawPages).get(), isEmpty);
    expect(await database.select(database.chapters).get(), isEmpty);
    expect(await database.select(database.narrationBlocks).get(), isEmpty);
    expect(await pdf.exists(), isFalse);
    expect(await cover.exists(), isFalse);
    expect(
      await Directory('${root.path}/books/.trash').list().toList(),
      isEmpty,
    );
    await database.close();
  });

  testWidgets(
    'restart loads persisted newest-first list visibly within two seconds',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('vox_novel_restart_'),
      );
      final databaseFile = File('${root!.path}/library.sqlite');
      await tester.runAsync(() async {
        final seedDatabase = AppDatabase(NativeDatabase(databaseFile));
        final seedRepository = DriftBookRepository(seedDatabase);
        await seedRepository.insert(
          _persistedBook(
            id: 'older',
            title: 'Older',
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await seedRepository.insert(
          _persistedBook(
            id: 'newer',
            title: 'Newer',
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        );
        await seedDatabase.close();
      });

      Future<GetIt> startFreshApplication() async {
        final locator = GetIt.asNewInstance();
        final app = await tester.runAsync(
          () => application.createApplication(
            instance: locator,
            databaseExecutor: NativeDatabase(databaseFile),
            supportDirectory: root,
          ),
        );
        await tester.pumpWidget(app!);
        await tester.pumpAndSettle();
        return locator;
      }

      var locator = await startFreshApplication();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.runAsync(() => resetDependencies(instance: locator));

      final stopwatch = Stopwatch()..start();
      locator = await startFreshApplication();
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(locator<LibraryCubit>().state.layout, LibraryLayout.list);
      expect(locator<LibraryCubit>().state.books.map((book) => book.id), [
        'newer',
        'older',
      ]);
      expect(
        tester.getTopLeft(find.text('Newer')).dy,
        lessThan(tester.getTopLeft(find.text('Older')).dy),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.runAsync(() => resetDependencies(instance: locator));
      await tester.runAsync(() => root.delete(recursive: true));
    },
  );
}

domain.Book _persistedBook({
  required String id,
  required String title,
  required DateTime updatedAt,
}) => domain.Book(
  id: id,
  title: title,
  originalFileName: '$id.pdf',
  storedFilePath: '/books/$id.pdf',
  fileHash: id,
  status: domain.BookStatus.ready,
  processingProgress: 0,
  createdAt: DateTime.utc(2026),
  updatedAt: updatedAt,
);

final class _FixturePicker implements PdfPicker {
  const _FixturePicker(this.path);
  final String path;
  @override
  Future<PickedPdf?> pickPdf() async =>
      PickedPdf(sourcePath: path, originalFileName: 'fixture.pdf');
}
