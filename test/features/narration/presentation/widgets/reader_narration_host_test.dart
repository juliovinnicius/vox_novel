import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';
import 'package:vox_novel/features/narration/domain/services/narration_engine.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/narration/presentation/widgets/reader_narration_host.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

void main() {
  testWidgets('loads content and exposes the persistent player', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _pumpHost(tester, fixture);
    await tester.pumpAndSettle();

    expect(fixture.cubit.state.status, NarrationStatus.ready);
    expect(find.text('Capítulo 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Reproduzir narração'), findsOneWidget);
  });

  testWidgets('playing focus is delivered to the visual reader in memory', (
    tester,
  ) async {
    final fixture = _Fixture();
    final focuses = <(String, String)>[];
    await _pumpHost(
      tester,
      fixture,
      onFocus: (chapterId, blockId) => focuses.add((chapterId, blockId)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Reproduzir narração'));
    await tester.pump();
    expect(fixture.cubit.state.status, NarrationStatus.playing);
    expect(focuses, [('chapter', 'block')]);
  });

  testWidgets('settings sheet forwards voice rate preview and scope actions', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _pumpHost(tester, fixture);
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel('Configurações de voz e velocidade'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Voz e velocidade'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Aumentar velocidade da narração'));
    await tester.pump();
    expect(fixture.cubit.state.settings!.rate, 1.1);
    await tester.tap(
      find.bySemanticsLabel('Usar ajustes de narração para este livro'),
    );
    await tester.pump();
    expect(fixture.cubit.state.usesBookOverride, isTrue);
  });

  for (final lifecycle in [
    AppLifecycleState.inactive,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    testWidgets('$lifecycle synchronously pauses and awaits exact stop/save', (
      tester,
    ) async {
      final fixture = _Fixture();
      await _pumpHost(tester, fixture);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Reproduzir narração'));
      await tester.pump();

      final observer =
          tester.state(find.byType(ReaderNarrationHost))
              as WidgetsBindingObserver;
      observer.didChangeAppLifecycleState(lifecycle);
      expect(fixture.cubit.state.status, NarrationStatus.paused);
      await tester.pump();
      expect(fixture.engine.stops, 1);
      expect(
        [
          fixture.repository.progress?.activeRunId,
          fixture.repository.progress?.chapterId,
          fixture.repository.progress?.blockId,
          fixture.repository.progress?.completed,
        ],
        ['run', 'chapter', 'block', false],
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(fixture.cubit.state.status, NarrationStatus.paused);
    });
  }
}

Future<void> _pumpHost(
  WidgetTester tester,
  _Fixture fixture, {
  void Function(String chapterId, String blockId)? onFocus,
  Future<void> Function(NarrationCubit cubit)? closeCubit,
}) => tester.pumpWidget(
  MaterialApp(
    home: ReaderNarrationHost(
      content: fixture.content,
      cubit: fixture.cubit,
      onNarrationFocus: onFocus ?? (_, _) {},
      closeCubit: closeCubit,
      builder: (context, playerBar) =>
          Scaffold(body: const Text('Leitor'), bottomNavigationBar: playerBar),
    ),
  ),
);

final class _Fixture {
  _Fixture()
    : repository = _Repository(),
      engine = _Engine(),
      content = _content() {
    cubit = NarrationCubit(
      repository: repository,
      engine: engine,
      clock: () => DateTime.utc(2025),
    );
  }

  final _Repository repository;
  final _Engine engine;
  final ReaderBookContent content;
  late final NarrationCubit cubit;
}

ReaderBookContent _content() {
  final chapter = ChapterDraft(
    id: 'chapter',
    title: 'Capítulo 1',
    sortOrder: 0,
    startPage: 1,
    endPage: 1,
    cleanText: 'Texto',
  );
  return ReaderBookContent(
    book: Book(
      id: 'book',
      title: 'Novel',
      originalFileName: 'novel.txt',
      storedFilePath: '/novel.txt',
      fileHash: 'hash',
      status: BookStatus.ready,
      processingProgress: 1,
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2025),
      pageCount: 1,
      chapterCount: 1,
      blockCount: 1,
      activeContentRunId: 'run',
    ),
    chapters: [
      ReaderChapter(
        chapter: chapter,
        blocks: [
          NarrationBlockDraft(
            id: 'block',
            chapterId: 'chapter',
            sortOrder: 0,
            originalText: 'Texto normalizado',
            normalizedText: 'Texto normalizado',
            characterCount: 'Texto normalizado'.runes.length,
            startPage: 1,
            endPage: 1,
          ),
        ],
      ),
    ],
  );
}

final class _Engine implements NarrationEngine {
  var stops = 0;
  final speech = Completer<void>();

  @override
  Future<List<NarrationVoice>> initialize() async => [
    NarrationVoice(name: 'Ana', locale: 'pt-BR'),
  ];

  @override
  Future<void> configure(NarrationVoice voice, double rate) async {}

  @override
  Future<void> speak(String text) => speech.future;

  @override
  Future<void> stop() async {
    stops++;
    if (!speech.isCompleted) speech.complete();
  }

  @override
  Future<void> close() async {}
}

final class _Repository implements NarrationRepository {
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
