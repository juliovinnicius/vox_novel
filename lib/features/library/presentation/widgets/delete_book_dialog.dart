import 'package:flutter/material.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';

Future<bool> showDeleteBookDialog(BuildContext context, Book book) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir livro'),
        content: Text('Deseja excluir “${book.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    ) ??
    false;
