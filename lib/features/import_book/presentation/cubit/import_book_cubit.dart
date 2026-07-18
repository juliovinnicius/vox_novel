import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/import_book/domain/services/import_book_service.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/import_book/presentation/cubit/import_book_state.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';

final class ImportBookCubit extends Cubit<ImportBookState> {
  ImportBookCubit({
    required this.picker,
    required this.service,
    this.textProcessingCubit,
  })
    : super(const ImportBookState());

  final PdfPicker picker;
  final ImportBookService service;
  final TextProcessingCubit? textProcessingCubit;

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
      final book = await service.importPdf(selected);
      final processingCubit = textProcessingCubit;
      if (processingCubit != null) {
        emit(const ImportBookState(status: ImportBookStatus.processing));
        await processingCubit.process(book.id);
      }
      emit(const ImportBookState());
    } catch (_) {
      emit(const ImportBookState(errorMessage: ImportBookException.message));
    }
  }

  void clearMessage() {
    if (state.errorMessage != null) emit(const ImportBookState());
  }
}
