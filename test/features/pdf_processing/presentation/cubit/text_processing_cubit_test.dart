import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_cubit.dart';
import 'package:vox_novel/features/pdf_processing/presentation/cubit/text_processing_state.dart';

void main() {
  test('initial state is exactly idle without active book or message', () {
    final operations = _Operations();
    final cubit = operations.cubit();

    expect(cubit.state, const TextProcessingState());
  });

  test(
    'completed processing exposes book then returns to exact idle',
    () async {
      final operations = _Operations();
      final cubit = operations.cubit();
      final states = <TextProcessingState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.process('book-1');

      expect(states, const [
        TextProcessingState(
          status: TextProcessingStatus.processing,
          activeBookId: 'book-1',
        ),
        TextProcessingState(),
      ]);
      await subscription.cancel();
    },
  );

  test('unsupported processing returns exact service message', () async {
    final operations = _Operations()
      ..result = const ProcessingResult.unsupported(
        'Este PDF não possui texto extraível',
      );
    final cubit = operations.cubit();

    await cubit.process('book-1');

    expect(
      cubit.state,
      const TextProcessingState(message: 'Este PDF não possui texto extraível'),
    );
  });

  test('failed processing returns exact standard message', () async {
    final operations = _Operations()
      ..result = const ProcessingResult.failed(
        'Não foi possível processar este PDF',
      );
    final cubit = operations.cubit();

    await cubit.process('book-1');

    expect(
      cubit.state,
      const TextProcessingState(message: 'Não foi possível processar este PDF'),
    );
  });

  test('cancel is book-specific and exposes exact state sequence', () async {
    final operations = _Operations()..pending = Completer<ProcessingResult>();
    final cubit = operations.cubit();
    final states = <TextProcessingState>[];
    final subscription = cubit.stream.listen(states.add);
    final processing = cubit.process('book-1');
    await Future<void>.delayed(Duration.zero);

    final cancellation = cubit.cancel('book-1');
    operations.pending!.complete(const ProcessingResult.cancelled());
    await processing;
    await cancellation;

    expect(operations.cancelledBookIds, ['book-1']);
    expect(states, const [
      TextProcessingState(
        status: TextProcessingStatus.processing,
        activeBookId: 'book-1',
      ),
      TextProcessingState(
        status: TextProcessingStatus.cancelling,
        activeBookId: 'book-1',
      ),
      TextProcessingState(message: 'Processamento cancelado'),
    ]);
    await subscription.cancel();
  });

  test(
    'cancel for another book does not call service or change state',
    () async {
      final operations = _Operations()..pending = Completer<ProcessingResult>();
      final cubit = operations.cubit();
      final processing = cubit.process('book-1');
      await Future<void>.delayed(Duration.zero);

      await cubit.cancel('book-2');

      expect(operations.cancelledBookIds, isEmpty);
      expect(
        cubit.state,
        const TextProcessingState(
          status: TextProcessingStatus.processing,
          activeBookId: 'book-1',
        ),
      );
      operations.pending!.complete(const ProcessingResult.completed());
      await processing;
    },
  );

  test('duplicate process requests start one service operation', () async {
    final operations = _Operations()..pending = Completer<ProcessingResult>();
    final cubit = operations.cubit();

    final first = cubit.process('book-1');
    await cubit.process('book-1');

    expect(operations.processedBookIds, ['book-1']);
    operations.pending!.complete(const ProcessingResult.completed());
    await first;
  });

  test('duplicate cancel requests start one cancel operation', () async {
    final operations = _Operations()
      ..pending = Completer<ProcessingResult>()
      ..cancelPending = Completer<ProcessingResult>();
    final cubit = operations.cubit();
    final processing = cubit.process('book-1');
    await Future<void>.delayed(Duration.zero);

    final first = cubit.cancel('book-1');
    final second = cubit.cancel('book-1');

    expect(operations.cancelledBookIds, ['book-1']);
    operations.cancelPending!.complete(const ProcessingResult.cancelled());
    operations.pending!.complete(const ProcessingResult.cancelled());
    await Future.wait([first, second, processing]);
  });

  test('clearMessage removes only the transient message', () async {
    final operations = _Operations()
      ..result = const ProcessingResult.failed('falha');
    final cubit = operations.cubit();
    await cubit.process('book-1');

    cubit.clearMessage();

    expect(cubit.state, const TextProcessingState());
  });

  test(
    'close awaits service cleanup and suppresses post-close state',
    () async {
      final operations = _Operations()
        ..pending = Completer<ProcessingResult>()
        ..closePending = Completer<void>();
      final cubit = operations.cubit();
      final states = <TextProcessingState>[];
      final subscription = cubit.stream.listen(states.add);
      final processing = cubit.process('book-1');
      await Future<void>.delayed(Duration.zero);

      final closing = cubit.close();
      expect(operations.closeCalls, 1);
      operations.closePending!.complete();
      await closing;
      operations.pending!.complete(const ProcessingResult.completed());
      await processing;

      expect(states, const [
        TextProcessingState(
          status: TextProcessingStatus.processing,
          activeBookId: 'book-1',
        ),
      ]);
      await subscription.cancel();
    },
  );
}

final class _Operations {
  ProcessingResult result = const ProcessingResult.completed();
  Completer<ProcessingResult>? pending;
  Completer<ProcessingResult>? cancelPending;
  Completer<void>? closePending;
  final processedBookIds = <String>[];
  final cancelledBookIds = <String>[];
  int closeCalls = 0;

  TextProcessingCubit cubit() => TextProcessingCubit(
    processBook: (bookId) {
      processedBookIds.add(bookId);
      return pending?.future ?? Future.value(result);
    },
    cancelBook: (bookId) {
      cancelledBookIds.add(bookId);
      return cancelPending?.future ??
          pending?.future ??
          Future.value(const ProcessingResult.cancelled());
    },
    closeService: () {
      closeCalls++;
      return closePending?.future ?? Future.value();
    },
  );
}
