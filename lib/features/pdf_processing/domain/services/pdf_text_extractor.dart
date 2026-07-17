enum PdfExtractionFailureKind { corrupt, passwordProtected, unavailable }

final class PdfExtractionRequest {
  const PdfExtractionRequest({required this.runId, required this.filePath});
  final String runId;
  final String filePath;
}

sealed class PdfExtractionEvent {
  const PdfExtractionEvent(this.runId);
  final String runId;
}

final class PdfExtractionOpened extends PdfExtractionEvent {
  const PdfExtractionOpened(super.runId, this.pageCount, this.workerIdentity);
  final int pageCount;
  final int workerIdentity;
}

final class PdfExtractionPage extends PdfExtractionEvent {
  const PdfExtractionPage(
    super.runId,
    this.pageNumber,
    this.pageCount,
    this.text,
  );
  final int pageNumber;
  final int pageCount;
  final String text;
}

final class PdfExtractionCompleted extends PdfExtractionEvent {
  const PdfExtractionCompleted(super.runId, this.pageCount);
  final int pageCount;
}

final class PdfExtractionFailed extends PdfExtractionEvent {
  const PdfExtractionFailed(super.runId, this.kind);
  final PdfExtractionFailureKind kind;
}

abstract interface class PdfTextExtractor {
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request);
  Future<void> cancel(String runId);
}
