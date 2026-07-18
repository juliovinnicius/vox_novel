import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';

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
  Widget build(BuildContext context) => Card(
    key: ValueKey(book.id),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.title, style: Theme.of(context).textTheme.titleMedium),
          if (book.author?.isNotEmpty ?? false) Text(book.author!),
          Text(bookStatusLabel(book.status)),
          if (book.status == BookStatus.processing &&
              book.processingStage != null) ...[
            Text(
              '${book.processingStage!.label} • '
              '${(book.processingProgress * 100).round()}%',
            ),
            LinearProgressIndicator(value: book.processingProgress),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (book.status == BookStatus.ready && onOpen != null)
                IconButton(
                  tooltip: 'Abrir ${book.title}',
                  onPressed: () => onOpen!(book),
                  icon: const Icon(Icons.chrome_reader_mode),
                ),
              if (book.status == BookStatus.processing &&
                  onCancelProcessing != null)
                IconButton(
                  tooltip: 'Cancelar processamento de ${book.title}',
                  onPressed: () => onCancelProcessing!(book),
                  icon: const Icon(Icons.cancel),
                ),
              IconButton(
                tooltip: 'Editar ${book.title}',
                onPressed: () => onEdit(book),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'Excluir ${book.title}',
                onPressed: () => onDelete(book),
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
