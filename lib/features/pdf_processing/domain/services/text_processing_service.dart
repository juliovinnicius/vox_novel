import 'dart:async';

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

typedef ChapterDetectorFactory = ChapterDetector Function();
typedef NarrationBlockSplitterFactory = NarrationBlockSplitter Function();
typedef ProcessingClock = DateTime Function();
typedef ProcessingRunId = String Function();

final class TextProcessingService {
  TextProcessingService({
    required BookRepository books,
    required TextProcessingRepository processing,
    required PdfTextExtractor extractor,
    required TextCleaner cleaner,
    required ChapterDetectorFactory chapterDetector,
    required NarrationBlockSplitterFactory blockSplitter,
    required ProcessingClock clock,
    required ProcessingRunId runId,
  }) :
       // Public dependency names intentionally omit private implementation
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
       _chapterDetector = chapterDetector,
       // ignore: prefer_initializing_formals
       _blockSplitter = blockSplitter,
       // ignore: prefer_initializing_formals
       _clock = clock,
       // ignore: prefer_initializing_formals
       _runId = runId;

  static Future<void> _globalTail = Future.value();

  final BookRepository _books;
  final TextProcessingRepository _processing;
  final PdfTextExtractor _extractor;
  final TextCleaner _cleaner;
  final ChapterDetectorFactory _chapterDetector;
  final NarrationBlockSplitterFactory _blockSplitter;
  final ProcessingClock _clock;
  final ProcessingRunId _runId;
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
      final profile = _cleaner.profile(rawPages);
      await _progress(bookId, ProcessingStage.cleaning, .40);
      final cleanPages = <CleanPage>[];
      for (var i = 0; i < rawPages.length; i++) {
        _check(cancellation);
        final clean = _cleaner.clean(rawPages[i], profile);
        await _processing.stageCleanPage(runId, clean);
        cleanPages.add(clean);
        await _progress(
          bookId,
          ProcessingStage.cleaning,
          .40 + .20 * (i + 1) / rawPages.length,
        );
      }

      final detector = _chapterDetector();
      for (var i = 0; i < cleanPages.length; i++) {
        _check(cancellation);
        detector.addPage(cleanPages[i]);
        await _progress(
          bookId,
          ProcessingStage.detectingChapters,
          .60 + .15 * (i + 1) / cleanPages.length,
        );
      }
      final chapters = detector.finish(book.title);
      final splitter = _blockSplitter();
      final blocks = <NarrationBlockDraft>[];
      if (chapters.isEmpty) {
        await _progress(bookId, ProcessingStage.buildingBlocks, .95);
      } else {
        for (var i = 0; i < chapters.length; i++) {
          _check(cancellation);
          final chapterBlocks = splitter.split(chapters[i]).toList();
          if (chapterBlocks.isEmpty) {
            await _progress(
              bookId,
              ProcessingStage.buildingBlocks,
              .75 + .20 * (i + 1) / chapters.length,
            );
          } else {
            for (var blockIndex = 0;
                blockIndex < chapterBlocks.length;
                blockIndex++) {
              _check(cancellation);
              blocks.add(chapterBlocks[blockIndex]);
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
}

final class _Cancellation {
  bool requested = false;
  String? runId;
}

final class _ProcessingCancelled implements Exception {
  const _ProcessingCancelled();
}
