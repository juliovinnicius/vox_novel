import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/presentation/widgets/book_list_item.dart';

final class BookGridItem extends StatelessWidget {
  const BookGridItem({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final Book book;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;
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
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
