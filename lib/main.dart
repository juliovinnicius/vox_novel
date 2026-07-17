import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';

typedef DependencyConfigurator =
    Future<void> Function({
      required GetIt instance,
      QueryExecutor? databaseExecutor,
    });

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createApplication());
}

Future<VoxNovelApp> createApplication({
  GetIt? instance,
  QueryExecutor? databaseExecutor,
  DependencyConfigurator? configure,
}) async {
  final locator = instance ?? GetIt.instance;
  await (configure ?? _configureDependencies)(
    instance: locator,
    databaseExecutor: databaseExecutor,
  );

  final appCubit = locator<AppCubit>()..markReady();
  return VoxNovelApp(router: locator<GoRouter>(), appCubit: appCubit);
}

Future<void> _configureDependencies({
  required GetIt instance,
  QueryExecutor? databaseExecutor,
}) {
  return configureDependencies(
    instance: instance,
    databaseExecutor: databaseExecutor,
  );
}
