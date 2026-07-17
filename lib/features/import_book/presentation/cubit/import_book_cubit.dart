import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_state.dart';

final class ImportBookCubit extends Cubit<ImportBookState> {
  ImportBookCubit({required this.picker, required this.service})
    : super(const ImportBookState());

  final PdfPicker picker;
  final ImportBookService service;

  Future<void> importPdf() async {
    if (state.status != ImportBookStatus.idle) return;
    emit(const ImportBookState(status: ImportBookStatus.selecting));
    try {
      final selected = await picker.pickPdf();
      if (selected == null) {
        emit(const ImportBookState());
        return;
      }
      emit(const ImportBookState(status: ImportBookStatus.importing));
      await service.importPdf(selected);
      emit(const ImportBookState());
    } catch (_) {
      emit(const ImportBookState(errorMessage: ImportBookException.message));
    }
  }

  void clearMessage() {
    if (state.errorMessage != null) emit(const ImportBookState());
  }
}
