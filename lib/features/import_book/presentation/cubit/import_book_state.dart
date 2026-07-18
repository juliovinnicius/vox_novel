enum ImportBookStatus { idle, selecting, importing, processing }

final class ImportBookState {
  const ImportBookState({
    this.status = ImportBookStatus.idle,
    this.errorMessage,
  });

  final ImportBookStatus status;
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      other is ImportBookState &&
      other.status == status &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, errorMessage);
}
