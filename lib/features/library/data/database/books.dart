import 'package:drift/drift.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

class BookStatusConverter extends TypeConverter<BookStatus, String> {
  const BookStatusConverter();

  @override
  BookStatus fromSql(String fromDb) => BookStatus.fromStorage(fromDb);

  @override
  String toSql(BookStatus value) => value.storageValue;
}

class UtcDateTimeConverter extends TypeConverter<DateTime, int> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

class ProcessingStageConverter extends TypeConverter<ProcessingStage, String> {
  const ProcessingStageConverter();

  @override
  ProcessingStage fromSql(String fromDb) => ProcessingStage.values.firstWhere(
    (stage) => stage.name == fromDb,
    orElse: () => throw FormatException('Unknown processing stage: $fromDb'),
  );

  @override
  String toSql(ProcessingStage value) => value.name;
}

@TableIndex(name: 'books_file_hash_unique', columns: {#fileHash}, unique: true)
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get originalFileName => text()();
  TextColumn get storedFilePath => text()();
  TextColumn get fileHash => text()();
  TextColumn get status => text().map(const BookStatusConverter())();
  RealColumn get processingProgress => real()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  IntColumn get chapterCount => integer().withDefault(const Constant(0))();
  IntColumn get blockCount => integer().withDefault(const Constant(0))();
  TextColumn get processingStage => text()
      .map(NullAwareTypeConverter.wrap(const ProcessingStageConverter()))
      .nullable()();
  TextColumn get activeContentRunId => text().nullable().customConstraint(
    'NULL REFERENCES processing_runs(id) ON DELETE SET NULL',
  )();
  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
