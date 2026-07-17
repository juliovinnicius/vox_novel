import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/router/app_router.dart';

void main() {
  testWidgets('application smoke test renders one Biblioteca', (tester) async {
    final router = createAppRouter();
    final cubit = AppCubit();
    addTearDown(router.dispose);
    addTearDown(cubit.close);

    await tester.pumpWidget(VoxNovelApp(router: router, appCubit: cubit));

    expect(find.text('Biblioteca'), findsOneWidget);
  });
}
