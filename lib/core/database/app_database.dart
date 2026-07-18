import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:vox_novel/features/library/data/database/books.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/data/database/chapters.dart';
import 'package:vox_novel/features/pdf_processing/data/database/narration_blocks.dart';
import 'package:vox_novel/features/pdf_processing/data/database/processing_runs.dart';
import 'package:vox_novel/features/pdf_processing/data/database/raw_pages.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Books, ProcessingRuns, RawPages, Chapters, NarrationBlocks],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : this(driftDatabase(name: 'vox_novel'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(books);
        await migrator.createTable(processingRuns);
        await migrator.createTable(rawPages);
        await migrator.createTable(chapters);
        await migrator.createTable(narrationBlocks);
      } else if (from < 3) {
        await migrator.addColumn(books, books.pageCount);
        await migrator.addColumn(books, books.chapterCount);
        await migrator.addColumn(books, books.blockCount);
        await migrator.addColumn(books, books.processingStage);
        await migrator.addColumn(books, books.activeContentRunId);
        await migrator.createTable(processingRuns);
        await migrator.createTable(rawPages);
        await migrator.createTable(chapters);
        await migrator.createTable(narrationBlocks);
      }
    },
  );
}
