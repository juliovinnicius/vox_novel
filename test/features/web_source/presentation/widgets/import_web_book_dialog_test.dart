import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/web_source/domain/services/import_web_book_service.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_cubit.dart';
import 'package:vox_novel/features/web_source/presentation/widgets/import_web_book_dialog.dart';

/// Every rejection the dialog must render inline, with the exact message its
/// reason earned.
const Map<ImportWebBookRejection, String> rejections = {
  ImportWebBookRejection.invalidUrl: 'Informe uma URL válida',
  ImportWebBookRejection.unsupportedDomain: 'Site não suportado: outro.com',
  ImportWebBookRejection.disallowedPath:
      'Este endereço não é permitido pelo site',
  ImportWebBookRejection.network: 'Sem conexão com a internet',
  ImportWebBookRejection.unsupported: 'Nenhum capítulo encontrado',
  ImportWebBookRejection.storage: ImportWebBookService.storageMessage,
};

final class FakeImport {
  FakeImport(this.result);

  final ImportWebBookResult result;
  final List<String> submitted = [];
  Completer<void>? gate;

  Future<ImportWebBookResult> call(String url) async {
    submitted.add(url);
    if (gate != null) await gate!.future;
    return result;
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

Widget host(ImportWebBookCubit cubit) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showImportWebBookDialog(context, cubit),
        child: const Text('abrir'),
      ),
    ),
  ),
);

void main() {
  const url = 'https://exemplo.com/series/obra-sintetica/';

  Future<ImportWebBookCubit> open(WidgetTester tester, FakeImport import) async {
    final cubit = ImportWebBookCubit(importBook: import.call);
    addTearDown(cubit.close);
    await tester.pumpWidget(host(cubit));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('submits the typed url and closes on success', (tester) async {
    final import = FakeImport(WebBookImported(webBook('book-1'), created: true));
    await open(tester, import);

    await tester.enterText(find.byType(TextField), url);
    await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
    await tester.pumpAndSettle();

    expect(import.submitted, [url]);
    expect(find.byType(ImportWebBookDialog), findsNothing);
  });

  for (final entry in rejections.entries) {
    testWidgets('shows the ${entry.key.name} message inline and stays open',
        (tester) async {
      final import = FakeImport(
        WebBookImportRejected(entry.key, entry.value),
      );
      await open(tester, import);

      await tester.enterText(find.byType(TextField), url);
      await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.byType(ImportWebBookDialog), findsOneWidget);
    });
  }

  testWidgets('submit is disabled while the import is in flight',
      (tester) async {
    final import = FakeImport(WebBookImported(webBook('book-1'), created: true))
      ..gate = Completer<void>();
    await open(tester, import);

    await tester.enterText(find.byType(TextField), url);
    await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
    await tester.pump();

    expect(
      tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Importar'),
      ).onPressed,
      isNull,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Importar'),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(import.submitted, [url]);

    import.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a previous attempt message does not greet the next dialog',
      (tester) async {
    final import = FakeImport(
      const WebBookImportRejected(
        ImportWebBookRejection.network,
        'Sem conexão com a internet',
      ),
    );
    final cubit = await open(tester, import);

    await tester.enterText(find.byType(TextField), url);
    await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
    await tester.pumpAndSettle();
    expect(find.text('Sem conexão com a internet'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet'), findsNothing);
    expect(cubit.state.errorMessage, isNull);
  });
}
