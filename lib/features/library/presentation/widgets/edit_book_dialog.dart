import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

Future<BookMetadata?> showEditBookDialog(BuildContext context, Book book) =>
    showDialog<BookMetadata>(
      context: context,
      builder: (_) => EditBookDialog(book: book),
    );

final class EditBookDialog extends StatefulWidget {
  const EditBookDialog({required this.book, super.key});
  final Book book;
  @override
  State<EditBookDialog> createState() => _EditBookDialogState();
}

final class _EditBookDialogState extends State<EditBookDialog> {
  late final title = TextEditingController(text: widget.book.title);
  late final author = TextEditingController(text: widget.book.author ?? '');
  final key = GlobalKey<FormState>();
  @override
  void dispose() {
    title.dispose();
    author.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar livro'),
    content: Form(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Título'),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? 'Informe o título' : null,
          ),
          TextFormField(
            controller: author,
            decoration: const InputDecoration(labelText: 'Autor'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!key.currentState!.validate()) return;
          Navigator.pop(
            context,
            Book.normalizeMetadata(title: title.text, author: author.text),
          );
        },
        child: const Text('Salvar'),
      ),
    ],
  );
}
