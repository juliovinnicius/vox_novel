import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter({WidgetBuilder? libraryPageBuilder}) {
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
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro de navegação')),
        body: Center(child: Text(state.uri.toString())),
      );
    },
  );
}
