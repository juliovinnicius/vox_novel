import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/chapter_drawer.dart';

void main() {
  ReaderChapter chapter(String id, String title, int order) => ReaderChapter(
    chapter: ChapterDraft(
      id: id,
      title: title,
      sortOrder: order,
      startPage: 1,
      endPage: 1,
      cleanText: '',
    ),
    blocks: const [],
  );

  Future<void> pumpHost(
    WidgetTester tester, {
    required List<ReaderChapter> chapters,
    String? currentChapterId,
    ValueChanged<String>? onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: Scaffold(
          drawer: ChapterDrawer(
            chapters: chapters,
            currentChapterId: currentChapterId,
            onChapterSelected: onSelected ?? (_) {},
          ),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: Scaffold.of(context).openDrawer,
              child: const Text('Abrir capítulos'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir capítulos'));
    await tester.pumpAndSettle();
  }

  testWidgets('each row carries its chapter number', (tester) async {
    await pumpHost(
      tester,
      chapters: [chapter('a', 'Começo', 0), chapter('b', 'Depois', 1)],
    );

    expect(find.text('1 - Começo'), findsOneWidget);
    expect(find.text('2 - Depois'), findsOneWidget);
  });

  testWidgets('a missing chapter does not renumber the ones after it', (
    tester,
  ) async {
    // A web chapter that failed to download leaves a hole in sortOrder.
    // Numbering by list position would show 2 for what the site calls 3.
    await pumpHost(
      tester,
      chapters: [chapter('a', 'Começo', 0), chapter('c', 'Terceiro', 2)],
    );

    expect(find.text('3 - Terceiro'), findsOneWidget);
    expect(find.text('2 - Terceiro'), findsNothing);
  });

  testWidgets('renders chapters in the supplied exact order', (tester) async {
    final chapters = [
      chapter('intro', 'Introdução', 0),
      chapter('middle', 'O meio', 1),
      chapter('end', 'Fim', 2),
    ];
    await pumpHost(tester, chapters: chapters);

    final positions = chapters
        .map(
          (item) => tester
              .getTopLeft(
                find.text(
                  '${item.chapter.sortOrder + 1} - ${item.chapter.title}',
                ),
              )
              .dy,
        )
        .toList();
    expect(positions, orderedEquals([...positions]..sort()));
  });

  testWidgets('marks the current chapter semantically', (tester) async {
    await pumpHost(
      tester,
      chapters: [chapter('one', 'Um', 0), chapter('two', 'Dois', 1)],
      currentChapterId: 'two',
    );

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('chapter-two')),
    );
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(semantics.label, contains('Capítulo atual'));
  });

  testWidgets('returns the exact ID and closes after a tap', (tester) async {
    String? selected;
    await pumpHost(
      tester,
      chapters: [chapter('id/with spaces', 'Especial', 0)],
      onSelected: (value) => selected = value,
    );

    await tester.tap(find.textContaining('Especial'));
    await tester.pumpAndSettle();

    expect(selected, 'id/with spaces');
    expect(find.text('Capítulos'), findsNothing);
    expect(find.text('Abrir capítulos'), findsOneWidget);
  });

  testWidgets('has accessible empty, single, and multiple states', (
    tester,
  ) async {
    await pumpHost(tester, chapters: const []);
    expect(find.text('Nenhum capítulo disponível'), findsOneWidget);

    await pumpHost(tester, chapters: [chapter('one', 'Único', 0)]);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('chapter-one'))).label,
      contains('Único'),
    );

    await pumpHost(
      tester,
      chapters: [chapter('one', 'Primeiro', 0), chapter('two', 'Segundo', 1)],
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('chapter-one'))).label,
      contains('Primeiro'),
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('chapter-two'))).label,
      contains('Segundo'),
    );
  });
}
