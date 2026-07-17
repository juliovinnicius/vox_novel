import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/router/app_router.dart';
import 'package:vox_novel/core/database/app_database.dart';

Future<void> configureDependencies({
  GetIt? instance,
  QueryExecutor? databaseExecutor,
}) async {
  final locator = instance ?? GetIt.instance;

  if (!locator.isRegistered<AppDatabase>()) {
    final database = databaseExecutor == null
        ? AppDatabase.defaults()
        : AppDatabase(databaseExecutor);
    locator.registerSingleton<AppDatabase>(
      database,
      dispose: (database) => database.close(),
    );
  }

  if (!locator.isRegistered<AppCubit>()) {
    locator.registerSingleton<AppCubit>(
      AppCubit(),
      dispose: (cubit) => cubit.close(),
    );
  }

  if (!locator.isRegistered<GoRouter>()) {
    locator.registerSingleton<GoRouter>(
      createAppRouter(),
      dispose: (router) => router.dispose(),
    );
  }
}

Future<void> resetDependencies({GetIt? instance}) {
  return (instance ?? GetIt.instance).reset();
}
