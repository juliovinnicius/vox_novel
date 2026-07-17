import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vox_novel/features/import_book/data/services/local_book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';

void main() {
  late Directory temporary;
  late LocalBookFileStorage storage;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('vox-storage-');
    storage = LocalBookFileStorage(supportDirectory: temporary);
  });

  tearDown(() => temporary.delete(recursive: true));

  test(
    'validates case-insensitive PDF and hashes an empty readable file',
    () async {
      final source = File(p.join(temporary.path, 'Empty.PDF'));
      await source.writeAsBytes(const []);

      final result = await storage.validateAndHash(
        PickedPdf(sourcePath: source.path, originalFileName: 'Empty.PDF'),
      );

      expect(
        result.hash,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    },
  );

  test('production hash and copy execute on a different isolate', () async {
    final source = File(p.join(temporary.path, 'worker.pdf'));
    await source.writeAsString('isolate payload');
    final callerIdentity = Isolate.current.hashCode;
    final workerIdentities = <int>[];
    final isolated = LocalBookFileStorage(
      supportDirectory: temporary,
      onWorkerIsolate: workerIdentities.add,
    );
    final picked = PickedPdf(
      sourcePath: source.path,
      originalFileName: 'worker.pdf',
    );

    final validated = await isolated.validateAndHash(picked);
    final staged = await isolated.stageCopy(source: picked, bookId: 'worker');

    expect(
      validated.hash,
      'baa94026fabcf226b6f839affb826a9832eddfdd83a491c07aaa04952b986d6b',
    );
    expect(await File(staged.stagingPath).readAsString(), 'isolate payload');
    expect(workerIdentities, hasLength(2));
    expect(
      workerIdentities.every((identity) => identity != callerIdentity),
      isTrue,
    );
  });

  test('hashes a known fixture through the injected chunked stream', () async {
    final source = File(p.join(temporary.path, 'book.pdf'));
    await source.writeAsString('abc');
    var chunks = 0;
    final chunked = LocalBookFileStorage(
      supportDirectory: temporary,
      readFile: (file) => file.openRead().map((bytes) {
        chunks++;
        return bytes;
      }),
    );

    final result = await chunked.validateAndHash(
      PickedPdf(sourcePath: source.path, originalFileName: 'book.pdf'),
    );

    expect(
      result.hash,
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(chunks, greaterThan(0));
  });

  test(
    'returns typed failures for missing, directory, unreadable and non-PDF',
    () async {
      final directory = Directory(p.join(temporary.path, 'folder.pdf'));
      await directory.create();
      final unreadable = File(p.join(temporary.path, 'unreadable.pdf'));
      await unreadable.writeAsString('data');
      final failingStorage = LocalBookFileStorage(
        supportDirectory: temporary,
        readFile: (_) => Stream.error(const FileSystemException('denied')),
      );

      Future<void> expectKind(
        LocalBookFileStorage subject,
        String path,
        PdfValidationFailureKind kind,
      ) async {
        await expectLater(
          subject.validateAndHash(
            PickedPdf(sourcePath: path, originalFileName: p.basename(path)),
          ),
          throwsA(
            isA<PdfValidationException>().having((e) => e.kind, 'kind', kind),
          ),
        );
      }

      await expectKind(
        storage,
        p.join(temporary.path, 'missing.pdf'),
        PdfValidationFailureKind.missing,
      );
      await expectKind(
        storage,
        directory.path,
        PdfValidationFailureKind.directory,
      );
      await expectKind(
        failingStorage,
        unreadable.path,
        PdfValidationFailureKind.unreadable,
      );
      await expectKind(
        storage,
        unreadable.path.replaceAll('.pdf', '.txt'),
        PdfValidationFailureKind.nonPdf,
      );
    },
  );

  test(
    'stages, commits and discards copies with exact filesystem outcomes',
    () async {
      final source = File(p.join(temporary.path, 'source.pdf'));
      await source.writeAsString('novel');
      final picked = PickedPdf(
        sourcePath: source.path,
        originalFileName: 'source.pdf',
      );

      final committedStage = await storage.stageCopy(
        source: picked,
        bookId: 'book-1',
      );
      expect(await File(committedStage.stagingPath).readAsString(), 'novel');
      final committedPath = await storage.commitStage(committedStage);
      expect(await File(committedPath).readAsString(), 'novel');
      expect(await File(committedStage.stagingPath).exists(), isFalse);

      final discardedStage = await storage.stageCopy(
        source: picked,
        bookId: 'book-2',
      );
      await storage.discardStage(discardedStage);
      expect(await File(discardedStage.stagingPath).exists(), isFalse);
    },
  );

  test('backs up, restores and discards an owned file', () async {
    final owned = File(p.join(temporary.path, 'books', 'book.pdf'));
    await owned.create(recursive: true);
    await owned.writeAsString('old');

    final backup = await storage.backupOwnedFile(owned.path);
    expect(backup, isNotNull);
    expect(await owned.exists(), isFalse);
    await storage.restoreBackup(backup!);
    expect(await owned.readAsString(), 'old');

    final secondBackup = await storage.backupOwnedFile(owned.path);
    await storage.discardBackup(secondBackup!);
    expect(await File(secondBackup.backupPath).exists(), isFalse);
  });

  test(
    'quarantines, restores and permanently discards owned PDF and cover',
    () async {
      final pdf = File(p.join(temporary.path, 'books', 'book.pdf'));
      final cover = File(p.join(temporary.path, 'books', 'cover.jpg'));
      await pdf.create(recursive: true);
      await cover.create();

      final quarantine = await storage.quarantineOwnedFiles(
        pdfPath: pdf.path,
        coverPath: cover.path,
      );
      expect(await pdf.exists(), isFalse);
      expect(await cover.exists(), isFalse);
      await storage.restoreQuarantine(quarantine);
      expect(await pdf.exists(), isTrue);
      expect(await cover.exists(), isTrue);

      final finalQuarantine = await storage.quarantineOwnedFiles(
        pdfPath: pdf.path,
        coverPath: cover.path,
      );
      await storage.discardQuarantine(finalQuarantine);
      expect(
        finalQuarantine.files.every(
          (file) => !File(file.backupPath).existsSync(),
        ),
        isTrue,
      );
    },
  );

  test(
    'rejects external and traversal deletion while missing owned files count as deleted',
    () async {
      final external = File(p.join(temporary.path, 'external.pdf'));
      await external.writeAsString('keep');

      await expectLater(
        storage.removeOwnedFiles(pdfPath: external.path),
        throwsA(isA<UnsafeBookPathException>()),
      );
      await expectLater(
        storage.removeOwnedFiles(
          pdfPath: p.join(temporary.path, 'books', '..', 'external.pdf'),
        ),
        throwsA(isA<UnsafeBookPathException>()),
      );
      expect(await external.readAsString(), 'keep');
      await storage.removeOwnedFiles(
        pdfPath: p.join(temporary.path, 'books', 'missing.pdf'),
      );
    },
  );

  test(
    'injected move and delete failures preserve pre-operation files',
    () async {
      final source = File(p.join(temporary.path, 'source.pdf'));
      await source.writeAsString('novel');
      final failingMove = LocalBookFileStorage(
        supportDirectory: temporary,
        moveFile: (file, destination) =>
            throw const FileSystemException('move'),
      );
      final staged = await failingMove.stageCopy(
        source: PickedPdf(
          sourcePath: source.path,
          originalFileName: 'source.pdf',
        ),
        bookId: 'book-1',
      );
      await expectLater(
        failingMove.commitStage(staged),
        throwsA(isA<FileSystemException>()),
      );
      expect(await File(staged.stagingPath).readAsString(), 'novel');

      final owned = File(p.join(temporary.path, 'books', 'owned.pdf'));
      await owned.writeAsString('owned');
      final failingDelete = LocalBookFileStorage(
        supportDirectory: temporary,
        deleteFile: (_) => throw const FileSystemException('delete'),
      );
      await expectLater(
        failingDelete.removeOwnedFiles(pdfPath: owned.path),
        throwsA(isA<FileSystemException>()),
      );
      expect(await owned.readAsString(), 'owned');
    },
  );

  for (final failure in [
    const FileSystemException('source disappeared'),
    const FileSystemException(
      'write failed',
      '',
      OSError('No space left on device', 28),
    ),
  ]) {
    test(
      '${failure.osError?.errorCode == 28 ? 'disk full' : 'mid-copy disappearance'} removes the partial stage',
      () async {
        final source = File(p.join(temporary.path, 'failing.pdf'));
        await source.writeAsBytes([1, 2, 3]);
        final failing = LocalBookFileStorage(
          supportDirectory: temporary,
          readFile: (_) => Stream<List<int>>.multi((controller) {
            controller.add([1]);
            controller.addError(failure);
            controller.close();
          }),
        );

        await expectLater(
          failing.stageCopy(
            source: PickedPdf(
              sourcePath: source.path,
              originalFileName: 'failing.pdf',
            ),
            bookId: 'failed',
          ),
          throwsA(
            isA<FileSystemException>().having(
              (error) => error.osError?.errorCode,
              'errorCode',
              failure.osError?.errorCode,
            ),
          ),
        );

        final staging = Directory(p.join(temporary.path, 'books', '.staging'));
        expect(await staging.list().toList(), isEmpty);
      },
    );
  }
}
