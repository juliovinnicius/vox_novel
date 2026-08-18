import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_cubit.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_state.dart';

Future<void> showImportWebBookDialog(
  BuildContext context,
  ImportWebBookCubit cubit,
) => showDialog<void>(
  context: context,
  builder: (_) => ImportWebBookDialog(cubit: cubit),
);

final class ImportWebBookDialog extends StatefulWidget {
  const ImportWebBookDialog({required this.cubit, super.key});

  final ImportWebBookCubit cubit;

  @override
  State<ImportWebBookDialog> createState() => _ImportWebBookDialogState();
}

final class _ImportWebBookDialogState extends State<ImportWebBookDialog> {
  final url = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The cubit outlives the dialog, so a previous attempt's message must not
    // greet the next one.
    widget.cubit.clearMessage();
  }

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.cubit,
    child: BlocConsumer<ImportWebBookCubit, ImportWebBookState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == ImportWebBookStatus.success,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final submitting = state.status == ImportWebBookStatus.submitting;
        return AlertDialog(
          title: const Text('Importar da web'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                autofocus: true,
                keyboardType: TextInputType.url,
                enabled: !submitting,
                decoration: InputDecoration(
                  labelText: 'Endereço da obra',
                  errorText: state.errorMessage,
                ),
              ),
              if (submitting) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () => widget.cubit.submit(url.text),
              child: const Text('Importar'),
            ),
          ],
        );
      },
    ),
  );
}
