import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';
import 'package:vox_novel/features/web_source/data/services/html_recipe_parser.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/site_recipe_registry.dart';
import 'package:vox_novel/features/web_source/domain/services/web_fetcher.dart';

enum WebDownloadOutcome { completed, cancelled, paused, unsupported, failed }

typedef WebDownloadClock = DateTime Function();
typedef WebDownloadRunId = String Function();

/// Drains a web book's chapter queue, one chapter at a time, into the shared
/// [ChapterIngest].
///
/// The book is activated at its **first** stored chapter instead of at the end
/// of the queue, so a long novel is readable and narratable while the rest
/// downloads. It deliberately stays outside `TextProcessingService`'s global
/// serialization so a long download never starves a PDF import (AD-009).
final class WebNovelDownloadService {
  WebNovelDownloadService({
    required BookRepository books,
    required WebSourceRepository source,
    required TextProcessingRepository processing,
    required ChapterIngest ingest,
    required WebFetcher fetcher,
    required SiteRecipeRegistry recipes,
    required WebDownloadClock clock,
    required WebDownloadRunId runId,
    HtmlRecipeParser parser = const HtmlRecipeParser(),
    TextCleaner cleaner = const TextCleaner(),
  }) : // Public dependency names intentionally omit private implementation
       // prefixes while preserving named constructor injection.
       // ignore: prefer_initializing_formals
       _books = books,
       // ignore: prefer_initializing_formals
       _source = source,
       // ignore: prefer_initializing_formals
       _processing = processing,
       // ignore: prefer_initializing_formals
       _ingest = ingest,
       // ignore: prefer_initializing_formals
       _fetcher = fetcher,
       // ignore: prefer_initializing_formals
       _recipes = recipes,
       // ignore: prefer_initializing_formals
       _clock = clock,
       // ignore: prefer_initializing_formals
       _runId = runId,
       // ignore: prefer_initializing_formals
       _parser = parser,
       // ignore: prefer_initializing_formals
       _cleaner = cleaner;

  final BookRepository _books;
  final WebSourceRepository _source;
  final TextProcessingRepository _processing;
  final ChapterIngest _ingest;
  final WebFetcher _fetcher;
  final SiteRecipeRegistry _recipes;
  final WebDownloadClock _clock;
  final WebDownloadRunId _runId;
  final HtmlRecipeParser _parser;
  final TextCleaner _cleaner;

  /// A web page has no repeated headers or footers to profile, so the shared
  /// cleaner runs with an empty profile: it still strips control characters,
  /// bare page numbers, and stray URLs, while the PDF-tuned edge heuristics
  /// stay inert and cannot discard a legitimate short line.
  static const HeaderFooterProfile _neutralProfile = HeaderFooterProfile(
    headers: <String>{},
    footers: <String>{},
  );

  /// Shown when a site's pages no longer match its recipe, so nothing in the
  /// book could be extracted.
  static const String unrecognizedLayoutMessage =
      'O layout do site não foi reconhecido';

  final Map<String, Future<WebDownloadOutcome>> _runs = {};
  final Map<String, _Cancellation> _cancellations = {};
  final Map<String, String> _messages = {};

  /// The message explaining [bookId]'s terminal outcome, when it has one.
  String? messageFor(String bookId) => _messages[bookId];

  /// Drains [bookId]'s queue, resuming from the first chapter with no stored
  /// text. Chapters already stored are never requested again.
  Future<WebDownloadOutcome> download(String bookId) {
    final running = _runs[bookId];
    if (running != null) {
      return running;
    }
    final cancellation = _Cancellation();
    _cancellations[bookId] = cancellation;
    final future = _drain(bookId, cancellation).whenComplete(() {
      _runs.remove(bookId);
      _cancellations.remove(bookId);
    });
    _runs[bookId] = future;
    return future;
  }

  /// Re-enqueues every web book whose queue still has chapters without stored
  /// text, so a download interrupted by an app restart continues. Returns the
  /// ids it enqueued.
  ///
  /// The drains are started, not awaited: the caller composes the app and must
  /// not block on the queue.
  Future<List<String>> resumePending() async {
    final library = await _books.watchAll().first;
    final resumed = <String>[];
    for (final book in library) {
      if (book.sourceType != BookSourceType.web ||
          book.status != BookStatus.processing) {
        continue;
      }
      if ((await _source.pending(book.id)).isEmpty) {
        continue;
      }
      resumed.add(book.id);
      download(book.id).ignore();
    }
    return resumed;
  }

  /// Stops issuing requests for [bookId], keeping every chapter already
  /// stored, and completes once the running pass has wound down.
  Future<void> cancel(String bookId) async {
    final running = _runs[bookId];
    if (running == null) {
      return;
    }
    _cancellations[bookId]!.requested = true;
    await running;
  }

  Future<WebDownloadOutcome> _drain(
    String bookId,
    _Cancellation cancellation,
  ) async {
    final book = await _books.findById(bookId);
    if (book == null) {
      return WebDownloadOutcome.failed;
    }

    final total = (await _source.counts(bookId)).total;
    final pending = await _source.pending(bookId);
    if (pending.isEmpty) {
      return WebDownloadOutcome.completed;
    }

    final runId = book.activeContentRunId ?? _runId();
    var activated = book.activeContentRunId != null;
    if (!activated) {
      await _processing.createRun(
        bookId: bookId,
        runId: runId,
        startedAt: _clock(),
        stage: ProcessingStage.downloading,
      );
    }

    var chapterCount = book.chapterCount;
    var blockCount = book.blockCount;
    var stored = total - pending.length;
    var extractionFailures = 0;
    var otherFailures = 0;

    for (final entry in pending) {
      if (cancellation.requested) {
        return WebDownloadOutcome.cancelled;
      }
      final read = await _read(entry);
      if (read is _ChapterFailed) {
        // A failed chapter is a hole in the book, not the end of the queue:
        // the remaining chapters still download and the stored ones stay
        // readable.
        await _source.markFailed(
          bookId,
          entry.sortOrder,
          read.reason,
          _clock(),
        );
        if (read.extraction) {
          extractionFailures += 1;
        } else {
          otherFailures += 1;
        }
        continue;
      }
      final chapter = (read as _ChapterRead).chapter;

      final ingested = await _ingest.ingest(
        runId: runId,
        bookId: bookId,
        chapters: [
          ChapterDraft(
            id: 'web-${entry.sortOrder}',
            title: _titleOf(entry, chapter),
            // Chapter sort orders are zero-based, as they are for a paged
            // source: the reader rejects content whose chapter at position i
            // does not carry sortOrder i.
            sortOrder: entry.sortOrder - 1,
            // The chapter's one-based ordinal in the index stands in for the
            // page bounds a paged source would supply, keeping ordering and
            // position resume working without a schema change.
            startPage: entry.sortOrder,
            endPage: entry.sortOrder,
            cleanText: _cleaner
                .clean(
                  RawPage(pageNumber: entry.sortOrder, text: chapter.text),
                  _neutralProfile,
                )
                .text,
          ),
        ],
        createdAt: _clock(),
      );
      await _source.markStored(bookId, entry.sortOrder, _clock());

      stored += 1;
      chapterCount += ingested.chapterCount;
      blockCount += ingested.blockCount;

      if (!activated) {
        await _processing.activatePartialRun(
          runId: runId,
          activatedAt: _clock(),
        );
        activated = true;
      }

      final progress = stored / total;
      await _processing.updateRunCounts(
        runId: runId,
        chapterCount: chapterCount,
        blockCount: blockCount,
        progress: progress,
        updatedAt: _clock(),
      );
      await _processing.updateProgress(
        bookId: bookId,
        stage: ProcessingStage.downloading,
        progress: progress,
        updatedAt: _clock(),
      );
    }

    // Only a book that stored nothing and failed *every* chapter on
    // extraction is evidence of an unrecognized layout. A single success, or
    // any network-shaped failure, means the site is fine and the queue should
    // simply be retried later.
    if (stored == 0 && otherFailures == 0 && extractionFailures == total) {
      _messages[bookId] = unrecognizedLayoutMessage;
      await _processing.discardRun(
        runId: runId,
        terminalStatus: BookStatus.unsupported,
        updatedAt: _clock(),
      );
      return WebDownloadOutcome.unsupported;
    }
    if (stored < total) {
      return WebDownloadOutcome.paused;
    }
    await _processing.activateRun(
      runId: runId,
      pageCount: total,
      chapterCount: chapterCount,
      blockCount: blockCount,
      completedAt: _clock(),
    );
    return WebDownloadOutcome.completed;
  }

  /// Fetches and extracts one chapter.
  ///
  /// Transient errors are already retried with bounded exponential backoff by
  /// the [WebFetcher], so a failure surfacing here means its attempts are
  /// spent and the entry is done for this pass.
  Future<_ChapterOutcome> _read(WebChapterEntry entry) async {
    final url = Uri.parse(entry.url);
    final host = _canonicalHost(url.host);
    final recipe = _recipes.forHost(host);
    if (recipe == null) {
      return _ChapterFailed('Site não suportado: $host', extraction: false);
    }
    final page = await _fetcher.fetch(url);
    if (page is WebFetchFailed) {
      return _ChapterFailed(page.message, extraction: false);
    }
    final parsed = _parser.parseChapter(
      (page as WebFetchSucceeded).body,
      recipe,
    );
    return switch (parsed) {
      ChapterParsed() => _ChapterRead(parsed),
      ChapterParseFailed(:final message) => _ChapterFailed(
        message,
        extraction: true,
      ),
    };
  }

  static String _titleOf(WebChapterEntry entry, ChapterParsed chapter) {
    final fromIndex = entry.title.trim();
    if (fromIndex.isNotEmpty) {
      return fromIndex;
    }
    final fromPage = chapter.title.trim();
    return fromPage.isNotEmpty ? fromPage : 'Capítulo ${entry.sortOrder}';
  }

  static String _canonicalHost(String host) {
    final lower = host.toLowerCase();
    return lower.startsWith('www.') ? lower.substring(4) : lower;
  }
}

final class _Cancellation {
  bool requested = false;
}

sealed class _ChapterOutcome {
  const _ChapterOutcome();
}

final class _ChapterRead extends _ChapterOutcome {
  const _ChapterRead(this.chapter);

  final ChapterParsed chapter;
}

final class _ChapterFailed extends _ChapterOutcome {
  const _ChapterFailed(this.reason, {required this.extraction});

  /// Persisted as the entry's `lastError` so a retry can report why.
  final String reason;

  /// Whether the page arrived but the recipe recognized no chapter in it.
  /// Only these failures can add up to an unrecognized site layout.
  final bool extraction;
}
