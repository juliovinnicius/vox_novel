import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_cubit.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_state.dart';

void main() {
  test(
    'load emits exact loading then ready defaults at first content',
    () async {
      final repository = _Repository(content: _content());
      final cubit = _cubit(repository);
      final states = <VisualReaderState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load('book');
      await Future<void>.delayed(Duration.zero);

      expect(states.map((state) => state.status), [
        VisualReaderStatus.loading,
        VisualReaderStatus.ready,
      ]);
      expect(
        [
          cubit.state.mode,
          cubit.state.chapterId,
          cubit.state.blockId,
          cubit.state.pdfPage,
          cubit.state.settings,
        ],
        [ReaderMode.text, 'chapter', 'block', 1, ReaderSettings.defaults()],
      );
      await subscription.cancel();
      await cubit.close();
    },
  );

  test('valid saved position and settings restore exact values', () async {
    final settings = ReaderSettings(
      theme: ReaderTheme.dark,
      fontFamily: ReaderFontFamily.serif,
      fontSize: 24,
      lineHeight: 1.8,
    );
    final repository = _Repository(
      content: _content(),
      settings: settings,
      position: _position(mode: ReaderMode.pdf, page: 2),
    );
    final cubit = _cubit(repository);

    await cubit.load('book');

    expect(
      [cubit.state.mode, cubit.state.pdfPage, cubit.state.settings],
      [ReaderMode.pdf, 2, settings],
    );
    expect(repository.savedPositions, isEmpty);
    await cubit.close();
  });

  test('missing and load failure expose exact unavailable state', () async {
    for (final repository in [
      _Repository(),
      _Repository(contentError: StateError('sql')),
    ]) {
      final cubit = _cubit(repository);
      await cubit.load('book');
      expect(
        [cubit.state.status, cubit.state.message, cubit.state.content],
        [
          VisualReaderStatus.unavailable,
          'Conteúdo do livro indisponível',
          null,
        ],
      );
      await cubit.close();
    }
  });

  test('stale identity and out-of-range page repair and persist', () async {
    final repository = _Repository(
      content: _content(),
      position: ReaderPosition(
        bookId: 'book',
        mode: ReaderMode.pdf,
        chapterId: 'stale',
        blockId: 'foreign',
        pdfPage: 99,
        updatedAt: DateTime.utc(2025),
      ),
    );
    final cubit = _cubit(repository);

    await cubit.load('book');

    expect(
      [
        cubit.state.mode,
        cubit.state.chapterId,
        cubit.state.blockId,
        cubit.state.pdfPage,
      ],
      [ReaderMode.text, 'chapter', 'block', 1],
    );
    expect(repository.savedPositions, hasLength(1));
    expect(repository.savedPositions.single.chapterId, 'chapter');
    expect(repository.savedPositions.single.blockId, 'block');
    await cubit.close();
  });

  test('late load cannot overwrite a newer book request', () async {
    final first = Completer<ReaderBookContent?>();
    final repository = _Repository(content: _content(), firstContent: first);
    final cubit = _cubit(repository);

    unawaited(cubit.load('old'));
    await Future<void>.delayed(Duration.zero);
    await cubit.load('book');
    first.complete(_content(id: 'old'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.content?.book.id, 'book');
    expect(cubit.state.status, VisualReaderStatus.ready);
    await cubit.close();
  });

  test(
    'block chapter and adjacent navigation persist exact positions',
    () async {
      final repository = _Repository(content: _navigationContent());
      final cubit = _cubit(repository);
      await cubit.load('book');

      cubit.selectBlock('first', 'second-block');
      cubit.nextChapter();
      expect([cubit.state.chapterId, cubit.state.blockId], ['empty', null]);
      cubit.nextChapter();
      expect([cubit.state.chapterId, cubit.state.blockId], ['empty', null]);
      cubit.previousChapter();
      await Future<void>.delayed(Duration.zero);

      expect(
        [cubit.state.chapterId, cubit.state.blockId],
        ['first', 'first-block'],
      );
      expect(
        repository.savedPositions.map(
          (position) => [position.chapterId, position.blockId],
        ),
        [
          ['first', 'second-block'],
          ['empty', null],
          ['first', 'first-block'],
        ],
      );
      await cubit.close();
    },
  );

  test(
    'text PDF mapping and page clamp persist full related position',
    () async {
      final repository = _Repository(content: _navigationContent());
      final cubit = _cubit(repository);
      await cubit.load('book');
      cubit.selectBlock('first', 'second-block');

      cubit.showPdf();
      expect([cubit.state.mode, cubit.state.pdfPage], [ReaderMode.pdf, 2]);
      cubit.pageChanged(99);
      expect(cubit.state.pdfPage, 3);
      cubit.showText();
      await Future<void>.delayed(Duration.zero);

      expect(
        [cubit.state.mode, cubit.state.chapterId, cubit.state.blockId],
        [ReaderMode.text, 'empty', null],
      );
      final saved = repository.savedPositions.last;
      expect(
        [
          saved.bookId,
          saved.mode,
          saved.chapterId,
          saved.blockId,
          saved.pdfPage,
        ],
        ['book', ReaderMode.text, 'empty', null, 3],
      );
      await cubit.close();
    },
  );

  test('foreign and repeated selections are idempotent', () async {
    final repository = _Repository(content: _navigationContent());
    final cubit = _cubit(repository);
    await cubit.load('book');

    cubit.selectBlock('foreign', 'first-block');
    cubit.selectBlock('first', 'foreign');
    cubit.selectBlock('first', 'first-block');
    cubit.selectChapter('first');
    await Future<void>.delayed(Duration.zero);

    expect(
      [cubit.state.chapterId, cubit.state.blockId],
      ['first', 'first-block'],
    );
    expect(repository.savedPositions, isEmpty);
    await cubit.close();
  });

  test(
    'state changes remain readable while position save is pending',
    () async {
      final pending = Completer<void>();
      final repository = _Repository(
        content: _navigationContent(),
        savePositionPending: pending,
      );
      final cubit = _cubit(repository);
      await cubit.load('book');

      cubit.selectBlock('first', 'second-block');

      expect(cubit.state.blockId, 'second-block');
      expect(cubit.state.status, VisualReaderStatus.ready);
      pending.complete();
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
    },
  );

  test(
    'settings persist complete bounded values and repeated values are no-op',
    () async {
      final repository = _Repository(content: _content());
      final cubit = _cubit(repository);
      await cubit.load('book');
      cubit.setTheme(ReaderTheme.sepia);
      cubit.setFontFamily(ReaderFontFamily.serif);
      cubit.setLineHeight(2);
      for (var step = 0; step < 10; step++) {
        cubit.increaseFont();
      }
      cubit.increaseFont();
      cubit.setTheme(ReaderTheme.sepia);
      await Future<void>.delayed(Duration.zero);

      expect(
        [
          cubit.state.settings?.theme,
          cubit.state.settings?.fontFamily,
          cubit.state.settings?.fontSize,
          cubit.state.settings?.lineHeight,
        ],
        [ReaderTheme.sepia, ReaderFontFamily.serif, 32, 2.0],
      );
      await cubit.close();
      final saved = repository.savedSettings.last;
      expect(
        [saved.theme, saved.fontFamily, saved.fontSize, saved.lineHeight],
        [ReaderTheme.sepia, ReaderFontFamily.serif, 32, 2.0],
      );
    },
  );

  test(
    'write failures retain state show exact messages and later continue',
    () async {
      final repository = _Repository(
        content: _navigationContent(),
        failNextPosition: true,
        failNextSettings: true,
      );
      final cubit = _cubit(repository);
      await cubit.load('book');
      cubit.selectBlock('first', 'second-block');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.message, 'Não foi possível salvar sua posição');
      expect(cubit.state.blockId, 'second-block');
      cubit.clearMessage();
      cubit.setTheme(ReaderTheme.dark);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.message, 'Não foi possível salvar suas configurações');
      expect(cubit.state.settings?.theme, ReaderTheme.dark);
      cubit.clearMessage();
      cubit.selectBlock('first', 'first-block');
      await cubit.close();
      expect(repository.savedPositions.last.blockId, 'first-block');
    },
  );

  test('close awaits ordered pending position and settings writes', () async {
    final positionPending = Completer<void>();
    final settingsPending = Completer<void>();
    final repository = _Repository(
      content: _navigationContent(),
      savePositionPending: positionPending,
      saveSettingsPending: settingsPending,
    );
    final cubit = _cubit(repository);
    await cubit.load('book');
    cubit.selectBlock('first', 'second-block');
    cubit.setTheme(ReaderTheme.dark);
    var closed = false;
    final close = cubit.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    positionPending.complete();
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    settingsPending.complete();
    await close;
    expect(closed, isTrue);
  });
}

VisualReaderCubit _cubit(_Repository repository) =>
    VisualReaderCubit(repository: repository, clock: () => DateTime.utc(2026));

ReaderPosition _position({ReaderMode mode = ReaderMode.text, int page = 1}) =>
    ReaderPosition(
      bookId: 'book',
      mode: mode,
      chapterId: 'chapter',
      blockId: 'block',
      pdfPage: page,
      updatedAt: DateTime.utc(2026),
    );

ReaderBookContent _content({String id = 'book'}) => ReaderBookContent(
  book: Book(
    id: id,
    title: 'Book',
    originalFileName: 'book.pdf',
    storedFilePath: '/book.pdf',
    fileHash: id,
    status: BookStatus.ready,
    processingProgress: 1,
    pageCount: 2,
    chapterCount: 1,
    blockCount: 1,
    activeContentRunId: 'run',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  chapters: [
    ReaderChapter(
      chapter: ChapterDraft(
        id: 'chapter',
        title: 'Chapter',
        sortOrder: 0,
        startPage: 1,
        endPage: 2,
        cleanText: 'Text',
      ),
      blocks: [
        NarrationBlockDraft(
          id: 'block',
          chapterId: 'chapter',
          sortOrder: 0,
          originalText: 'Text',
          normalizedText: 'Text',
          characterCount: 4,
          startPage: 1,
          endPage: 2,
        ),
      ],
    ),
  ],
);

ReaderBookContent _navigationContent() => ReaderBookContent(
  book: Book(
    id: 'book',
    title: 'Book',
    originalFileName: 'book.pdf',
    storedFilePath: '/book.pdf',
    fileHash: 'book',
    status: BookStatus.ready,
    processingProgress: 1,
    pageCount: 3,
    chapterCount: 2,
    blockCount: 2,
    activeContentRunId: 'run',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  ),
  chapters: [
    ReaderChapter(
      chapter: ChapterDraft(
        id: 'first',
        title: 'First',
        sortOrder: 0,
        startPage: 1,
        endPage: 2,
        cleanText: 'First\n\nSecond',
      ),
      blocks: [
        NarrationBlockDraft(
          id: 'first-block',
          chapterId: 'first',
          sortOrder: 0,
          originalText: 'First',
          normalizedText: 'First',
          characterCount: 5,
          startPage: 1,
          endPage: 1,
        ),
        NarrationBlockDraft(
          id: 'second-block',
          chapterId: 'first',
          sortOrder: 1,
          originalText: 'Second',
          normalizedText: 'Second',
          characterCount: 6,
          startPage: 2,
          endPage: 2,
        ),
      ],
    ),
    ReaderChapter(
      chapter: ChapterDraft(
        id: 'empty',
        title: 'Empty',
        sortOrder: 1,
        startPage: 3,
        endPage: 3,
        cleanText: '',
      ),
      blocks: const [],
    ),
  ],
);

final class _Repository implements VisualReaderRepository {
  _Repository({
    this.content,
    this.settings,
    this.position,
    this.contentError,
    this.firstContent,
    this.savePositionPending,
    this.saveSettingsPending,
    this.failNextPosition = false,
    this.failNextSettings = false,
  });
  final ReaderBookContent? content;
  final ReaderSettings? settings;
  final ReaderPosition? position;
  final Object? contentError;
  final Completer<ReaderBookContent?>? firstContent;
  final Completer<void>? savePositionPending;
  final Completer<void>? saveSettingsPending;
  final savedPositions = <ReaderPosition>[];
  final savedSettings = <ReaderSettings>[];
  bool failNextPosition;
  bool failNextSettings;
  var loads = 0;

  @override
  Future<ReaderBookContent?> loadContent(String bookId) {
    if (contentError != null) return Future.error(contentError!);
    if (loads++ == 0 && firstContent != null) return firstContent!.future;
    return Future.value(content);
  }

  @override
  Future<ReaderPosition?> loadPosition(String bookId) async => position;
  @override
  Future<ReaderSettings> loadSettings() async =>
      settings ?? ReaderSettings.defaults();
  @override
  Future<void> savePosition(ReaderPosition position) async {
    savedPositions.add(position);
    if (failNextPosition) {
      failNextPosition = false;
      throw StateError('position');
    }
    await savePositionPending?.future;
  }

  @override
  Future<void> saveSettings(ReaderSettings settings) async {
    savedSettings.add(settings);
    if (failNextSettings) {
      failNextSettings = false;
      throw StateError('settings');
    }
    await saveSettingsPending?.future;
  }
}
