// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storedFilePathMeta = const VerificationMeta(
    'storedFilePath',
  );
  @override
  late final GeneratedColumn<String> storedFilePath = GeneratedColumn<String>(
    'stored_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BookStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BookStatus>($BooksTable.$converterstatus);
  static const VerificationMeta _processingProgressMeta =
      const VerificationMeta('processingProgress');
  @override
  late final GeneratedColumn<double> processingProgress =
      GeneratedColumn<double>(
        'processing_progress',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _chapterCountMeta = const VerificationMeta(
    'chapterCount',
  );
  @override
  late final GeneratedColumn<int> chapterCount = GeneratedColumn<int>(
    'chapter_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _blockCountMeta = const VerificationMeta(
    'blockCount',
  );
  @override
  late final GeneratedColumn<int> blockCount = GeneratedColumn<int>(
    'block_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProcessingStage?, String>
  processingStage = GeneratedColumn<String>(
    'processing_stage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ProcessingStage?>($BooksTable.$converterprocessingStage);
  static const VerificationMeta _activeContentRunIdMeta =
      const VerificationMeta('activeContentRunId');
  @override
  late final GeneratedColumn<String> activeContentRunId =
      GeneratedColumn<String>(
        'active_content_run_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints:
            'NULL REFERENCES processing_runs(id) ON DELETE SET NULL',
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BooksTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BooksTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    coverPath,
    originalFileName,
    storedFilePath,
    fileHash,
    status,
    processingProgress,
    pageCount,
    chapterCount,
    blockCount,
    processingStage,
    activeContentRunId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalFileNameMeta);
    }
    if (data.containsKey('stored_file_path')) {
      context.handle(
        _storedFilePathMeta,
        storedFilePath.isAcceptableOrUnknown(
          data['stored_file_path']!,
          _storedFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storedFilePathMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('processing_progress')) {
      context.handle(
        _processingProgressMeta,
        processingProgress.isAcceptableOrUnknown(
          data['processing_progress']!,
          _processingProgressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processingProgressMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('chapter_count')) {
      context.handle(
        _chapterCountMeta,
        chapterCount.isAcceptableOrUnknown(
          data['chapter_count']!,
          _chapterCountMeta,
        ),
      );
    }
    if (data.containsKey('block_count')) {
      context.handle(
        _blockCountMeta,
        blockCount.isAcceptableOrUnknown(data['block_count']!, _blockCountMeta),
      );
    }
    if (data.containsKey('active_content_run_id')) {
      context.handle(
        _activeContentRunIdMeta,
        activeContentRunId.isAcceptableOrUnknown(
          data['active_content_run_id']!,
          _activeContentRunIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      )!,
      storedFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stored_file_path'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      status: $BooksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      processingProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}processing_progress'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      chapterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_count'],
      )!,
      blockCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}block_count'],
      )!,
      processingStage: $BooksTable.$converterprocessingStage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}processing_stage'],
        ),
      ),
      activeContentRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_content_run_id'],
      ),
      createdAt: $BooksTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $BooksTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }

  static TypeConverter<BookStatus, String> $converterstatus =
      const BookStatusConverter();
  static TypeConverter<ProcessingStage?, String?> $converterprocessingStage =
      NullAwareTypeConverter.wrap(const ProcessingStageConverter());
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Book extends DataClass implements Insertable<Book> {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String originalFileName;
  final String storedFilePath;
  final String fileHash;
  final BookStatus status;
  final double processingProgress;
  final int pageCount;
  final int chapterCount;
  final int blockCount;
  final ProcessingStage? processingStage;
  final String? activeContentRunId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Book({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    required this.originalFileName,
    required this.storedFilePath,
    required this.fileHash,
    required this.status,
    required this.processingProgress,
    required this.pageCount,
    required this.chapterCount,
    required this.blockCount,
    this.processingStage,
    this.activeContentRunId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['original_file_name'] = Variable<String>(originalFileName);
    map['stored_file_path'] = Variable<String>(storedFilePath);
    map['file_hash'] = Variable<String>(fileHash);
    {
      map['status'] = Variable<String>(
        $BooksTable.$converterstatus.toSql(status),
      );
    }
    map['processing_progress'] = Variable<double>(processingProgress);
    map['page_count'] = Variable<int>(pageCount);
    map['chapter_count'] = Variable<int>(chapterCount);
    map['block_count'] = Variable<int>(blockCount);
    if (!nullToAbsent || processingStage != null) {
      map['processing_stage'] = Variable<String>(
        $BooksTable.$converterprocessingStage.toSql(processingStage),
      );
    }
    if (!nullToAbsent || activeContentRunId != null) {
      map['active_content_run_id'] = Variable<String>(activeContentRunId);
    }
    {
      map['created_at'] = Variable<int>(
        $BooksTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $BooksTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      originalFileName: Value(originalFileName),
      storedFilePath: Value(storedFilePath),
      fileHash: Value(fileHash),
      status: Value(status),
      processingProgress: Value(processingProgress),
      pageCount: Value(pageCount),
      chapterCount: Value(chapterCount),
      blockCount: Value(blockCount),
      processingStage: processingStage == null && nullToAbsent
          ? const Value.absent()
          : Value(processingStage),
      activeContentRunId: activeContentRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(activeContentRunId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      originalFileName: serializer.fromJson<String>(json['originalFileName']),
      storedFilePath: serializer.fromJson<String>(json['storedFilePath']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      status: serializer.fromJson<BookStatus>(json['status']),
      processingProgress: serializer.fromJson<double>(
        json['processingProgress'],
      ),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      chapterCount: serializer.fromJson<int>(json['chapterCount']),
      blockCount: serializer.fromJson<int>(json['blockCount']),
      processingStage: serializer.fromJson<ProcessingStage?>(
        json['processingStage'],
      ),
      activeContentRunId: serializer.fromJson<String?>(
        json['activeContentRunId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'coverPath': serializer.toJson<String?>(coverPath),
      'originalFileName': serializer.toJson<String>(originalFileName),
      'storedFilePath': serializer.toJson<String>(storedFilePath),
      'fileHash': serializer.toJson<String>(fileHash),
      'status': serializer.toJson<BookStatus>(status),
      'processingProgress': serializer.toJson<double>(processingProgress),
      'pageCount': serializer.toJson<int>(pageCount),
      'chapterCount': serializer.toJson<int>(chapterCount),
      'blockCount': serializer.toJson<int>(blockCount),
      'processingStage': serializer.toJson<ProcessingStage?>(processingStage),
      'activeContentRunId': serializer.toJson<String?>(activeContentRunId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Book copyWith({
    String? id,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> coverPath = const Value.absent(),
    String? originalFileName,
    String? storedFilePath,
    String? fileHash,
    BookStatus? status,
    double? processingProgress,
    int? pageCount,
    int? chapterCount,
    int? blockCount,
    Value<ProcessingStage?> processingStage = const Value.absent(),
    Value<String?> activeContentRunId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    originalFileName: originalFileName ?? this.originalFileName,
    storedFilePath: storedFilePath ?? this.storedFilePath,
    fileHash: fileHash ?? this.fileHash,
    status: status ?? this.status,
    processingProgress: processingProgress ?? this.processingProgress,
    pageCount: pageCount ?? this.pageCount,
    chapterCount: chapterCount ?? this.chapterCount,
    blockCount: blockCount ?? this.blockCount,
    processingStage: processingStage.present
        ? processingStage.value
        : this.processingStage,
    activeContentRunId: activeContentRunId.present
        ? activeContentRunId.value
        : this.activeContentRunId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      storedFilePath: data.storedFilePath.present
          ? data.storedFilePath.value
          : this.storedFilePath,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      status: data.status.present ? data.status.value : this.status,
      processingProgress: data.processingProgress.present
          ? data.processingProgress.value
          : this.processingProgress,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      chapterCount: data.chapterCount.present
          ? data.chapterCount.value
          : this.chapterCount,
      blockCount: data.blockCount.present
          ? data.blockCount.value
          : this.blockCount,
      processingStage: data.processingStage.present
          ? data.processingStage.value
          : this.processingStage,
      activeContentRunId: data.activeContentRunId.present
          ? data.activeContentRunId.value
          : this.activeContentRunId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('storedFilePath: $storedFilePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('status: $status, ')
          ..write('processingProgress: $processingProgress, ')
          ..write('pageCount: $pageCount, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('blockCount: $blockCount, ')
          ..write('processingStage: $processingStage, ')
          ..write('activeContentRunId: $activeContentRunId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    coverPath,
    originalFileName,
    storedFilePath,
    fileHash,
    status,
    processingProgress,
    pageCount,
    chapterCount,
    blockCount,
    processingStage,
    activeContentRunId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverPath == this.coverPath &&
          other.originalFileName == this.originalFileName &&
          other.storedFilePath == this.storedFilePath &&
          other.fileHash == this.fileHash &&
          other.status == this.status &&
          other.processingProgress == this.processingProgress &&
          other.pageCount == this.pageCount &&
          other.chapterCount == this.chapterCount &&
          other.blockCount == this.blockCount &&
          other.processingStage == this.processingStage &&
          other.activeContentRunId == this.activeContentRunId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> coverPath;
  final Value<String> originalFileName;
  final Value<String> storedFilePath;
  final Value<String> fileHash;
  final Value<BookStatus> status;
  final Value<double> processingProgress;
  final Value<int> pageCount;
  final Value<int> chapterCount;
  final Value<int> blockCount;
  final Value<ProcessingStage?> processingStage;
  final Value<String?> activeContentRunId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.storedFilePath = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.status = const Value.absent(),
    this.processingProgress = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.blockCount = const Value.absent(),
    this.processingStage = const Value.absent(),
    this.activeContentRunId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String title,
    this.author = const Value.absent(),
    this.coverPath = const Value.absent(),
    required String originalFileName,
    required String storedFilePath,
    required String fileHash,
    required BookStatus status,
    required double processingProgress,
    this.pageCount = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.blockCount = const Value.absent(),
    this.processingStage = const Value.absent(),
    this.activeContentRunId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       originalFileName = Value(originalFileName),
       storedFilePath = Value(storedFilePath),
       fileHash = Value(fileHash),
       status = Value(status),
       processingProgress = Value(processingProgress),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverPath,
    Expression<String>? originalFileName,
    Expression<String>? storedFilePath,
    Expression<String>? fileHash,
    Expression<String>? status,
    Expression<double>? processingProgress,
    Expression<int>? pageCount,
    Expression<int>? chapterCount,
    Expression<int>? blockCount,
    Expression<String>? processingStage,
    Expression<String>? activeContentRunId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverPath != null) 'cover_path': coverPath,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (storedFilePath != null) 'stored_file_path': storedFilePath,
      if (fileHash != null) 'file_hash': fileHash,
      if (status != null) 'status': status,
      if (processingProgress != null) 'processing_progress': processingProgress,
      if (pageCount != null) 'page_count': pageCount,
      if (chapterCount != null) 'chapter_count': chapterCount,
      if (blockCount != null) 'block_count': blockCount,
      if (processingStage != null) 'processing_stage': processingStage,
      if (activeContentRunId != null)
        'active_content_run_id': activeContentRunId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? coverPath,
    Value<String>? originalFileName,
    Value<String>? storedFilePath,
    Value<String>? fileHash,
    Value<BookStatus>? status,
    Value<double>? processingProgress,
    Value<int>? pageCount,
    Value<int>? chapterCount,
    Value<int>? blockCount,
    Value<ProcessingStage?>? processingStage,
    Value<String?>? activeContentRunId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      originalFileName: originalFileName ?? this.originalFileName,
      storedFilePath: storedFilePath ?? this.storedFilePath,
      fileHash: fileHash ?? this.fileHash,
      status: status ?? this.status,
      processingProgress: processingProgress ?? this.processingProgress,
      pageCount: pageCount ?? this.pageCount,
      chapterCount: chapterCount ?? this.chapterCount,
      blockCount: blockCount ?? this.blockCount,
      processingStage: processingStage ?? this.processingStage,
      activeContentRunId: activeContentRunId ?? this.activeContentRunId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (storedFilePath.present) {
      map['stored_file_path'] = Variable<String>(storedFilePath.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $BooksTable.$converterstatus.toSql(status.value),
      );
    }
    if (processingProgress.present) {
      map['processing_progress'] = Variable<double>(processingProgress.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (chapterCount.present) {
      map['chapter_count'] = Variable<int>(chapterCount.value);
    }
    if (blockCount.present) {
      map['block_count'] = Variable<int>(blockCount.value);
    }
    if (processingStage.present) {
      map['processing_stage'] = Variable<String>(
        $BooksTable.$converterprocessingStage.toSql(processingStage.value),
      );
    }
    if (activeContentRunId.present) {
      map['active_content_run_id'] = Variable<String>(activeContentRunId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $BooksTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $BooksTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverPath: $coverPath, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('storedFilePath: $storedFilePath, ')
          ..write('fileHash: $fileHash, ')
          ..write('status: $status, ')
          ..write('processingProgress: $processingProgress, ')
          ..write('pageCount: $pageCount, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('blockCount: $blockCount, ')
          ..write('processingStage: $processingStage, ')
          ..write('activeContentRunId: $activeContentRunId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProcessingRunsTable extends ProcessingRuns
    with TableInfo<$ProcessingRunsTable, ProcessingRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProcessingRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _cleanTextMeta = const VerificationMeta(
    'cleanText',
  );
  @override
  late final GeneratedColumn<String> cleanText = GeneratedColumn<String>(
    'clean_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ProcessingRunsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ProcessingRunsTable.$convertercompletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    cleanText,
    state,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'processing_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProcessingRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('clean_text')) {
      context.handle(
        _cleanTextMeta,
        cleanText.isAcceptableOrUnknown(data['clean_text']!, _cleanTextMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProcessingRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProcessingRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      cleanText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clean_text'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      startedAt: $ProcessingRunsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      completedAt: $ProcessingRunsTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        ),
      ),
    );
  }

  @override
  $ProcessingRunsTable createAlias(String alias) {
    return $ProcessingRunsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $convertercompletedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $convertercompletedAtn =
      NullAwareTypeConverter.wrap($convertercompletedAt);
}

class ProcessingRun extends DataClass implements Insertable<ProcessingRun> {
  final String id;
  final String bookId;
  final String? cleanText;
  final String state;
  final DateTime startedAt;
  final DateTime? completedAt;
  const ProcessingRun({
    required this.id,
    required this.bookId,
    this.cleanText,
    required this.state,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || cleanText != null) {
      map['clean_text'] = Variable<String>(cleanText);
    }
    map['state'] = Variable<String>(state);
    {
      map['started_at'] = Variable<int>(
        $ProcessingRunsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $ProcessingRunsTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    return map;
  }

  ProcessingRunsCompanion toCompanion(bool nullToAbsent) {
    return ProcessingRunsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      cleanText: cleanText == null && nullToAbsent
          ? const Value.absent()
          : Value(cleanText),
      state: Value(state),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ProcessingRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProcessingRun(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      cleanText: serializer.fromJson<String?>(json['cleanText']),
      state: serializer.fromJson<String>(json['state']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'cleanText': serializer.toJson<String?>(cleanText),
      'state': serializer.toJson<String>(state),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ProcessingRun copyWith({
    String? id,
    String? bookId,
    Value<String?> cleanText = const Value.absent(),
    String? state,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ProcessingRun(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    cleanText: cleanText.present ? cleanText.value : this.cleanText,
    state: state ?? this.state,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ProcessingRun copyWithCompanion(ProcessingRunsCompanion data) {
    return ProcessingRun(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      cleanText: data.cleanText.present ? data.cleanText.value : this.cleanText,
      state: data.state.present ? data.state.value : this.state,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProcessingRun(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('cleanText: $cleanText, ')
          ..write('state: $state, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, cleanText, state, startedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProcessingRun &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.cleanText == this.cleanText &&
          other.state == this.state &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class ProcessingRunsCompanion extends UpdateCompanion<ProcessingRun> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String?> cleanText;
  final Value<String> state;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const ProcessingRunsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.cleanText = const Value.absent(),
    this.state = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProcessingRunsCompanion.insert({
    required String id,
    required String bookId,
    this.cleanText = const Value.absent(),
    required String state,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       state = Value(state),
       startedAt = Value(startedAt);
  static Insertable<ProcessingRun> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? cleanText,
    Expression<String>? state,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (cleanText != null) 'clean_text': cleanText,
      if (state != null) 'state': state,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProcessingRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String?>? cleanText,
    Value<String>? state,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return ProcessingRunsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      cleanText: cleanText ?? this.cleanText,
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (cleanText.present) {
      map['clean_text'] = Variable<String>(cleanText.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $ProcessingRunsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $ProcessingRunsTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProcessingRunsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('cleanText: $cleanText, ')
          ..write('state: $state, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RawPagesTable extends RawPages with TableInfo<$RawPagesTable, RawPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processing_runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanTextMeta = const VerificationMeta(
    'cleanText',
  );
  @override
  late final GeneratedColumn<String> cleanText = GeneratedColumn<String>(
    'clean_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [runId, pageNumber, rawText, cleanText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('clean_text')) {
      context.handle(
        _cleanTextMeta,
        cleanText.isAcceptableOrUnknown(data['clean_text']!, _cleanTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId, pageNumber};
  @override
  RawPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawPage(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      cleanText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clean_text'],
      ),
    );
  }

  @override
  $RawPagesTable createAlias(String alias) {
    return $RawPagesTable(attachedDatabase, alias);
  }
}

class RawPage extends DataClass implements Insertable<RawPage> {
  final String runId;
  final int pageNumber;
  final String rawText;
  final String? cleanText;
  const RawPage({
    required this.runId,
    required this.pageNumber,
    required this.rawText,
    this.cleanText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['page_number'] = Variable<int>(pageNumber);
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || cleanText != null) {
      map['clean_text'] = Variable<String>(cleanText);
    }
    return map;
  }

  RawPagesCompanion toCompanion(bool nullToAbsent) {
    return RawPagesCompanion(
      runId: Value(runId),
      pageNumber: Value(pageNumber),
      rawText: Value(rawText),
      cleanText: cleanText == null && nullToAbsent
          ? const Value.absent()
          : Value(cleanText),
    );
  }

  factory RawPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawPage(
      runId: serializer.fromJson<String>(json['runId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      rawText: serializer.fromJson<String>(json['rawText']),
      cleanText: serializer.fromJson<String?>(json['cleanText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'runId': serializer.toJson<String>(runId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'rawText': serializer.toJson<String>(rawText),
      'cleanText': serializer.toJson<String?>(cleanText),
    };
  }

  RawPage copyWith({
    String? runId,
    int? pageNumber,
    String? rawText,
    Value<String?> cleanText = const Value.absent(),
  }) => RawPage(
    runId: runId ?? this.runId,
    pageNumber: pageNumber ?? this.pageNumber,
    rawText: rawText ?? this.rawText,
    cleanText: cleanText.present ? cleanText.value : this.cleanText,
  );
  RawPage copyWithCompanion(RawPagesCompanion data) {
    return RawPage(
      runId: data.runId.present ? data.runId.value : this.runId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      cleanText: data.cleanText.present ? data.cleanText.value : this.cleanText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawPage(')
          ..write('runId: $runId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('rawText: $rawText, ')
          ..write('cleanText: $cleanText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(runId, pageNumber, rawText, cleanText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawPage &&
          other.runId == this.runId &&
          other.pageNumber == this.pageNumber &&
          other.rawText == this.rawText &&
          other.cleanText == this.cleanText);
}

class RawPagesCompanion extends UpdateCompanion<RawPage> {
  final Value<String> runId;
  final Value<int> pageNumber;
  final Value<String> rawText;
  final Value<String?> cleanText;
  final Value<int> rowid;
  const RawPagesCompanion({
    this.runId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.rawText = const Value.absent(),
    this.cleanText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RawPagesCompanion.insert({
    required String runId,
    required int pageNumber,
    required String rawText,
    this.cleanText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       pageNumber = Value(pageNumber),
       rawText = Value(rawText);
  static Insertable<RawPage> custom({
    Expression<String>? runId,
    Expression<int>? pageNumber,
    Expression<String>? rawText,
    Expression<String>? cleanText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (rawText != null) 'raw_text': rawText,
      if (cleanText != null) 'clean_text': cleanText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RawPagesCompanion copyWith({
    Value<String>? runId,
    Value<int>? pageNumber,
    Value<String>? rawText,
    Value<String?>? cleanText,
    Value<int>? rowid,
  }) {
    return RawPagesCompanion(
      runId: runId ?? this.runId,
      pageNumber: pageNumber ?? this.pageNumber,
      rawText: rawText ?? this.rawText,
      cleanText: cleanText ?? this.cleanText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (cleanText.present) {
      map['clean_text'] = Variable<String>(cleanText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawPagesCompanion(')
          ..write('runId: $runId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('rawText: $rawText, ')
          ..write('cleanText: $cleanText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processing_runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endPageMeta = const VerificationMeta(
    'endPage',
  );
  @override
  late final GeneratedColumn<int> endPage = GeneratedColumn<int>(
    'end_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanTextMeta = const VerificationMeta(
    'cleanText',
  );
  @override
  late final GeneratedColumn<String> cleanText = GeneratedColumn<String>(
    'clean_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ChaptersTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ChaptersTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    bookId,
    title,
    sortOrder,
    startPage,
    endPage,
    cleanText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    } else if (isInserting) {
      context.missing(_startPageMeta);
    }
    if (data.containsKey('end_page')) {
      context.handle(
        _endPageMeta,
        endPage.isAcceptableOrUnknown(data['end_page']!, _endPageMeta),
      );
    } else if (isInserting) {
      context.missing(_endPageMeta);
    }
    if (data.containsKey('clean_text')) {
      context.handle(
        _cleanTextMeta,
        cleanText.isAcceptableOrUnknown(data['clean_text']!, _cleanTextMeta),
      );
    } else if (isInserting) {
      context.missing(_cleanTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      endPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_page'],
      )!,
      cleanText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clean_text'],
      )!,
      createdAt: $ChaptersTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ChaptersTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final String id;
  final String runId;
  final String bookId;
  final String title;
  final int sortOrder;
  final int startPage;
  final int endPage;
  final String cleanText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Chapter({
    required this.id,
    required this.runId,
    required this.bookId,
    required this.title,
    required this.sortOrder,
    required this.startPage,
    required this.endPage,
    required this.cleanText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['book_id'] = Variable<String>(bookId);
    map['title'] = Variable<String>(title);
    map['sort_order'] = Variable<int>(sortOrder);
    map['start_page'] = Variable<int>(startPage);
    map['end_page'] = Variable<int>(endPage);
    map['clean_text'] = Variable<String>(cleanText);
    {
      map['created_at'] = Variable<int>(
        $ChaptersTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $ChaptersTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      runId: Value(runId),
      bookId: Value(bookId),
      title: Value(title),
      sortOrder: Value(sortOrder),
      startPage: Value(startPage),
      endPage: Value(endPage),
      cleanText: Value(cleanText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      title: serializer.fromJson<String>(json['title']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      startPage: serializer.fromJson<int>(json['startPage']),
      endPage: serializer.fromJson<int>(json['endPage']),
      cleanText: serializer.fromJson<String>(json['cleanText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'runId': serializer.toJson<String>(runId),
      'bookId': serializer.toJson<String>(bookId),
      'title': serializer.toJson<String>(title),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'startPage': serializer.toJson<int>(startPage),
      'endPage': serializer.toJson<int>(endPage),
      'cleanText': serializer.toJson<String>(cleanText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chapter copyWith({
    String? id,
    String? runId,
    String? bookId,
    String? title,
    int? sortOrder,
    int? startPage,
    int? endPage,
    String? cleanText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Chapter(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    sortOrder: sortOrder ?? this.sortOrder,
    startPage: startPage ?? this.startPage,
    endPage: endPage ?? this.endPage,
    cleanText: cleanText ?? this.cleanText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      title: data.title.present ? data.title.value : this.title,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      endPage: data.endPage.present ? data.endPage.value : this.endPage,
      cleanText: data.cleanText.present ? data.cleanText.value : this.cleanText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('cleanText: $cleanText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    bookId,
    title,
    sortOrder,
    startPage,
    endPage,
    cleanText,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.bookId == this.bookId &&
          other.title == this.title &&
          other.sortOrder == this.sortOrder &&
          other.startPage == this.startPage &&
          other.endPage == this.endPage &&
          other.cleanText == this.cleanText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> bookId;
  final Value<String> title;
  final Value<int> sortOrder;
  final Value<int> startPage;
  final Value<int> endPage;
  final Value<String> cleanText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.title = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
    this.cleanText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String runId,
    required String bookId,
    required String title,
    required int sortOrder,
    required int startPage,
    required int endPage,
    required String cleanText,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       bookId = Value(bookId),
       title = Value(title),
       sortOrder = Value(sortOrder),
       startPage = Value(startPage),
       endPage = Value(endPage),
       cleanText = Value(cleanText),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Chapter> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? bookId,
    Expression<String>? title,
    Expression<int>? sortOrder,
    Expression<int>? startPage,
    Expression<int>? endPage,
    Expression<String>? cleanText,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (bookId != null) 'book_id': bookId,
      if (title != null) 'title': title,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (startPage != null) 'start_page': startPage,
      if (endPage != null) 'end_page': endPage,
      if (cleanText != null) 'clean_text': cleanText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? bookId,
    Value<String>? title,
    Value<int>? sortOrder,
    Value<int>? startPage,
    Value<int>? endPage,
    Value<String>? cleanText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      cleanText: cleanText ?? this.cleanText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (endPage.present) {
      map['end_page'] = Variable<int>(endPage.value);
    }
    if (cleanText.present) {
      map['clean_text'] = Variable<String>(cleanText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $ChaptersTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ChaptersTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('cleanText: $cleanText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NarrationBlocksTable extends NarrationBlocks
    with TableInfo<$NarrationBlocksTable, NarrationBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NarrationBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES processing_runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta(
    'originalText',
  );
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedTextMeta = const VerificationMeta(
    'normalizedText',
  );
  @override
  late final GeneratedColumn<String> normalizedText = GeneratedColumn<String>(
    'normalized_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterCountMeta = const VerificationMeta(
    'characterCount',
  );
  @override
  late final GeneratedColumn<int> characterCount = GeneratedColumn<int>(
    'character_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endPageMeta = const VerificationMeta(
    'endPage',
  );
  @override
  late final GeneratedColumn<int> endPage = GeneratedColumn<int>(
    'end_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    chapterId,
    sortOrder,
    originalText,
    normalizedText,
    characterCount,
    startPage,
    endPage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'narration_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<NarrationBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('original_text')) {
      context.handle(
        _originalTextMeta,
        originalText.isAcceptableOrUnknown(
          data['original_text']!,
          _originalTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalTextMeta);
    }
    if (data.containsKey('normalized_text')) {
      context.handle(
        _normalizedTextMeta,
        normalizedText.isAcceptableOrUnknown(
          data['normalized_text']!,
          _normalizedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTextMeta);
    }
    if (data.containsKey('character_count')) {
      context.handle(
        _characterCountMeta,
        characterCount.isAcceptableOrUnknown(
          data['character_count']!,
          _characterCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterCountMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    } else if (isInserting) {
      context.missing(_startPageMeta);
    }
    if (data.containsKey('end_page')) {
      context.handle(
        _endPageMeta,
        endPage.isAcceptableOrUnknown(data['end_page']!, _endPageMeta),
      );
    } else if (isInserting) {
      context.missing(_endPageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NarrationBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NarrationBlock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      originalText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_text'],
      )!,
      normalizedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_text'],
      )!,
      characterCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}character_count'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      endPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_page'],
      )!,
    );
  }

  @override
  $NarrationBlocksTable createAlias(String alias) {
    return $NarrationBlocksTable(attachedDatabase, alias);
  }
}

class NarrationBlock extends DataClass implements Insertable<NarrationBlock> {
  final String id;
  final String runId;
  final String chapterId;
  final int sortOrder;
  final String originalText;
  final String normalizedText;
  final int characterCount;
  final int startPage;
  final int endPage;
  const NarrationBlock({
    required this.id,
    required this.runId,
    required this.chapterId,
    required this.sortOrder,
    required this.originalText,
    required this.normalizedText,
    required this.characterCount,
    required this.startPage,
    required this.endPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['original_text'] = Variable<String>(originalText);
    map['normalized_text'] = Variable<String>(normalizedText);
    map['character_count'] = Variable<int>(characterCount);
    map['start_page'] = Variable<int>(startPage);
    map['end_page'] = Variable<int>(endPage);
    return map;
  }

  NarrationBlocksCompanion toCompanion(bool nullToAbsent) {
    return NarrationBlocksCompanion(
      id: Value(id),
      runId: Value(runId),
      chapterId: Value(chapterId),
      sortOrder: Value(sortOrder),
      originalText: Value(originalText),
      normalizedText: Value(normalizedText),
      characterCount: Value(characterCount),
      startPage: Value(startPage),
      endPage: Value(endPage),
    );
  }

  factory NarrationBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NarrationBlock(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      originalText: serializer.fromJson<String>(json['originalText']),
      normalizedText: serializer.fromJson<String>(json['normalizedText']),
      characterCount: serializer.fromJson<int>(json['characterCount']),
      startPage: serializer.fromJson<int>(json['startPage']),
      endPage: serializer.fromJson<int>(json['endPage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'runId': serializer.toJson<String>(runId),
      'chapterId': serializer.toJson<String>(chapterId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'originalText': serializer.toJson<String>(originalText),
      'normalizedText': serializer.toJson<String>(normalizedText),
      'characterCount': serializer.toJson<int>(characterCount),
      'startPage': serializer.toJson<int>(startPage),
      'endPage': serializer.toJson<int>(endPage),
    };
  }

  NarrationBlock copyWith({
    String? id,
    String? runId,
    String? chapterId,
    int? sortOrder,
    String? originalText,
    String? normalizedText,
    int? characterCount,
    int? startPage,
    int? endPage,
  }) => NarrationBlock(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    chapterId: chapterId ?? this.chapterId,
    sortOrder: sortOrder ?? this.sortOrder,
    originalText: originalText ?? this.originalText,
    normalizedText: normalizedText ?? this.normalizedText,
    characterCount: characterCount ?? this.characterCount,
    startPage: startPage ?? this.startPage,
    endPage: endPage ?? this.endPage,
  );
  NarrationBlock copyWithCompanion(NarrationBlocksCompanion data) {
    return NarrationBlock(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      normalizedText: data.normalizedText.present
          ? data.normalizedText.value
          : this.normalizedText,
      characterCount: data.characterCount.present
          ? data.characterCount.value
          : this.characterCount,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      endPage: data.endPage.present ? data.endPage.value : this.endPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NarrationBlock(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('chapterId: $chapterId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('originalText: $originalText, ')
          ..write('normalizedText: $normalizedText, ')
          ..write('characterCount: $characterCount, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    chapterId,
    sortOrder,
    originalText,
    normalizedText,
    characterCount,
    startPage,
    endPage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NarrationBlock &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.chapterId == this.chapterId &&
          other.sortOrder == this.sortOrder &&
          other.originalText == this.originalText &&
          other.normalizedText == this.normalizedText &&
          other.characterCount == this.characterCount &&
          other.startPage == this.startPage &&
          other.endPage == this.endPage);
}

class NarrationBlocksCompanion extends UpdateCompanion<NarrationBlock> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> chapterId;
  final Value<int> sortOrder;
  final Value<String> originalText;
  final Value<String> normalizedText;
  final Value<int> characterCount;
  final Value<int> startPage;
  final Value<int> endPage;
  final Value<int> rowid;
  const NarrationBlocksCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.originalText = const Value.absent(),
    this.normalizedText = const Value.absent(),
    this.characterCount = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NarrationBlocksCompanion.insert({
    required String id,
    required String runId,
    required String chapterId,
    required int sortOrder,
    required String originalText,
    required String normalizedText,
    required int characterCount,
    required int startPage,
    required int endPage,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       chapterId = Value(chapterId),
       sortOrder = Value(sortOrder),
       originalText = Value(originalText),
       normalizedText = Value(normalizedText),
       characterCount = Value(characterCount),
       startPage = Value(startPage),
       endPage = Value(endPage);
  static Insertable<NarrationBlock> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? chapterId,
    Expression<int>? sortOrder,
    Expression<String>? originalText,
    Expression<String>? normalizedText,
    Expression<int>? characterCount,
    Expression<int>? startPage,
    Expression<int>? endPage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (originalText != null) 'original_text': originalText,
      if (normalizedText != null) 'normalized_text': normalizedText,
      if (characterCount != null) 'character_count': characterCount,
      if (startPage != null) 'start_page': startPage,
      if (endPage != null) 'end_page': endPage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NarrationBlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? chapterId,
    Value<int>? sortOrder,
    Value<String>? originalText,
    Value<String>? normalizedText,
    Value<int>? characterCount,
    Value<int>? startPage,
    Value<int>? endPage,
    Value<int>? rowid,
  }) {
    return NarrationBlocksCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      chapterId: chapterId ?? this.chapterId,
      sortOrder: sortOrder ?? this.sortOrder,
      originalText: originalText ?? this.originalText,
      normalizedText: normalizedText ?? this.normalizedText,
      characterCount: characterCount ?? this.characterCount,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (normalizedText.present) {
      map['normalized_text'] = Variable<String>(normalizedText.value);
    }
    if (characterCount.present) {
      map['character_count'] = Variable<int>(characterCount.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (endPage.present) {
      map['end_page'] = Variable<int>(endPage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NarrationBlocksCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('chapterId: $chapterId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('originalText: $originalText, ')
          ..write('normalizedText: $normalizedText, ')
          ..write('characterCount: $characterCount, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReaderSettingsRowsTable extends ReaderSettingsRows
    with TableInfo<$ReaderSettingsRowsTable, ReaderSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL CHECK (id = 1)',
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReaderTheme, String> theme =
      GeneratedColumn<String>(
        'theme',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReaderTheme>($ReaderSettingsRowsTable.$convertertheme);
  @override
  late final GeneratedColumnWithTypeConverter<ReaderFontFamily, String>
  fontFamily =
      GeneratedColumn<String>(
        'font_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReaderFontFamily>(
        $ReaderSettingsRowsTable.$converterfontFamily,
      );
  static const VerificationMeta _fontSizeMeta = const VerificationMeta(
    'fontSize',
  );
  @override
  late final GeneratedColumn<int> fontSize = GeneratedColumn<int>(
    'font_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (font_size BETWEEN 14 AND 32 AND font_size % 2 = 0)',
  );
  static const VerificationMeta _lineHeightMeta = const VerificationMeta(
    'lineHeight',
  );
  @override
  late final GeneratedColumn<double> lineHeight = GeneratedColumn<double>(
    'line_height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (line_height IN (1.2, 1.5, 1.8, 2.0))',
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReaderSettingsRowsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    theme,
    fontFamily,
    fontSize,
    lineHeight,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('font_size')) {
      context.handle(
        _fontSizeMeta,
        fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fontSizeMeta);
    }
    if (data.containsKey('line_height')) {
      context.handle(
        _lineHeightMeta,
        lineHeight.isAcceptableOrUnknown(data['line_height']!, _lineHeightMeta),
      );
    } else if (isInserting) {
      context.missing(_lineHeightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReaderSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      theme: $ReaderSettingsRowsTable.$convertertheme.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme'],
        )!,
      ),
      fontFamily: $ReaderSettingsRowsTable.$converterfontFamily.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}font_family'],
        )!,
      ),
      fontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}font_size'],
      )!,
      lineHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_height'],
      )!,
      updatedAt: $ReaderSettingsRowsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ReaderSettingsRowsTable createAlias(String alias) {
    return $ReaderSettingsRowsTable(attachedDatabase, alias);
  }

  static TypeConverter<ReaderTheme, String> $convertertheme =
      const ReaderThemeConverter();
  static TypeConverter<ReaderFontFamily, String> $converterfontFamily =
      const ReaderFontFamilyConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class ReaderSettingsRow extends DataClass
    implements Insertable<ReaderSettingsRow> {
  final int id;
  final ReaderTheme theme;
  final ReaderFontFamily fontFamily;
  final int fontSize;
  final double lineHeight;
  final DateTime updatedAt;
  const ReaderSettingsRow({
    required this.id,
    required this.theme,
    required this.fontFamily,
    required this.fontSize,
    required this.lineHeight,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['theme'] = Variable<String>(
        $ReaderSettingsRowsTable.$convertertheme.toSql(theme),
      );
    }
    {
      map['font_family'] = Variable<String>(
        $ReaderSettingsRowsTable.$converterfontFamily.toSql(fontFamily),
      );
    }
    map['font_size'] = Variable<int>(fontSize);
    map['line_height'] = Variable<double>(lineHeight);
    {
      map['updated_at'] = Variable<int>(
        $ReaderSettingsRowsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReaderSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return ReaderSettingsRowsCompanion(
      id: Value(id),
      theme: Value(theme),
      fontFamily: Value(fontFamily),
      fontSize: Value(fontSize),
      lineHeight: Value(lineHeight),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReaderSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      theme: serializer.fromJson<ReaderTheme>(json['theme']),
      fontFamily: serializer.fromJson<ReaderFontFamily>(json['fontFamily']),
      fontSize: serializer.fromJson<int>(json['fontSize']),
      lineHeight: serializer.fromJson<double>(json['lineHeight']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'theme': serializer.toJson<ReaderTheme>(theme),
      'fontFamily': serializer.toJson<ReaderFontFamily>(fontFamily),
      'fontSize': serializer.toJson<int>(fontSize),
      'lineHeight': serializer.toJson<double>(lineHeight),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReaderSettingsRow copyWith({
    int? id,
    ReaderTheme? theme,
    ReaderFontFamily? fontFamily,
    int? fontSize,
    double? lineHeight,
    DateTime? updatedAt,
  }) => ReaderSettingsRow(
    id: id ?? this.id,
    theme: theme ?? this.theme,
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReaderSettingsRow copyWithCompanion(ReaderSettingsRowsCompanion data) {
    return ReaderSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      theme: data.theme.present ? data.theme.value : this.theme,
      fontFamily: data.fontFamily.present
          ? data.fontFamily.value
          : this.fontFamily,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      lineHeight: data.lineHeight.present
          ? data.lineHeight.value
          : this.lineHeight,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderSettingsRow(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('fontSize: $fontSize, ')
          ..write('lineHeight: $lineHeight, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, theme, fontFamily, fontSize, lineHeight, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderSettingsRow &&
          other.id == this.id &&
          other.theme == this.theme &&
          other.fontFamily == this.fontFamily &&
          other.fontSize == this.fontSize &&
          other.lineHeight == this.lineHeight &&
          other.updatedAt == this.updatedAt);
}

class ReaderSettingsRowsCompanion extends UpdateCompanion<ReaderSettingsRow> {
  final Value<int> id;
  final Value<ReaderTheme> theme;
  final Value<ReaderFontFamily> fontFamily;
  final Value<int> fontSize;
  final Value<double> lineHeight;
  final Value<DateTime> updatedAt;
  const ReaderSettingsRowsCompanion({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.fontFamily = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.lineHeight = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReaderSettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    required ReaderTheme theme,
    required ReaderFontFamily fontFamily,
    required int fontSize,
    required double lineHeight,
    required DateTime updatedAt,
  }) : theme = Value(theme),
       fontFamily = Value(fontFamily),
       fontSize = Value(fontSize),
       lineHeight = Value(lineHeight),
       updatedAt = Value(updatedAt);
  static Insertable<ReaderSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? theme,
    Expression<String>? fontFamily,
    Expression<int>? fontSize,
    Expression<double>? lineHeight,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (theme != null) 'theme': theme,
      if (fontFamily != null) 'font_family': fontFamily,
      if (fontSize != null) 'font_size': fontSize,
      if (lineHeight != null) 'line_height': lineHeight,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReaderSettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<ReaderTheme>? theme,
    Value<ReaderFontFamily>? fontFamily,
    Value<int>? fontSize,
    Value<double>? lineHeight,
    Value<DateTime>? updatedAt,
  }) {
    return ReaderSettingsRowsCompanion(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(
        $ReaderSettingsRowsTable.$convertertheme.toSql(theme.value),
      );
    }
    if (fontFamily.present) {
      map['font_family'] = Variable<String>(
        $ReaderSettingsRowsTable.$converterfontFamily.toSql(fontFamily.value),
      );
    }
    if (fontSize.present) {
      map['font_size'] = Variable<int>(fontSize.value);
    }
    if (lineHeight.present) {
      map['line_height'] = Variable<double>(lineHeight.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ReaderSettingsRowsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderSettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('fontSize: $fontSize, ')
          ..write('lineHeight: $lineHeight, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReaderPositionsTable extends ReaderPositions
    with TableInfo<$ReaderPositionsTable, ReaderPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReaderPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReaderMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReaderMode>($ReaderPositionsTable.$convertermode);
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPageMeta = const VerificationMeta(
    'pdfPage',
  );
  @override
  late final GeneratedColumn<int> pdfPage = GeneratedColumn<int>(
    'pdf_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (pdf_page > 0)',
    defaultValue: const CustomExpression('1'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReaderPositionsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    mode,
    chapterId,
    blockId,
    pdfPage,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    }
    if (data.containsKey('pdf_page')) {
      context.handle(
        _pdfPageMeta,
        pdfPage.isAcceptableOrUnknown(data['pdf_page']!, _pdfPageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  ReaderPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderPosition(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      mode: $ReaderPositionsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      ),
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      ),
      pdfPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pdf_page'],
      )!,
      updatedAt: $ReaderPositionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ReaderPositionsTable createAlias(String alias) {
    return $ReaderPositionsTable(attachedDatabase, alias);
  }

  static TypeConverter<ReaderMode, String> $convertermode =
      const ReaderModeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class ReaderPosition extends DataClass implements Insertable<ReaderPosition> {
  final String bookId;
  final ReaderMode mode;
  final String? chapterId;
  final String? blockId;
  final int pdfPage;
  final DateTime updatedAt;
  const ReaderPosition({
    required this.bookId,
    required this.mode,
    this.chapterId,
    this.blockId,
    required this.pdfPage,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    {
      map['mode'] = Variable<String>(
        $ReaderPositionsTable.$convertermode.toSql(mode),
      );
    }
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<String>(chapterId);
    }
    if (!nullToAbsent || blockId != null) {
      map['block_id'] = Variable<String>(blockId);
    }
    map['pdf_page'] = Variable<int>(pdfPage);
    {
      map['updated_at'] = Variable<int>(
        $ReaderPositionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReaderPositionsCompanion toCompanion(bool nullToAbsent) {
    return ReaderPositionsCompanion(
      bookId: Value(bookId),
      mode: Value(mode),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      blockId: blockId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockId),
      pdfPage: Value(pdfPage),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReaderPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderPosition(
      bookId: serializer.fromJson<String>(json['bookId']),
      mode: serializer.fromJson<ReaderMode>(json['mode']),
      chapterId: serializer.fromJson<String?>(json['chapterId']),
      blockId: serializer.fromJson<String?>(json['blockId']),
      pdfPage: serializer.fromJson<int>(json['pdfPage']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'mode': serializer.toJson<ReaderMode>(mode),
      'chapterId': serializer.toJson<String?>(chapterId),
      'blockId': serializer.toJson<String?>(blockId),
      'pdfPage': serializer.toJson<int>(pdfPage),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReaderPosition copyWith({
    String? bookId,
    ReaderMode? mode,
    Value<String?> chapterId = const Value.absent(),
    Value<String?> blockId = const Value.absent(),
    int? pdfPage,
    DateTime? updatedAt,
  }) => ReaderPosition(
    bookId: bookId ?? this.bookId,
    mode: mode ?? this.mode,
    chapterId: chapterId.present ? chapterId.value : this.chapterId,
    blockId: blockId.present ? blockId.value : this.blockId,
    pdfPage: pdfPage ?? this.pdfPage,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReaderPosition copyWithCompanion(ReaderPositionsCompanion data) {
    return ReaderPosition(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      mode: data.mode.present ? data.mode.value : this.mode,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      pdfPage: data.pdfPage.present ? data.pdfPage.value : this.pdfPage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderPosition(')
          ..write('bookId: $bookId, ')
          ..write('mode: $mode, ')
          ..write('chapterId: $chapterId, ')
          ..write('blockId: $blockId, ')
          ..write('pdfPage: $pdfPage, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bookId, mode, chapterId, blockId, pdfPage, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderPosition &&
          other.bookId == this.bookId &&
          other.mode == this.mode &&
          other.chapterId == this.chapterId &&
          other.blockId == this.blockId &&
          other.pdfPage == this.pdfPage &&
          other.updatedAt == this.updatedAt);
}

class ReaderPositionsCompanion extends UpdateCompanion<ReaderPosition> {
  final Value<String> bookId;
  final Value<ReaderMode> mode;
  final Value<String?> chapterId;
  final Value<String?> blockId;
  final Value<int> pdfPage;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReaderPositionsCompanion({
    this.bookId = const Value.absent(),
    this.mode = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.blockId = const Value.absent(),
    this.pdfPage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReaderPositionsCompanion.insert({
    required String bookId,
    required ReaderMode mode,
    this.chapterId = const Value.absent(),
    this.blockId = const Value.absent(),
    this.pdfPage = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       mode = Value(mode),
       updatedAt = Value(updatedAt);
  static Insertable<ReaderPosition> custom({
    Expression<String>? bookId,
    Expression<String>? mode,
    Expression<String>? chapterId,
    Expression<String>? blockId,
    Expression<int>? pdfPage,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (mode != null) 'mode': mode,
      if (chapterId != null) 'chapter_id': chapterId,
      if (blockId != null) 'block_id': blockId,
      if (pdfPage != null) 'pdf_page': pdfPage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReaderPositionsCompanion copyWith({
    Value<String>? bookId,
    Value<ReaderMode>? mode,
    Value<String?>? chapterId,
    Value<String?>? blockId,
    Value<int>? pdfPage,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReaderPositionsCompanion(
      bookId: bookId ?? this.bookId,
      mode: mode ?? this.mode,
      chapterId: chapterId ?? this.chapterId,
      blockId: blockId ?? this.blockId,
      pdfPage: pdfPage ?? this.pdfPage,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $ReaderPositionsTable.$convertermode.toSql(mode.value),
      );
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (pdfPage.present) {
      map['pdf_page'] = Variable<int>(pdfPage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $ReaderPositionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderPositionsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('mode: $mode, ')
          ..write('chapterId: $chapterId, ')
          ..write('blockId: $blockId, ')
          ..write('pdfPage: $pdfPage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $ProcessingRunsTable processingRuns = $ProcessingRunsTable(this);
  late final $RawPagesTable rawPages = $RawPagesTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $NarrationBlocksTable narrationBlocks = $NarrationBlocksTable(
    this,
  );
  late final $ReaderSettingsRowsTable readerSettingsRows =
      $ReaderSettingsRowsTable(this);
  late final $ReaderPositionsTable readerPositions = $ReaderPositionsTable(
    this,
  );
  late final Index booksFileHashUnique = Index(
    'books_file_hash_unique',
    'CREATE UNIQUE INDEX books_file_hash_unique ON books (file_hash)',
  );
  late final Index processingRunsBookId = Index(
    'processing_runs_book_id',
    'CREATE INDEX processing_runs_book_id ON processing_runs (book_id)',
  );
  late final Index rawPagesRunPageUnique = Index(
    'raw_pages_run_page_unique',
    'CREATE UNIQUE INDEX raw_pages_run_page_unique ON raw_pages (run_id, page_number)',
  );
  late final Index chaptersBookId = Index(
    'chapters_book_id',
    'CREATE INDEX chapters_book_id ON chapters (book_id)',
  );
  late final Index chaptersRunId = Index(
    'chapters_run_id',
    'CREATE INDEX chapters_run_id ON chapters (run_id)',
  );
  late final Index chaptersRunOrderUnique = Index(
    'chapters_run_order_unique',
    'CREATE UNIQUE INDEX chapters_run_order_unique ON chapters (run_id, sort_order)',
  );
  late final Index narrationBlocksRunId = Index(
    'narration_blocks_run_id',
    'CREATE INDEX narration_blocks_run_id ON narration_blocks (run_id)',
  );
  late final Index narrationBlocksChapterOrderUnique = Index(
    'narration_blocks_chapter_order_unique',
    'CREATE UNIQUE INDEX narration_blocks_chapter_order_unique ON narration_blocks (chapter_id, sort_order)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    processingRuns,
    rawPages,
    chapters,
    narrationBlocks,
    readerSettingsRows,
    readerPositions,
    booksFileHashUnique,
    processingRunsBookId,
    rawPagesRunPageUnique,
    chaptersBookId,
    chaptersRunId,
    chaptersRunOrderUnique,
    narrationBlocksRunId,
    narrationBlocksChapterOrderUnique,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('processing_runs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'processing_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('raw_pages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'processing_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'processing_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('narration_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('narration_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reader_positions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      required String id,
      required String title,
      Value<String?> author,
      Value<String?> coverPath,
      required String originalFileName,
      required String storedFilePath,
      required String fileHash,
      required BookStatus status,
      required double processingProgress,
      Value<int> pageCount,
      Value<int> chapterCount,
      Value<int> blockCount,
      Value<ProcessingStage?> processingStage,
      Value<String?> activeContentRunId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> author,
      Value<String?> coverPath,
      Value<String> originalFileName,
      Value<String> storedFilePath,
      Value<String> fileHash,
      Value<BookStatus> status,
      Value<double> processingProgress,
      Value<int> pageCount,
      Value<int> chapterCount,
      Value<int> blockCount,
      Value<ProcessingStage?> processingStage,
      Value<String?> activeContentRunId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BooksTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProcessingRunsTable, List<ProcessingRun>>
  _processingRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.processingRuns,
    aliasName: 'books__id__processing_runs__book_id',
  );

  $$ProcessingRunsTableProcessedTableManager get processingRunsRefs {
    final manager = $$ProcessingRunsTableTableManager(
      $_db,
      $_db.processingRuns,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_processingRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'books__id__chapters__book_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReaderPositionsTable, List<ReaderPosition>>
  _readerPositionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readerPositions,
    aliasName: 'books__id__reader_positions__book_id',
  );

  $$ReaderPositionsTableProcessedTableManager get readerPositionsRefs {
    final manager = $$ReaderPositionsTableTableManager(
      $_db,
      $_db.readerPositions,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readerPositionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storedFilePath => $composableBuilder(
    column: $table.storedFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BookStatus, BookStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get processingProgress => $composableBuilder(
    column: $table.processingProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blockCount => $composableBuilder(
    column: $table.blockCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProcessingStage?, ProcessingStage, String>
  get processingStage => $composableBuilder(
    column: $table.processingStage,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get activeContentRunId => $composableBuilder(
    column: $table.activeContentRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> processingRunsRefs(
    Expression<bool> Function($$ProcessingRunsTableFilterComposer f) f,
  ) {
    final $$ProcessingRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableFilterComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readerPositionsRefs(
    Expression<bool> Function($$ReaderPositionsTableFilterComposer f) f,
  ) {
    final $$ReaderPositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readerPositions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReaderPositionsTableFilterComposer(
            $db: $db,
            $table: $db.readerPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storedFilePath => $composableBuilder(
    column: $table.storedFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get processingProgress => $composableBuilder(
    column: $table.processingProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blockCount => $composableBuilder(
    column: $table.blockCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStage => $composableBuilder(
    column: $table.processingStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeContentRunId => $composableBuilder(
    column: $table.activeContentRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storedFilePath => $composableBuilder(
    column: $table.storedFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BookStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get processingProgress => $composableBuilder(
    column: $table.processingProgress,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get chapterCount => $composableBuilder(
    column: $table.chapterCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blockCount => $composableBuilder(
    column: $table.blockCount,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ProcessingStage?, String>
  get processingStage => $composableBuilder(
    column: $table.processingStage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activeContentRunId => $composableBuilder(
    column: $table.activeContentRunId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> processingRunsRefs<T extends Object>(
    Expression<T> Function($$ProcessingRunsTableAnnotationComposer a) f,
  ) {
    final $$ProcessingRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readerPositionsRefs<T extends Object>(
    Expression<T> Function($$ReaderPositionsTableAnnotationComposer a) f,
  ) {
    final $$ReaderPositionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readerPositions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReaderPositionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readerPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, $$BooksTableReferences),
          Book,
          PrefetchHooks Function({
            bool processingRunsRefs,
            bool chaptersRefs,
            bool readerPositionsRefs,
          })
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String> originalFileName = const Value.absent(),
                Value<String> storedFilePath = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<BookStatus> status = const Value.absent(),
                Value<double> processingProgress = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> chapterCount = const Value.absent(),
                Value<int> blockCount = const Value.absent(),
                Value<ProcessingStage?> processingStage = const Value.absent(),
                Value<String?> activeContentRunId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                author: author,
                coverPath: coverPath,
                originalFileName: originalFileName,
                storedFilePath: storedFilePath,
                fileHash: fileHash,
                status: status,
                processingProgress: processingProgress,
                pageCount: pageCount,
                chapterCount: chapterCount,
                blockCount: blockCount,
                processingStage: processingStage,
                activeContentRunId: activeContentRunId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                required String originalFileName,
                required String storedFilePath,
                required String fileHash,
                required BookStatus status,
                required double processingProgress,
                Value<int> pageCount = const Value.absent(),
                Value<int> chapterCount = const Value.absent(),
                Value<int> blockCount = const Value.absent(),
                Value<ProcessingStage?> processingStage = const Value.absent(),
                Value<String?> activeContentRunId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                author: author,
                coverPath: coverPath,
                originalFileName: originalFileName,
                storedFilePath: storedFilePath,
                fileHash: fileHash,
                status: status,
                processingProgress: processingProgress,
                pageCount: pageCount,
                chapterCount: chapterCount,
                blockCount: blockCount,
                processingStage: processingStage,
                activeContentRunId: activeContentRunId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BooksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                processingRunsRefs = false,
                chaptersRefs = false,
                readerPositionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (processingRunsRefs) db.processingRuns,
                    if (chaptersRefs) db.chapters,
                    if (readerPositionsRefs) db.readerPositions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (processingRunsRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          ProcessingRun
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._processingRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).processingRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chaptersRefs)
                        await $_getPrefetchedData<Book, $BooksTable, Chapter>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readerPositionsRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          ReaderPosition
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._readerPositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).readerPositionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, $$BooksTableReferences),
      Book,
      PrefetchHooks Function({
        bool processingRunsRefs,
        bool chaptersRefs,
        bool readerPositionsRefs,
      })
    >;
typedef $$ProcessingRunsTableCreateCompanionBuilder =
    ProcessingRunsCompanion Function({
      required String id,
      required String bookId,
      Value<String?> cleanText,
      required String state,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$ProcessingRunsTableUpdateCompanionBuilder =
    ProcessingRunsCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String?> cleanText,
      Value<String> state,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$ProcessingRunsTableReferences
    extends BaseReferences<_$AppDatabase, $ProcessingRunsTable, ProcessingRun> {
  $$ProcessingRunsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('processing_runs__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RawPagesTable, List<RawPage>> _rawPagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rawPages,
    aliasName: 'processing_runs__id__raw_pages__run_id',
  );

  $$RawPagesTableProcessedTableManager get rawPagesRefs {
    final manager = $$RawPagesTableTableManager(
      $_db,
      $_db.rawPages,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rawPagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'processing_runs__id__chapters__run_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NarrationBlocksTable, List<NarrationBlock>>
  _narrationBlocksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.narrationBlocks,
    aliasName: 'processing_runs__id__narration_blocks__run_id',
  );

  $$NarrationBlocksTableProcessedTableManager get narrationBlocksRefs {
    final manager = $$NarrationBlocksTableTableManager(
      $_db,
      $_db.narrationBlocks,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _narrationBlocksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProcessingRunsTableFilterComposer
    extends Composer<_$AppDatabase, $ProcessingRunsTable> {
  $$ProcessingRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleanText => $composableBuilder(
    column: $table.cleanText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rawPagesRefs(
    Expression<bool> Function($$RawPagesTableFilterComposer f) f,
  ) {
    final $$RawPagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawPages,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawPagesTableFilterComposer(
            $db: $db,
            $table: $db.rawPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> narrationBlocksRefs(
    Expression<bool> Function($$NarrationBlocksTableFilterComposer f) f,
  ) {
    final $$NarrationBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.narrationBlocks,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NarrationBlocksTableFilterComposer(
            $db: $db,
            $table: $db.narrationBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProcessingRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProcessingRunsTable> {
  $$ProcessingRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleanText => $composableBuilder(
    column: $table.cleanText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProcessingRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProcessingRunsTable> {
  $$ProcessingRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cleanText =>
      $composableBuilder(column: $table.cleanText, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get completedAt =>
      $composableBuilder(
        column: $table.completedAt,
        builder: (column) => column,
      );

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rawPagesRefs<T extends Object>(
    Expression<T> Function($$RawPagesTableAnnotationComposer a) f,
  ) {
    final $$RawPagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rawPages,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RawPagesTableAnnotationComposer(
            $db: $db,
            $table: $db.rawPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> narrationBlocksRefs<T extends Object>(
    Expression<T> Function($$NarrationBlocksTableAnnotationComposer a) f,
  ) {
    final $$NarrationBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.narrationBlocks,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NarrationBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.narrationBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProcessingRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProcessingRunsTable,
          ProcessingRun,
          $$ProcessingRunsTableFilterComposer,
          $$ProcessingRunsTableOrderingComposer,
          $$ProcessingRunsTableAnnotationComposer,
          $$ProcessingRunsTableCreateCompanionBuilder,
          $$ProcessingRunsTableUpdateCompanionBuilder,
          (ProcessingRun, $$ProcessingRunsTableReferences),
          ProcessingRun,
          PrefetchHooks Function({
            bool bookId,
            bool rawPagesRefs,
            bool chaptersRefs,
            bool narrationBlocksRefs,
          })
        > {
  $$ProcessingRunsTableTableManager(
    _$AppDatabase db,
    $ProcessingRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProcessingRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProcessingRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProcessingRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String?> cleanText = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProcessingRunsCompanion(
                id: id,
                bookId: bookId,
                cleanText: cleanText,
                state: state,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                Value<String?> cleanText = const Value.absent(),
                required String state,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProcessingRunsCompanion.insert(
                id: id,
                bookId: bookId,
                cleanText: cleanText,
                state: state,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProcessingRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookId = false,
                rawPagesRefs = false,
                chaptersRefs = false,
                narrationBlocksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rawPagesRefs) db.rawPages,
                    if (chaptersRefs) db.chapters,
                    if (narrationBlocksRefs) db.narrationBlocks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bookId,
                                    referencedTable:
                                        $$ProcessingRunsTableReferences
                                            ._bookIdTable(db),
                                    referencedColumn:
                                        $$ProcessingRunsTableReferences
                                            ._bookIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rawPagesRefs)
                        await $_getPrefetchedData<
                          ProcessingRun,
                          $ProcessingRunsTable,
                          RawPage
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessingRunsTableReferences
                              ._rawPagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessingRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).rawPagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          ProcessingRun,
                          $ProcessingRunsTable,
                          Chapter
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessingRunsTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessingRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (narrationBlocksRefs)
                        await $_getPrefetchedData<
                          ProcessingRun,
                          $ProcessingRunsTable,
                          NarrationBlock
                        >(
                          currentTable: table,
                          referencedTable: $$ProcessingRunsTableReferences
                              ._narrationBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProcessingRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).narrationBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProcessingRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProcessingRunsTable,
      ProcessingRun,
      $$ProcessingRunsTableFilterComposer,
      $$ProcessingRunsTableOrderingComposer,
      $$ProcessingRunsTableAnnotationComposer,
      $$ProcessingRunsTableCreateCompanionBuilder,
      $$ProcessingRunsTableUpdateCompanionBuilder,
      (ProcessingRun, $$ProcessingRunsTableReferences),
      ProcessingRun,
      PrefetchHooks Function({
        bool bookId,
        bool rawPagesRefs,
        bool chaptersRefs,
        bool narrationBlocksRefs,
      })
    >;
typedef $$RawPagesTableCreateCompanionBuilder =
    RawPagesCompanion Function({
      required String runId,
      required int pageNumber,
      required String rawText,
      Value<String?> cleanText,
      Value<int> rowid,
    });
typedef $$RawPagesTableUpdateCompanionBuilder =
    RawPagesCompanion Function({
      Value<String> runId,
      Value<int> pageNumber,
      Value<String> rawText,
      Value<String?> cleanText,
      Value<int> rowid,
    });

final class $$RawPagesTableReferences
    extends BaseReferences<_$AppDatabase, $RawPagesTable, RawPage> {
  $$RawPagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProcessingRunsTable _runIdTable(_$AppDatabase db) =>
      db.processingRuns.createAlias('raw_pages__run_id__processing_runs__id');

  $$ProcessingRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$ProcessingRunsTableTableManager(
      $_db,
      $_db.processingRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RawPagesTableFilterComposer
    extends Composer<_$AppDatabase, $RawPagesTable> {
  $$RawPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleanText => $composableBuilder(
    column: $table.cleanText,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessingRunsTableFilterComposer get runId {
    final $$ProcessingRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableFilterComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $RawPagesTable> {
  $$RawPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleanText => $composableBuilder(
    column: $table.cleanText,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessingRunsTableOrderingComposer get runId {
    final $$ProcessingRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableOrderingComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawPagesTable> {
  $$RawPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get cleanText =>
      $composableBuilder(column: $table.cleanText, builder: (column) => column);

  $$ProcessingRunsTableAnnotationComposer get runId {
    final $$ProcessingRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RawPagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawPagesTable,
          RawPage,
          $$RawPagesTableFilterComposer,
          $$RawPagesTableOrderingComposer,
          $$RawPagesTableAnnotationComposer,
          $$RawPagesTableCreateCompanionBuilder,
          $$RawPagesTableUpdateCompanionBuilder,
          (RawPage, $$RawPagesTableReferences),
          RawPage,
          PrefetchHooks Function({bool runId})
        > {
  $$RawPagesTableTableManager(_$AppDatabase db, $RawPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> cleanText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RawPagesCompanion(
                runId: runId,
                pageNumber: pageNumber,
                rawText: rawText,
                cleanText: cleanText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                required int pageNumber,
                required String rawText,
                Value<String?> cleanText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RawPagesCompanion.insert(
                runId: runId,
                pageNumber: pageNumber,
                rawText: rawText,
                cleanText: cleanText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RawPagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $$RawPagesTableReferences
                                    ._runIdTable(db),
                                referencedColumn: $$RawPagesTableReferences
                                    ._runIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RawPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawPagesTable,
      RawPage,
      $$RawPagesTableFilterComposer,
      $$RawPagesTableOrderingComposer,
      $$RawPagesTableAnnotationComposer,
      $$RawPagesTableCreateCompanionBuilder,
      $$RawPagesTableUpdateCompanionBuilder,
      (RawPage, $$RawPagesTableReferences),
      RawPage,
      PrefetchHooks Function({bool runId})
    >;
typedef $$ChaptersTableCreateCompanionBuilder =
    ChaptersCompanion Function({
      required String id,
      required String runId,
      required String bookId,
      required String title,
      required int sortOrder,
      required int startPage,
      required int endPage,
      required String cleanText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChaptersTableUpdateCompanionBuilder =
    ChaptersCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> bookId,
      Value<String> title,
      Value<int> sortOrder,
      Value<int> startPage,
      Value<int> endPage,
      Value<String> cleanText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, Chapter> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProcessingRunsTable _runIdTable(_$AppDatabase db) =>
      db.processingRuns.createAlias('chapters__run_id__processing_runs__id');

  $$ProcessingRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$ProcessingRunsTableTableManager(
      $_db,
      $_db.processingRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('chapters__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NarrationBlocksTable, List<NarrationBlock>>
  _narrationBlocksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.narrationBlocks,
    aliasName: 'chapters__id__narration_blocks__chapter_id',
  );

  $$NarrationBlocksTableProcessedTableManager get narrationBlocksRefs {
    final manager = $$NarrationBlocksTableTableManager(
      $_db,
      $_db.narrationBlocks,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _narrationBlocksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cleanText => $composableBuilder(
    column: $table.cleanText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ProcessingRunsTableFilterComposer get runId {
    final $$ProcessingRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableFilterComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> narrationBlocksRefs(
    Expression<bool> Function($$NarrationBlocksTableFilterComposer f) f,
  ) {
    final $$NarrationBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.narrationBlocks,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NarrationBlocksTableFilterComposer(
            $db: $db,
            $table: $db.narrationBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cleanText => $composableBuilder(
    column: $table.cleanText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessingRunsTableOrderingComposer get runId {
    final $$ProcessingRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableOrderingComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get endPage =>
      $composableBuilder(column: $table.endPage, builder: (column) => column);

  GeneratedColumn<String> get cleanText =>
      $composableBuilder(column: $table.cleanText, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProcessingRunsTableAnnotationComposer get runId {
    final $$ProcessingRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> narrationBlocksRefs<T extends Object>(
    Expression<T> Function($$NarrationBlocksTableAnnotationComposer a) f,
  ) {
    final $$NarrationBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.narrationBlocks,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NarrationBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.narrationBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChaptersTable,
          Chapter,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (Chapter, $$ChaptersTableReferences),
          Chapter,
          PrefetchHooks Function({
            bool runId,
            bool bookId,
            bool narrationBlocksRefs,
          })
        > {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int> endPage = const Value.absent(),
                Value<String> cleanText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                runId: runId,
                bookId: bookId,
                title: title,
                sortOrder: sortOrder,
                startPage: startPage,
                endPage: endPage,
                cleanText: cleanText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String bookId,
                required String title,
                required int sortOrder,
                required int startPage,
                required int endPage,
                required String cleanText,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                runId: runId,
                bookId: bookId,
                title: title,
                sortOrder: sortOrder,
                startPage: startPage,
                endPage: endPage,
                cleanText: cleanText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({runId = false, bookId = false, narrationBlocksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (narrationBlocksRefs) db.narrationBlocks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (runId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.runId,
                                    referencedTable: $$ChaptersTableReferences
                                        ._runIdTable(db),
                                    referencedColumn: $$ChaptersTableReferences
                                        ._runIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (bookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bookId,
                                    referencedTable: $$ChaptersTableReferences
                                        ._bookIdTable(db),
                                    referencedColumn: $$ChaptersTableReferences
                                        ._bookIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (narrationBlocksRefs)
                        await $_getPrefetchedData<
                          Chapter,
                          $ChaptersTable,
                          NarrationBlock
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._narrationBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).narrationBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChaptersTable,
      Chapter,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (Chapter, $$ChaptersTableReferences),
      Chapter,
      PrefetchHooks Function({
        bool runId,
        bool bookId,
        bool narrationBlocksRefs,
      })
    >;
typedef $$NarrationBlocksTableCreateCompanionBuilder =
    NarrationBlocksCompanion Function({
      required String id,
      required String runId,
      required String chapterId,
      required int sortOrder,
      required String originalText,
      required String normalizedText,
      required int characterCount,
      required int startPage,
      required int endPage,
      Value<int> rowid,
    });
typedef $$NarrationBlocksTableUpdateCompanionBuilder =
    NarrationBlocksCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> chapterId,
      Value<int> sortOrder,
      Value<String> originalText,
      Value<String> normalizedText,
      Value<int> characterCount,
      Value<int> startPage,
      Value<int> endPage,
      Value<int> rowid,
    });

final class $$NarrationBlocksTableReferences
    extends
        BaseReferences<_$AppDatabase, $NarrationBlocksTable, NarrationBlock> {
  $$NarrationBlocksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProcessingRunsTable _runIdTable(_$AppDatabase db) => db.processingRuns
      .createAlias('narration_blocks__run_id__processing_runs__id');

  $$ProcessingRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$ProcessingRunsTableTableManager(
      $_db,
      $_db.processingRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$AppDatabase db) =>
      db.chapters.createAlias('narration_blocks__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NarrationBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $NarrationBlocksTable> {
  $$NarrationBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get characterCount => $composableBuilder(
    column: $table.characterCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnFilters(column),
  );

  $$ProcessingRunsTableFilterComposer get runId {
    final $$ProcessingRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableFilterComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NarrationBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $NarrationBlocksTable> {
  $$NarrationBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get characterCount => $composableBuilder(
    column: $table.characterCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProcessingRunsTableOrderingComposer get runId {
    final $$ProcessingRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableOrderingComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NarrationBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NarrationBlocksTable> {
  $$NarrationBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get originalText => $composableBuilder(
    column: $table.originalText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get characterCount => $composableBuilder(
    column: $table.characterCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get endPage =>
      $composableBuilder(column: $table.endPage, builder: (column) => column);

  $$ProcessingRunsTableAnnotationComposer get runId {
    final $$ProcessingRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.processingRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProcessingRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.processingRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NarrationBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NarrationBlocksTable,
          NarrationBlock,
          $$NarrationBlocksTableFilterComposer,
          $$NarrationBlocksTableOrderingComposer,
          $$NarrationBlocksTableAnnotationComposer,
          $$NarrationBlocksTableCreateCompanionBuilder,
          $$NarrationBlocksTableUpdateCompanionBuilder,
          (NarrationBlock, $$NarrationBlocksTableReferences),
          NarrationBlock,
          PrefetchHooks Function({bool runId, bool chapterId})
        > {
  $$NarrationBlocksTableTableManager(
    _$AppDatabase db,
    $NarrationBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NarrationBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NarrationBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NarrationBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> originalText = const Value.absent(),
                Value<String> normalizedText = const Value.absent(),
                Value<int> characterCount = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int> endPage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NarrationBlocksCompanion(
                id: id,
                runId: runId,
                chapterId: chapterId,
                sortOrder: sortOrder,
                originalText: originalText,
                normalizedText: normalizedText,
                characterCount: characterCount,
                startPage: startPage,
                endPage: endPage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String chapterId,
                required int sortOrder,
                required String originalText,
                required String normalizedText,
                required int characterCount,
                required int startPage,
                required int endPage,
                Value<int> rowid = const Value.absent(),
              }) => NarrationBlocksCompanion.insert(
                id: id,
                runId: runId,
                chapterId: chapterId,
                sortOrder: sortOrder,
                originalText: originalText,
                normalizedText: normalizedText,
                characterCount: characterCount,
                startPage: startPage,
                endPage: endPage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NarrationBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable:
                                    $$NarrationBlocksTableReferences
                                        ._runIdTable(db),
                                referencedColumn:
                                    $$NarrationBlocksTableReferences
                                        ._runIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (chapterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chapterId,
                                referencedTable:
                                    $$NarrationBlocksTableReferences
                                        ._chapterIdTable(db),
                                referencedColumn:
                                    $$NarrationBlocksTableReferences
                                        ._chapterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NarrationBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NarrationBlocksTable,
      NarrationBlock,
      $$NarrationBlocksTableFilterComposer,
      $$NarrationBlocksTableOrderingComposer,
      $$NarrationBlocksTableAnnotationComposer,
      $$NarrationBlocksTableCreateCompanionBuilder,
      $$NarrationBlocksTableUpdateCompanionBuilder,
      (NarrationBlock, $$NarrationBlocksTableReferences),
      NarrationBlock,
      PrefetchHooks Function({bool runId, bool chapterId})
    >;
typedef $$ReaderSettingsRowsTableCreateCompanionBuilder =
    ReaderSettingsRowsCompanion Function({
      Value<int> id,
      required ReaderTheme theme,
      required ReaderFontFamily fontFamily,
      required int fontSize,
      required double lineHeight,
      required DateTime updatedAt,
    });
typedef $$ReaderSettingsRowsTableUpdateCompanionBuilder =
    ReaderSettingsRowsCompanion Function({
      Value<int> id,
      Value<ReaderTheme> theme,
      Value<ReaderFontFamily> fontFamily,
      Value<int> fontSize,
      Value<double> lineHeight,
      Value<DateTime> updatedAt,
    });

class $$ReaderSettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderSettingsRowsTable> {
  $$ReaderSettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReaderTheme, ReaderTheme, String> get theme =>
      $composableBuilder(
        column: $table.theme,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ReaderFontFamily, ReaderFontFamily, String>
  get fontFamily => $composableBuilder(
    column: $table.fontFamily,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineHeight => $composableBuilder(
    column: $table.lineHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ReaderSettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderSettingsRowsTable> {
  $$ReaderSettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fontFamily => $composableBuilder(
    column: $table.fontFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fontSize => $composableBuilder(
    column: $table.fontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineHeight => $composableBuilder(
    column: $table.lineHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReaderSettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderSettingsRowsTable> {
  $$ReaderSettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReaderTheme, String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReaderFontFamily, String> get fontFamily =>
      $composableBuilder(
        column: $table.fontFamily,
        builder: (column) => column,
      );

  GeneratedColumn<int> get fontSize =>
      $composableBuilder(column: $table.fontSize, builder: (column) => column);

  GeneratedColumn<double> get lineHeight => $composableBuilder(
    column: $table.lineHeight,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReaderSettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderSettingsRowsTable,
          ReaderSettingsRow,
          $$ReaderSettingsRowsTableFilterComposer,
          $$ReaderSettingsRowsTableOrderingComposer,
          $$ReaderSettingsRowsTableAnnotationComposer,
          $$ReaderSettingsRowsTableCreateCompanionBuilder,
          $$ReaderSettingsRowsTableUpdateCompanionBuilder,
          (
            ReaderSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $ReaderSettingsRowsTable,
              ReaderSettingsRow
            >,
          ),
          ReaderSettingsRow,
          PrefetchHooks Function()
        > {
  $$ReaderSettingsRowsTableTableManager(
    _$AppDatabase db,
    $ReaderSettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderSettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderSettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderSettingsRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<ReaderTheme> theme = const Value.absent(),
                Value<ReaderFontFamily> fontFamily = const Value.absent(),
                Value<int> fontSize = const Value.absent(),
                Value<double> lineHeight = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ReaderSettingsRowsCompanion(
                id: id,
                theme: theme,
                fontFamily: fontFamily,
                fontSize: fontSize,
                lineHeight: lineHeight,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required ReaderTheme theme,
                required ReaderFontFamily fontFamily,
                required int fontSize,
                required double lineHeight,
                required DateTime updatedAt,
              }) => ReaderSettingsRowsCompanion.insert(
                id: id,
                theme: theme,
                fontFamily: fontFamily,
                fontSize: fontSize,
                lineHeight: lineHeight,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReaderSettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderSettingsRowsTable,
      ReaderSettingsRow,
      $$ReaderSettingsRowsTableFilterComposer,
      $$ReaderSettingsRowsTableOrderingComposer,
      $$ReaderSettingsRowsTableAnnotationComposer,
      $$ReaderSettingsRowsTableCreateCompanionBuilder,
      $$ReaderSettingsRowsTableUpdateCompanionBuilder,
      (
        ReaderSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $ReaderSettingsRowsTable,
          ReaderSettingsRow
        >,
      ),
      ReaderSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ReaderPositionsTableCreateCompanionBuilder =
    ReaderPositionsCompanion Function({
      required String bookId,
      required ReaderMode mode,
      Value<String?> chapterId,
      Value<String?> blockId,
      Value<int> pdfPage,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReaderPositionsTableUpdateCompanionBuilder =
    ReaderPositionsCompanion Function({
      Value<String> bookId,
      Value<ReaderMode> mode,
      Value<String?> chapterId,
      Value<String?> blockId,
      Value<int> pdfPage,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ReaderPositionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReaderPositionsTable, ReaderPosition> {
  $$ReaderPositionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('reader_positions__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReaderPositionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReaderPositionsTable> {
  $$ReaderPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<ReaderMode, ReaderMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pdfPage => $composableBuilder(
    column: $table.pdfPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReaderPositionsTable> {
  $$ReaderPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pdfPage => $composableBuilder(
    column: $table.pdfPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReaderPositionsTable> {
  $$ReaderPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<ReaderMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<int> get pdfPage =>
      $composableBuilder(column: $table.pdfPage, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReaderPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReaderPositionsTable,
          ReaderPosition,
          $$ReaderPositionsTableFilterComposer,
          $$ReaderPositionsTableOrderingComposer,
          $$ReaderPositionsTableAnnotationComposer,
          $$ReaderPositionsTableCreateCompanionBuilder,
          $$ReaderPositionsTableUpdateCompanionBuilder,
          (ReaderPosition, $$ReaderPositionsTableReferences),
          ReaderPosition,
          PrefetchHooks Function({bool bookId})
        > {
  $$ReaderPositionsTableTableManager(
    _$AppDatabase db,
    $ReaderPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReaderPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReaderPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReaderPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<ReaderMode> mode = const Value.absent(),
                Value<String?> chapterId = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<int> pdfPage = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReaderPositionsCompanion(
                bookId: bookId,
                mode: mode,
                chapterId: chapterId,
                blockId: blockId,
                pdfPage: pdfPage,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required ReaderMode mode,
                Value<String?> chapterId = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<int> pdfPage = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReaderPositionsCompanion.insert(
                bookId: bookId,
                mode: mode,
                chapterId: chapterId,
                blockId: blockId,
                pdfPage: pdfPage,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReaderPositionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable:
                                    $$ReaderPositionsTableReferences
                                        ._bookIdTable(db),
                                referencedColumn:
                                    $$ReaderPositionsTableReferences
                                        ._bookIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReaderPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReaderPositionsTable,
      ReaderPosition,
      $$ReaderPositionsTableFilterComposer,
      $$ReaderPositionsTableOrderingComposer,
      $$ReaderPositionsTableAnnotationComposer,
      $$ReaderPositionsTableCreateCompanionBuilder,
      $$ReaderPositionsTableUpdateCompanionBuilder,
      (ReaderPosition, $$ReaderPositionsTableReferences),
      ReaderPosition,
      PrefetchHooks Function({bool bookId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ProcessingRunsTableTableManager get processingRuns =>
      $$ProcessingRunsTableTableManager(_db, _db.processingRuns);
  $$RawPagesTableTableManager get rawPages =>
      $$RawPagesTableTableManager(_db, _db.rawPages);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$NarrationBlocksTableTableManager get narrationBlocks =>
      $$NarrationBlocksTableTableManager(_db, _db.narrationBlocks);
  $$ReaderSettingsRowsTableTableManager get readerSettingsRows =>
      $$ReaderSettingsRowsTableTableManager(_db, _db.readerSettingsRows);
  $$ReaderPositionsTableTableManager get readerPositions =>
      $$ReaderPositionsTableTableManager(_db, _db.readerPositions);
}
