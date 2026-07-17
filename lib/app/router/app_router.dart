import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/features/library/presentation/pages/library_placeholder_page.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LibraryPlaceholderPage(),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erro de navegação'),
        ),
        body: Center(
          child: Text(state.uri.toString()),
        ),
      );
    },
  );
}
