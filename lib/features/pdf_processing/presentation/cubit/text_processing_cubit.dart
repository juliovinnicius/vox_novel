import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_state.dart';

typedef ProcessBook = Future<ProcessingResult> Function(String bookId);
typedef CancelBook = Future<ProcessingResult> Function(String bookId);
typedef CloseTextProcessingService = Future<void> Function();

final class TextProcessingCubit extends Cubit<TextProcessingState> {
  TextProcessingCubit({
    required ProcessBook processBook,
    required CancelBook cancelBook,
    required CloseTextProcessingService closeService,
  }) :
       // Public callback names intentionally omit private field prefixes.
       // ignore: prefer_initializing_formals
       _processBook = processBook,
       // ignore: prefer_initializing_formals
       _cancelBook = cancelBook,
       // ignore: prefer_initializing_formals
       _closeService = closeService,
       super(const TextProcessingState());

  final ProcessBook _processBook;
  final CancelBook _cancelBook;
  final CloseTextProcessingService _closeService;
  Future<void>? _processing;
  Future<void>? _cancelling;

  Future<void> process(String bookId) {
    final running = _processing;
    if (running != null || isClosed) return Future.value();
    final future = _runProcess(bookId);
    _processing = future;
    return future.whenComplete(() {
      if (identical(_processing, future)) _processing = null;
    });
  }

  Future<void> _runProcess(String bookId) async {
    emit(
      TextProcessingState(
        status: TextProcessingStatus.processing,
        activeBookId: bookId,
      ),
    );
    final result = await _processBook(bookId);
    if (isClosed || state.status == TextProcessingStatus.cancelling) return;
    emit(
      TextProcessingState(
        message: switch (result.outcome) {
          ProcessingOutcome.completed => null,
          ProcessingOutcome.cancelled => 'Processamento cancelado',
          ProcessingOutcome.unsupported ||
          ProcessingOutcome.failed => result.message,
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> cancel(String bookId) {
    final running = _cancelling;
    if (running != null || isClosed) return running ?? Future.value();
    if (state.status != TextProcessingStatus.processing ||
        state.activeBookId != bookId) {
      return Future.value();
    }
    final future = _runCancel(bookId);
    _cancelling = future;
    return future.whenComplete(() {
      if (identical(_cancelling, future)) _cancelling = null;
    });
  }

  Future<void> _runCancel(String bookId) async {
    emit(
      TextProcessingState(
        status: TextProcessingStatus.cancelling,
        activeBookId: bookId,
      ),
    );
    await _cancelBook(bookId);
    if (!isClosed) {
      emit(const TextProcessingState(message: 'Processamento cancelado'));
      await Future<void>.delayed(Duration.zero);
    }
  }

  void clearMessage() {
    if (!isClosed && state.message != null) emit(const TextProcessingState());
  }

  @override
  Future<void> close() async {
    await _closeService();
    return super.close();
  }
}
