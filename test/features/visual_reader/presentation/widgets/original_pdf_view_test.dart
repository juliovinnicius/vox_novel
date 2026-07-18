import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/original_pdf_view.dart';

void main() {
  late PdfSurfaceSpec spec;
  late _FakeController controller;
  var builds = 0;

  Widget builder(PdfSurfaceSpec value) {
    spec = value;
    builds++;
    return const ColoredBox(color: Colors.grey);
  }

  Future<void> pump(
    WidgetTester tester, {
    int page = 2,
    int pages = 5,
    String path = '/books/original.pdf',
    ValueChanged<int>? onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OriginalPdfView(
          path: path,
          initialPage: page,
          expectedPages: pages,
          onPageChanged: onChanged ?? (_) {},
          surfaceBuilder: builder,
        ),
      ),
    ),
  );

  setUp(() {
    controller = _FakeController();
    builds = 0;
  });

  testWidgets('passes path and one-based initial page to the surface', (
    tester,
  ) async {
    await pump(tester, page: 3);
    expect(spec.path, '/books/original.pdf');
    expect(spec.initialPage, 3);
    expect(find.text('Página 3 de 5'), findsOneWidget);
  });

  testWidgets('reports valid page changes and updates exact label', (
    tester,
  ) async {
    final changes = <int>[];
    await pump(tester, onChanged: changes.add);

    spec.onPageChanged(4);
    await tester.pump();
    expect(changes, [4]);
    expect(find.text('Página 4 de 5'), findsOneWidget);

    spec.onPageChanged(0);
    spec.onPageChanged(6);
    spec.onPageChanged(4);
    await tester.pump();
    expect(changes, [4]);
  });

  testWidgets('syncs external page through controller without loops', (
    tester,
  ) async {
    final changes = <int>[];
    await pump(tester, onChanged: changes.add);
    spec.onControllerReady(controller);

    await pump(tester, page: 4, onChanged: changes.add);
    expect(controller.pages, [4]);
    expect(changes, isEmpty);

    spec.onPageChanged(4);
    await tester.pump();
    expect(controller.pages, [4]);
    expect(changes, isEmpty);
  });

  testWidgets('rebuilds the surface for a changed path', (tester) async {
    await pump(tester);
    spec.onControllerReady(controller);
    await pump(tester, path: '/books/replacement.pdf', page: 1);

    expect(spec.path, '/books/replacement.pdf');
    expect(spec.initialPage, 1);
    expect(controller.pages, isEmpty);
    expect(builds, 2);
  });

  testWidgets('shows the standard message for invalid input or errors', (
    tester,
  ) async {
    await pump(tester, path: '');
    expect(find.text('Não foi possível abrir o PDF original'), findsOneWidget);

    await pump(tester);
    spec.onError();
    await tester.pump();
    expect(find.text('Não foi possível abrir o PDF original'), findsOneWidget);
  });
}

final class _FakeController implements PdfPageController {
  final pages = <int>[];

  @override
  Future<void> goToPage(int page) async {
    pages.add(page);
  }
}
