import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

abstract interface class NarrationRepository {
  Future<NarrationSettings> loadGlobalSettings();
  Future<void> saveGlobalSettings(NarrationSettings settings);
  Future<BookNarrationOverride?> loadBookOverride(String bookId);
  Future<void> saveBookOverride(BookNarrationOverride override);
  Future<void> deleteBookOverride(String bookId);
  Future<NarrationProgress?> loadProgress(String bookId);
  Future<void> saveProgress(NarrationProgress progress);
}
