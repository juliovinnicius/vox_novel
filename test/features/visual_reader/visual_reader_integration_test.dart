import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart'
    hide Book, RawPage, ReaderPosition;
import 'package:vox_novel/features/library/data/repositories/drift_book_repository.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/data/repositories/drift_text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/data/repositories/drift_visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_cubit.dart';

void main() {
  late Directory root;
  late File databaseFile;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vox_reader_integration_');
    databaseFile = File('${root.path}/reader.sqlite');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'file-backed flow restores navigation and settings then cascades only book state',
    () async {
      var database = AppDatabase(NativeDatabase(databaseFile));
      await _seedReadyBook(database);
      var books = DriftBookRepository(database);
      var repository = DriftVisualReaderRepository(database);
      var cubit = _cubit(repository);

      await cubit.load('book-id');
      expect(cubit.state.chapterId, 'chapter-1');
      expect(cubit.state.blockId, 'block-1');
      cubit.selectChapter('chapter-2');
      cubit.showPdf();
      cubit.setTheme(ReaderTheme.dark);
      cubit.setFontFamily(ReaderFontFamily.serif);
      cubit.increaseFont();
      cubit.setLineHeight(1.8);
      await cubit.close();
      await database.close();

      database = AppDatabase(NativeDatabase(databaseFile));
      books = DriftBookRepository(database);
      repository = DriftVisualReaderRepository(database);
      cubit = _cubit(repository);
      await cubit.load('book-id');

      expect(cubit.state.mode, ReaderMode.pdf);
      expect(cubit.state.chapterId, 'chapter-2');
      expect(cubit.state.blockId, 'block-2');
      expect(cubit.state.pdfPage, 2);
      expect(
        cubit.state.settings,
        ReaderSettings(
          theme: ReaderTheme.dark,
          fontFamily: ReaderFontFamily.serif,
          fontSize: 20,
          lineHeight: 1.8,
        ),
      );
      await cubit.close();

      await books.deleteById('book-id');
      expect(await repository.loadContent('book-id'), isNull);
      expect(await repository.loadPosition('book-id'), isNull);
      expect(
        await repository.loadSettings(),
        ReaderSettings(
          theme: ReaderTheme.dark,
          fontFamily: ReaderFontFamily.serif,
          fontSize: 20,
          lineHeight: 1.8,
        ),
      );
      expect(await database.select(database.processingRuns).get(), isEmpty);
      expect(await database.select(database.chapters).get(), isEmpty);
      expect(await database.select(database.narrationBlocks).get(), isEmpty);
      await database.close();
    },
  );

  test('stale durable identities repair to source-order content', () async {
    final database = AppDatabase(NativeDatabase(databaseFile));
    await _seedReadyBook(database);
    final repository = DriftVisualReaderRepository(database);
    await repository.savePosition(
      ReaderPosition(
        bookId: 'book-id',
        mode: ReaderMode.text,
        chapterId: 'removed-chapter',
        blockId: 'removed-block',
        pdfPage: 99,
        updatedAt: DateTime.utc(2025),
      ),
    );

    final cubit = _cubit(repository);
    await cubit.load('book-id');
    expect(cubit.state.chapterId, 'chapter-1');
    expect(cubit.state.blockId, 'block-1');
    await cubit.close();

    final repaired = await repository.loadPosition('book-id');
    expect(repaired?.chapterId, 'chapter-1');
    expect(repaired?.blockId, 'block-1');
    expect(repaired?.pdfPage, 1);
    await database.close();
  });

  test(
    'write failure keeps readable state and later navigation continues',
    () async {
      final database = AppDatabase(NativeDatabase(databaseFile));
      await _seedReadyBook(database);
      final durable = DriftVisualReaderRepository(database);
      final repository = _ControlledRepository(durable, failures: 1);
      final cubit = _cubit(repository);
      await cubit.load('book-id');

      cubit.nextChapter();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.chapterId, 'chapter-2');
      expect(cubit.state.message, 'Não foi possível salvar sua posição');
      cubit.previousChapter();
      await cubit.close();

      expect((await durable.loadPosition('book-id'))?.chapterId, 'chapter-1');
      await database.close();
    },
  );

  test('close waits for the pending latest position before restart', () async {
    var database = AppDatabase(NativeDatabase(databaseFile));
    await _seedReadyBook(database);
    var durable = DriftVisualReaderRepository(database);
    final gate = Completer<void>();
    final repository = _ControlledRepository(durable, gate: gate);
    final cubit = _cubit(repository);
    await cubit.load('book-id');
    cubit.nextChapter();

    var closed = false;
    final closing = cubit.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    gate.complete();
    await closing;
    await database.close();

    database = AppDatabase(NativeDatabase(databaseFile));
    durable = DriftVisualReaderRepository(database);
    expect((await durable.loadPosition('book-id'))?.chapterId, 'chapter-2');
    await database.close();
  });
}

VisualReaderCubit _cubit(VisualReaderRepository repository) =>
    VisualReaderCubit(repository: repository, clock: () => DateTime.utc(2026));

Future<void> _seedReadyBook(AppDatabase database) async {
  final now = DateTime.utc(2026);
  await DriftBookRepository(database).insert(
    Book(
      id: 'book-id',
      title: 'Livro',
      originalFileName: 'livro.pdf',
      storedFilePath: '/books/livro.pdf',
      fileHash: 'hash',
      status: BookStatus.importing,
      processingProgress: 0,
      createdAt: now,
      updatedAt: now,
    ),
  );
  final processing = DriftTextProcessingRepository(database);
  await processing.createRun(
    bookId: 'book-id',
    runId: 'run-id',
    startedAt: now,
  );
  await processing.stageRawPage(
    'run-id',
    RawPage(pageNumber: 1, text: 'Texto um'),
  );
  await processing.stageRawPage(
    'run-id',
    RawPage(pageNumber: 2, text: 'Texto dois'),
  );
  await processing.stageCleanPage(
    'run-id',
    CleanPage(pageNumber: 1, text: 'Texto um'),
  );
  await processing.stageCleanPage(
    'run-id',
    CleanPage(pageNumber: 2, text: 'Texto dois'),
  );
  final chapters = [
    ChapterDraft(
      id: 'chapter-1',
      title: 'Primeiro',
      sortOrder: 0,
      startPage: 1,
      endPage: 1,
      cleanText: 'Texto um',
    ),
    ChapterDraft(
      id: 'chapter-2',
      title: 'Segundo',
      sortOrder: 1,
      startPage: 2,
      endPage: 2,
      cleanText: 'Texto dois',
    ),
  ];
  final blocks = [
    NarrationBlockDraft(
      id: 'block-1',
      chapterId: 'chapter-1',
      sortOrder: 0,
      originalText: 'Texto um',
      normalizedText: 'Texto um',
      characterCount: 'Texto um'.runes.length,
      startPage: 1,
      endPage: 1,
    ),
    NarrationBlockDraft(
      id: 'block-1-last',
      chapterId: 'chapter-1',
      sortOrder: 1,
      originalText: 'Último texto um',
      normalizedText: 'Último texto um',
      characterCount: 'Último texto um'.runes.length,
      startPage: 1,
      endPage: 1,
    ),
    NarrationBlockDraft(
      id: 'block-2',
      chapterId: 'chapter-2',
      sortOrder: 0,
      originalText: 'Texto dois',
      normalizedText: 'Texto dois',
      characterCount: 'Texto dois'.runes.length,
      startPage: 2,
      endPage: 2,
    ),
  ];
  await processing.stageChaptersAndBlocks(
    runId: 'run-id',
    bookId: 'book-id',
    chapters: chapters,
    blocks: blocks,
    createdAt: now,
  );
  await processing.activateRun(
    runId: 'run-id',
    pageCount: 2,
    chapterCount: 2,
    blockCount: 3,
    completedAt: now,
  );
}

final class _ControlledRepository implements VisualReaderRepository {
  _ControlledRepository(this.delegate, {this.failures = 0, this.gate});

  final VisualReaderRepository delegate;
  int failures;
  final Completer<void>? gate;

  @override
  Future<ReaderBookContent?> loadContent(String bookId) =>
      delegate.loadContent(bookId);
  @override
  Future<ReaderPosition?> loadPosition(String bookId) =>
      delegate.loadPosition(bookId);
  @override
  Future<ReaderSettings> loadSettings() => delegate.loadSettings();
  @override
  Future<void> saveSettings(ReaderSettings settings) =>
      delegate.saveSettings(settings);

  @override
  Future<void> savePosition(ReaderPosition position) async {
    if (failures > 0) {
      failures--;
      throw StateError('injected write failure');
    }
    await gate?.future;
    await delegate.savePosition(position);
  }
}
