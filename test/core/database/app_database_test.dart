import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vox_novel/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('creates the production database boundary', () async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => '/tmp');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final database = AppDatabase.defaults();

    expect(database.schemaVersion, 1);

    await database.close();
  });

  test('executes a query with an in-memory database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final result = await database
        .customSelect('SELECT 1 AS value')
        .getSingle();

    expect(result.read<int>('value'), 1);
  });

  test('rejects queries after the database is closed', () async {
    final executor = NativeDatabase.memory();
    final database = AppDatabase(executor);

    await database.close();

    expect(
      executor.runSelect('SELECT 1', const []),
      throwsA(isA<StateError>()),
    );
  });
}
