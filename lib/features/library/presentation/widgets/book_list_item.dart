import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

String bookStatusLabel(BookStatus status) => switch (status) {
  BookStatus.importing => 'Importando',
  BookStatus.processing => 'Processando',
  BookStatus.ready => 'Pronto',
  BookStatus.failed => 'Falhou',
  BookStatus.unsupported => 'Não suportado',
};

final class BookListItem extends StatelessWidget {
  const BookListItem({
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
    child: ListTile(
      title: Text(book.title),
      subtitle: Text(
        [
          if (book.author?.isNotEmpty ?? false) book.author!,
          bookStatusLabel(book.status),
        ].join(' • '),
      ),
      trailing: _BookActions(book: book, onEdit: onEdit, onDelete: onDelete),
    ),
  );
}

final class _BookActions extends StatelessWidget {
  const _BookActions({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });
  final Book book;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
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
  );
}
