final class NarrationValidationException implements Exception {
  const NarrationValidationException(this.message);
  final String message;
}

final class NarrationVoice {
  NarrationVoice({required this.name, required this.locale}) {
    if (name.trim().isEmpty || locale.trim().isEmpty) {
      throw const NarrationValidationException('invalid narration voice');
    }
  }

  final String name;
  final String locale;

  @override
  bool operator ==(Object other) =>
      other is NarrationVoice && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);
}

final class NarrationSettings {
  NarrationSettings({required this.voice, required this.rate}) {
    _validateRate(rate);
  }

  NarrationSettings.defaults() : this(voice: null, rate: 1);

  final NarrationVoice? voice;
  final double rate;

  NarrationSettings copyWith({Object? voice = _unset, double? rate}) =>
      NarrationSettings(
        voice: identical(voice, _unset) ? this.voice : voice as NarrationVoice?,
        rate: rate ?? this.rate,
      );

  @override
  bool operator ==(Object other) =>
      other is NarrationSettings && other.voice == voice && other.rate == rate;

  @override
  int get hashCode => Object.hash(voice, rate);
}

final class BookNarrationOverride {
  BookNarrationOverride({
    required this.bookId,
    required this.settings,
    required this.updatedAt,
  }) {
    if (bookId.isEmpty || settings.voice == null || !updatedAt.isUtc) {
      throw const NarrationValidationException(
        'invalid book narration override',
      );
    }
  }

  final String bookId;
  final NarrationSettings settings;
  final DateTime updatedAt;
}

final class NarrationProgress {
  NarrationProgress({
    required this.bookId,
    required this.activeRunId,
    required this.chapterId,
    required this.blockId,
    required this.completed,
    required this.settings,
    required this.updatedAt,
  }) {
    if (bookId.isEmpty ||
        activeRunId.isEmpty ||
        chapterId.isEmpty ||
        blockId.isEmpty ||
        settings.voice == null ||
        !updatedAt.isUtc) {
      throw const NarrationValidationException('invalid narration progress');
    }
  }

  final String bookId;
  final String activeRunId;
  final String chapterId;
  final String blockId;
  final bool completed;
  final NarrationSettings settings;
  final DateTime updatedAt;
}

final class NarrationQueueEntry {
  NarrationQueueEntry({
    required this.activeRunId,
    required this.chapterId,
    required this.blockId,
    required this.chapterTitle,
    required this.normalizedText,
  }) {
    if (activeRunId.isEmpty ||
        chapterId.isEmpty ||
        blockId.isEmpty ||
        chapterTitle.isEmpty) {
      throw const NarrationValidationException('invalid narration queue entry');
    }
  }

  final String activeRunId;
  final String chapterId;
  final String blockId;
  final String chapterTitle;
  final String normalizedText;

  @override
  bool operator ==(Object other) =>
      other is NarrationQueueEntry &&
      other.activeRunId == activeRunId &&
      other.chapterId == chapterId &&
      other.blockId == blockId &&
      other.chapterTitle == chapterTitle &&
      other.normalizedText == normalizedText;

  @override
  int get hashCode => Object.hash(
    activeRunId,
    chapterId,
    blockId,
    chapterTitle,
    normalizedText,
  );
}

enum NarrationStatus {
  initial,
  loading,
  ready,
  playing,
  paused,
  completed,
  unavailable,
  error,
}

void _validateRate(double rate) {
  if (!rate.isFinite ||
      rate < 0.5 ||
      rate > 2.0 ||
      (rate * 10).roundToDouble() != rate * 10) {
    throw const NarrationValidationException('invalid narration rate');
  }
}

const Object _unset = Object();
