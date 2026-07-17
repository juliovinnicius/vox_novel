import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/data/services/pdfrx_pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';

void main() {
  late PdfrxPdfTextExtractor extractor;

  setUpAll(() {
    final name = Platform.isMacOS
        ? 'libpdfium.dylib'
        : Platform.isLinux
        ? 'libpdfium.so'
        : 'pdfium.dll';
    final candidates = Directory.current
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith(name))
        .toList();
    if (candidates.isEmpty) {
      throw StateError('Generated PDFium native asset $name was not found');
    }
    extractor = PdfrxPdfTextExtractor(pdfiumModulePath: candidates.first.path);
  });

  PdfExtractionRequest request(String id, String fixture) =>
      PdfExtractionRequest(runId: id, filePath: 'test/fixtures/$fixture');

  test('emits exact ordered pages, empty text and completion', () async {
    final events = await extractor
        .extract(request('ordered', 'selectable_three_pages.pdf'))
        .toList();
    expect(events, hasLength(5));
    final opened = events.first as PdfExtractionOpened;
    expect(opened.runId, 'ordered');
    expect(opened.pageCount, 3);
    final pages = events.whereType<PdfExtractionPage>().toList();
    expect(pages.map((e) => e.pageNumber), [1, 2, 3]);
    expect(pages.map((e) => e.pageCount), [3, 3, 3]);
    expect(pages.map((e) => e.text), [
      'Primeira pagina',
      '',
      'Terceira pagina',
    ]);
    expect((events.last as PdfExtractionCompleted).pageCount, 3);
  });

  test('uses a non-caller isolate', () async {
    final event = await extractor
        .extract(request('isolate', 'selectable_three_pages.pdf'))
        .first;
    expect(
      (event as PdfExtractionOpened).workerIdentity,
      isNot(Isolate.current.hashCode),
    );
  });

  test('corrupt input emits only a sanitized failure', () async {
    final events = await extractor
        .extract(request('corrupt', 'corrupt.pdf'))
        .toList();
    expect(events, hasLength(1));
    expect(
      (events.single as PdfExtractionFailed).kind,
      PdfExtractionFailureKind.corrupt,
    );
    expect(events.whereType<PdfExtractionPage>(), isEmpty);
  });

  test('password-protected input emits only a sanitized failure', () async {
    final encoded = await File(
      'test/fixtures/encrypted.pdf.b64',
    ).readAsString();
    final protectedFile = File(
      '${Directory.systemTemp.path}/vox-protected-${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    await protectedFile.writeAsBytes(base64Decode(encoded.trim()));
    addTearDown(() => protectedFile.delete());

    final events = await extractor
        .extract(
          PdfExtractionRequest(
            runId: 'protected',
            filePath: protectedFile.path,
          ),
        )
        .toList();

    expect(events, hasLength(1));
    expect(
      (events.single as PdfExtractionFailed).kind,
      PdfExtractionFailureKind.passwordProtected,
    );
    expect(events.whereType<PdfExtractionPage>(), isEmpty);
  });

  test('missing input emits one sanitized corrupt-input failure', () async {
    final events = await extractor
        .extract(request('missing', 'missing.pdf'))
        .toList();
    expect(events, hasLength(1));
    expect(
      (events.single as PdfExtractionFailed).kind,
      PdfExtractionFailureKind.corrupt,
    );
  });

  test('cancellation closes before the next page event', () async {
    final events = <PdfExtractionEvent>[];
    final done = Completer<void>();
    late StreamSubscription<PdfExtractionEvent> subscription;
    subscription = extractor
        .extract(request('cancel', 'selectable_three_pages.pdf'))
        .listen((event) async {
          events.add(event);
          if (event is PdfExtractionOpened) {
            await extractor.cancel('cancel');
            done.complete();
          }
        });
    await done.future;
    await subscription.asFuture<void>();
    expect(events, [isA<PdfExtractionOpened>()]);
  });

  test('completed run is reusable without duplicate events', () async {
    for (var i = 0; i < 2; i++) {
      final events = await extractor
          .extract(request('reused', 'selectable_three_pages.pdf'))
          .toList();
      expect(events.whereType<PdfExtractionOpened>(), hasLength(1));
      expect(events.whereType<PdfExtractionPage>(), hasLength(3));
      expect(events.whereType<PdfExtractionCompleted>(), hasLength(1));
    }
  });

  test('cancel after completion and unknown cancel are harmless', () async {
    final events = await extractor
        .extract(request('complete', 'selectable_three_pages.pdf'))
        .toList();
    await extractor.cancel('complete');
    await extractor.cancel('unknown');
    expect(events.last, isA<PdfExtractionCompleted>());
  });
}
