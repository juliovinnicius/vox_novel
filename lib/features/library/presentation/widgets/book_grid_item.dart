import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_visuals.dart';

final class BookGridItem extends StatelessWidget {
  const BookGridItem({
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
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // The cover shrinks instead of overflowing when a long
                    // title or a large system font eats the card's height.
                    Center(
                      child: FittedBox(child: BookCover(book: book, size: 72)),
                    ),
                    if (openable)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: BookAction(
                          tooltip: 'Abrir ${book.title}',
                          icon: Icons.play_arrow_rounded,
                          emphasized: true,
                          onPressed: () => onOpen!(book),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (book.author?.isNotEmpty ?? false)
                Text(
                  book.author!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              if (progress == null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: BookStatusChip(
                    status: book.status,
                    label: bookStatusLabel(book.status),
                  ),
                )
              else
                BookProgressLine(
                  label: progress.label,
                  progress: progress.progress,
                ),
              const SizedBox(height: 4),
              BookActions(
                book: book,
                showOpen: false,
                onEdit: onEdit,
                onDelete: onDelete,
                onOpen: onOpen,
                onCancelProcessing: onCancelProcessing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
