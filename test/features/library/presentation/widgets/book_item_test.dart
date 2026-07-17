import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_grid_item.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';

void main() {
  for (final grid in [false, true]) {
    testWidgets(
      '${grid ? 'grid' : 'list'} renders metadata and exact actions',
      (tester) async {
        final book = _book(author: 'Author');
        Book? edited;
        Book? deleted;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: grid
                  ? BookGridItem(
                      book: book,
                      onEdit: (value) => edited = value,
                      onDelete: (value) => deleted = value,
                    )
                  : BookListItem(
                      book: book,
                      onEdit: (value) => edited = value,
                      onDelete: (value) => deleted = value,
                    ),
            ),
          ),
        );
        expect(find.text('Title'), findsOneWidget);
        expect(find.textContaining('Author'), findsOneWidget);
        expect(find.textContaining('Importando'), findsOneWidget);
        await tester.tap(find.byTooltip('Editar Title'));
        expect(edited, same(book));
        await tester.tap(find.byTooltip('Excluir Title'));
        expect(deleted, same(book));
      },
    );
  }
  testWidgets('empty author is omitted', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookListItem(book: _book(), onEdit: (_) {}, onDelete: (_) {}),
        ),
      ),
    );
    expect(find.text('Author'), findsNothing);
  });

  for (final entry in {
    BookStatus.importing: 'Importando',
    BookStatus.processing: 'Processando',
    BookStatus.ready: 'Pronto',
    BookStatus.failed: 'Falhou',
    BookStatus.unsupported: 'Não suportado',
  }.entries) {
    testWidgets('${entry.key.name} renders exact localized status', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookListItem(
              book: _book(status: entry.key),
              onEdit: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );

      expect(find.text(entry.value), findsOneWidget);
    });
  }
}

Book _book({String? author, BookStatus status = BookStatus.importing}) => Book(
  id: 'id',
  title: 'Title',
  author: author,
  originalFileName: 'a.pdf',
  storedFilePath: '/a.pdf',
  fileHash: 'hash',
  status: status,
  processingProgress: 0,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
