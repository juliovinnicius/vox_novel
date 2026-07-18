import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

  testWidgets('reader route decodes the exact book ID and supports back', (
    tester,
  ) async {
    String? receivedId;
    final router = createAppRouter(
      readerPageBuilder: (context, bookId) {
        receivedId = bookId;
        return Scaffold(
          body: TextButton(
            onPressed: context.pop,
            child: const Text('Fechar leitor'),
          ),
        );
      },
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.push('/reader/${Uri.encodeComponent('id com espaço')}');
    await tester.pumpAndSettle();
    expect(receivedId, 'id com espaço');
    await tester.tap(find.text('Fechar leitor'));
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca'), findsOneWidget);
  });

  testWidgets('deep link without available content offers library return', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/reader/missing');
    await tester.pumpAndSettle();
    expect(find.text('Conteúdo do livro indisponível'), findsOneWidget);
    await tester.tap(find.text('Voltar à biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca'), findsOneWidget);
  });
}
