import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_grid_item.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

void main() {
  for (final grid in [false, true]) {
    testWidgets('${grid ? 'grid' : 'list'} opens ready books only', (
      tester,
    ) async {
      Book? opened;
      Widget item(Book book) => grid
          ? BookGridItem(
              book: book,
              onEdit: (_) {},
              onDelete: (_) {},
              onOpen: (value) => opened = value,
            )
          : BookListItem(
              book: book,
              onEdit: (_) {},
              onDelete: (_) {},
              onOpen: (value) => opened = value,
            );
      final ready = _book(status: BookStatus.ready);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: item(ready))));
      await tester.tap(find.byTooltip('Abrir Title'));
      expect(opened, same(ready));

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: item(_book()))));
      expect(find.byTooltip('Abrir Title'), findsNothing);
    });

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
            find.text('${entry.value.$1} • ${(entry.value.$2 * 100).round()}%'),
            findsOneWidget,
          );
          expect(find.byType(LinearProgressIndicator), findsOneWidget);
          final indicator = tester.widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          );
          expect(indicator.value, entry.value.$2);
          await tester.tap(find.byTooltip('Cancelar processamento de Title'));
          expect(cancelled, same(book));
        },
      );
    }
  }

  for (final grid in [false, true]) {
    testWidgets(
      '${grid ? 'grid' : 'list'} hides processing controls otherwise',
      (tester) async {
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
        expect(find.byTooltip('Cancelar processamento de Title'), findsNothing);
      },
    );
  }

  for (final grid in [false, true]) {
    Widget item(Book book, {ValueChanged<Book>? onOpen}) => MaterialApp(
      home: Scaffold(
        body: grid
            ? BookGridItem(
                book: book,
                onEdit: (_) {},
                onDelete: (_) {},
                onOpen: onOpen,
              )
            : BookListItem(
                book: book,
                onEdit: (_) {},
                onDelete: (_) {},
                onOpen: onOpen,
              ),
      ),
    );

    testWidgets(
      '${grid ? 'grid' : 'list'} opens a downloading web book that already '
      'stored a chapter',
      (tester) async {
        final book = _webBook(stored: 1, indexed: 4, progress: 0.25);
        Book? opened;

        await tester.pumpWidget(item(book, onOpen: (value) => opened = value));
        await tester.tap(find.byTooltip('Abrir Title'));

        expect(opened, same(book));
      },
    );

    testWidgets(
      '${grid ? 'grid' : 'list'} does not open a web book with no stored '
      'chapter',
      (tester) async {
        await tester.pumpWidget(
          item(_webBook(stored: 0, indexed: 4), onOpen: (_) {}),
        );

        expect(find.byTooltip('Abrir Title'), findsNothing);
      },
    );

    testWidgets(
      '${grid ? 'grid' : 'list'} still refuses to open a processing pdf book',
      (tester) async {
        final pdf = _book(
          status: BookStatus.processing,
          stage: ProcessingStage.cleaning,
          progress: 0.5,
        );

        await tester.pumpWidget(item(pdf, onOpen: (_) {}));

        expect(find.byTooltip('Abrir Title'), findsNothing);
      },
    );

    testWidgets(
      '${grid ? 'grid' : 'list'} renders web download progress as stored over '
      'indexed chapters',
      (tester) async {
        await tester.pumpWidget(
          item(_webBook(stored: 3, indexed: 12, progress: 0.25)),
        );

        expect(find.text('Baixando capítulos • 3/12'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0.25,
        );
      },
    );

    testWidgets(
      '${grid ? 'grid' : 'list'} keeps the percentage line for a processing '
      'pdf book',
      (tester) async {
        await tester.pumpWidget(
          item(
            _book(
              status: BookStatus.processing,
              stage: ProcessingStage.cleaning,
              progress: 0.6,
            ),
          ),
        );

        expect(find.text('Limpando • 60%'), findsOneWidget);
        expect(find.textContaining('Baixando capítulos'), findsNothing);
      },
    );

    testWidgets(
      '${grid ? 'grid' : 'list'} shows no download line once the web book is '
      'ready',
      (tester) async {
        final book = _webBook(
          stored: 4,
          indexed: 4,
          progress: 1,
          status: BookStatus.ready,
        );

        await tester.pumpWidget(item(book, onOpen: (_) {}));

        expect(find.textContaining('Baixando capítulos'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.byTooltip('Abrir Title'), findsOneWidget);
      },
    );
  }
}

Book _webBook({
  required int stored,
  required int indexed,
  double progress = 0,
  BookStatus status = BookStatus.processing,
}) => Book(
  id: 'id',
  title: 'Title',
  sourceType: BookSourceType.web,
  sourceRef: 'https://exemplo.com/series/obra/',
  status: status,
  processingProgress: progress,
  pageCount: indexed,
  chapterCount: stored,
  processingStage: ProcessingStage.extracting,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

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
