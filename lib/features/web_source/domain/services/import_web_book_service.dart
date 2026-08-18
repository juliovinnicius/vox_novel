import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/services/web_novel_index_resolver.dart';

/// Why a submitted URL did not become a book. Every reason renders its own
/// message so the import flow can tell them apart.
enum ImportWebBookRejection {
  invalidUrl,
  unsupportedDomain,
  disallowedPath,
  network,
  unsupported,
  storage,
}

sealed class ImportWebBookResult {
  const ImportWebBookResult();
}

final class WebBookImported extends ImportWebBookResult {
  const WebBookImported(this.book, {required this.created});

  final Book book;

  /// Whether this import created the book, as opposed to resolving to the
  /// book the same series already has in the library.
  final bool created;
}

final class WebBookImportRejected extends ImportWebBookResult {
  const WebBookImportRejected(this.reason, this.message);

  final ImportWebBookRejection reason;
  final String message;
}

/// Starts draining [bookId]'s chapter queue in the background.
typedef StartWebDownload = void Function(String bookId);

/// Turns a submitted URL into a durable web book with a persisted chapter
/// index, then hands the queue to the download service.
final class ImportWebBookService {
  const ImportWebBookService({
    required this.books,
    required this.source,
    required this.resolver,
    required this.startDownload,
    required this.generateId,
    required this.clock,
  });

  static const String storageMessage = 'Não foi possível salvar esta obra';

  final BookRepository books;
  final WebSourceRepository source;
  final WebNovelIndexResolver resolver;
  final StartWebDownload startDownload;
  final String Function() generateId;
  final DateTime Function() clock;

  Future<ImportWebBookResult> import(String submitted) async {
    final url = Uri.tryParse(submitted.trim());
    if (url == null) {
      return const WebBookImportRejected(
        ImportWebBookRejection.invalidUrl,
        'Informe uma URL válida',
      );
    }
    // The resolver owns the whole validation order — URL form, known domain,
    // allowed path, resolvable index, non-empty index — and rejects every
    // step it can decide before issuing a request.
    final resolved = await resolver.resolve(url);
    if (resolved is WebNovelIndexRejected) {
      return WebBookImportRejected(
        _rejectionFor(resolved.reason),
        resolved.message,
      );
    }
    final index = (resolved as WebNovelIndexResolved).index;
    final sourceRef = index.seriesUrl.toString();

    final existing = await books.findBySourceRef(sourceRef);
    if (existing != null) {
      startDownload(existing.id);
      return WebBookImported(existing, created: false);
    }

    final now = clock();
    final book = Book(
      id: generateId(),
      title: index.title,
      sourceType: BookSourceType.web,
      sourceRef: sourceRef,
      status: BookStatus.processing,
      processingProgress: 0,
      // A web book has no pages; the indexed chapter count is what the
      // download reports progress against, and what the completed run will
      // carry as its page count.
      pageCount: index.chapters.length,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await books.insert(book);
      await source.replaceIndex(book.id, index.chapters);
    } catch (_) {
      // An import that cannot persist its index must leave nothing behind:
      // a book without a queue would sit in the library forever.
      await _discard(book.id);
      return const WebBookImportRejected(
        ImportWebBookRejection.storage,
        storageMessage,
      );
    }
    startDownload(book.id);
    return WebBookImported(book, created: true);
  }

  Future<void> _discard(String bookId) async {
    try {
      await books.deleteById(bookId);
    } catch (_) {
      // Nothing better remains to do; the caller is already reporting a
      // failed import.
    }
  }

  static ImportWebBookRejection _rejectionFor(WebNovelIndexRejection reason) =>
      switch (reason) {
        WebNovelIndexRejection.invalidUrl => ImportWebBookRejection.invalidUrl,
        WebNovelIndexRejection.unsupportedDomain =>
          ImportWebBookRejection.unsupportedDomain,
        WebNovelIndexRejection.disallowedPath =>
          ImportWebBookRejection.disallowedPath,
        WebNovelIndexRejection.network => ImportWebBookRejection.network,
        WebNovelIndexRejection.unsupported =>
          ImportWebBookRejection.unsupported,
      };
}
