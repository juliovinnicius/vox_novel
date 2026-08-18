import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/web_source/domain/services/import_web_book_service.dart';
import 'package:vox_novel/features/web_source/presentation/cubit/import_web_book_state.dart';

/// Submits a URL for import — `ImportWebBookService.import` in production.
typedef ImportWebBook = Future<ImportWebBookResult> Function(String url);

final class ImportWebBookCubit extends Cubit<ImportWebBookState> {
  ImportWebBookCubit({required this.importBook})
    : super(const ImportWebBookState());

  /// Shown when the import fails in a way the service could not classify.
  static const failureMessage = 'Não foi possível importar esta obra';

  final ImportWebBook importBook;

  Future<void> submit(String url) async {
    if (state.status == ImportWebBookStatus.submitting) return;
    emit(const ImportWebBookState(status: ImportWebBookStatus.submitting));
    try {
      final result = await importBook(url);
      // Every rejection carries the message its own reason earned, so the
      // dialog never has to guess why the URL was refused.
      emit(switch (result) {
        WebBookImported(:final book) => ImportWebBookState(
          status: ImportWebBookStatus.success,
          importedBookId: book.id,
        ),
        WebBookImportRejected(:final message) => ImportWebBookState(
          errorMessage: message,
        ),
      });
    } catch (_) {
      emit(const ImportWebBookState(errorMessage: failureMessage));
    }
  }

  void clearMessage() {
    if (state.errorMessage != null) emit(const ImportWebBookState());
  }
}
