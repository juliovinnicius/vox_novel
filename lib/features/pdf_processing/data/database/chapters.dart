import 'package:drift/drift.dart';
import 'package:vox_novel/features/library/data/database/books.dart';
import 'package:vox_novel/features/pdf_processing/data/database/processing_runs.dart';

@TableIndex(name: 'chapters_book_id', columns: {#bookId})
@TableIndex(name: 'chapters_run_id', columns: {#runId})
@TableIndex(
  name: 'chapters_run_order_unique',
  columns: {#runId, #sortOrder},
  unique: true,
)
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get runId =>
      text().references(ProcessingRuns, #id, onDelete: KeyAction.cascade)();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get startPage => integer()();
  IntColumn get endPage => integer()();
  TextColumn get cleanText => text()();
  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
