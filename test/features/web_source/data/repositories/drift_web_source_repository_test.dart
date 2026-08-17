import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/web_source/data/repositories/drift_web_source_repository.dart';
import 'package:vox_novel/features/web_source/domain/repositories/web_source_repository.dart';

void main() {
  late AppDatabase database;
  late DriftWebSourceRepository repository;
  final indexedAt = DateTime.utc(2026, 8, 17);
  final markedAt = DateTime.utc(2026, 8, 18);

  WebChapterRef ref(int sortOrder) => WebChapterRef(
    url: 'https://centralnovel.com/novela-capitulo-$sortOrder/',
    title: 'Capítulo $sortOrder',
    sortOrder: sortOrder,
  );

  Future<void> seedBook(String id) {
    return database.into(database.books).insert(
      BooksCompanion.insert(
        id: id,
        title: 'Novela $id',
        sourceType: const Value(BookSourceType.web),
        sourceRef: Value('https://centralnovel.com/series/$id/'),
        status: BookStatus.processing,
        processingProgress: 0,
        createdAt: indexedAt,
        updatedAt: indexedAt,
      ),
    );
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftWebSourceRepository(database, clock: () => indexedAt);
    await seedBook('book');
  });

  tearDown(() => database.close());

  group('WebChapterState', () {
    for (final state in WebChapterState.values) {
      test('${state.name} round-trips through storage', () {
        expect(WebChapterState.fromStorage(state.storageValue), state);
      });
    }
  });

  test('replaceIndex persists every chapter as a pending entry', () async {
    await repository.replaceIndex('book', [ref(1), ref(2), ref(3)]);

    final entries = await repository.pending('book');

    expect(entries.map((entry) => entry.sortOrder), [1, 2, 3]);
    expect(entries.first.url, 'https://centralnovel.com/novela-capitulo-1/');
    expect(entries.first.title, 'Capítulo 1');
    expect(entries.first.state, WebChapterState.pending);
    expect(entries.first.attemptCount, 0);
    expect(entries.first.lastError, isNull);
    expect(entries.first.updatedAt, indexedAt);
  });

  test('replaceIndex discards the previous index of that book', () async {
    await seedBook('other');
    await repository.replaceIndex('other', [ref(1)]);
    await repository.replaceIndex('book', [ref(1), ref(2), ref(3)]);

    await repository.replaceIndex('book', [ref(1)]);

    expect((await repository.counts('book')).total, 1);
    expect((await repository.counts('other')).total, 1);
  });

  test('pending is ordered by sortOrder and excludes stored entries', () async {
    await repository.replaceIndex('book', [ref(1), ref(2), ref(3), ref(4)]);
    await repository.markStored('book', 2, markedAt);
    await repository.markFailed('book', 3, 'http 404', markedAt);

    final entries = await repository.pending('book');

    expect(entries.map((entry) => entry.sortOrder), [1, 3, 4]);
  });

  test('failed returns only failed entries with their reason', () async {
    await repository.replaceIndex('book', [ref(1), ref(2), ref(3)]);
    await repository.markFailed('book', 3, 'http 404', markedAt);
    await repository.markFailed('book', 1, 'extraction', markedAt);

    final entries = await repository.failed('book');

    expect(entries.map((entry) => entry.sortOrder), [1, 3]);
    expect(entries.map((entry) => entry.lastError), ['extraction', 'http 404']);
  });

  test('markStored records the state and the given timestamp', () async {
    await repository.replaceIndex('book', [ref(1)]);
    await repository.markFailed('book', 1, 'http 500', indexedAt);

    await repository.markStored('book', 1, markedAt);

    final entry = (await repository.counts('book'));
    expect(entry.stored, 1);
    expect(entry.failed, 0);
    final rows = await database.select(database.webChapterEntries).get();
    expect(rows.single.state, 'stored');
    expect(rows.single.lastError, isNull);
    expect(rows.single.updatedAt, markedAt);
  });

  test('markFailed accumulates attemptCount and keeps the reason', () async {
    await repository.replaceIndex('book', [ref(1)]);

    await repository.markFailed('book', 1, 'timeout', indexedAt);
    await repository.markFailed('book', 1, 'http 500', markedAt);

    final entry = (await repository.failed('book')).single;
    expect(entry.attemptCount, 2);
    expect(entry.lastError, 'http 500');
    expect(entry.updatedAt, markedAt);
  });

  test('marking an unknown entry fails loudly', () async {
    await repository.replaceIndex('book', [ref(1)]);

    await expectLater(
      repository.markStored('book', 9, markedAt),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      repository.markFailed('book', 9, 'http 404', markedAt),
      throwsA(isA<StateError>()),
    );
  });

  test('counts reports total, stored and failed after mixed marking', () async {
    await repository.replaceIndex('book', [
      ref(1),
      ref(2),
      ref(3),
      ref(4),
      ref(5),
    ]);
    await repository.markStored('book', 1, markedAt);
    await repository.markStored('book', 2, markedAt);
    await repository.markFailed('book', 3, 'http 404', markedAt);

    expect(
      await repository.counts('book'),
      const WebChapterCounts(total: 5, stored: 2, failed: 1),
    );
  });

  test('knownUrls returns every indexed url of that book only', () async {
    await seedBook('other');
    await repository.replaceIndex('book', [ref(1), ref(2)]);
    await repository.replaceIndex('other', [ref(3)]);

    expect(await repository.knownUrls('book'), {
      'https://centralnovel.com/novela-capitulo-1/',
      'https://centralnovel.com/novela-capitulo-2/',
    });
  });

  test('appendNew adds only unknown urls after the existing ones', () async {
    await repository.replaceIndex('book', [ref(1), ref(2)]);

    final appended = await repository.appendNew('book', [
      ref(1),
      ref(2),
      const WebChapterRef(
        url: 'https://centralnovel.com/novela-capitulo-3/',
        title: 'Capítulo 3',
        sortOrder: 1,
      ),
      const WebChapterRef(
        url: 'https://centralnovel.com/novela-capitulo-4/',
        title: 'Capítulo 4',
        sortOrder: 1,
      ),
    ]);

    expect(appended, 2);
    final entries = await repository.pending('book');
    expect(entries.map((entry) => entry.sortOrder), [1, 2, 3, 4]);
    expect(entries.map((entry) => entry.url), [
      'https://centralnovel.com/novela-capitulo-1/',
      'https://centralnovel.com/novela-capitulo-2/',
      'https://centralnovel.com/novela-capitulo-3/',
      'https://centralnovel.com/novela-capitulo-4/',
    ]);
  });

  test('appendNew continues the sequence past stored entries', () async {
    await repository.replaceIndex('book', [ref(1), ref(2)]);
    await repository.markStored('book', 1, markedAt);
    await repository.markStored('book', 2, markedAt);

    final appended = await repository.appendNew('book', [ref(3)]);

    expect(appended, 1);
    expect((await repository.pending('book')).single.sortOrder, 3);
    expect((await repository.counts('book')).total, 3);
  });

  test('appendNew appends nothing when every url is known', () async {
    await repository.replaceIndex('book', [ref(1), ref(2)]);

    final appended = await repository.appendNew('book', [ref(1), ref(2)]);

    expect(appended, 0);
    expect((await repository.counts('book')).total, 2);
  });
}
