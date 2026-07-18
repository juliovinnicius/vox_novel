import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';

enum VisualReaderStatus { initial, loading, ready, unavailable }

final class VisualReaderState {
  const VisualReaderState({
    this.status = VisualReaderStatus.initial,
    this.content,
    this.settings,
    this.mode = ReaderMode.text,
    this.chapterId,
    this.blockId,
    this.pdfPage = 1,
    this.message,
  });

  final VisualReaderStatus status;
  final ReaderBookContent? content;
  final ReaderSettings? settings;
  final ReaderMode mode;
  final String? chapterId;
  final String? blockId;
  final int pdfPage;
  final String? message;

  VisualReaderState copyWith({
    VisualReaderStatus? status,
    ReaderBookContent? content,
    ReaderSettings? settings,
    ReaderMode? mode,
    Object? chapterId = _unset,
    Object? blockId = _unset,
    int? pdfPage,
    Object? message = _unset,
  }) => VisualReaderState(
    status: status ?? this.status,
    content: content ?? this.content,
    settings: settings ?? this.settings,
    mode: mode ?? this.mode,
    chapterId: identical(chapterId, _unset)
        ? this.chapterId
        : chapterId as String?,
    blockId: identical(blockId, _unset) ? this.blockId : blockId as String?,
    pdfPage: pdfPage ?? this.pdfPage,
    message: identical(message, _unset) ? this.message : message as String?,
  );
}

const Object _unset = Object();
