import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/library/presentation/pages/library_placeholder_page.dart';

void main() {
  testWidgets('renders the Biblioteca title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LibraryPlaceholderPage()),
    );

    expect(find.text('Biblioteca'), findsOneWidget);
  });

  testWidgets('exposes the Biblioteca title to semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(home: LibraryPlaceholderPage()),
    );

    expect(
      tester.getSemantics(find.text('Biblioteca')).label,
      'Biblioteca',
    );

    semantics.dispose();
  });
}
