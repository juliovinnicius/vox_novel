import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BGN-02 — narration holds a foreground media session for as long as playback
/// is active. On Android that is a platform contract expressed entirely in the
/// manifest and the host activity: none of it is reachable from Dart, so it is
/// asserted the same way the macOS PDF entitlements are.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  for (final permission in [
    'android.permission.WAKE_LOCK',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
  ]) {
    test('the manifest requests $permission', () {
      expect(
        manifest,
        contains('<uses-permission android:name="$permission"/>'),
      );
    });
  }

  test('the media service is declared for media playback', () {
    expect(
      manifest,
      contains('android:name="com.ryanheise.audioservice.AudioService"'),
    );
    expect(manifest, contains('android:foregroundServiceType="mediaPlayback"'));
    expect(
      manifest,
      contains('<action android:name="android.media.browse.MediaBrowserService" />'),
    );
  });

  test('media buttons are routed to a receiver', () {
    expect(
      manifest,
      contains('android:name="com.ryanheise.audioservice.MediaButtonReceiver"'),
    );
    expect(
      manifest,
      contains('<action android:name="android.intent.action.MEDIA_BUTTON" />'),
    );
  });

  test('the host activity is the one the media service can bind to', () {
    final activity = File(
      'android/app/src/main/kotlin/com/example/vox_novel/MainActivity.kt',
    ).readAsStringSync();

    // A plain FlutterActivity does not expose the engine the background
    // service attaches to, so speech would stop with the activity.
    expect(activity, contains('AudioServiceActivity'));
    expect(activity, isNot(contains(': FlutterActivity()')));
  });

  test('the media packages are declared dependencies', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('audio_service:'));
    expect(pubspec, contains('audio_session:'));
  });
}
