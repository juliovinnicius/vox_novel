import 'package:drift/drift.dart';
import 'package:vox_novel/features/pdf_processing/data/database/chapters.dart';
import 'package:vox_novel/features/pdf_processing/data/database/processing_runs.dart';

@TableIndex(name: 'narration_blocks_run_id', columns: {#runId})
@TableIndex(
  name: 'narration_blocks_chapter_order_unique',
  columns: {#chapterId, #sortOrder},
  unique: true,
)
class NarrationBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get runId =>
      text().references(ProcessingRuns, #id, onDelete: KeyAction.cascade)();
  TextColumn get chapterId =>
      text().references(Chapters, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get originalText => text()();
  TextColumn get normalizedText => text()();
  IntColumn get characterCount => integer()();
  IntColumn get startPage => integer()();
  IntColumn get endPage => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
