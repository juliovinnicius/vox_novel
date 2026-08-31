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

  /// The queue ran out of blocks while the book still has chapters
  /// downloading — the book has not ended, the next chapter has not arrived.
  awaitingDownload,
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

/// The one value every narration surface renders.
///
/// The in-app player, the media notification, and the lock screen are all
/// projections of this: deriving them from a single value is what keeps them
/// from disagreeing about what is playing.
final class NarrationSessionState {
  const NarrationSessionState({
    this.status = NarrationStatus.initial,
    this.bookId,
    this.bookTitle,
    this.current,
    this.voices = const [],
    this.settings,
    this.usesBookOverride = false,
    this.canPrevious = false,
    this.canNext = false,
    this.awaitsDownload = false,
    this.message,
  });

  final NarrationStatus status;
  final String? bookId;
  final String? bookTitle;

  /// The block being spoken, or the one play would start from. Every identity
  /// a surface needs — run, chapter, block, chapter title — comes from here.
  final NarrationQueueEntry? current;

  /// Voices the engine offers, and the settings playback speaks with. The
  /// session owns them because speech repair rewrites the voice when one
  /// fails, and because the media notification can start playback with no
  /// Cubit alive to supply them.
  final List<NarrationVoice> voices;
  final NarrationSettings? settings;
  final bool usesBookOverride;

  final bool canPrevious;
  final bool canNext;

  /// The queue ran out while the book still has chapters downloading, so its
  /// end is a download boundary rather than the end of the book.
  final bool awaitsDownload;

  /// A one-shot message for the reader, cleared once shown.
  final String? message;

  NarrationSessionState copyWith({
    NarrationStatus? status,
    Object? bookId = _unset,
    Object? bookTitle = _unset,
    Object? current = _unset,
    List<NarrationVoice>? voices,
    NarrationSettings? settings,
    bool? usesBookOverride,
    bool? canPrevious,
    bool? canNext,
    bool? awaitsDownload,
    Object? message = _unset,
  }) => NarrationSessionState(
    status: status ?? this.status,
    bookId: identical(bookId, _unset) ? this.bookId : bookId as String?,
    bookTitle: identical(bookTitle, _unset)
        ? this.bookTitle
        : bookTitle as String?,
    current: identical(current, _unset)
        ? this.current
        : current as NarrationQueueEntry?,
    voices: voices ?? this.voices,
    settings: settings ?? this.settings,
    usesBookOverride: usesBookOverride ?? this.usesBookOverride,
    canPrevious: canPrevious ?? this.canPrevious,
    canNext: canNext ?? this.canNext,
    awaitsDownload: awaitsDownload ?? this.awaitsDownload,
    message: identical(message, _unset) ? this.message : message as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is NarrationSessionState &&
      other.status == status &&
      other.bookId == bookId &&
      other.bookTitle == bookTitle &&
      other.current == current &&
      _sameVoices(other.voices) &&
      other.settings == settings &&
      other.usesBookOverride == usesBookOverride &&
      other.canPrevious == canPrevious &&
      other.canNext == canNext &&
      other.awaitsDownload == awaitsDownload &&
      other.message == message;

  bool _sameVoices(List<NarrationVoice> other) {
    if (other.length != voices.length) return false;
    for (var i = 0; i < voices.length; i++) {
      if (other[i] != voices[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    status,
    bookId,
    bookTitle,
    current,
    Object.hashAll(voices),
    settings,
    usesBookOverride,
    canPrevious,
    canNext,
    awaitsDownload,
    message,
  );
}

const Object _unset = Object();
