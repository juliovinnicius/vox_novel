import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef ReaderPageBuilder =
    Widget? Function(BuildContext context, String bookId);

GoRouter createAppRouter({
  WidgetBuilder? libraryPageBuilder,
  ReaderPageBuilder? readerPageBuilder,
}) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            libraryPageBuilder?.call(context) ??
            Scaffold(
              appBar: AppBar(
                title: Semantics(header: true, child: const Text('Biblioteca')),
              ),
            ),
      ),
      GoRoute(
        path: '/reader/:bookId',
        builder: (context, state) {
          final encodedId = state.pathParameters['bookId'];
          if (encodedId == null || encodedId.isEmpty) {
            return const _UnavailableReaderRoute();
          }
          // go_router exposes path parameters already URI-decoded.
          return readerPageBuilder?.call(context, encodedId) ??
              const _UnavailableReaderRoute();
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro de navegação')),
        body: Center(child: Text(state.uri.toString())),
      );
    },
  );
}

class _UnavailableReaderRoute extends StatelessWidget {
  const _UnavailableReaderRoute();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Leitor')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Conteúdo do livro indisponível'),
          TextButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            child: const Text('Voltar à biblioteca'),
          ),
        ],
      ),
    ),
  );
}
