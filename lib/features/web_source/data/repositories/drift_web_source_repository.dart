import 'package:drift/drift.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';

final class DriftWebSourceRepository implements WebSourceRepository {
  const DriftWebSourceRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.timestamp;

  final db.AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<void> replaceIndex(String bookId, List<WebChapterRef> chapters) {
    return _database.transaction(() async {
      await (_database.delete(
        _database.webChapterEntries,
      )..where((row) => row.bookId.equals(bookId))).go();
      await _database.batch((batch) {
        batch.insertAll(_database.webChapterEntries, [
          for (final chapter in chapters) _companion(bookId, chapter),
        ]);
      });
    });
  }

  @override
  Future<List<WebChapterEntry>> pending(String bookId) async {
    final query = _database.select(_database.webChapterEntries)
      ..where(
        (row) =>
            row.bookId.equals(bookId) &
            row.state.equals(WebChapterState.stored.storageValue).not(),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]);
    return List<WebChapterEntry>.unmodifiable(
      (await query.get()).map(_toDomain),
    );
  }

  @override
  Future<List<WebChapterEntry>> failed(String bookId) async {
    final query = _database.select(_database.webChapterEntries)
      ..where(
        (row) =>
            row.bookId.equals(bookId) &
            row.state.equals(WebChapterState.failed.storageValue),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]);
    return List<WebChapterEntry>.unmodifiable(
      (await query.get()).map(_toDomain),
    );
  }

  @override
  Future<WebChapterCounts> counts(String bookId) async {
    final rows =
        await (_database.select(
          _database.webChapterEntries,
        )..where((row) => row.bookId.equals(bookId))).get();
    return WebChapterCounts(
      total: rows.length,
      stored: rows
          .where((row) => row.state == WebChapterState.stored.storageValue)
          .length,
      failed: rows
          .where((row) => row.state == WebChapterState.failed.storageValue)
          .length,
    );
  }

  @override
  Future<Set<String>> knownUrls(String bookId) async {
    final rows =
        await (_database.select(
          _database.webChapterEntries,
        )..where((row) => row.bookId.equals(bookId))).get();
    return Set<String>.unmodifiable(rows.map((row) => row.url));
  }

  @override
  Future<int> appendNew(String bookId, List<WebChapterRef> chapters) {
    return _database.transaction(() async {
      final existing =
          await (_database.select(
            _database.webChapterEntries,
          )..where((row) => row.bookId.equals(bookId))).get();
      final known = existing.map((row) => row.url).toSet();
      var nextSortOrder = existing.fold<int>(
        0,
        (highest, row) => row.sortOrder > highest ? row.sortOrder : highest,
      );
      final appended = <db.WebChapterEntriesCompanion>[];
      for (final chapter in chapters) {
        if (!known.add(chapter.url)) continue;
        nextSortOrder += 1;
        appended.add(
          _companion(
            bookId,
            WebChapterRef(
              url: chapter.url,
              title: chapter.title,
              sortOrder: nextSortOrder,
            ),
          ),
        );
      }
      if (appended.isEmpty) return 0;
      await _database.batch((batch) {
        batch.insertAll(_database.webChapterEntries, appended);
      });
      return appended.length;
    });
  }

  @override
  Future<void> markStored(String bookId, int sortOrder, DateTime at) async {
    await _write(
      bookId,
      sortOrder,
      db.WebChapterEntriesCompanion(
        state: Value(WebChapterState.stored.storageValue),
        lastError: const Value(null),
        updatedAt: Value(at),
      ),
    );
  }

  @override
  Future<void> markFailed(
    String bookId,
    int sortOrder,
    String reason,
    DateTime at,
  ) {
    return _database.transaction(() async {
      final row =
          await (_database.select(_database.webChapterEntries)..where(
                (row) =>
                    row.bookId.equals(bookId) & row.sortOrder.equals(sortOrder),
              ))
              .getSingleOrNull();
      if (row == null) {
        throw StateError('Web chapter entry not found');
      }
      await (_database.update(_database.webChapterEntries)..where(
            (target) =>
                target.bookId.equals(bookId) &
                target.sortOrder.equals(sortOrder),
          ))
          .write(
            db.WebChapterEntriesCompanion(
              state: Value(WebChapterState.failed.storageValue),
              attemptCount: Value(row.attemptCount + 1),
              lastError: Value(reason),
              updatedAt: Value(at),
            ),
          );
    });
  }

  Future<void> _write(
    String bookId,
    int sortOrder,
    db.WebChapterEntriesCompanion companion,
  ) async {
    final changed =
        await (_database.update(_database.webChapterEntries)..where(
              (row) =>
                  row.bookId.equals(bookId) & row.sortOrder.equals(sortOrder),
            ))
            .write(companion);
    if (changed != 1) {
      throw StateError('Web chapter entry not found');
    }
  }

  db.WebChapterEntriesCompanion _companion(
    String bookId,
    WebChapterRef chapter,
  ) {
    return db.WebChapterEntriesCompanion.insert(
      bookId: bookId,
      sortOrder: chapter.sortOrder,
      url: chapter.url,
      title: chapter.title,
      state: WebChapterState.pending.storageValue,
      updatedAt: _clock(),
    );
  }

  WebChapterEntry _toDomain(db.WebChapterEntry row) {
    return WebChapterEntry(
      bookId: row.bookId,
      sortOrder: row.sortOrder,
      url: row.url,
      title: row.title,
      state: WebChapterState.fromStorage(row.state),
      attemptCount: row.attemptCount,
      lastError: row.lastError,
      updatedAt: row.updatedAt,
    );
  }
}
