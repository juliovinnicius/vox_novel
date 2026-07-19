import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_cubit.dart';
import 'package:vox_novel/features/visual_reader/presentation/pages/reader_page.dart';

void main() {
  ReaderBookContent content({bool empty = false}) {
    ReaderChapter chapter(String id, String title, int order, String text) {
      final draft = ChapterDraft(
        id: id,
        title: title,
        sortOrder: order,
        startPage: order + 1,
        endPage: order + 1,
        cleanText: text,
      );
      return ReaderChapter(
        chapter: draft,
        blocks: empty
            ? const []
            : [
                NarrationBlockDraft(
                  id: '$id-block',
                  chapterId: id,
                  sortOrder: 0,
                  originalText: text,
                  normalizedText: text,
                  characterCount: text.runes.length,
                  startPage: order + 1,
                  endPage: order + 1,
                ),
              ],
      );
    }

    return ReaderBookContent(
      book: Book(
        id: 'book',
        title: 'Minha Novel',
        originalFileName: 'novel.pdf',
        storedFilePath: '/books/novel.pdf',
        fileHash: 'hash',
        status: BookStatus.ready,
        processingProgress: 1,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        pageCount: 2,
        chapterCount: 2,
        blockCount: empty ? 0 : 2,
        activeContentRunId: 'run',
      ),
      chapters: [
        chapter('one', 'Primeiro', 0, 'Texto um'),
        chapter('two', 'Segundo', 1, 'Texto dois'),
      ],
    );
  }

  Future<VisualReaderCubit> pumpPage(
    WidgetTester tester,
    _Repository repository, {
    Size size = const Size(800, 600),
    NarrationCubit? narrationCubit,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = VisualReaderCubit(
      repository: repository,
      clock: () => DateTime(2025),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPage(
          bookId: 'book',
          cubit: cubit,
          narrationCubit: narrationCubit,
          pdfSurfaceBuilder: (spec) => const ColoredBox(color: Colors.grey),
        ),
      ),
    );
    return cubit;
  }

  testWidgets('shows exact loading and unavailable states', (tester) async {
    final completer = Completer<ReaderBookContent?>();
    final repository = _Repository(load: () => completer.future);
    await pumpPage(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Leitor'), findsOneWidget);

    completer.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Conteúdo do livro indisponível'), findsOneWidget);
    expect(find.text('Voltar à biblioteca'), findsOneWidget);
  });

  testWidgets('composes text, chapter drawer, settings, and PDF mode', (
    tester,
  ) async {
    final repository = _Repository(load: () async => content());
    final cubit = await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Minha Novel'), findsOneWidget);
    expect(find.text('Texto um'), findsOneWidget);
    await tester.tap(find.byTooltip('Capítulos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Segundo'));
    await tester.pumpAndSettle();
    expect(cubit.state.chapterId, 'two');
    expect(find.text('Texto dois'), findsOneWidget);

    await tester.tap(find.byTooltip('Configurações do leitor'));
    await tester.pumpAndSettle();
    expect(find.text('Aparência'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Tema escuro'));
    await tester.pump();
    expect(cubit.state.settings!.theme, ReaderTheme.dark);
    Navigator.of(tester.element(find.text('Aparência'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver PDF original'));
    await tester.pumpAndSettle();
    expect(cubit.state.mode, ReaderMode.pdf);
    expect(find.text('Página 2 de 2'), findsOneWidget);
    expect(find.byTooltip('Ver texto reformatado'), findsOneWidget);
  });

  testWidgets('renders exact empty chapter state', (tester) async {
    await pumpPage(tester, _Repository(load: () async => content(empty: true)));
    await tester.pumpAndSettle();
    expect(find.text('Este capítulo não possui texto'), findsOneWidget);
  });

  testWidgets('shows and clears a persistence message once', (tester) async {
    final repository = _Repository(
      load: () async => content(),
      failPosition: true,
    );
    final cubit = await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    cubit.nextChapter();
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível salvar sua posição'), findsOneWidget);
    expect(cubit.state.message, isNull);
  });

  testWidgets('rotation preserves reader-owned state', (tester) async {
    final repository = _Repository(load: () async => content());
    final cubit = await pumpPage(tester, repository);
    await tester.pumpAndSettle();
    cubit.nextChapter();
    cubit.setTheme(ReaderTheme.sepia);
    await tester.pump();

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    expect(cubit.state.chapterId, 'two');
    expect(cubit.state.settings!.theme, ReaderTheme.sepia);
    expect(find.text('Texto dois'), findsOneWidget);
  });

  testWidgets(
    'explicit tap sets play origin and narration focus does not save visual position',
    (tester) async {
      final repository = _Repository(load: () async => content());
      final narrationRepository = _NarrationRepository();
      final engine = _NarrationEngine();
      final narrationCubit = NarrationCubit(
        repository: narrationRepository,
        engine: engine,
        clock: () => DateTime.utc(2025),
      );
      final cubit = await pumpPage(
        tester,
        repository,
        narrationCubit: narrationCubit,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Capítulos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Segundo'));
      await tester.pumpAndSettle();
      tester
          .widget<InkWell>(find.byKey(const ValueKey('reader-block-two-block')))
          .onTap!();
      cubit.previousChapter();
      await tester.pump();
      final savesBeforePlay = repository.savedPositions.length;
      expect(cubit.state.chapterId, 'one');
      expect(narrationRepository.progress, isNull);

      await tester.tap(find.bySemanticsLabel('Reproduzir narração'));
      await tester.pump();
      expect(engine.spoken, ['Texto dois']);
      expect(cubit.state.chapterId, 'two');
      expect(cubit.state.blockId, 'two-block');
      expect(repository.savedPositions.length, savesBeforePlay);
    },
  );
}

final class _Repository implements VisualReaderRepository {
  _Repository({required this.load, this.failPosition = false});
  final Future<ReaderBookContent?> Function() load;
  final bool failPosition;
  final savedPositions = <ReaderPosition>[];

  @override
  Future<ReaderBookContent?> loadContent(String bookId) => load();
  @override
  Future<ReaderPosition?> loadPosition(String bookId) async => null;
  @override
  Future<ReaderSettings> loadSettings() async => ReaderSettings.defaults();
  @override
  Future<void> savePosition(ReaderPosition position) async {
    if (failPosition) throw StateError('failed');
    savedPositions.add(position);
  }

  @override
  Future<void> saveSettings(ReaderSettings settings) async {}
}

final class _NarrationEngine implements NarrationEngine {
  final spoken = <String>[];
  final pendingSpeech = Completer<void>();

  @override
  Future<List<NarrationVoice>> initialize() async => [
    NarrationVoice(name: 'Ana', locale: 'pt-BR'),
  ];
  @override
  Future<void> configure(NarrationVoice voice, double rate) async {}
  @override
  Future<void> speak(String text) {
    spoken.add(text);
    return pendingSpeech.future;
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> close() async {}
}

final class _NarrationRepository implements NarrationRepository {
  NarrationProgress? progress;
  var global = NarrationSettings.defaults();
  BookNarrationOverride? bookOverride;

  @override
  Future<NarrationSettings> loadGlobalSettings() async => global;
  @override
  Future<void> saveGlobalSettings(NarrationSettings settings) async {
    global = settings;
  }

  @override
  Future<BookNarrationOverride?> loadBookOverride(String bookId) async =>
      bookOverride;
  @override
  Future<void> saveBookOverride(BookNarrationOverride value) async {
    bookOverride = value;
  }

  @override
  Future<void> deleteBookOverride(String bookId) async {
    bookOverride = null;
  }

  @override
  Future<NarrationProgress?> loadProgress(String bookId) async => progress;
  @override
  Future<void> saveProgress(NarrationProgress value) async {
    progress = value;
  }
}
