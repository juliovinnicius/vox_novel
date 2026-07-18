import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/text_reader_view.dart';

void main() {
  ReaderChapter chapter(List<String> texts) {
    final draft = ChapterDraft(
      id: 'chapter-1',
      title: 'Capítulo 1',
      sortOrder: 0,
      startPage: 1,
      endPage: 1,
      cleanText: texts.join('\n'),
    );
    return ReaderChapter(
      chapter: draft,
      blocks: [
        for (var index = 0; index < texts.length; index++)
          NarrationBlockDraft(
            id: 'block-$index',
            chapterId: draft.id,
            sortOrder: index,
            originalText: texts[index],
            normalizedText: texts[index],
            characterCount: texts[index].runes.length,
            startPage: 1,
            endPage: 1,
          ),
      ],
    );
  }

  Future<void> pumpReader(
    WidgetTester tester, {
    required ReaderChapter chapter,
    String? selectedBlockId,
    ValueChanged<String>? onSelected,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    bool hasPrevious = true,
    bool hasNext = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextReaderView(
          chapter: chapter,
          selectedBlockId: selectedBlockId,
          onBlockSelected: onSelected ?? (_) {},
          onPreviousChapter: onPrevious ?? () {},
          onNextChapter: onNext ?? () {},
          hasPreviousChapter: hasPrevious,
          hasNextChapter: hasNext,
        ),
      ),
    ),
  );

  testWidgets('renders blocks in exact order without changing Unicode', (
    tester,
  ) async {
    const texts = ['Olá, coração 👩🏽‍🚀', '第二段 — “inalterado”'];
    await pumpReader(tester, chapter: chapter(texts));

    expect(find.text(texts[0]), findsOneWidget);
    expect(find.text(texts[1]), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(texts[0])).dy,
      lessThan(tester.getTopLeft(find.text(texts[1])).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes and updates the selected block', (tester) async {
    String? selected;
    await pumpReader(
      tester,
      chapter: chapter(const ['Um', 'Dois']),
      selectedBlockId: 'block-1',
      onSelected: (value) => selected = value,
    );

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('reader-block-block-1')),
    );
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);

    tester
        .widget<InkWell>(find.byKey(const ValueKey('reader-block-block-0')))
        .onTap!();
    expect(selected, 'block-0');
  });

  testWidgets('shows the exact empty-state message', (tester) async {
    await pumpReader(tester, chapter: chapter(const []));
    expect(find.text('Este capítulo não possui texto'), findsOneWidget);
  });

  testWidgets('invokes enabled chapter navigation and disables boundaries', (
    tester,
  ) async {
    var previous = 0;
    var next = 0;
    await pumpReader(
      tester,
      chapter: chapter(const ['Texto']),
      onPrevious: () => previous++,
      onNext: () => next++,
    );
    await tester.tap(find.text('Capítulo anterior'));
    await tester.tap(find.text('Próximo capítulo'));
    expect((previous, next), (1, 1));

    await pumpReader(
      tester,
      chapter: chapter(const ['Texto']),
      hasPrevious: false,
      hasNext: false,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Capítulo anterior'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Próximo capítulo'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('builds a large chapter lazily without horizontal overflow', (
    tester,
  ) async {
    final texts = List.generate(
      1000,
      (index) => 'Bloco $index ${'palavra ' * 20}',
    );
    await pumpReader(tester, chapter: chapter(texts));

    expect(find.text(texts.first), findsOneWidget);
    expect(find.text(texts.last), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
