import 'package:drift/drift.dart';
import 'package:vox_novel/features/library/data/database/books.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

class ReaderThemeConverter extends TypeConverter<ReaderTheme, String> {
  const ReaderThemeConverter();

  @override
  ReaderTheme fromSql(String fromDb) => ReaderTheme.values.firstWhere(
    (value) => value.name == fromDb,
    orElse: () => throw FormatException('Unknown reader theme: $fromDb'),
  );

  @override
  String toSql(ReaderTheme value) => value.name;
}

class ReaderFontFamilyConverter
    extends TypeConverter<ReaderFontFamily, String> {
  const ReaderFontFamilyConverter();

  @override
  ReaderFontFamily fromSql(String fromDb) => ReaderFontFamily.values.firstWhere(
    (value) => value.name == fromDb,
    orElse: () => throw FormatException('Unknown reader font family: $fromDb'),
  );

  @override
  String toSql(ReaderFontFamily value) => value.name;
}

class ReaderSettingsRows extends Table {
  IntColumn get id =>
      integer().customConstraint('NOT NULL CHECK (id = 1)')();
  TextColumn get theme => text().map(const ReaderThemeConverter())();
  TextColumn get fontFamily => text().map(const ReaderFontFamilyConverter())();
  IntColumn get fontSize => integer().customConstraint(
    'NOT NULL CHECK (font_size BETWEEN 14 AND 32 AND font_size % 2 = 0)',
  )();
  RealColumn get lineHeight => real().customConstraint(
    'NOT NULL CHECK (line_height IN (1.2, 1.5, 1.8, 2.0))',
  )();
  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
