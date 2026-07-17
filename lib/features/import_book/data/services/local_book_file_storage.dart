import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:vox_novel/features/import_book/domain/services/book_file_storage.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';

typedef FileReader = Stream<List<int>> Function(File file);
typedef FileMover = Future<File> Function(File source, String destination);
typedef FileDeleter = Future<void> Function(File file);

final class LocalBookFileStorage implements BookFileStorage {
  LocalBookFileStorage({
    required Directory supportDirectory,
    FileReader? readFile,
    FileMover? moveFile,
    FileDeleter? deleteFile,
  }) : _booksRoot = Directory(p.join(supportDirectory.path, 'books')),
       _readFile = readFile ?? ((file) => file.openRead()),
       _moveFile =
           moveFile ?? ((file, destination) => file.rename(destination)),
       _deleteFile = deleteFile ?? ((file) => file.delete());

  final Directory _booksRoot;
  final FileReader _readFile;
  final FileMover _moveFile;
  final FileDeleter _deleteFile;

  @override
  Future<ValidatedPdf> validateAndHash(PickedPdf source) async {
    if (!source.sourcePath.toLowerCase().endsWith('.pdf')) {
      throw const PdfValidationException(PdfValidationFailureKind.nonPdf);
    }
    final type = await FileSystemEntity.type(
      source.sourcePath,
      followLinks: true,
    );
    if (type == FileSystemEntityType.notFound) {
      throw const PdfValidationException(PdfValidationFailureKind.missing);
    }
    if (type != FileSystemEntityType.file) {
      throw const PdfValidationException(PdfValidationFailureKind.directory);
    }
    try {
      return ValidatedPdf(
        hash: (await sha256.bind(_readFile(File(source.sourcePath))).first)
            .toString(),
      );
    } on PdfValidationException {
      rethrow;
    } catch (_) {
      throw const PdfValidationException(PdfValidationFailureKind.unreadable);
    }
  }

  @override
  Future<StagedBookFile> stageCopy({
    required PickedPdf source,
    required String bookId,
  }) async {
    await _ensureDirectories();
    final finalPath = p.join(_booksRoot.path, '$bookId.pdf');
    final stagingPath = p.join(
      _booksRoot.path,
      '.staging',
      '$bookId-${DateTime.now().microsecondsSinceEpoch}.pdf',
    );
    final staged = File(stagingPath);
    try {
      final sink = staged.openWrite();
      await sink.addStream(_readFile(File(source.sourcePath)));
      await sink.close();
      return StagedBookFile(stagingPath: stagingPath, finalPath: finalPath);
    } catch (_) {
      if (await staged.exists()) {
        await staged.delete();
      }
      rethrow;
    }
  }

  @override
  Future<String> commitStage(StagedBookFile staged) async {
    _requireOwned(staged.stagingPath);
    _requireOwned(staged.finalPath);
    await _moveFile(File(staged.stagingPath), staged.finalPath);
    return staged.finalPath;
  }

  @override
  Future<void> discardStage(StagedBookFile staged) =>
      _deleteOwnedIfPresent(staged.stagingPath);

  @override
  Future<BookFileBackup?> backupOwnedFile(String path) async {
    _requireOwned(path);
    final source = File(path);
    if (!await source.exists()) {
      return null;
    }
    await _ensureDirectories();
    final backupPath = p.join(
      _booksRoot.path,
      '.backup',
      '${p.basename(path)}-${DateTime.now().microsecondsSinceEpoch}',
    );
    await _moveFile(source, backupPath);
    return BookFileBackup(originalPath: path, backupPath: backupPath);
  }

  @override
  Future<void> restoreBackup(BookFileBackup backup) async {
    _requireOwned(backup.originalPath);
    _requireOwned(backup.backupPath);
    if (await File(backup.backupPath).exists()) {
      await _moveFile(File(backup.backupPath), backup.originalPath);
    }
  }

  @override
  Future<void> discardBackup(BookFileBackup backup) =>
      _deleteOwnedIfPresent(backup.backupPath);

  @override
  Future<QuarantinedBookFiles> quarantineOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {
    final paths = [
      pdfPath,
      if (coverPath != null && coverPath.isNotEmpty) coverPath,
    ];
    for (final path in paths) {
      _requireOwned(path);
    }
    await _ensureDirectories();
    final moved = <BookFileBackup>[];
    try {
      for (final path in paths) {
        if (!await File(path).exists()) {
          continue;
        }
        final trashPath = p.join(
          _booksRoot.path,
          '.trash',
          '${p.basename(path)}-${DateTime.now().microsecondsSinceEpoch}',
        );
        await _moveFile(File(path), trashPath);
        moved.add(BookFileBackup(originalPath: path, backupPath: trashPath));
      }
      return QuarantinedBookFiles(List.unmodifiable(moved));
    } catch (_) {
      for (final file in moved.reversed) {
        await restoreBackup(file);
      }
      rethrow;
    }
  }

  @override
  Future<void> restoreQuarantine(QuarantinedBookFiles quarantine) async {
    for (final file in quarantine.files.reversed) {
      await restoreBackup(file);
    }
  }

  @override
  Future<void> discardQuarantine(QuarantinedBookFiles quarantine) async {
    for (final file in quarantine.files) {
      await discardBackup(file);
    }
  }

  @override
  Future<void> removeOwnedFiles({
    required String pdfPath,
    String? coverPath,
  }) async {
    await _deleteOwnedIfPresent(pdfPath);
    if (coverPath != null && coverPath.isNotEmpty) {
      await _deleteOwnedIfPresent(coverPath);
    }
  }

  Future<void> _ensureDirectories() async {
    await _booksRoot.create(recursive: true);
    for (final name in ['.staging', '.backup', '.trash']) {
      await Directory(p.join(_booksRoot.path, name)).create();
    }
  }

  Future<void> _deleteOwnedIfPresent(String path) async {
    _requireOwned(path);
    final file = File(path);
    if (await file.exists()) {
      await _deleteFile(file);
    }
  }

  void _requireOwned(String path) {
    final root = p.normalize(p.absolute(_booksRoot.path));
    final candidate = p.normalize(p.absolute(path));
    if (!p.isWithin(root, candidate)) {
      throw UnsafeBookPathException(path);
    }
  }
}
