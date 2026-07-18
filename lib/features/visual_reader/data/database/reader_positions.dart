import 'package:drift/drift.dart';
import 'package:vox_novel/features/library/data/database/books.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

class ReaderModeConverter extends TypeConverter<ReaderMode, String> {
  const ReaderModeConverter();

  @override
  ReaderMode fromSql(String fromDb) => ReaderMode.values.firstWhere(
    (value) => value.name == fromDb,
    orElse: () => throw FormatException('Unknown reader mode: $fromDb'),
  );

  @override
  String toSql(ReaderMode value) => value.name;
}

class ReaderPositions extends Table {
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get mode => text().map(const ReaderModeConverter())();
  TextColumn get chapterId => text().nullable()();
  TextColumn get blockId => text().nullable()();
  IntColumn get pdfPage => integer().customConstraint(
    'NOT NULL DEFAULT 1 CHECK (pdf_page > 0)',
  )();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}
