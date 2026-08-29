import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// AD-013 — the platform media packages stay in the data layer, the way AD-010
/// confines `package:http` to the polite fetcher. Domain and presentation are
/// what the suite can exercise without a device, so a package reaching them is
/// behaviour that only a phone could verify.
Iterable<File> dartSourcesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));

void main() {
  const mediaPackages = ['audio_service', 'audio_session'];
  const allowedDirectory = 'lib/features/narration/data/';

  for (final package in mediaPackages) {
    test('only the narration data layer imports package:$package', () {
      // Scanning imports rather than type names: a name pattern only catches
      // the collaborators someone thought to name (lesson L-017).
      final importers = <String>[
        for (final source in dartSourcesIn('lib'))
          if (RegExp(
            "import\\s+'package:$package/",
          ).hasMatch(source.readAsStringSync()))
            source.path,
      ];

      expect(importers, isNotEmpty, reason: 'the package should be in use');
      expect(
        importers.where((path) => !path.startsWith(allowedDirectory)),
        isEmpty,
        reason:
            'Playback rules must stay testable without a device: keep '
            '$package behind an adapter in $allowedDirectory.',
      );
    });
  }

  test('the media session is brought up through androidForceEnableMediaButtons',
      () {
    final source = File(
      'lib/features/narration/data/services/narration_media_session.dart',
    ).readAsStringSync();

    // Text to speech produces no audio stream Android recognises as playback.
    // The T2 spike measured it: without this call every headset and
    // lock-screen button is dropped while the notification still looks
    // functional — a failure no unit test can see.
    expect(source, contains('androidForceEnableMediaButtons()'));
  });
}
