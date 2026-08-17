enum WebChapterState {
  pending,
  stored,
  failed;

  static WebChapterState fromStorage(String value) {
    return WebChapterState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => throw FormatException('Unknown web chapter state: $value'),
    );
  }

  String get storageValue => name;
}

/// A chapter as the site's index lists it, before it has any local state.
final class WebChapterRef {
  const WebChapterRef({
    required this.url,
    required this.title,
    required this.sortOrder,
  });

  final String url;
  final String title;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      other is WebChapterRef &&
      other.url == url &&
      other.title == title &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(url, title, sortOrder);
}

/// A chapter of the persisted download queue.
final class WebChapterEntry {
  const WebChapterEntry({
    required this.bookId,
    required this.sortOrder,
    required this.url,
    required this.title,
    required this.state,
    required this.attemptCount,
    required this.updatedAt,
    this.lastError,
  });

  final String bookId;
  final int sortOrder;
  final String url;
  final String title;
  final WebChapterState state;
  final int attemptCount;
  final String? lastError;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is WebChapterEntry &&
      other.bookId == bookId &&
      other.sortOrder == sortOrder &&
      other.url == url &&
      other.title == title &&
      other.state == state &&
      other.attemptCount == attemptCount &&
      other.lastError == lastError &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    bookId,
    sortOrder,
    url,
    title,
    state,
    attemptCount,
    lastError,
    updatedAt,
  );
}

final class WebChapterCounts {
  const WebChapterCounts({
    required this.total,
    required this.stored,
    required this.failed,
  });

  final int total;
  final int stored;
  final int failed;

  @override
  bool operator ==(Object other) =>
      other is WebChapterCounts &&
      other.total == total &&
      other.stored == stored &&
      other.failed == failed;

  @override
  int get hashCode => Object.hash(total, stored, failed);
}

abstract interface class WebSourceRepository {
  /// Replaces the whole persisted index of [bookId] with [chapters].
  Future<void> replaceIndex(String bookId, List<WebChapterRef> chapters);

  /// Entries that are not stored yet, ordered by `sortOrder`.
  Future<List<WebChapterEntry>> pending(String bookId);

  /// Entries marked failed, ordered by `sortOrder`.
  Future<List<WebChapterEntry>> failed(String bookId);

  Future<WebChapterCounts> counts(String bookId);

  Future<Set<String>> knownUrls(String bookId);

  /// Appends the chapters whose url is not indexed yet, continuing the
  /// existing `sortOrder` sequence. Returns how many were appended.
  Future<int> appendNew(String bookId, List<WebChapterRef> chapters);

  Future<void> markStored(String bookId, int sortOrder, DateTime at);

  Future<void> markFailed(
    String bookId,
    int sortOrder,
    String reason,
    DateTime at,
  );
}
