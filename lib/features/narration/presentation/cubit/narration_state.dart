import 'package:vox_novel/features/narration/domain/entities/narration_models.dart';

final class NarrationState {
  const NarrationState({
    this.status = NarrationStatus.initial,
    this.voices = const [],
    this.settings,
    this.usesBookOverride = false,
    this.bookId,
    this.activeRunId,
    this.chapterId,
    this.blockId,
    this.chapterTitle,
    this.canPrevious = false,
    this.canNext = false,
    this.message,
  });

  final NarrationStatus status;
  final List<NarrationVoice> voices;
  final NarrationSettings? settings;
  final bool usesBookOverride;
  final String? bookId;
  final String? activeRunId;
  final String? chapterId;
  final String? blockId;
  final String? chapterTitle;
  final bool canPrevious;
  final bool canNext;
  final String? message;

  NarrationState copyWith({
    NarrationStatus? status,
    List<NarrationVoice>? voices,
    NarrationSettings? settings,
    bool? usesBookOverride,
    Object? bookId = _unset,
    Object? activeRunId = _unset,
    Object? chapterId = _unset,
    Object? blockId = _unset,
    Object? chapterTitle = _unset,
    bool? canPrevious,
    bool? canNext,
    Object? message = _unset,
  }) => NarrationState(
    status: status ?? this.status,
    voices: voices ?? this.voices,
    settings: settings ?? this.settings,
    usesBookOverride: usesBookOverride ?? this.usesBookOverride,
    bookId: identical(bookId, _unset) ? this.bookId : bookId as String?,
    activeRunId: identical(activeRunId, _unset)
        ? this.activeRunId
        : activeRunId as String?,
    chapterId: identical(chapterId, _unset)
        ? this.chapterId
        : chapterId as String?,
    blockId: identical(blockId, _unset) ? this.blockId : blockId as String?,
    chapterTitle: identical(chapterTitle, _unset)
        ? this.chapterTitle
        : chapterTitle as String?,
    canPrevious: canPrevious ?? this.canPrevious,
    canNext: canNext ?? this.canNext,
    message: identical(message, _unset) ? this.message : message as String?,
  );
}

const Object _unset = Object();
