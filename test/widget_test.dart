import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/app_state.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';
import 'package:vox_novel/app/router/app_router.dart';
import 'package:vox_novel/core/database/app_database.dart';
import 'package:vox_novel/main.dart' as application;

void main() {
  testWidgets('application smoke test renders one Biblioteca', (tester) async {
    final router = createAppRouter();
    final cubit = AppCubit();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(VoxNovelApp(router: router, appCubit: cubit));

    expect(find.text('Biblioteca'), findsOneWidget);
  });

  testWidgets('bootstrap awaits dependencies before returning the app', (
    tester,
  ) async {
    final locator = GetIt.asNewInstance();
    final allowConfiguration = Completer<void>();
    var applicationCreated = false;
    addTearDown(() => resetDependencies(instance: locator));

    final applicationFuture = application
        .createApplication(
          instance: locator,
          databaseExecutor: NativeDatabase.memory(),
          configure: ({required instance, databaseExecutor}) async {
            await allowConfiguration.future;
            await configureDependencies(
              instance: instance,
              databaseExecutor: databaseExecutor,
            );
          },
        )
        .then((app) {
          applicationCreated = true;
          return app;
        });

    await tester.pump();
    expect(applicationCreated, isFalse);

    allowConfiguration.complete();
    final app = await applicationFuture;

    expect(locator.isRegistered<AppDatabase>(), isTrue);
    expect(locator.isRegistered<AppCubit>(), isTrue);
    expect(locator.isRegistered<GoRouter>(), isTrue);
    expect(locator<AppCubit>().state.status, AppStatus.ready);

    await tester.pumpWidget(app);
    expect(find.text('Biblioteca'), findsOneWidget);
  });
}
