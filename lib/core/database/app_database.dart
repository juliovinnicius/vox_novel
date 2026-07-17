import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:vox_novel/features/library/data/database/books.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Books])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : this(driftDatabase(name: 'vox_novel'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(books);
      }
    },
  );
}
