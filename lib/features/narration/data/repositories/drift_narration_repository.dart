import 'package:drift/drift.dart';
import 'package:vox_novel/core/database/app_database.dart' as db;
import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';
import 'package:vox_novel/features/narration/domain/repositories/narration_repository.dart';

final class DriftNarrationRepository implements NarrationRepository {
  DriftNarrationRepository(
    this._database, {
    Future<void> Function(NarrationProgress progress)? beforeProgressWrite,
  }) : // Public seam name intentionally omits a private prefix.
       // ignore: prefer_initializing_formals
       _beforeProgressWrite = beforeProgressWrite;

  final db.AppDatabase _database;
  final Future<void> Function(NarrationProgress progress)? _beforeProgressWrite;
  final Map<String, Future<void>> _progressTails = {};

  @override
  Future<NarrationSettings> loadGlobalSettings() async {
    final row = await _database
        .select(_database.narrationSettingsRows)
        .getSingleOrNull();
    return row == null
        ? NarrationSettings.defaults()
        : NarrationSettings(
            voice: _voice(row.voiceName, row.voiceLocale),
            rate: row.speechRate,
          );
  }

  @override
  Future<void> saveGlobalSettings(NarrationSettings settings) {
    return _database
        .into(_database.narrationSettingsRows)
        .insertOnConflictUpdate(
          db.NarrationSettingsRowsCompanion.insert(
            id: const Value(1),
            voiceName: Value(settings.voice?.name),
            voiceLocale: Value(settings.voice?.locale),
            speechRate: settings.rate,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  @override
  Future<BookNarrationOverride?> loadBookOverride(String bookId) async {
    final row = await (_database.select(
      _database.bookNarrationSettings,
    )..where((row) => row.bookId.equals(bookId))).getSingleOrNull();
    return row == null
        ? null
        : BookNarrationOverride(
            bookId: row.bookId,
            settings: NarrationSettings(
              voice: NarrationVoice(
                name: row.voiceName,
                locale: row.voiceLocale,
              ),
              rate: row.speechRate,
            ),
            updatedAt: row.updatedAt,
          );
  }

  @override
  Future<void> saveBookOverride(BookNarrationOverride override) {
    final voice = override.settings.voice!;
    return _database
        .into(_database.bookNarrationSettings)
        .insertOnConflictUpdate(
          db.BookNarrationSettingsCompanion.insert(
            bookId: override.bookId,
            voiceName: voice.name,
            voiceLocale: voice.locale,
            speechRate: override.settings.rate,
            updatedAt: override.updatedAt,
          ),
        );
  }

  @override
  Future<void> deleteBookOverride(String bookId) {
    return (_database.delete(
      _database.bookNarrationSettings,
    )..where((row) => row.bookId.equals(bookId))).go();
  }

  @override
  Future<NarrationProgress?> loadProgress(String bookId) async {
    final row = await (_database.select(
      _database.readingProgress,
    )..where((row) => row.bookId.equals(bookId))).getSingleOrNull();
    return row == null
        ? null
        : NarrationProgress(
            bookId: row.bookId,
            activeRunId: row.activeRunId,
            chapterId: row.chapterId,
            blockId: row.blockId,
            completed: row.completed,
            settings: NarrationSettings(
              voice: NarrationVoice(
                name: row.voiceName,
                locale: row.voiceLocale,
              ),
              rate: row.speechRate,
            ),
            updatedAt: row.updatedAt,
          );
  }

  @override
  Future<void> saveProgress(NarrationProgress progress) {
    final previous = _progressTails[progress.bookId] ?? Future.value();
    final next = previous.catchError((_) {}).then((_) async {
      await _beforeProgressWrite?.call(progress);
      final voice = progress.settings.voice!;
      await _database
          .into(_database.readingProgress)
          .insertOnConflictUpdate(
            db.ReadingProgressCompanion.insert(
              bookId: progress.bookId,
              activeRunId: progress.activeRunId,
              chapterId: progress.chapterId,
              blockId: progress.blockId,
              completed: progress.completed,
              voiceName: voice.name,
              voiceLocale: voice.locale,
              speechRate: progress.settings.rate,
              updatedAt: progress.updatedAt,
            ),
          );
    });
    _progressTails[progress.bookId] = next;
    return next.whenComplete(() {
      if (identical(_progressTails[progress.bookId], next)) {
        _progressTails.remove(progress.bookId);
      }
    });
  }

  NarrationVoice? _voice(String? name, String? locale) =>
      name == null ? null : NarrationVoice(name: name, locale: locale!);
}
