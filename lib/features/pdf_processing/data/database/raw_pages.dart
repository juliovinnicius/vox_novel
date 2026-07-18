import 'package:drift/drift.dart';
import 'package:vox_novel/features/pdf_processing/data/database/processing_runs.dart';

@TableIndex(
  name: 'raw_pages_run_page_unique',
  columns: {#runId, #pageNumber},
  unique: true,
)
class RawPages extends Table {
  TextColumn get runId =>
      text().references(ProcessingRuns, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageNumber => integer()();
  TextColumn get rawText => text()();
  TextColumn get cleanText => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {runId, pageNumber};
}
