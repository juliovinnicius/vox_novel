import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/narration/presentation/cubit/narration_cubit.dart';
import 'package:vox_novel/features/narration/presentation/widgets/reader_narration_host.dart';
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
    this.closeCubit,
    this.narrationCubit,
    this.narrationActivation,
    this.closeNarrationCubit,
    super.key,
  });

  final String bookId;
  final VisualReaderCubit cubit;
  final PdfSurfaceBuilder pdfSurfaceBuilder;
  final Future<void> Function(VisualReaderCubit cubit)? closeCubit;
  final NarrationCubit? narrationCubit;
  final Future<void>? narrationActivation;
  final Future<void> Function(NarrationCubit cubit)? closeNarrationCubit;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

final class _ReaderPageState extends State<ReaderPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollControllers = <String, ScrollController>{};
  String? _lastScrolledBlock;

  /// The app bar steps aside while the reader scrolls into the chapter and
  /// comes back on the first scroll upwards.
  bool _chromeVisible = true;

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
    unawaited(widget.closeCubit?.call(widget.cubit) ?? widget.cubit.close());
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
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Conteúdo do livro indisponível',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Voltar à biblioteca'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final content = state.content!;
    final settings = state.settings!;
    final chapter = content.chapters
        .where((item) => item.chapter.id == state.chapterId)
        .firstOrNull;
    // A web book has no local document, so the reader offers only the text
    // view and never mounts the original-document surface.
    final hasOriginal = content.book.storedFilePath != null;
    // A failed chapter leaves a hole, so neighbours come from the position in
    // the loaded list, never from the chapter's sort order.
    final position = chapter == null ? -1 : content.chapters.indexOf(chapter);
    final palette = ReaderVisualTheme.palette(settings.theme);
    _scheduleScroll(chapter, state.blockId);

    Widget scaffold(BuildContext context, Widget? playerBar) => Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.background,
      bottomNavigationBar: playerBar,
      endDrawer: ChapterDrawer(
        chapters: content.chapters,
        currentChapterId: state.chapterId,
        onChapterSelected: _selectChapter,
      ),
      appBar: _CollapsingAppBar(
        // The PDF surface has its own gestures, so only the text view earns
        // the extra height.
        visible: _chromeVisible || state.mode == ReaderMode.pdf,
        child: AppBar(
          title: Semantics(
            header: true,
            child: Text(
              content.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            if (hasOriginal)
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
      ),
      body: state.mode == ReaderMode.pdf && hasOriginal
          ? OriginalPdfView(
              path: content.book.storedFilePath!,
              initialPage: state.pdfPage,
              expectedPages: content.book.pageCount,
              onPageChanged: widget.cubit.pageChanged,
              surfaceBuilder: widget.pdfSurfaceBuilder,
            )
          : chapter == null
          ? const Center(child: Text('Este capítulo não possui texto'))
          : NotificationListener<UserScrollNotification>(
              onNotification: _followScroll,
              child: TextReaderView(
                chapter: chapter,
                selectedBlockId: state.blockId,
                onBlockSelected: (blockId) =>
                    _selectBlock(chapter.chapter.id, blockId),
                onPreviousChapter: _previousChapter,
                onNextChapter: _nextChapter,
                hasPreviousChapter: position > 0,
                hasNextChapter: position < content.chapters.length - 1,
                controller: _scrollControllers.putIfAbsent(
                  chapter.chapter.id,
                  ScrollController.new,
                ),
                textStyle: ReaderVisualTheme.textStyle(settings),
              ),
            ),
    );

    Widget buildReader(Widget? playerBar) => Theme(
      data: ReaderVisualTheme.chrome(Theme.of(context), palette),
      child: Builder(builder: (inner) => scaffold(inner, playerBar)),
    );

    final narrationCubit = widget.narrationCubit;
    if (narrationCubit == null) return buildReader(null);
    return ReaderNarrationHost(
      content: content,
      cubit: narrationCubit,
      activation: widget.narrationActivation,
      onNarrationFocus: widget.cubit.followNarration,
      closeCubit: widget.closeNarrationCubit,
      builder: (_, playerBar) => buildReader(playerBar),
    );
  }

  bool _followScroll(UserScrollNotification notification) {
    if (notification.depth != 0) return false;
    final hide = notification.direction == ScrollDirection.reverse;
    final show = notification.direction == ScrollDirection.forward;
    if (hide && _chromeVisible) {
      setState(() => _chromeVisible = false);
    } else if (show && !_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
    return false;
  }

  void _selectBlock(String chapterId, String blockId) {
    widget.cubit.selectBlock(chapterId, blockId);
    widget.narrationCubit?.setPendingStart(chapterId, blockId);
  }

  void _selectChapter(String chapterId) {
    setState(() => _chromeVisible = true);
    widget.cubit.selectChapter(chapterId);
    _startNarrationWhereTheReaderIs();
  }

  void _previousChapter() {
    widget.cubit.previousChapter();
    _startNarrationWhereTheReaderIs();
  }

  void _nextChapter() {
    widget.cubit.nextChapter();
    _startNarrationWhereTheReaderIs();
  }

  /// Play starts from the chapter the reader is showing.
  ///
  /// AD-007 keeps the visual position and narration progress separate, and
  /// that still holds — nothing durable is written here. What changes is only
  /// where the *next* play begins: jumping to chapter 236 and pressing play
  /// used to narrate chapter 1, because only tapping a paragraph ever told
  /// narration where the reader had gone.
  void _startNarrationWhereTheReaderIs() {
    final narration = widget.narrationCubit;
    if (narration == null) return;
    final state = widget.cubit.state;
    final chapterId = state.chapterId;
    final blockId = state.blockId;
    if (chapterId == null || blockId == null) return;
    narration.setPendingStart(chapterId, blockId);
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

/// Gives the app bar's height back to the page while keeping the widget — and
/// its actions — mounted.
///
/// `Scaffold` adds the status bar inset itself, so only the toolbar part
/// collapses and the text never slides under the system clock.
final class _CollapsingAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _CollapsingAppBar({required this.visible, required this.child});

  final bool visible;
  final AppBar child;

  @override
  Size get preferredSize => Size.fromHeight(visible ? kToolbarHeight : 0);

  @override
  Widget build(BuildContext context) {
    final full = kToolbarHeight + MediaQuery.viewPaddingOf(context).top;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: full,
        maxHeight: full,
        child: child,
      ),
    );
  }
}
