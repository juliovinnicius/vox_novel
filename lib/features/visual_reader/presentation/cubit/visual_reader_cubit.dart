import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/visual_reader/domain/entities/reader_models.dart';
import 'package:vox_novel/features/visual_reader/domain/repositories/visual_reader_repository.dart';
import 'package:vox_novel/features/visual_reader/domain/services/reader_position_resolver.dart';
import 'package:vox_novel/features/visual_reader/presentation/cubit/visual_reader_state.dart';

final class VisualReaderCubit extends Cubit<VisualReaderState> {
  VisualReaderCubit({
    required VisualReaderRepository repository,
    required DateTime Function() clock,
    ReaderPositionResolver resolver = const ReaderPositionResolver(),
  }) : // Public dependency names intentionally omit private prefixes.
       // ignore: prefer_initializing_formals
       _repository = repository,
       // ignore: prefer_initializing_formals
       _clock = clock,
       // ignore: prefer_initializing_formals
       _resolver = resolver,
       super(const VisualReaderState());

  final VisualReaderRepository _repository;
  final DateTime Function() _clock;
  final ReaderPositionResolver _resolver;
  var _loadToken = 0;

  Future<void> load(String bookId) async {
    final token = ++_loadToken;
    emit(const VisualReaderState(status: VisualReaderStatus.loading));
    try {
      final content = await _repository.loadContent(bookId);
      if (token != _loadToken || isClosed) return;
      if (content == null) {
        emit(
          const VisualReaderState(
            status: VisualReaderStatus.unavailable,
            message: 'Conteúdo do livro indisponível',
          ),
        );
        return;
      }
      ReaderSettings settings;
      try {
        settings = await _repository.loadSettings();
      } catch (_) {
        settings = ReaderSettings.defaults();
      }
      final saved = await _repository.loadPosition(bookId);
      if (token != _loadToken || isClosed) return;
      final fallback = _resolver.fallback(content, _clock());
      final position = saved == null
          ? fallback
          : _resolver.validate(
              content,
              saved,
              pageCount: content.book.pageCount,
              updatedAt: _clock(),
            );
      if (saved != null && !_samePosition(saved, position)) {
        await _repository.savePosition(position);
      }
      if (token != _loadToken || isClosed) return;
      emit(
        VisualReaderState(
          status: VisualReaderStatus.ready,
          content: content,
          settings: settings,
          mode: position.mode,
          chapterId: position.chapterId,
          blockId: position.blockId,
          pdfPage: position.pdfPage,
        ),
      );
    } catch (_) {
      if (token == _loadToken && !isClosed) {
        emit(
          const VisualReaderState(
            status: VisualReaderStatus.unavailable,
            message: 'Conteúdo do livro indisponível',
          ),
        );
      }
    }
  }

  bool _samePosition(ReaderPosition first, ReaderPosition second) =>
      first.bookId == second.bookId &&
      first.mode == second.mode &&
      first.chapterId == second.chapterId &&
      first.blockId == second.blockId &&
      first.pdfPage == second.pdfPage;
}
