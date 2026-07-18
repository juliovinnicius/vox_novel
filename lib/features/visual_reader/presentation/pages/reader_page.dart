import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_cubit.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_state.dart';
import 'package:vox_novel/features/visual_reader/presentation/theme/reader_theme.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/chapter_drawer.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/original_pdf_view.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/reader_settings_sheet.dart';
import 'package:vox_novel/features/visual_reader/presentation/widgets/text_reader_view.dart';

final class ReaderPage extends StatefulWidget {
  const ReaderPage({
    required this.bookId,
    required this.cubit,
    this.pdfSurfaceBuilder = buildPdfrxSurface,
    super.key,
  });

  final String bookId;
  final VisualReaderCubit cubit;
  final PdfSurfaceBuilder pdfSurfaceBuilder;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

final class _ReaderPageState extends State<ReaderPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollControllers = <String, ScrollController>{};
  String? _lastScrolledBlock;

  @override
  void initState() {
    super.initState();
    unawaited(widget.cubit.load(widget.bookId));
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    unawaited(widget.cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocListener<VisualReaderCubit, VisualReaderState>(
        listenWhen: (previous, current) =>
            current.status == VisualReaderStatus.ready &&
            current.message != null &&
            previous.message != current.message,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
          widget.cubit.clearMessage();
        },
        child: BlocBuilder<VisualReaderCubit, VisualReaderState>(
          builder: _buildState,
        ),
      ),
    );
  }

  Widget _buildState(BuildContext context, VisualReaderState state) {
    if (state.status == VisualReaderStatus.initial ||
        state.status == VisualReaderStatus.loading) {
      return const Scaffold(
        appBar: _ReaderLoadingAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.status == VisualReaderStatus.unavailable ||
        state.content == null ||
        state.settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leitor')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Conteúdo do livro indisponível'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Voltar à biblioteca'),
              ),
            ],
          ),
        ),
      );
    }

    final content = state.content!;
    final settings = state.settings!;
    final chapter = content.chapters
        .where((item) => item.chapter.id == state.chapterId)
        .firstOrNull;
    final palette = ReaderVisualTheme.palette(settings.theme);
    _scheduleScroll(chapter, state.blockId);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.background,
      endDrawer: ChapterDrawer(
        chapters: content.chapters,
        currentChapterId: state.chapterId,
        onChapterSelected: widget.cubit.selectChapter,
      ),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(content.book.title)),
        actions: [
          IconButton(
            tooltip: state.mode == ReaderMode.text
                ? 'Ver PDF original'
                : 'Ver texto reformatado',
            onPressed: state.mode == ReaderMode.text
                ? widget.cubit.showPdf
                : widget.cubit.showText,
            icon: Icon(
              state.mode == ReaderMode.text
                  ? Icons.picture_as_pdf_outlined
                  : Icons.notes,
            ),
          ),
          IconButton(
            tooltip: 'Capítulos',
            onPressed: content.chapters.isEmpty
                ? null
                : () => _scaffoldKey.currentState?.openEndDrawer(),
            icon: const Icon(Icons.menu_book),
          ),
          IconButton(
            tooltip: 'Configurações do leitor',
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.text_format),
          ),
        ],
      ),
      body: state.mode == ReaderMode.pdf
          ? OriginalPdfView(
              path: content.book.storedFilePath,
              initialPage: state.pdfPage,
              expectedPages: content.book.pageCount,
              onPageChanged: widget.cubit.pageChanged,
              surfaceBuilder: widget.pdfSurfaceBuilder,
            )
          : chapter == null
          ? const Center(child: Text('Este capítulo não possui texto'))
          : Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primaryContainer: palette.selectedBackground,
                  onPrimaryContainer: palette.selectedForeground,
                ),
              ),
              child: TextReaderView(
                chapter: chapter,
                selectedBlockId: state.blockId,
                onBlockSelected: (blockId) =>
                    widget.cubit.selectBlock(chapter.chapter.id, blockId),
                onPreviousChapter: widget.cubit.previousChapter,
                onNextChapter: widget.cubit.nextChapter,
                hasPreviousChapter: chapter.chapter.sortOrder > 0,
                hasNextChapter:
                    chapter.chapter.sortOrder < content.chapters.length - 1,
                controller: _scrollControllers.putIfAbsent(
                  chapter.chapter.id,
                  ScrollController.new,
                ),
                textStyle: ReaderVisualTheme.textStyle(settings),
              ),
            ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: widget.cubit,
        child: BlocBuilder<VisualReaderCubit, VisualReaderState>(
          builder: (context, state) => ReaderSettingsSheet(
            settings: state.settings!,
            onThemeChanged: widget.cubit.setTheme,
            onFontFamilyChanged: widget.cubit.setFontFamily,
            onLineHeightChanged: widget.cubit.setLineHeight,
            onIncreaseFont: widget.cubit.increaseFont,
            onDecreaseFont: widget.cubit.decreaseFont,
          ),
        ),
      ),
    );
  }

  void _scheduleScroll(ReaderChapter? chapter, String? blockId) {
    if (chapter == null ||
        blockId == null ||
        blockId == _lastScrolledBlock ||
        chapter.blocks.isEmpty) {
      return;
    }
    _lastScrolledBlock = blockId;
    final index = chapter.blocks.indexWhere((block) => block.id == blockId);
    if (index < 0) return;
    final controller = _scrollControllers.putIfAbsent(
      chapter.chapter.id,
      ScrollController.new,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpTo(
        (index * 80.0).clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent,
        ),
      );
    });
  }
}

class _ReaderLoadingAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ReaderLoadingAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Leitor'));
}
