import 'package:vox_novel/features/content_ingestion/domain/services/chapter_ingest.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
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
       _parser = parser;

  final BookRepository _books;
  final WebSourceRepository _source;
  final TextProcessingRepository _processing;
  final ChapterIngest _ingest;
  final WebFetcher _fetcher;
  final SiteRecipeRegistry _recipes;
  final WebDownloadClock _clock;
  final WebDownloadRunId _runId;
  final HtmlRecipeParser _parser;

  Future<WebDownloadOutcome> download(String bookId) async {
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
      );
    }

    var chapterCount = book.chapterCount;
    var blockCount = book.blockCount;
    var stored = total - pending.length;

    for (final entry in pending) {
      final chapter = await _read(entry);
      if (chapter == null) {
        return WebDownloadOutcome.paused;
      }

      final ingested = await _ingest.ingest(
        runId: runId,
        bookId: bookId,
        chapters: [
          ChapterDraft(
            id: 'web-${entry.sortOrder}',
            title: _titleOf(entry, chapter),
            // The chapter's ordinal in the index stands in for the page
            // bounds a paged source would supply, keeping ordering and
            // position resume working without a schema change.
            sortOrder: entry.sortOrder,
            startPage: entry.sortOrder,
            endPage: entry.sortOrder,
            cleanText: chapter.text,
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

  Future<ChapterParsed?> _read(WebChapterEntry entry) async {
    final url = Uri.parse(entry.url);
    final recipe = _recipes.forHost(_canonicalHost(url.host));
    if (recipe == null) {
      return null;
    }
    final page = await _fetcher.fetch(url);
    if (page is! WebFetchSucceeded) {
      return null;
    }
    final parsed = _parser.parseChapter(page.body, recipe);
    return parsed is ChapterParsed ? parsed : null;
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
