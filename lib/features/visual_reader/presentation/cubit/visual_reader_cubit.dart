import 'dart:async';

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
  Future<void> _writeTail = Future.value();

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

  void selectBlock(String chapterId, String blockId) {
    final chapter = _chapter(chapterId);
    if (chapter == null ||
        !chapter.blocks.any((block) => block.id == blockId) ||
        state.chapterId == chapterId && state.blockId == blockId) {
      return;
    }
    _apply(chapterId: chapterId, blockId: blockId);
  }

  void followNarration(String chapterId, String blockId) {
    if (state.status != VisualReaderStatus.ready) return;
    final chapter = _chapter(chapterId);
    if (chapter == null ||
        !chapter.blocks.any((block) => block.id == blockId) ||
        state.chapterId == chapterId && state.blockId == blockId) {
      return;
    }
    emit(state.copyWith(chapterId: chapterId, blockId: blockId, message: null));
  }

  void selectChapter(String chapterId) {
    final chapter = _chapter(chapterId);
    if (chapter == null || state.chapterId == chapterId) return;
    _apply(chapterId: chapterId, blockId: chapter.blocks.firstOrNull?.id);
  }

  void previousChapter() => _moveChapter(-1);
  void nextChapter() => _moveChapter(1);

  void _moveChapter(int offset) {
    final content = state.content;
    if (content == null) return;
    final index = content.chapters.indexWhere(
      (chapter) => chapter.chapter.id == state.chapterId,
    );
    final target = index + offset;
    if (index < 0 || target < 0 || target >= content.chapters.length) return;
    final chapter = content.chapters[target];
    _apply(
      chapterId: chapter.chapter.id,
      blockId: chapter.blocks.firstOrNull?.id,
    );
  }

  void showPdf() {
    final chapter = _chapter(state.chapterId);
    if (chapter == null || state.mode == ReaderMode.pdf) return;
    final page = _resolver
        .textToPdf(chapter, state.blockId)
        .clamp(1, state.content!.book.pageCount);
    _apply(mode: ReaderMode.pdf, pdfPage: page);
  }

  void showText() {
    final content = state.content;
    if (content == null || state.mode == ReaderMode.text) return;
    final prior = _position();
    final mapped = _resolver.pdfToText(content, state.pdfPage, prior, _clock());
    _apply(
      mode: ReaderMode.text,
      chapterId: mapped.chapterId,
      blockId: mapped.blockId,
    );
  }

  void pageChanged(int page) {
    final content = state.content;
    if (content == null || state.mode != ReaderMode.pdf) return;
    final clamped = page.clamp(1, content.book.pageCount);
    if (clamped == state.pdfPage) return;
    _apply(pdfPage: clamped);
  }

  ReaderChapter? _chapter(String? id) => state.content?.chapters
      .where((chapter) => chapter.chapter.id == id)
      .firstOrNull;

  void _apply({
    ReaderMode? mode,
    Object? chapterId = _navigationUnset,
    Object? blockId = _navigationUnset,
    int? pdfPage,
  }) {
    emit(
      state.copyWith(
        mode: mode,
        chapterId: identical(chapterId, _navigationUnset)
            ? state.chapterId
            : chapterId as String?,
        blockId: identical(blockId, _navigationUnset)
            ? state.blockId
            : blockId as String?,
        pdfPage: pdfPage,
        message: null,
      ),
    );
    _queuePosition();
  }

  ReaderPosition _position() => ReaderPosition(
    bookId: state.content!.book.id,
    mode: state.mode,
    chapterId: state.chapterId,
    blockId: state.blockId,
    pdfPage: state.pdfPage,
    updatedAt: _clock(),
  );

  void _queuePosition() {
    final position = _position();
    _writeTail = _writeTail
        .catchError((_) {})
        .then((_) => _repository.savePosition(position))
        .catchError((_) {
          if (!isClosed) {
            emit(
              state.copyWith(message: 'Não foi possível salvar sua posição'),
            );
          }
        });
    unawaited(_writeTail);
  }

  void setTheme(ReaderTheme theme) {
    final settings = state.settings;
    if (settings == null || settings.theme == theme) return;
    _applySettings(settings.copyWith(theme: theme));
  }

  void setFontFamily(ReaderFontFamily family) {
    final settings = state.settings;
    if (settings == null || settings.fontFamily == family) return;
    _applySettings(settings.copyWith(fontFamily: family));
  }

  void setLineHeight(double lineHeight) {
    final settings = state.settings;
    if (settings == null ||
        settings.lineHeight == lineHeight ||
        !const [1.2, 1.5, 1.8, 2.0].contains(lineHeight)) {
      return;
    }
    _applySettings(settings.copyWith(lineHeight: lineHeight));
  }

  void increaseFont() => _changeFont(2);
  void decreaseFont() => _changeFont(-2);

  void _changeFont(int delta) {
    final settings = state.settings;
    if (settings == null) return;
    final size = settings.fontSize + delta;
    if (size < 14 || size > 32) return;
    _applySettings(settings.copyWith(fontSize: size));
  }

  void _applySettings(ReaderSettings settings) {
    emit(state.copyWith(settings: settings, message: null));
    _writeTail = _writeTail
        .catchError((_) {})
        .then((_) => _repository.saveSettings(settings))
        .catchError((_) {
          if (!isClosed) {
            emit(
              state.copyWith(
                message: 'Não foi possível salvar suas configurações',
              ),
            );
          }
        });
    unawaited(_writeTail);
  }

  void clearMessage() {
    if (state.message != null && !isClosed) {
      emit(state.copyWith(message: null));
    }
  }

  @override
  Future<void> close() async {
    _loadToken++;
    await _writeTail.catchError((_) {});
    return super.close();
  }
}

const Object _navigationUnset = Object();
