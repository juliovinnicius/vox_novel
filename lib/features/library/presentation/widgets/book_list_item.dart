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
    this.onCancelProcessing,
    super.key,
  });
  final Book book;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;
  final ValueChanged<Book>? onCancelProcessing;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey(book.id),
    child: ListTile(
      title: Text(book.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (book.author?.isNotEmpty ?? false) book.author!,
              bookStatusLabel(book.status),
            ].join(' • '),
          ),
          if (book.status == BookStatus.processing &&
              book.processingStage != null) ...[
            Text(_processingLabel(book)),
            LinearProgressIndicator(value: book.processingProgress),
          ],
        ],
      ),
      trailing: _BookActions(
        book: book,
        onEdit: onEdit,
        onDelete: onDelete,
        onCancelProcessing: onCancelProcessing,
      ),
    ),
  );
}

String _processingLabel(Book book) =>
    '${book.processingStage!.label} • ${(book.processingProgress * 100).round()}%';

final class _BookActions extends StatelessWidget {
  const _BookActions({
    required this.book,
    required this.onEdit,
    required this.onDelete,
    required this.onCancelProcessing,
  });
  final Book book;
  final ValueChanged<Book> onEdit;
  final ValueChanged<Book> onDelete;
  final ValueChanged<Book>? onCancelProcessing;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
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
  );
}
