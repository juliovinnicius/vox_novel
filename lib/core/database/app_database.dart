import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:vox_novel/features/library/data/database/books.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/data/database/chapters.dart';
import 'package:vox_novel/features/pdf_processing/data/database/narration_blocks.dart';
import 'package:vox_novel/features/pdf_processing/data/database/processing_runs.dart';
import 'package:vox_novel/features/pdf_processing/data/database/raw_pages.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/visual_reader/data/database/reader_positions.dart';
import 'package:vox_novel/features/visual_reader/data/database/reader_settings.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Books,
    ProcessingRuns,
    RawPages,
    Chapters,
    NarrationBlocks,
    ReaderSettingsRows,
    ReaderPositions,
    NarrationSettingsRows,
    BookNarrationSettings,
    ReadingProgress,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : this(driftDatabase(name: 'vox_novel'));

  @override
  int get schemaVersion => 5;

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
      if (from < 4) {
        await migrator.createTable(readerSettingsRows);
        await migrator.createTable(readerPositions);
      }
      if (from < 5) {
        await migrator.createTable(narrationSettingsRows);
        await migrator.createTable(bookNarrationSettings);
        await migrator.createTable(readingProgress);
      }
    },
  );
}

class NarrationSettingsRows extends Table {
  IntColumn get id => integer().customConstraint('NOT NULL CHECK (id = 1)')();
  TextColumn get voiceName => text().nullable().customConstraint(
    'NULL CHECK (voice_name IS NULL OR length(trim(voice_name)) > 0)',
  )();
  TextColumn get voiceLocale => text().nullable().customConstraint(
    'NULL CHECK (voice_locale IS NULL OR length(trim(voice_locale)) > 0)',
  )();
  RealColumn get speechRate => real().customConstraint(
    'NOT NULL CHECK (speech_rate IN '
    '(0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2.0))',
  )();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  String get tableName => 'narration_settings';

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ((voice_name IS NULL) = (voice_locale IS NULL))',
  ];
}

class BookNarrationSettings extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get voiceName => text().customConstraint(
    'NOT NULL CHECK (length(trim(voice_name)) > 0)',
  )();
  TextColumn get voiceLocale => text().customConstraint(
    'NOT NULL CHECK (length(trim(voice_locale)) > 0)',
  )();
  RealColumn get speechRate => real().customConstraint(
    'NOT NULL CHECK (speech_rate IN '
    '(0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2.0))',
  )();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}

class ReadingProgress extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get activeRunId =>
      text().customConstraint('NOT NULL CHECK (length(active_run_id) > 0)')();
  TextColumn get chapterId =>
      text().customConstraint('NOT NULL CHECK (length(chapter_id) > 0)')();
  TextColumn get blockId =>
      text().customConstraint('NOT NULL CHECK (length(block_id) > 0)')();
  BoolColumn get completed => boolean()();
  TextColumn get voiceName => text().customConstraint(
    'NOT NULL CHECK (length(trim(voice_name)) > 0)',
  )();
  TextColumn get voiceLocale => text().customConstraint(
    'NOT NULL CHECK (length(trim(voice_locale)) > 0)',
  )();
  RealColumn get speechRate => real().customConstraint(
    'NOT NULL CHECK (speech_rate IN '
    '(0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2.0))',
  )();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}
