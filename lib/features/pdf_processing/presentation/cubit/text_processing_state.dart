enum TextProcessingStatus { idle, processing, cancelling }

final class TextProcessingState {
  const TextProcessingState({
    this.status = TextProcessingStatus.idle,
    this.activeBookId,
    this.message,
  });

  final TextProcessingStatus status;
  final String? activeBookId;
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is TextProcessingState &&
      other.status == status &&
      other.activeBookId == activeBookId &&
      other.message == message;

  @override
  int get hashCode => Object.hash(status, activeBookId, message);
}
