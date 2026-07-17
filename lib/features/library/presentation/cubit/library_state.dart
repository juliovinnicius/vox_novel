import 'package:vox_novel/features/library/domain/entities/book.dart';

enum LibraryLayout { list, grid }

final class LibraryState {
  const LibraryState({
    this.layout = LibraryLayout.list,
    this.books = const [],
    this.loading = false,
    this.errorMessage,
  });

  final LibraryLayout layout;
  final List<Book> books;
  final bool loading;
  final String? errorMessage;

  LibraryState copyWith({
    LibraryLayout? layout,
    List<Book>? books,
    bool? loading,
    Object? errorMessage = _unset,
  }) => LibraryState(
    layout: layout ?? this.layout,
    books: books ?? this.books,
    loading: loading ?? this.loading,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
  );
}

const _unset = Object();
