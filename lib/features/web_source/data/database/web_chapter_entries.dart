import 'package:drift/drift.dart';
import 'package:vox_novel/features/library/data/database/books.dart';

@TableIndex(
  name: 'web_chapter_entries_book_order_unique',
  columns: {#bookId, #sortOrder},
  unique: true,
)
@TableIndex(
  name: 'web_chapter_entries_book_url_unique',
  columns: {#bookId, #url},
  unique: true,
)
class WebChapterEntries extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  TextColumn get state => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {bookId, sortOrder};
}
