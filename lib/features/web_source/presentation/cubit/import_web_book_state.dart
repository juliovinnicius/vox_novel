enum ImportWebBookStatus { idle, submitting, success }

final class ImportWebBookState {
  const ImportWebBookState({
    this.status = ImportWebBookStatus.idle,
    this.importedBookId,
    this.errorMessage,
  });

  final ImportWebBookStatus status;

  /// The book the last successful submission resolved to.
  final String? importedBookId;
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      other is ImportWebBookState &&
      other.status == status &&
      other.importedBookId == importedBookId &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, importedBookId, errorMessage);
}
