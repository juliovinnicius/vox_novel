import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_grid_item.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

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

  for (final grid in [false, true]) {
    for (final entry in {
      ProcessingStage.extracting: ('Extraindo texto', 0.4),
      ProcessingStage.cleaning: ('Limpando', 0.6),
      ProcessingStage.detectingChapters: ('Detectando capítulos', 0.75),
      ProcessingStage.buildingBlocks: ('Preparando narração', 0.95),
      ProcessingStage.completed: ('Concluído', 1.0),
    }.entries) {
      testWidgets(
        '${grid ? 'grid' : 'list'} shows ${entry.value.$1} and rounded percentage',
        (tester) async {
          final book = _book(
            status: BookStatus.processing,
            stage: entry.key,
            progress: entry.value.$2,
          );
          Book? cancelled;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: grid
                    ? BookGridItem(
                        book: book,
                        onEdit: (_) {},
                        onDelete: (_) {},
                        onCancelProcessing: (value) => cancelled = value,
                      )
                    : BookListItem(
                        book: book,
                        onEdit: (_) {},
                        onDelete: (_) {},
                        onCancelProcessing: (value) => cancelled = value,
                      ),
              ),
            ),
          );

          expect(
            find.text(
              '${entry.value.$1} • ${(entry.value.$2 * 100).round()}%',
            ),
            findsOneWidget,
          );
          expect(find.byType(LinearProgressIndicator), findsOneWidget);
          final indicator = tester.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          );
          expect(indicator.value, entry.value.$2);
          await tester.tap(
            find.byTooltip('Cancelar processamento de Title'),
          );
          expect(cancelled, same(book));
        },
      );
    }
  }

  for (final grid in [false, true]) {
    testWidgets('${grid ? 'grid' : 'list'} hides processing controls otherwise', (
      tester,
    ) async {
      final book = _book(
        status: BookStatus.ready,
        stage: ProcessingStage.completed,
        progress: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: grid
                ? BookGridItem(
                    book: book,
                    onEdit: (_) {},
                    onDelete: (_) {},
                    onCancelProcessing: (_) {},
                  )
                : BookListItem(
                    book: book,
                    onEdit: (_) {},
                    onDelete: (_) {},
                    onCancelProcessing: (_) {},
                  ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Concluído'), findsNothing);
      expect(
        find.byTooltip('Cancelar processamento de Title'),
        findsNothing,
      );
    });
  }
}

Book _book({
  String? author,
  BookStatus status = BookStatus.importing,
  ProcessingStage? stage,
  double progress = 0,
}) => Book(
  id: 'id',
  title: 'Title',
  author: author,
  originalFileName: 'a.pdf',
  storedFilePath: '/a.pdf',
  fileHash: 'hash',
  status: status,
  processingProgress: progress,
  processingStage: stage,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
