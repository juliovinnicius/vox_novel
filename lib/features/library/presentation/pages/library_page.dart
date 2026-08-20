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
          IconButton(
            tooltip: 'Visualização em lista',
            isSelected: state.layout == LibraryLayout.list,
            onPressed: context.read<LibraryCubit>().showList,
            icon: const Icon(Icons.view_list),
          ),
          IconButton(
            tooltip: 'Visualização em grade',
            isSelected: state.layout == LibraryLayout.grid,
            onPressed: context.read<LibraryCubit>().showGrid,
            icon: const Icon(Icons.grid_view),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (state.books.isEmpty && !state.loading)
            const Center(child: Text('Sua biblioteca está vazia'))
          else if (state.layout == LibraryLayout.list)
            ListView.builder(
              itemCount: state.books.length,
              itemBuilder: (context, index) =>
                  _listItem(context, state.books[index]),
            )
          else
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: state.books.length,
              itemBuilder: (context, index) =>
                  _gridItem(context, state.books[index]),
            ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
      floatingActionButton: _importActions(context, busy: busy),
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
