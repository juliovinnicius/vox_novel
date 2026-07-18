import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vox_novel/app/app.dart';
import 'package:vox_novel/app/app_cubit.dart';
import 'package:vox_novel/app/dependency_injection/configure_dependencies.dart';
import 'package:vox_novel/features/import_book/domain/services/pdf_picker.dart';
import 'package:vox_novel/features/pdf_processing/domain/repositories/text_processing_repository.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/pdf_text_extractor.dart';
import 'package:vox_novel/features/pdf_processing/domain/services/text_processing_service.dart';

typedef DependencyConfigurator =
    Future<void> Function({
      required GetIt instance,
      QueryExecutor? databaseExecutor,
      Directory? supportDirectory,
      PdfPicker? pdfPicker,
      DateTime Function()? clock,
      String Function()? generateId,
      PdfTextExtractor? pdfTextExtractor,
      TextProcessingRepository? textProcessingRepository,
      ProcessingExecutor processingExecutor,
      Future<void> Function()? initializePdfEngine,
    });

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createApplication());
}

Future<VoxNovelApp> createApplication({
  GetIt? instance,
  QueryExecutor? databaseExecutor,
  Directory? supportDirectory,
  PdfPicker? pdfPicker,
  DateTime Function()? clock,
  String Function()? generateId,
  PdfTextExtractor? pdfTextExtractor,
  TextProcessingRepository? textProcessingRepository,
  ProcessingExecutor processingExecutor = isolateProcessingExecutor,
  Future<void> Function()? initializePdfEngine,
  DependencyConfigurator? configure,
}) async {
  final locator = instance ?? GetIt.instance;
  await (configure ?? _configureDependencies)(
    instance: locator,
    databaseExecutor: databaseExecutor,
    supportDirectory: supportDirectory,
    pdfPicker: pdfPicker,
    clock: clock,
    generateId: generateId,
    pdfTextExtractor: pdfTextExtractor,
    textProcessingRepository: textProcessingRepository,
    processingExecutor: processingExecutor,
    initializePdfEngine: initializePdfEngine,
  );

  final appCubit = locator<AppCubit>()..markReady();
  return VoxNovelApp(router: locator<GoRouter>(), appCubit: appCubit);
}

Future<void> _configureDependencies({
  required GetIt instance,
  QueryExecutor? databaseExecutor,
  Directory? supportDirectory,
  PdfPicker? pdfPicker,
  DateTime Function()? clock,
  String Function()? generateId,
  PdfTextExtractor? pdfTextExtractor,
  TextProcessingRepository? textProcessingRepository,
  ProcessingExecutor processingExecutor = isolateProcessingExecutor,
  Future<void> Function()? initializePdfEngine,
}) {
  return configureDependencies(
    instance: instance,
    databaseExecutor: databaseExecutor,
    supportDirectory: supportDirectory,
    pdfPicker: pdfPicker,
    clock: clock,
    generateId: generateId,
    pdfTextExtractor: pdfTextExtractor,
    textProcessingRepository: textProcessingRepository,
    processingExecutor: processingExecutor,
    initializePdfEngine: initializePdfEngine,
  );
}
