import 'dart:async';
import 'dart:io';

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
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
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

    final book = await tester.runAsync(
      () => locator<BookRepository>().findById('book-id'),
    );
    await tester.runAsync(
      () => locator<LibraryCubit>().updateMetadata(
        book: book!,
        title: '  Renomeado  ',
      ),
    );
    await tester.pump();
    expect(find.text('Renomeado'), findsOneWidget);

    final renamed = await tester.runAsync(
      () => locator<BookRepository>().findById('book-id'),
    );
    await tester.runAsync(() => locator<LibraryCubit>().deleteBook(renamed!));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.text('Sua biblioteca está vazia'), findsOneWidget);
    expect(File('${root.path}/books/book-id.pdf').existsSync(), isFalse);
  });
}

final class _FixturePicker implements PdfPicker {
  const _FixturePicker(this.path);
  final String path;
  @override
  Future<PickedPdf?> pickPdf() async =>
      PickedPdf(sourcePath: path, originalFileName: 'fixture.pdf');
}
