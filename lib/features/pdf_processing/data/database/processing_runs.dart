import 'package:drift/drift.dart';
import 'package:vox_novel/features/library/data/database/books.dart';

@TableIndex(name: 'processing_runs_book_id', columns: {#bookId})
class ProcessingRuns extends Table {
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get cleanText => text().nullable()();
  TextColumn get state => text()();
  IntColumn get startedAt => integer().map(const UtcDateTimeConverter())();
  IntColumn get completedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
