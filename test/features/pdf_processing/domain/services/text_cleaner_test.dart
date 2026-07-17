import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/features/pdf_processing/domain/entities/text_processing_models.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_cleaner.dart';

void main() {
  const cleaner = TextCleaner();
  const emptyProfile = HeaderFooterProfile(headers: {}, footers: {});

  CleanPage clean(String text) =>
      cleaner.clean(RawPage(pageNumber: 1, text: text), emptyProfile);

  test('removes C0 controls except tab and line feed', () {
    expect(clean('a\u0000b\t c\nx').text, 'ab c\nx');
  });
  test('trims edges and collapses horizontal whitespace', () {
    expect(clean('  um \t  dois  ').text, 'um dois');
  });
  test('retains at most one blank separator', () {
    expect(clean('\nA\n\n\n\nB\n\n').text, 'A\n\nB');
  });
  test('removes complete-line HTTP and HTTPS URLs', () {
    expect(clean('A\nhttp://example.com\nHTTPS://x.test/a\nB').text, 'A\nB');
  });
  test('removes isolated Arabic page numbers', () {
    expect(clean('A\n  42 \nB').text, 'A\nB');
  });
  test('retains URL and number lookalikes inside narrative lines', () {
    expect(
      clean('Visite http://example.com agora\nPágina 42').text,
      'Visite http://example.com agora\nPágina 42',
    );
  });
  test('removes repeated headers and footers only at matching edges', () {
    final pages = List.generate(
      3,
      (i) => RawPage(pageNumber: i + 1, text: ' CABEÇALHO \nTexto $i\nRodapé'),
    );
    final profile = cleaner.profile(pages);
    expect(profile.headers, {'cabeçalho'});
    expect(profile.footers, {'rodapé'});
    expect(cleaner.clean(pages.first, profile).text, 'Texto 0');
  });
  test('does not profile fewer than three edge occurrences', () {
    final profile = cleaner.profile([
      RawPage(pageNumber: 1, text: 'X\nA'),
      RawPage(pageNumber: 2, text: 'X\nB'),
    ]);
    expect(profile.headers, isEmpty);
  });
  test('does not profile an edge below sixty percent', () {
    final pages = List.generate(
      5,
      (i) => RawPage(pageNumber: i + 1, text: '${i < 2 ? 'X' : 'H$i'}\nBody'),
    );
    expect(cleaner.profile(pages).headers, isEmpty);
  });
  test('joins lowercase hyphenated continuations without the hyphen', () {
    expect(clean('pala-\nvra').text, 'palavra');
  });
  test('retains nonmatching hyphens and uppercase continuations', () {
    expect(clean('fim-\nAgora\n-\ntexto').text, 'fim-\nAgora\n-\ntexto');
  });
  test('does not mutate immutable raw input', () {
    final raw = RawPage(pageNumber: 1, text: '  Original  ');
    cleaner.clean(raw, emptyProfile);
    expect(raw, RawPage(pageNumber: 1, text: '  Original  '));
  });
}
