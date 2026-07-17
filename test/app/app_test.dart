import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/app_state.dart';
import 'package:vox_novel/app/router/app_router.dart';

void main() {
  testWidgets('uses the provided router and renders Biblioteca', (tester) async {
    final router = createAppRouter();
    final cubit = AppCubit();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(VoxNovelApp(router: router, appCubit: cubit));

    expect(find.text('Biblioteca'), findsOneWidget);

    router.go('/rota-inexistente');
    await tester.pumpAndSettle();

    expect(find.text('Erro de navegação'), findsOneWidget);
  });

  testWidgets('provides the supplied Cubit below the root widget', (
    tester,
  ) async {
    final router = createAppRouter();
    final cubit = AppCubit();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(VoxNovelApp(router: router, appCubit: cubit));

    expect(
      tester.element(find.text('Biblioteca')).read<AppCubit>(),
      same(cubit),
    );
  });

  testWidgets('markReady changes the provided Cubit status to ready', (
    tester,
  ) async {
    final router = createAppRouter();
    final cubit = AppCubit();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(VoxNovelApp(router: router, appCubit: cubit));

    cubit.markReady();

    expect(cubit.state.status, AppStatus.ready);
  });
}
