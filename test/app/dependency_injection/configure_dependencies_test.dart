import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';
import 'package:vox_novel/core/database/app_database.dart';

void main() {
  late GetIt locator;

  setUp(() {
    locator = GetIt.asNewInstance();
  });

  tearDown(() async {
    await resetDependencies(instance: locator);
  });

  test('registers one database, Cubit, and router', () async {
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
    );

    expect(locator.isRegistered<AppDatabase>(), isTrue);
    expect(locator.isRegistered<AppCubit>(), isTrue);
    expect(locator.isRegistered<GoRouter>(), isTrue);
  });

  test('repeated setup reuses the registered instances', () async {
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
    );
    final database = locator<AppDatabase>();
    final cubit = locator<AppCubit>();
    final router = locator<GoRouter>();

    await configureDependencies(instance: locator);

    expect(locator<AppDatabase>(), same(database));
    expect(locator<AppCubit>(), same(cubit));
    expect(locator<GoRouter>(), same(router));
  });

  test('reset disposes resources and clears the supplied locator', () async {
    final executor = NativeDatabase.memory();
    await configureDependencies(
      instance: locator,
      databaseExecutor: executor,
    );
    final cubit = locator<AppCubit>();

    await resetDependencies(instance: locator);

    expect(locator.isRegistered<AppDatabase>(), isFalse);
    expect(locator.isRegistered<AppCubit>(), isFalse);
    expect(locator.isRegistered<GoRouter>(), isFalse);
    expect(cubit.isClosed, isTrue);
    await expectLater(
      executor.runSelect('SELECT 1', const []),
      throwsA(isA<StateError>()),
    );
  });

  test('resolved database uses the injected in-memory executor', () async {
    await configureDependencies(
      instance: locator,
      databaseExecutor: NativeDatabase.memory(),
    );

    final result = await locator<AppDatabase>()
        .customSelect('SELECT 1 AS value')
        .getSingle();

    expect(result.read<int>('value'), 1);
  });
}
