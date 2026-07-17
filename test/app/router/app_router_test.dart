import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/app/router/app_router.dart';

void main() {
  testWidgets('root route renders one Biblioteca title', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Biblioteca'), findsOneWidget);
  });

  testWidgets('unknown route renders a navigation error', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/rota-inexistente');
    await tester.pumpAndSettle();

    expect(find.text('Erro de navegação'), findsOneWidget);
  });

  testWidgets('navigation error includes the attempted location', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/rota-inexistente');
    await tester.pumpAndSettle();

    expect(find.text('/rota-inexistente'), findsOneWidget);
  });
}
