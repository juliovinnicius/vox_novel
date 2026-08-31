import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_visuals.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';

String bookStatusLabel(BookStatus status) => switch (status) {
  BookStatus.importing => 'Importando',
  BookStatus.processing => 'Processando',
  BookStatus.ready => 'Pronto',
  BookStatus.failed => 'Falhou',
  BookStatus.unsupported => 'Não suportado',
};

/// Whether the reader can be opened for [book].
///
/// A web book becomes readable at its first stored chapter and stays readable
/// while the rest of its queue drains; a PDF book has no partial-readability
/// semantics and still has to finish processing.
bool bookCanOpen(Book book) =>
    book.status == BookStatus.ready ||
    book.sourceType == BookSourceType.web &&
        book.status == BookStatus.processing &&
        book.chapterCount > 0;

/// The download line of a web book: chapters stored over chapters indexed.
String? bookDownloadLabel(Book book) =>
    book.sourceType == BookSourceType.web &&
        book.status == BookStatus.processing
    ? '${ProcessingStage.downloading.label} • '
          '${book.chapterCount}/${book.pageCount}'
    : null;

/// The progress line a book shows while it is being brought in, or null when
/// there is nothing running.
({String label, double progress})? bookProgress(Book book) {
  if (bookDownloadLabel(book) case final download?) {
    return (label: download, progress: book.processingProgress);
  }
  if (book.status == BookStatus.processing && book.processingStage != null) {
    return (
      label:
          '${book.processingStage!.label} • '
          '${(book.processingProgress * 100).round()}%',
      progress: book.processingProgress,
    );
  }
  return null;
}

final class BookListItem extends StatelessWidget {
  const BookListItem({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    this.onOpen,
    this.onCancelProcessing,
    super.key,
  });
  final Book book;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;
  final ValueChanged<Book>? onOpen;
  final ValueChanged<Book>? onCancelProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = bookProgress(book);
    final openable = bookCanOpen(book) && onOpen != null;
    return Card(
      key: ValueKey(book.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: openable ? () => onOpen!(book) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(book: book, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (book.author?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      BookProgressLine(
                        label: progress.label,
                        progress: progress.progress,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // A running import already names its stage above, so
                        // the pill would only repeat it.
                        if (progress == null)
                          BookStatusChip(
                            status: book.status,
                            label: bookStatusLabel(book.status),
                          ),
                        const Spacer(),
                        BookActions(
                          book: book,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onOpen: onOpen,
                          onCancelProcessing: onCancelProcessing,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The four library actions. Kept in one widget so the list and the grid
/// always offer exactly the same affordances with the same labels.
final class BookActions extends StatelessWidget {
  const BookActions({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
    required this.onCancelProcessing,
    this.alignment = WrapAlignment.end,
    this.showOpen = true,
    super.key,
  });
  final Book book;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;
  final ValueChanged<Book>? onOpen;
  final ValueChanged<Book>? onCancelProcessing;
  final WrapAlignment alignment;

  /// The grid puts the open affordance on the cover instead, where it reads as
  /// a play button and leaves room for the remaining actions on one line.
  final bool showOpen;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: alignment,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (showOpen && bookCanOpen(book) && onOpen != null)
        BookAction(
          tooltip: 'Abrir ${book.title}',
          icon: Icons.play_arrow_rounded,
          emphasized: true,
          onPressed: () => onOpen!(book),
        ),
      if (book.status == BookStatus.processing && onCancelProcessing != null)
        BookAction(
          tooltip: 'Cancelar processamento de ${book.title}',
          icon: Icons.close_rounded,
          onPressed: () => onCancelProcessing!(book),
        ),
      BookAction(
        tooltip: 'Editar ${book.title}',
        icon: Icons.edit_outlined,
        onPressed: () => onEdit(book),
      ),
      BookAction(
        tooltip: 'Excluir ${book.title}',
        icon: Icons.delete_outline_rounded,
        onPressed: () => onDelete(book),
      ),
    ],
  );
}
