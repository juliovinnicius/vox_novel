import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

abstract interface class PdfPageController {
  Future<void> goToPage(int page);
}

final class PdfSurfaceSpec {
  const PdfSurfaceSpec({
    required this.path,
    required this.initialPage,
    required this.onPageChanged,
    required this.onControllerReady,
    required this.onError,
  });

  final String path;
  final int initialPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<PdfPageController> onControllerReady;
  final VoidCallback onError;
}

typedef PdfSurfaceBuilder = Widget Function(PdfSurfaceSpec spec);

class OriginalPdfView extends StatefulWidget {
  const OriginalPdfView({
    required this.path,
    required this.initialPage,
    required this.expectedPages,
    required this.onPageChanged,
    this.surfaceBuilder = buildPdfrxSurface,
    super.key,
  });

  final String path;
  final int initialPage;
  final int expectedPages;
  final ValueChanged<int> onPageChanged;
  final PdfSurfaceBuilder surfaceBuilder;

  @override
  State<OriginalPdfView> createState() => _OriginalPdfViewState();
}

class _OriginalPdfViewState extends State<OriginalPdfView> {
  PdfPageController? _controller;
  late int _visiblePage;
  var _failed = false;

  bool get _valid =>
      widget.path.isNotEmpty &&
      widget.expectedPages > 0 &&
      widget.initialPage >= 1 &&
      widget.initialPage <= widget.expectedPages;

  @override
  void initState() {
    super.initState();
    _visiblePage = widget.initialPage;
    _failed = !_valid;
  }

  @override
  void didUpdateWidget(covariant OriginalPdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_valid) {
      setState(() => _failed = true);
      return;
    }
    if (widget.path != oldWidget.path) {
      _controller = null;
      _visiblePage = widget.initialPage;
      _failed = false;
      return;
    }
    if (widget.initialPage != _visiblePage) {
      _visiblePage = widget.initialPage;
      _controller?.goToPage(widget.initialPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(child: Text('Não foi possível abrir o PDF original'));
    }
    return Stack(
      children: [
        Positioned.fill(
          child: widget.surfaceBuilder(
            PdfSurfaceSpec(
              path: widget.path,
              initialPage: widget.initialPage,
              onPageChanged: _handlePageChanged,
              onControllerReady: (controller) => _controller = controller,
              onError: () {
                if (mounted) setState(() => _failed = true);
              },
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Semantics(
            liveRegion: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text('Página $_visiblePage de ${widget.expectedPages}'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handlePageChanged(int page) {
    if (page < 1 ||
        page > widget.expectedPages ||
        page == _visiblePage ||
        !mounted) {
      return;
    }
    setState(() => _visiblePage = page);
    widget.onPageChanged(page);
  }
}

Widget buildPdfrxSurface(PdfSurfaceSpec spec) =>
    _PdfrxSurface(key: ValueKey(spec.path), spec: spec);

class _PdfrxSurface extends StatefulWidget {
  const _PdfrxSurface({required this.spec, super.key});
  final PdfSurfaceSpec spec;

  @override
  State<_PdfrxSurface> createState() => _PdfrxSurfaceState();
}

class _PdfrxSurfaceState extends State<_PdfrxSurface>
    implements PdfPageController {
  final _controller = PdfViewerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.spec.onControllerReady(this);
    });
  }

  @override
  Future<void> goToPage(int page) =>
      _controller.goToPage(pageNumber: page, duration: Duration.zero);

  @override
  Widget build(BuildContext context) => PdfViewer.file(
    widget.spec.path,
    controller: _controller,
    initialPageNumber: widget.spec.initialPage,
    params: PdfViewerParams(
      onPageChanged: (page) {
        if (page != null) widget.spec.onPageChanged(page);
      },
      errorBannerBuilder: (context, error, stackTrace, documentRef) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.spec.onError();
        });
        return const SizedBox.shrink();
      },
    ),
  );
}
