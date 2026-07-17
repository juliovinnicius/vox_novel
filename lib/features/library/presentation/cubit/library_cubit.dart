import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/library/domain/entities/book.dart';
import 'package:vox_novel/features/library/domain/repositories/book_repository.dart';
import 'package:vox_novel/features/library/domain/services/library_service.dart';
import 'package:vox_novel/features/library/presentation/cubit/library_state.dart';

final class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({required this.repository, required this.service})
    : super(const LibraryState());

  static const loadError = 'Não foi possível carregar a biblioteca';
  final BookRepository repository;
  final LibraryService service;
  StreamSubscription<List<Book>>? _subscription;

  void start() {
    if (_subscription != null) return;
    emit(state.copyWith(loading: true, errorMessage: null));
    _subscription = repository.watchAll().listen(
      (books) => emit(
        state.copyWith(
          books: List<Book>.unmodifiable(books),
          loading: false,
          errorMessage: null,
        ),
      ),
      onError: (_) =>
          emit(state.copyWith(loading: false, errorMessage: loadError)),
    );
  }

  void showList() => emit(state.copyWith(layout: LibraryLayout.list));
  void showGrid() => emit(state.copyWith(layout: LibraryLayout.grid));
  void clearError() => emit(state.copyWith(errorMessage: null));

  Future<bool> updateMetadata({
    required Book book,
    required String title,
    String? author,
  }) async {
    final result = await service.updateMetadata(
      id: book.id,
      title: title,
      author: author,
    );
    if (!result.success) emit(state.copyWith(errorMessage: result.message));
    return result.success;
  }

  Future<bool> deleteBook(Book book) async {
    final result = await service.deleteBook(book);
    if (!result.success) emit(state.copyWith(errorMessage: result.message));
    return result.success;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
