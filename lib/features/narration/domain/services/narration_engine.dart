import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

abstract interface class NarrationEngine {
  Future<List<NarrationVoice>> initialize();
  Future<void> configure(NarrationVoice voice, double rate);
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> close();
}
