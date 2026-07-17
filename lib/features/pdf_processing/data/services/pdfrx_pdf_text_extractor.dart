import 'dart:async';
import 'dart:isolate';

import 'package:pdfrx/pdfrx.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';

final class PdfrxPdfTextExtractor implements PdfTextExtractor {
  PdfrxPdfTextExtractor({this.pdfiumModulePath});

  final String? pdfiumModulePath;
  final Map<String, _ActiveExtraction> _active = {};

  @override
  Stream<PdfExtractionEvent> extract(PdfExtractionRequest request) {
    late StreamController<PdfExtractionEvent> controller;
    controller = StreamController(
      onListen: () => _start(request, controller),
      onCancel: () => cancel(request.runId),
    );
    return controller.stream;
  }

  Future<void> _start(
    PdfExtractionRequest request,
    StreamController<PdfExtractionEvent> controller,
  ) async {
    if (_active.containsKey(request.runId)) {
      controller.add(
        PdfExtractionFailed(
          request.runId,
          PdfExtractionFailureKind.unavailable,
        ),
      );
      await controller.close();
      return;
    }
    final port = ReceivePort();
    final active = _ActiveExtraction(port, controller);
    _active[request.runId] = active;
    port.listen((message) => _receive(request.runId, message));
    try {
      active.isolate = await Isolate.spawn(_extractInWorker, (
        port.sendPort,
        request.runId,
        request.filePath,
        pdfiumModulePath,
      ), onError: port.sendPort);
    } catch (_) {
      controller.add(
        PdfExtractionFailed(
          request.runId,
          PdfExtractionFailureKind.unavailable,
        ),
      );
      await _finish(request.runId);
    }
  }

  void _receive(String runId, Object? message) {
    final active = _active[runId];
    if (active == null || message is! Map) return;
    switch (message['type']) {
      case 'opened':
        active.controller.add(
          PdfExtractionOpened(
            runId,
            message['pageCount'] as int,
            message['workerIdentity'] as int,
          ),
        );
      case 'page':
        active.controller.add(
          PdfExtractionPage(
            runId,
            message['pageNumber'] as int,
            message['pageCount'] as int,
            message['text'] as String,
          ),
        );
      case 'completed':
        active.controller.add(
          PdfExtractionCompleted(runId, message['pageCount'] as int),
        );
        unawaited(_finish(runId));
      case 'failed':
        active.controller.add(
          PdfExtractionFailed(
            runId,
            PdfExtractionFailureKind.values.byName(message['kind'] as String),
          ),
        );
        unawaited(_finish(runId));
    }
  }

  @override
  Future<void> cancel(String runId) async {
    final active = _active.remove(runId);
    if (active == null) return;
    active.isolate?.kill(priority: Isolate.immediate);
    active.port.close();
    if (!active.controller.isClosed) {
      unawaited(active.controller.close());
    }
  }

  Future<void> _finish(String runId) async {
    final active = _active.remove(runId);
    if (active == null) return;
    active.port.close();
    if (!active.controller.isClosed) await active.controller.close();
  }
}

final class _ActiveExtraction {
  _ActiveExtraction(this.port, this.controller);
  final ReceivePort port;
  final StreamController<PdfExtractionEvent> controller;
  Isolate? isolate;
}

Future<void> _extractInWorker(
  (SendPort, String, String, String?) arguments,
) async {
  final (sendPort, _, filePath, modulePath) = arguments;
  PdfDocument? document;
  try {
    Pdfrx.pdfiumModulePath = modulePath;
    await pdfrxInitialize();
    document = await PdfDocument.openFile(filePath);
    final pageCount = document.pages.length;
    sendPort.send({
      'type': 'opened',
      'pageCount': pageCount,
      'workerIdentity': Isolate.current.hashCode,
    });
    for (final page in document.pages) {
      final text = await page.loadText();
      sendPort.send({
        'type': 'page',
        'pageNumber': page.pageNumber,
        'pageCount': pageCount,
        'text': text?.fullText ?? '',
      });
    }
    sendPort.send({'type': 'completed', 'pageCount': pageCount});
  } on PdfPasswordException {
    sendPort.send({
      'type': 'failed',
      'kind': PdfExtractionFailureKind.passwordProtected.name,
    });
  } on PdfException {
    sendPort.send({
      'type': 'failed',
      'kind': PdfExtractionFailureKind.corrupt.name,
    });
  } catch (_) {
    sendPort.send({
      'type': 'failed',
      'kind': PdfExtractionFailureKind.unavailable.name,
    });
  } finally {
    await document?.dispose();
  }
}
