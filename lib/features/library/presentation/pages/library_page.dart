import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_cubit.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_state.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_cubit.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_state.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_grid_item.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';
import 'package:vox_novel/features/library/presentation/widgets/delete_book_dialog.dart';
import 'package:vox_novel/features/library/presentation/widgets/edit_book_dialog.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_state.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_cubit.dart';
import 'package:vox_novel/features/web_source/presentation/widgets/import_web_book_dialog.dart';

/// Stops the chapter queue of the web book with this id.
typedef CancelWebDownload = Future<void> Function(String bookId);

final class LibraryPage extends StatefulWidget {
  const LibraryPage({
    required this.libraryCubit,
    required this.importBookCubit,
    this.textProcessingCubit,
    this.importWebBookCubit,
    this.cancelWebDownload,
    this.onOpenBook,
    super.key,
  });
  final LibraryCubit libraryCubit;
  final ImportBookCubit importBookCubit;
  final TextProcessingCubit? textProcessingCubit;
  final ImportWebBookCubit? importWebBookCubit;

  /// Stops a web book's chapter queue. A web book has no `TextProcessingService`
  /// run, so the shared cancel affordance needs this second route.
  final CancelWebDownload? cancelWebDownload;
  final ValueChanged<Book>? onOpenBook;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

final class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    widget.libraryCubit.start();
  }

  @override
  Widget build(BuildContext context) {
    final processingCubit = widget.textProcessingCubit;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.libraryCubit),
        BlocProvider.value(value: widget.importBookCubit),
        if (processingCubit != null) BlocProvider.value(value: processingCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ImportBookCubit, ImportBookState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage &&
                current.errorMessage != null,
            listener: (context, state) =>
                _message(context, state.errorMessage!),
          ),
          BlocListener<LibraryCubit, LibraryState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage &&
                current.errorMessage != null,
            listener: (context, state) =>
                _message(context, state.errorMessage!),
          ),
          if (processingCubit != null)
            BlocListener<TextProcessingCubit, TextProcessingState>(
              listenWhen: (previous, current) =>
                  previous.message != current.message &&
                  current.message != null,
              listener: (context, state) {
                _message(context, state.message!);
                processingCubit.clearMessage();
              },
            ),
        ],
        child: _LibraryView(
          processingCubit: processingCubit,
          importWebBookCubit: widget.importWebBookCubit,
          cancelWebDownload: widget.cancelWebDownload,
          onOpenBook: widget.onOpenBook,
        ),
      ),
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _LibraryView extends StatelessWidget {
  const _LibraryView({
    required this.processingCubit,
    required this.importWebBookCubit,
    required this.cancelWebDownload,
    required this.onOpenBook,
  });
  final TextProcessingCubit? processingCubit;
  final ImportWebBookCubit? importWebBookCubit;
  final CancelWebDownload? cancelWebDownload;
  final ValueChanged<Book>? onOpenBook;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryCubit>().state;
    final importing =
        context.watch<ImportBookCubit>().state.status != ImportBookStatus.idle;
    final processing =
        processingCubit != null &&
        context.watch<TextProcessingCubit>().state.status !=
            TextProcessingStatus.idle;
    final busy = importing || processing;
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text('Biblioteca')),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _layoutToggle(
                  context,
                  tooltip: 'Visualização em lista',
                  icon: Icons.view_agenda_outlined,
                  selected: state.layout == LibraryLayout.list,
                  onPressed: context.read<LibraryCubit>().showList,
                ),
                _layoutToggle(
                  context,
                  tooltip: 'Visualização em grade',
                  icon: Icons.grid_view_rounded,
                  selected: state.layout == LibraryLayout.grid,
                  onPressed: context.read<LibraryCubit>().showGrid,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (busy) const LinearProgressIndicator(minHeight: 3),
          Expanded(child: _books(context, state)),
        ],
      ),
      floatingActionButton: _importActions(context, busy: busy),
    );
  }

  Widget _layoutToggle(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? scheme.primary.withValues(alpha: 0.18)
            : null,
        foregroundColor: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      icon: Icon(icon, size: 20),
    );
  }

  Widget _books(BuildContext context, LibraryState state) {
    if (state.books.isEmpty && !state.loading) return const _EmptyLibrary();
    // Room for the floating import actions to hover over the last card.
    const padding = EdgeInsets.fromLTRB(16, 12, 16, 140);
    if (state.layout == LibraryLayout.list) {
      return ListView.separated(
        padding: padding,
        itemCount: state.books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _listItem(context, state.books[index]),
      );
    }
    return GridView.builder(
      padding: padding,
      // A fixed card height, not an aspect ratio: on a wide screen two
      // columns of a 0.6 ratio grow taller than the viewport.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 300,
      ),
      itemCount: state.books.length,
      itemBuilder: (context, index) => _gridItem(context, state.books[index]),
    );
  }

  Widget _importActions(BuildContext context, {required bool busy}) {
    final webCubit = importWebBookCubit;
    final pdf = FloatingActionButton.extended(
      heroTag: 'import-pdf',
      onPressed: busy ? null : context.read<ImportBookCubit>().importPdf,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Importar PDF'),
    );
    if (webCubit == null) return pdf;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'import-web',
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 1,
          onPressed: busy
              ? null
              : () => showImportWebBookDialog(context, webCubit),
          icon: const Icon(Icons.public),
          label: const Text('Importar da web'),
        ),
        const SizedBox(height: 12),
        pdf,
      ],
    );
  }

  Widget _listItem(BuildContext context, Book book) => BookListItem(
    book: book,
    onEdit: (book) => _edit(context, book),
    onDelete: (book) => _delete(context, book),
    onOpen: (book) => _open(context, book),
    onCancelProcessing: _cancelProcessing,
  );
  Widget _gridItem(BuildContext context, Book book) => BookGridItem(
    book: book,
    onEdit: (book) => _edit(context, book),
    onDelete: (book) => _delete(context, book),
    onOpen: (book) => _open(context, book),
    onCancelProcessing: _cancelProcessing,
  );

  /// A web book's queue lives in `WebNovelDownloadService`; only a PDF book has
  /// a processing run to cancel.
  ValueChanged<Book>? get _cancelProcessing {
    final cancelWeb = cancelWebDownload;
    final cancelPdf = processingCubit;
    if (cancelWeb == null && cancelPdf == null) return null;
    return (book) {
      if (book.sourceType == BookSourceType.web) {
        cancelWeb?.call(book.id);
        return;
      }
      cancelPdf?.cancel(book.id);
    };
  }

  void _open(BuildContext context, Book book) {
    final callback = onOpenBook;
    if (callback != null) {
      callback(book);
      return;
    }
    context.push('/reader/${Uri.encodeComponent(book.id)}');
  }

  Future<void> _edit(BuildContext context, Book book) async {
    final metadata = await showEditBookDialog(context, book);
    if (metadata != null && context.mounted) {
      await context.read<LibraryCubit>().updateMetadata(
        book: book,
        title: metadata.title,
        author: metadata.author,
      );
    }
  }

  Future<void> _delete(BuildContext context, Book book) async {
    if (await showDeleteBookDialog(context, book) && context.mounted) {
      await context.read<LibraryCubit>().deleteBook(book);
    }
  }
}

final class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceContainerHigh,
              ),
              child: Icon(
                Icons.auto_stories_outlined,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sua biblioteca está vazia',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Importe um PDF ou cole o link de uma novel para começar a ouvir.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
