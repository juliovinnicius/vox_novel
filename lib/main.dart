import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  final appCubit = GetIt.instance<AppCubit>()..markReady();
  runApp(
    VoxNovelApp(
      router: GetIt.instance<GoRouter>(),
      appCubit: appCubit,
    ),
  );
}
