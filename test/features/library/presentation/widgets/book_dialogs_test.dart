import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/delete_book_dialog.dart';
import 'package:vox_novel/features/library/presentation/widgets/edit_book_dialog.dart';

void main() {
  testWidgets('edit initializes, validates, trims and cancels', (tester) async {
    BookMetadata? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showEditBookDialog(context, _book()),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Title'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Author'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), '  ');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Informe o título'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, ' New ');
    await tester.enterText(find.byType(TextFormField).at(1), ' Writer ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(result!.title, 'New');
    expect(result!.author, 'Writer');
  });
  testWidgets('delete names book and returns typed choices', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await showDeleteBookDialog(context, _book()),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Title'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}

Book _book() => Book(
  id: 'id',
  title: 'Title',
  author: 'Author',
  originalFileName: 'a.pdf',
  storedFilePath: '/a',
  fileHash: 'h',
  status: BookStatus.ready,
  processingProgress: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
