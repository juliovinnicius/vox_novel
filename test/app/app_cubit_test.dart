import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/app_state.dart';

void main() {
  test('starts with the initial application status', () {
    final cubit = AppCubit();
    addTearDown(cubit.close);

    expect(cubit.state.status, AppStatus.initial);
  });

  blocTest<AppCubit, AppState>(
    'emits the ready application status',
    build: AppCubit.new,
    act: (cubit) => cubit.markReady(),
    expect: () => [
      isA<AppState>().having(
        (state) => state.status,
        'status',
        AppStatus.ready,
      ),
    ],
  );

  blocTest<AppCubit, AppState>(
    'does not emit duplicate ready states',
    build: AppCubit.new,
    act: (cubit) {
      cubit
        ..markReady()
        ..markReady();
    },
    expect: () => [
      isA<AppState>().having(
        (state) => state.status,
        'status',
        AppStatus.ready,
      ),
    ],
  );
}
