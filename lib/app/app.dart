import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/theme/app_theme.dart';

final class VoxNovelApp extends StatelessWidget {
  const VoxNovelApp({required this.router, required this.appCubit, super.key});

  final GoRouter router;
  final AppCubit appCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: appCubit,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // A reading app is used at night: dark is the default, and the light
        // scheme stays defined for whoever flips it later.
        themeMode: ThemeMode.dark,
      ),
    );
  }
}
