import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

abstract interface class VisualReaderRepository {
  Future<ReaderBookContent?> loadContent(String bookId);
  Future<ReaderSettings> loadSettings();
  Future<void> saveSettings(ReaderSettings settings);
  Future<ReaderPosition?> loadPosition(String bookId);
  Future<void> savePosition(ReaderPosition position);
}
