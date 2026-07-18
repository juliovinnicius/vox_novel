import 'dart:async';
import 'dart:isolate';

import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/chapter_detector.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/narration_block_splitter.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';

enum ProcessingOutcome { completed, cancelled, unsupported, failed }

final class ProcessingResult {
  const ProcessingResult._(this.outcome, this.message);
  const ProcessingResult.completed()
    : this._(ProcessingOutcome.completed, null);
  const ProcessingResult.cancelled()
    : this._(ProcessingOutcome.cancelled, null);
  const ProcessingResult.unsupported(String message)
    : this._(ProcessingOutcome.unsupported, message);
  const ProcessingResult.failed(String message)
    : this._(ProcessingOutcome.failed, message);

  final ProcessingOutcome outcome;
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is ProcessingResult &&
      other.outcome == outcome &&
      other.message == message;
  @override
  int get hashCode => Object.hash(outcome, message);
}

typedef ProcessingClock = DateTime Function();
typedef ProcessingRunId = String Function();
typedef ProcessingExecutor =
    Future<T> Function<T>(FutureOr<T> Function() computation);

final class TextProcessingService {
  TextProcessingService({
    required BookRepository books,
    required TextProcessingRepository processing,
    required PdfTextExtractor extractor,
    required TextCleaner cleaner,
    required ProcessingIdGenerator chapterId,
    required ProcessingIdGenerator blockId,
    required ProcessingClock clock,
    required ProcessingRunId runId,
    ProcessingExecutor executor = inlineProcessingExecutor,
    void Function(int workerIdentity)? onCpuWorkerIsolate,
  }) : // Public dependency names intentionally omit private implementation
       // prefixes while preserving named constructor injection.
       // ignore: prefer_initializing_formals
       _books = books,
       // ignore: prefer_initializing_formals
       _processing = processing,
       // ignore: prefer_initializing_formals
       _extractor = extractor,
       // ignore: prefer_initializing_formals
       _cleaner = cleaner,
       // ignore: prefer_initializing_formals
       _chapterId = chapterId,
       // ignore: prefer_initializing_formals
       _blockId = blockId,
       // ignore: prefer_initializing_formals
       _clock = clock,
       // ignore: prefer_initializing_formals
       _runId = runId,
       // Public dependency names intentionally omit private implementation
       // prefixes while preserving named constructor injection.
       // ignore: prefer_initializing_formals
       _executor = executor,
       // ignore: prefer_initializing_formals
       _onCpuWorkerIsolate = onCpuWorkerIsolate;

  static Future<void> _globalTail = Future.value();

  final BookRepository _books;
  final TextProcessingRepository _processing;
  final PdfTextExtractor _extractor;
  final TextCleaner _cleaner;
  final ProcessingIdGenerator _chapterId;
  final ProcessingIdGenerator _blockId;
  final ProcessingClock _clock;
  final ProcessingRunId _runId;
  final ProcessingExecutor _executor;
  final void Function(int workerIdentity)? _onCpuWorkerIsolate;
  final Map<String, Future<ProcessingResult>> _runs = {};
  final Map<String, _Cancellation> _cancellations = {};
  final Map<String, ProcessingResult> _lastResults = {};
  bool _closed = false;

  Future<ProcessingResult> process(String bookId) {
    final existing = _runs[bookId];
    if (existing != null) return existing;
    if (_closed) return Future.value(const ProcessingResult.cancelled());
    final cancellation = _Cancellation();
    _cancellations[bookId] = cancellation;
    final future = _serialized(() => _run(bookId, cancellation)).whenComplete(
      () {
        _runs.remove(bookId);
        _cancellations.remove(bookId);
      },
    );
    _runs[bookId] = future;
    return future;
  }

  Future<ProcessingResult> cancel(String bookId) async {
    final running = _runs[bookId];
    if (running == null) {
      return _lastResults[bookId] ?? const ProcessingResult.cancelled();
    }
    final cancellation = _cancellations[bookId]!..requested = true;
    final runId = cancellation.runId;
    if (runId != null) await _extractor.cancel(runId);
    return running;
  }

  Future<void> close() async {
    _closed = true;
    final books = _runs.keys.toList(growable: false);
    await Future.wait([for (final bookId in books) cancel(bookId)]);
  }

  Future<ProcessingResult> _serialized(
    Future<ProcessingResult> Function() action,
  ) {
    final previous = _globalTail;
    final released = Completer<void>();
    _globalTail = released.future;
    return previous.then((_) => action()).whenComplete(released.complete);
  }

  Future<ProcessingResult> _run(
    String bookId,
    _Cancellation cancellation,
  ) async {
    final runId = _runId();
    cancellation.runId = runId;
    var runCreated = false;
    try {
      final book = await _books.findById(bookId);
      if (book == null) throw StateError('Book not found');
      await _processing.createRun(
        bookId: bookId,
        runId: runId,
        startedAt: _clock(),
      );
      runCreated = true;
      _check(cancellation);

      var pageCount = 0;
      var extractedCharacters = 0;
      await for (final event in _extractor.extract(
        PdfExtractionRequest(runId: runId, filePath: book.storedFilePath),
      )) {
        _check(cancellation);
        switch (event) {
          case PdfExtractionOpened():
            pageCount = event.pageCount;
          case PdfExtractionPage():
            await _processing.stageRawPage(
              runId,
              RawPage(pageNumber: event.pageNumber, text: event.text),
            );
            extractedCharacters += event.text.trim().runes.length;
            await _progress(
              bookId,
              ProcessingStage.extracting,
              pageCount == 0 ? 0 : .40 * event.pageNumber / pageCount,
            );
          case PdfExtractionCompleted():
            pageCount = event.pageCount;
          case PdfExtractionFailed():
            throw StateError('PDF extraction failed');
        }
      }
      _check(cancellation);
      if (extractedCharacters == 0) {
        const result = ProcessingResult.unsupported(
          'Este PDF não possui texto extraível',
        );
        await _processing.discardRun(
          runId: runId,
          terminalStatus: BookStatus.unsupported,
          updatedAt: _clock(),
        );
        _lastResults[bookId] = result;
        return result;
      }

      final rawPages = await _processing.streamRawPages(runId).toList();
      final cleaner = _cleaner;
      final profile = await _cpu(() => cleaner.profile(rawPages));
      await _progress(bookId, ProcessingStage.cleaning, .40);
      final cleanPages = <CleanPage>[];
      for (var i = 0; i < rawPages.length; i++) {
        _check(cancellation);
        final page = rawPages[i];
        final clean = await _cpu(() => cleaner.clean(page, profile));
        await _processing.stageCleanPage(runId, clean);
        cleanPages.add(clean);
        await _progress(
          bookId,
          ProcessingStage.cleaning,
          .40 + .20 * (i + 1) / rawPages.length,
        );
      }

      for (var i = 0; i < cleanPages.length; i++) {
        _check(cancellation);
        await _progress(
          bookId,
          ProcessingStage.detectingChapters,
          .60 + .15 * (i + 1) / cleanPages.length,
        );
      }
      final detected = await _cpu(() {
        final detector = ChapterDetector(idGenerator: _workerId);
        for (final page in cleanPages) {
          detector.addPage(page);
        }
        return detector.finish(book.title);
      });
      final chapterIds = <String, String>{};
      final chapters = [
        for (final chapter in detected)
          ChapterDraft(
            id: chapterIds[chapter.id] = _chapterId(),
            title: chapter.title,
            sortOrder: chapter.sortOrder,
            startPage: chapter.startPage,
            endPage: chapter.endPage,
            cleanText: chapter.cleanText,
          ),
      ];
      final splitBlocks = await _cpu(() {
        final splitter = NarrationBlockSplitter(_workerId);
        return [for (final chapter in detected) ...splitter.split(chapter)];
      });
      final blocks = [
        for (final block in splitBlocks)
          NarrationBlockDraft(
            id: _blockId(),
            chapterId: chapterIds[block.chapterId]!,
            sortOrder: block.sortOrder,
            originalText: block.originalText,
            normalizedText: block.normalizedText,
            characterCount: block.characterCount,
            startPage: block.startPage,
            endPage: block.endPage,
          ),
      ];
      if (chapters.isEmpty) {
        await _progress(bookId, ProcessingStage.buildingBlocks, .95);
      } else {
        var blockOffset = 0;
        for (var i = 0; i < chapters.length; i++) {
          _check(cancellation);
          final chapterBlocks = blocks
              .where((block) => block.chapterId == chapters[i].id)
              .toList(growable: false);
          if (chapterBlocks.isEmpty) {
            await _progress(
              bookId,
              ProcessingStage.buildingBlocks,
              .75 + .20 * (i + 1) / chapters.length,
            );
          } else {
            for (
              var blockIndex = 0;
              blockIndex < chapterBlocks.length;
              blockIndex++
            ) {
              _check(cancellation);
              blockOffset++;
              final completedChapterFraction =
                  (i + (blockIndex + 1) / chapterBlocks.length) /
                  chapters.length;
              await _progress(
                bookId,
                ProcessingStage.buildingBlocks,
                .75 + .20 * completedChapterFraction,
              );
            }
          }
        }
        assert(blockOffset == blocks.length);
      }
      _check(cancellation);
      await _processing.stageChaptersAndBlocks(
        runId: runId,
        bookId: bookId,
        chapters: chapters,
        blocks: blocks,
        createdAt: _clock(),
      );
      await _progress(bookId, ProcessingStage.completing, .95);
      _check(cancellation);
      await _processing.activateRun(
        runId: runId,
        pageCount: pageCount,
        chapterCount: chapters.length,
        blockCount: blocks.length,
        completedAt: _clock(),
      );
      const result = ProcessingResult.completed();
      _lastResults[bookId] = result;
      return result;
    } on _ProcessingCancelled {
      if (runCreated) {
        await _processing.discardRun(
          runId: runId,
          terminalStatus: BookStatus.importing,
          updatedAt: _clock(),
        );
      }
      const result = ProcessingResult.cancelled();
      _lastResults[bookId] = result;
      return result;
    } catch (_) {
      if (runCreated) {
        await _processing.discardRun(
          runId: runId,
          terminalStatus: BookStatus.failed,
          updatedAt: _clock(),
        );
      }
      const result = ProcessingResult.failed(
        'Não foi possível processar este PDF',
      );
      _lastResults[bookId] = result;
      return result;
    }
  }

  Future<void> _progress(
    String bookId,
    ProcessingStage stage,
    double progress,
  ) {
    final exactProgress = double.parse(progress.toStringAsFixed(6));
    return _processing.updateProgress(
      bookId: bookId,
      stage: stage,
      progress: exactProgress,
      updatedAt: _clock(),
    );
  }

  void _check(_Cancellation cancellation) {
    if (cancellation.requested) throw const _ProcessingCancelled();
  }

  Future<T> _cpu<T>(FutureOr<T> Function() computation) async {
    final result = await _executor(
      () => (workerIdentity: Isolate.current.hashCode, value: computation()),
    );
    _onCpuWorkerIsolate?.call(result.workerIdentity);
    return await result.value;
  }
}

Future<T> isolateProcessingExecutor<T>(FutureOr<T> Function() computation) =>
    Isolate.run(computation);

Future<T> inlineProcessingExecutor<T>(
  FutureOr<T> Function() computation,
) async => await computation();

var _workerIdSequence = 0;
String _workerId() => 'worker-${_workerIdSequence++}';

final class _Cancellation {
  bool requested = false;
  String? runId;
}

final class _ProcessingCancelled implements Exception {
  const _ProcessingCancelled();
}
