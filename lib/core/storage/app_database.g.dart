// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PuzzleRecordsTable extends PuzzleRecords
    with TableInfo<$PuzzleRecordsTable, PuzzleRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDailyMeta = const VerificationMeta(
    'isDaily',
  );
  @override
  late final GeneratedColumn<bool> isDaily = GeneratedColumn<bool>(
    'is_daily',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_daily" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeSecondsMeta = const VerificationMeta(
    'timeSeconds',
  );
  @override
  late final GeneratedColumn<int> timeSeconds = GeneratedColumn<int>(
    'time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsUsedMeta = const VerificationMeta(
    'hintsUsed',
  );
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
    'hints_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mistakesMeta = const VerificationMeta(
    'mistakes',
  );
  @override
  late final GeneratedColumn<int> mistakes = GeneratedColumn<int>(
    'mistakes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solveTimesMeta = const VerificationMeta(
    'solveTimes',
  );
  @override
  late final GeneratedColumn<String> solveTimes = GeneratedColumn<String>(
    'solve_times',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _undosUsedMeta = const VerificationMeta(
    'undosUsed',
  );
  @override
  late final GeneratedColumn<int> undosUsed = GeneratedColumn<int>(
    'undos_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _usedNotesMeta = const VerificationMeta(
    'usedNotes',
  );
  @override
  late final GeneratedColumn<bool> usedNotes = GeneratedColumn<bool>(
    'used_notes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used_notes" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _longestPauseSecondsMeta =
      const VerificationMeta('longestPauseSeconds');
  @override
  late final GeneratedColumn<int> longestPauseSeconds = GeneratedColumn<int>(
    'longest_pause_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mistakeCellsMeta = const VerificationMeta(
    'mistakeCells',
  );
  @override
  late final GeneratedColumn<String> mistakeCells = GeneratedColumn<String>(
    'mistake_cells',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _qualityScoreMeta = const VerificationMeta(
    'qualityScore',
  );
  @override
  late final GeneratedColumn<double> qualityScore = GeneratedColumn<double>(
    'quality_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    puzzleId,
    difficulty,
    isDaily,
    timeSeconds,
    hintsUsed,
    mistakes,
    completedAt,
    solveTimes,
    undosUsed,
    usedNotes,
    longestPauseSeconds,
    mistakeCells,
    qualityScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('is_daily')) {
      context.handle(
        _isDailyMeta,
        isDaily.isAcceptableOrUnknown(data['is_daily']!, _isDailyMeta),
      );
    }
    if (data.containsKey('time_seconds')) {
      context.handle(
        _timeSecondsMeta,
        timeSeconds.isAcceptableOrUnknown(
          data['time_seconds']!,
          _timeSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSecondsMeta);
    }
    if (data.containsKey('hints_used')) {
      context.handle(
        _hintsUsedMeta,
        hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta),
      );
    }
    if (data.containsKey('mistakes')) {
      context.handle(
        _mistakesMeta,
        mistakes.isAcceptableOrUnknown(data['mistakes']!, _mistakesMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('solve_times')) {
      context.handle(
        _solveTimesMeta,
        solveTimes.isAcceptableOrUnknown(data['solve_times']!, _solveTimesMeta),
      );
    }
    if (data.containsKey('undos_used')) {
      context.handle(
        _undosUsedMeta,
        undosUsed.isAcceptableOrUnknown(data['undos_used']!, _undosUsedMeta),
      );
    }
    if (data.containsKey('used_notes')) {
      context.handle(
        _usedNotesMeta,
        usedNotes.isAcceptableOrUnknown(data['used_notes']!, _usedNotesMeta),
      );
    }
    if (data.containsKey('longest_pause_seconds')) {
      context.handle(
        _longestPauseSecondsMeta,
        longestPauseSeconds.isAcceptableOrUnknown(
          data['longest_pause_seconds']!,
          _longestPauseSecondsMeta,
        ),
      );
    }
    if (data.containsKey('mistake_cells')) {
      context.handle(
        _mistakeCellsMeta,
        mistakeCells.isAcceptableOrUnknown(
          data['mistake_cells']!,
          _mistakeCellsMeta,
        ),
      );
    }
    if (data.containsKey('quality_score')) {
      context.handle(
        _qualityScoreMeta,
        qualityScore.isAcceptableOrUnknown(
          data['quality_score']!,
          _qualityScoreMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PuzzleRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      isDaily: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_daily'],
      )!,
      timeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_seconds'],
      )!,
      hintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_used'],
      )!,
      mistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mistakes'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      solveTimes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solve_times'],
      )!,
      undosUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}undos_used'],
      )!,
      usedNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used_notes'],
      )!,
      longestPauseSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_pause_seconds'],
      )!,
      mistakeCells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mistake_cells'],
      )!,
      qualityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quality_score'],
      )!,
    );
  }

  @override
  $PuzzleRecordsTable createAlias(String alias) {
    return $PuzzleRecordsTable(attachedDatabase, alias);
  }
}

class PuzzleRecord extends DataClass implements Insertable<PuzzleRecord> {
  final int id;
  final String puzzleId;
  final String difficulty;
  final bool isDaily;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final DateTime completedAt;
  final String solveTimes;
  final int undosUsed;
  final bool usedNotes;
  final int longestPauseSeconds;
  final String mistakeCells;
  final double qualityScore;
  const PuzzleRecord({
    required this.id,
    required this.puzzleId,
    required this.difficulty,
    required this.isDaily,
    required this.timeSeconds,
    required this.hintsUsed,
    required this.mistakes,
    required this.completedAt,
    required this.solveTimes,
    required this.undosUsed,
    required this.usedNotes,
    required this.longestPauseSeconds,
    required this.mistakeCells,
    required this.qualityScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['difficulty'] = Variable<String>(difficulty);
    map['is_daily'] = Variable<bool>(isDaily);
    map['time_seconds'] = Variable<int>(timeSeconds);
    map['hints_used'] = Variable<int>(hintsUsed);
    map['mistakes'] = Variable<int>(mistakes);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['solve_times'] = Variable<String>(solveTimes);
    map['undos_used'] = Variable<int>(undosUsed);
    map['used_notes'] = Variable<bool>(usedNotes);
    map['longest_pause_seconds'] = Variable<int>(longestPauseSeconds);
    map['mistake_cells'] = Variable<String>(mistakeCells);
    map['quality_score'] = Variable<double>(qualityScore);
    return map;
  }

  PuzzleRecordsCompanion toCompanion(bool nullToAbsent) {
    return PuzzleRecordsCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      difficulty: Value(difficulty),
      isDaily: Value(isDaily),
      timeSeconds: Value(timeSeconds),
      hintsUsed: Value(hintsUsed),
      mistakes: Value(mistakes),
      completedAt: Value(completedAt),
      solveTimes: Value(solveTimes),
      undosUsed: Value(undosUsed),
      usedNotes: Value(usedNotes),
      longestPauseSeconds: Value(longestPauseSeconds),
      mistakeCells: Value(mistakeCells),
      qualityScore: Value(qualityScore),
    );
  }

  factory PuzzleRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleRecord(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      isDaily: serializer.fromJson<bool>(json['isDaily']),
      timeSeconds: serializer.fromJson<int>(json['timeSeconds']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      mistakes: serializer.fromJson<int>(json['mistakes']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      solveTimes: serializer.fromJson<String>(json['solveTimes']),
      undosUsed: serializer.fromJson<int>(json['undosUsed']),
      usedNotes: serializer.fromJson<bool>(json['usedNotes']),
      longestPauseSeconds: serializer.fromJson<int>(
        json['longestPauseSeconds'],
      ),
      mistakeCells: serializer.fromJson<String>(json['mistakeCells']),
      qualityScore: serializer.fromJson<double>(json['qualityScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'difficulty': serializer.toJson<String>(difficulty),
      'isDaily': serializer.toJson<bool>(isDaily),
      'timeSeconds': serializer.toJson<int>(timeSeconds),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'mistakes': serializer.toJson<int>(mistakes),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'solveTimes': serializer.toJson<String>(solveTimes),
      'undosUsed': serializer.toJson<int>(undosUsed),
      'usedNotes': serializer.toJson<bool>(usedNotes),
      'longestPauseSeconds': serializer.toJson<int>(longestPauseSeconds),
      'mistakeCells': serializer.toJson<String>(mistakeCells),
      'qualityScore': serializer.toJson<double>(qualityScore),
    };
  }

  PuzzleRecord copyWith({
    int? id,
    String? puzzleId,
    String? difficulty,
    bool? isDaily,
    int? timeSeconds,
    int? hintsUsed,
    int? mistakes,
    DateTime? completedAt,
    String? solveTimes,
    int? undosUsed,
    bool? usedNotes,
    int? longestPauseSeconds,
    String? mistakeCells,
    double? qualityScore,
  }) => PuzzleRecord(
    id: id ?? this.id,
    puzzleId: puzzleId ?? this.puzzleId,
    difficulty: difficulty ?? this.difficulty,
    isDaily: isDaily ?? this.isDaily,
    timeSeconds: timeSeconds ?? this.timeSeconds,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    mistakes: mistakes ?? this.mistakes,
    completedAt: completedAt ?? this.completedAt,
    solveTimes: solveTimes ?? this.solveTimes,
    undosUsed: undosUsed ?? this.undosUsed,
    usedNotes: usedNotes ?? this.usedNotes,
    longestPauseSeconds: longestPauseSeconds ?? this.longestPauseSeconds,
    mistakeCells: mistakeCells ?? this.mistakeCells,
    qualityScore: qualityScore ?? this.qualityScore,
  );
  PuzzleRecord copyWithCompanion(PuzzleRecordsCompanion data) {
    return PuzzleRecord(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      isDaily: data.isDaily.present ? data.isDaily.value : this.isDaily,
      timeSeconds: data.timeSeconds.present
          ? data.timeSeconds.value
          : this.timeSeconds,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      mistakes: data.mistakes.present ? data.mistakes.value : this.mistakes,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      solveTimes: data.solveTimes.present
          ? data.solveTimes.value
          : this.solveTimes,
      undosUsed: data.undosUsed.present ? data.undosUsed.value : this.undosUsed,
      usedNotes: data.usedNotes.present ? data.usedNotes.value : this.usedNotes,
      longestPauseSeconds: data.longestPauseSeconds.present
          ? data.longestPauseSeconds.value
          : this.longestPauseSeconds,
      mistakeCells: data.mistakeCells.present
          ? data.mistakeCells.value
          : this.mistakeCells,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleRecord(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('isDaily: $isDaily, ')
          ..write('timeSeconds: $timeSeconds, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('mistakes: $mistakes, ')
          ..write('completedAt: $completedAt, ')
          ..write('solveTimes: $solveTimes, ')
          ..write('undosUsed: $undosUsed, ')
          ..write('usedNotes: $usedNotes, ')
          ..write('longestPauseSeconds: $longestPauseSeconds, ')
          ..write('mistakeCells: $mistakeCells, ')
          ..write('qualityScore: $qualityScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    puzzleId,
    difficulty,
    isDaily,
    timeSeconds,
    hintsUsed,
    mistakes,
    completedAt,
    solveTimes,
    undosUsed,
    usedNotes,
    longestPauseSeconds,
    mistakeCells,
    qualityScore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleRecord &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.difficulty == this.difficulty &&
          other.isDaily == this.isDaily &&
          other.timeSeconds == this.timeSeconds &&
          other.hintsUsed == this.hintsUsed &&
          other.mistakes == this.mistakes &&
          other.completedAt == this.completedAt &&
          other.solveTimes == this.solveTimes &&
          other.undosUsed == this.undosUsed &&
          other.usedNotes == this.usedNotes &&
          other.longestPauseSeconds == this.longestPauseSeconds &&
          other.mistakeCells == this.mistakeCells &&
          other.qualityScore == this.qualityScore);
}

class PuzzleRecordsCompanion extends UpdateCompanion<PuzzleRecord> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> difficulty;
  final Value<bool> isDaily;
  final Value<int> timeSeconds;
  final Value<int> hintsUsed;
  final Value<int> mistakes;
  final Value<DateTime> completedAt;
  final Value<String> solveTimes;
  final Value<int> undosUsed;
  final Value<bool> usedNotes;
  final Value<int> longestPauseSeconds;
  final Value<String> mistakeCells;
  final Value<double> qualityScore;
  const PuzzleRecordsCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isDaily = const Value.absent(),
    this.timeSeconds = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.mistakes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.solveTimes = const Value.absent(),
    this.undosUsed = const Value.absent(),
    this.usedNotes = const Value.absent(),
    this.longestPauseSeconds = const Value.absent(),
    this.mistakeCells = const Value.absent(),
    this.qualityScore = const Value.absent(),
  });
  PuzzleRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String difficulty,
    this.isDaily = const Value.absent(),
    required int timeSeconds,
    this.hintsUsed = const Value.absent(),
    this.mistakes = const Value.absent(),
    required DateTime completedAt,
    this.solveTimes = const Value.absent(),
    this.undosUsed = const Value.absent(),
    this.usedNotes = const Value.absent(),
    this.longestPauseSeconds = const Value.absent(),
    this.mistakeCells = const Value.absent(),
    this.qualityScore = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       difficulty = Value(difficulty),
       timeSeconds = Value(timeSeconds),
       completedAt = Value(completedAt);
  static Insertable<PuzzleRecord> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? difficulty,
    Expression<bool>? isDaily,
    Expression<int>? timeSeconds,
    Expression<int>? hintsUsed,
    Expression<int>? mistakes,
    Expression<DateTime>? completedAt,
    Expression<String>? solveTimes,
    Expression<int>? undosUsed,
    Expression<bool>? usedNotes,
    Expression<int>? longestPauseSeconds,
    Expression<String>? mistakeCells,
    Expression<double>? qualityScore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (difficulty != null) 'difficulty': difficulty,
      if (isDaily != null) 'is_daily': isDaily,
      if (timeSeconds != null) 'time_seconds': timeSeconds,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (mistakes != null) 'mistakes': mistakes,
      if (completedAt != null) 'completed_at': completedAt,
      if (solveTimes != null) 'solve_times': solveTimes,
      if (undosUsed != null) 'undos_used': undosUsed,
      if (usedNotes != null) 'used_notes': usedNotes,
      if (longestPauseSeconds != null)
        'longest_pause_seconds': longestPauseSeconds,
      if (mistakeCells != null) 'mistake_cells': mistakeCells,
      if (qualityScore != null) 'quality_score': qualityScore,
    });
  }

  PuzzleRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? puzzleId,
    Value<String>? difficulty,
    Value<bool>? isDaily,
    Value<int>? timeSeconds,
    Value<int>? hintsUsed,
    Value<int>? mistakes,
    Value<DateTime>? completedAt,
    Value<String>? solveTimes,
    Value<int>? undosUsed,
    Value<bool>? usedNotes,
    Value<int>? longestPauseSeconds,
    Value<String>? mistakeCells,
    Value<double>? qualityScore,
  }) {
    return PuzzleRecordsCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      difficulty: difficulty ?? this.difficulty,
      isDaily: isDaily ?? this.isDaily,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakes: mistakes ?? this.mistakes,
      completedAt: completedAt ?? this.completedAt,
      solveTimes: solveTimes ?? this.solveTimes,
      undosUsed: undosUsed ?? this.undosUsed,
      usedNotes: usedNotes ?? this.usedNotes,
      longestPauseSeconds: longestPauseSeconds ?? this.longestPauseSeconds,
      mistakeCells: mistakeCells ?? this.mistakeCells,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (isDaily.present) {
      map['is_daily'] = Variable<bool>(isDaily.value);
    }
    if (timeSeconds.present) {
      map['time_seconds'] = Variable<int>(timeSeconds.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (mistakes.present) {
      map['mistakes'] = Variable<int>(mistakes.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (solveTimes.present) {
      map['solve_times'] = Variable<String>(solveTimes.value);
    }
    if (undosUsed.present) {
      map['undos_used'] = Variable<int>(undosUsed.value);
    }
    if (usedNotes.present) {
      map['used_notes'] = Variable<bool>(usedNotes.value);
    }
    if (longestPauseSeconds.present) {
      map['longest_pause_seconds'] = Variable<int>(longestPauseSeconds.value);
    }
    if (mistakeCells.present) {
      map['mistake_cells'] = Variable<String>(mistakeCells.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<double>(qualityScore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleRecordsCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('isDaily: $isDaily, ')
          ..write('timeSeconds: $timeSeconds, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('mistakes: $mistakes, ')
          ..write('completedAt: $completedAt, ')
          ..write('solveTimes: $solveTimes, ')
          ..write('undosUsed: $undosUsed, ')
          ..write('usedNotes: $usedNotes, ')
          ..write('longestPauseSeconds: $longestPauseSeconds, ')
          ..write('mistakeCells: $mistakeCells, ')
          ..write('qualityScore: $qualityScore')
          ..write(')'))
        .toString();
  }
}

class $PlayerProfilesTable extends PlayerProfiles
    with TableInfo<$PlayerProfilesTable, PlayerProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('anon'),
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedDateMeta = const VerificationMeta(
    'lastPlayedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedDate =
      GeneratedColumn<DateTime>(
        'last_played_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalSolvedMeta = const VerificationMeta(
    'totalSolved',
  );
  @override
  late final GeneratedColumn<int> totalSolved = GeneratedColumn<int>(
    'total_solved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalStartedMeta = const VerificationMeta(
    'totalStarted',
  );
  @override
  late final GeneratedColumn<int> totalStarted = GeneratedColumn<int>(
    'total_started',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _preferredDifficultyMeta =
      const VerificationMeta('preferredDifficulty');
  @override
  late final GeneratedColumn<String> preferredDifficulty =
      GeneratedColumn<String>(
        'preferred_difficulty',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('medium'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    currentStreak,
    longestStreak,
    lastPlayedDate,
    totalSolved,
    totalStarted,
    preferredDifficulty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
      );
    }
    if (data.containsKey('last_played_date')) {
      context.handle(
        _lastPlayedDateMeta,
        lastPlayedDate.isAcceptableOrUnknown(
          data['last_played_date']!,
          _lastPlayedDateMeta,
        ),
      );
    }
    if (data.containsKey('total_solved')) {
      context.handle(
        _totalSolvedMeta,
        totalSolved.isAcceptableOrUnknown(
          data['total_solved']!,
          _totalSolvedMeta,
        ),
      );
    }
    if (data.containsKey('total_started')) {
      context.handle(
        _totalStartedMeta,
        totalStarted.isAcceptableOrUnknown(
          data['total_started']!,
          _totalStartedMeta,
        ),
      );
    }
    if (data.containsKey('preferred_difficulty')) {
      context.handle(
        _preferredDifficultyMeta,
        preferredDifficulty.isAcceptableOrUnknown(
          data['preferred_difficulty']!,
          _preferredDifficultyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      lastPlayedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_date'],
      ),
      totalSolved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_solved'],
      )!,
      totalStarted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_started'],
      )!,
      preferredDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_difficulty'],
      )!,
    );
  }

  @override
  $PlayerProfilesTable createAlias(String alias) {
    return $PlayerProfilesTable(attachedDatabase, alias);
  }
}

class PlayerProfile extends DataClass implements Insertable<PlayerProfile> {
  final int id;
  final String displayName;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPlayedDate;
  final int totalSolved;
  final int totalStarted;
  final String preferredDifficulty;
  const PlayerProfile({
    required this.id,
    required this.displayName,
    required this.currentStreak,
    required this.longestStreak,
    this.lastPlayedDate,
    required this.totalSolved,
    required this.totalStarted,
    required this.preferredDifficulty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['current_streak'] = Variable<int>(currentStreak);
    map['longest_streak'] = Variable<int>(longestStreak);
    if (!nullToAbsent || lastPlayedDate != null) {
      map['last_played_date'] = Variable<DateTime>(lastPlayedDate);
    }
    map['total_solved'] = Variable<int>(totalSolved);
    map['total_started'] = Variable<int>(totalStarted);
    map['preferred_difficulty'] = Variable<String>(preferredDifficulty);
    return map;
  }

  PlayerProfilesCompanion toCompanion(bool nullToAbsent) {
    return PlayerProfilesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      lastPlayedDate: lastPlayedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedDate),
      totalSolved: Value(totalSolved),
      totalStarted: Value(totalStarted),
      preferredDifficulty: Value(preferredDifficulty),
    );
  }

  factory PlayerProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerProfile(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      lastPlayedDate: serializer.fromJson<DateTime?>(json['lastPlayedDate']),
      totalSolved: serializer.fromJson<int>(json['totalSolved']),
      totalStarted: serializer.fromJson<int>(json['totalStarted']),
      preferredDifficulty: serializer.fromJson<String>(
        json['preferredDifficulty'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'lastPlayedDate': serializer.toJson<DateTime?>(lastPlayedDate),
      'totalSolved': serializer.toJson<int>(totalSolved),
      'totalStarted': serializer.toJson<int>(totalStarted),
      'preferredDifficulty': serializer.toJson<String>(preferredDifficulty),
    };
  }

  PlayerProfile copyWith({
    int? id,
    String? displayName,
    int? currentStreak,
    int? longestStreak,
    Value<DateTime?> lastPlayedDate = const Value.absent(),
    int? totalSolved,
    int? totalStarted,
    String? preferredDifficulty,
  }) => PlayerProfile(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastPlayedDate: lastPlayedDate.present
        ? lastPlayedDate.value
        : this.lastPlayedDate,
    totalSolved: totalSolved ?? this.totalSolved,
    totalStarted: totalStarted ?? this.totalStarted,
    preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
  );
  PlayerProfile copyWithCompanion(PlayerProfilesCompanion data) {
    return PlayerProfile(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      lastPlayedDate: data.lastPlayedDate.present
          ? data.lastPlayedDate.value
          : this.lastPlayedDate,
      totalSolved: data.totalSolved.present
          ? data.totalSolved.value
          : this.totalSolved,
      totalStarted: data.totalStarted.present
          ? data.totalStarted.value
          : this.totalStarted,
      preferredDifficulty: data.preferredDifficulty.present
          ? data.preferredDifficulty.value
          : this.preferredDifficulty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerProfile(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('lastPlayedDate: $lastPlayedDate, ')
          ..write('totalSolved: $totalSolved, ')
          ..write('totalStarted: $totalStarted, ')
          ..write('preferredDifficulty: $preferredDifficulty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    currentStreak,
    longestStreak,
    lastPlayedDate,
    totalSolved,
    totalStarted,
    preferredDifficulty,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerProfile &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.currentStreak == this.currentStreak &&
          other.longestStreak == this.longestStreak &&
          other.lastPlayedDate == this.lastPlayedDate &&
          other.totalSolved == this.totalSolved &&
          other.totalStarted == this.totalStarted &&
          other.preferredDifficulty == this.preferredDifficulty);
}

class PlayerProfilesCompanion extends UpdateCompanion<PlayerProfile> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<int> currentStreak;
  final Value<int> longestStreak;
  final Value<DateTime?> lastPlayedDate;
  final Value<int> totalSolved;
  final Value<int> totalStarted;
  final Value<String> preferredDifficulty;
  const PlayerProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastPlayedDate = const Value.absent(),
    this.totalSolved = const Value.absent(),
    this.totalStarted = const Value.absent(),
    this.preferredDifficulty = const Value.absent(),
  });
  PlayerProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastPlayedDate = const Value.absent(),
    this.totalSolved = const Value.absent(),
    this.totalStarted = const Value.absent(),
    this.preferredDifficulty = const Value.absent(),
  });
  static Insertable<PlayerProfile> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<int>? currentStreak,
    Expression<int>? longestStreak,
    Expression<DateTime>? lastPlayedDate,
    Expression<int>? totalSolved,
    Expression<int>? totalStarted,
    Expression<String>? preferredDifficulty,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (lastPlayedDate != null) 'last_played_date': lastPlayedDate,
      if (totalSolved != null) 'total_solved': totalSolved,
      if (totalStarted != null) 'total_started': totalStarted,
      if (preferredDifficulty != null)
        'preferred_difficulty': preferredDifficulty,
    });
  }

  PlayerProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<int>? currentStreak,
    Value<int>? longestStreak,
    Value<DateTime?>? lastPlayedDate,
    Value<int>? totalSolved,
    Value<int>? totalStarted,
    Value<String>? preferredDifficulty,
  }) {
    return PlayerProfilesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      totalSolved: totalSolved ?? this.totalSolved,
      totalStarted: totalStarted ?? this.totalStarted,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (lastPlayedDate.present) {
      map['last_played_date'] = Variable<DateTime>(lastPlayedDate.value);
    }
    if (totalSolved.present) {
      map['total_solved'] = Variable<int>(totalSolved.value);
    }
    if (totalStarted.present) {
      map['total_started'] = Variable<int>(totalStarted.value);
    }
    if (preferredDifficulty.present) {
      map['preferred_difficulty'] = Variable<String>(preferredDifficulty.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerProfilesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('lastPlayedDate: $lastPlayedDate, ')
          ..write('totalSolved: $totalSolved, ')
          ..write('totalStarted: $totalStarted, ')
          ..write('preferredDifficulty: $preferredDifficulty')
          ..write(')'))
        .toString();
  }
}

class $GamePreferencesTableTable extends GamePreferencesTable
    with TableInfo<$GamePreferencesTableTable, GamePreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamePreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _autoRemoveNotesMeta = const VerificationMeta(
    'autoRemoveNotes',
  );
  @override
  late final GeneratedColumn<bool> autoRemoveNotes = GeneratedColumn<bool>(
    'auto_remove_notes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_remove_notes" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _highlightMatchingMeta = const VerificationMeta(
    'highlightMatching',
  );
  @override
  late final GeneratedColumn<bool> highlightMatching = GeneratedColumn<bool>(
    'highlight_matching',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("highlight_matching" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showTimerMeta = const VerificationMeta(
    'showTimer',
  );
  @override
  late final GeneratedColumn<bool> showTimer = GeneratedColumn<bool>(
    'show_timer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_timer" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _mistakeLimitMeta = const VerificationMeta(
    'mistakeLimit',
  );
  @override
  late final GeneratedColumn<int> mistakeLimit = GeneratedColumn<int>(
    'mistake_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dark'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    autoRemoveNotes,
    highlightMatching,
    showTimer,
    mistakeLimit,
    theme,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_preferences_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<GamePreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('auto_remove_notes')) {
      context.handle(
        _autoRemoveNotesMeta,
        autoRemoveNotes.isAcceptableOrUnknown(
          data['auto_remove_notes']!,
          _autoRemoveNotesMeta,
        ),
      );
    }
    if (data.containsKey('highlight_matching')) {
      context.handle(
        _highlightMatchingMeta,
        highlightMatching.isAcceptableOrUnknown(
          data['highlight_matching']!,
          _highlightMatchingMeta,
        ),
      );
    }
    if (data.containsKey('show_timer')) {
      context.handle(
        _showTimerMeta,
        showTimer.isAcceptableOrUnknown(data['show_timer']!, _showTimerMeta),
      );
    }
    if (data.containsKey('mistake_limit')) {
      context.handle(
        _mistakeLimitMeta,
        mistakeLimit.isAcceptableOrUnknown(
          data['mistake_limit']!,
          _mistakeLimitMeta,
        ),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GamePreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GamePreferencesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      autoRemoveNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_remove_notes'],
      )!,
      highlightMatching: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}highlight_matching'],
      )!,
      showTimer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_timer'],
      )!,
      mistakeLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mistake_limit'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
    );
  }

  @override
  $GamePreferencesTableTable createAlias(String alias) {
    return $GamePreferencesTableTable(attachedDatabase, alias);
  }
}

class GamePreferencesTableData extends DataClass
    implements Insertable<GamePreferencesTableData> {
  final int id;
  final bool autoRemoveNotes;
  final bool highlightMatching;
  final bool showTimer;
  final int mistakeLimit;
  final String theme;
  const GamePreferencesTableData({
    required this.id,
    required this.autoRemoveNotes,
    required this.highlightMatching,
    required this.showTimer,
    required this.mistakeLimit,
    required this.theme,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['auto_remove_notes'] = Variable<bool>(autoRemoveNotes);
    map['highlight_matching'] = Variable<bool>(highlightMatching);
    map['show_timer'] = Variable<bool>(showTimer);
    map['mistake_limit'] = Variable<int>(mistakeLimit);
    map['theme'] = Variable<String>(theme);
    return map;
  }

  GamePreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return GamePreferencesTableCompanion(
      id: Value(id),
      autoRemoveNotes: Value(autoRemoveNotes),
      highlightMatching: Value(highlightMatching),
      showTimer: Value(showTimer),
      mistakeLimit: Value(mistakeLimit),
      theme: Value(theme),
    );
  }

  factory GamePreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GamePreferencesTableData(
      id: serializer.fromJson<int>(json['id']),
      autoRemoveNotes: serializer.fromJson<bool>(json['autoRemoveNotes']),
      highlightMatching: serializer.fromJson<bool>(json['highlightMatching']),
      showTimer: serializer.fromJson<bool>(json['showTimer']),
      mistakeLimit: serializer.fromJson<int>(json['mistakeLimit']),
      theme: serializer.fromJson<String>(json['theme']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'autoRemoveNotes': serializer.toJson<bool>(autoRemoveNotes),
      'highlightMatching': serializer.toJson<bool>(highlightMatching),
      'showTimer': serializer.toJson<bool>(showTimer),
      'mistakeLimit': serializer.toJson<int>(mistakeLimit),
      'theme': serializer.toJson<String>(theme),
    };
  }

  GamePreferencesTableData copyWith({
    int? id,
    bool? autoRemoveNotes,
    bool? highlightMatching,
    bool? showTimer,
    int? mistakeLimit,
    String? theme,
  }) => GamePreferencesTableData(
    id: id ?? this.id,
    autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
    highlightMatching: highlightMatching ?? this.highlightMatching,
    showTimer: showTimer ?? this.showTimer,
    mistakeLimit: mistakeLimit ?? this.mistakeLimit,
    theme: theme ?? this.theme,
  );
  GamePreferencesTableData copyWithCompanion(
    GamePreferencesTableCompanion data,
  ) {
    return GamePreferencesTableData(
      id: data.id.present ? data.id.value : this.id,
      autoRemoveNotes: data.autoRemoveNotes.present
          ? data.autoRemoveNotes.value
          : this.autoRemoveNotes,
      highlightMatching: data.highlightMatching.present
          ? data.highlightMatching.value
          : this.highlightMatching,
      showTimer: data.showTimer.present ? data.showTimer.value : this.showTimer,
      mistakeLimit: data.mistakeLimit.present
          ? data.mistakeLimit.value
          : this.mistakeLimit,
      theme: data.theme.present ? data.theme.value : this.theme,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GamePreferencesTableData(')
          ..write('id: $id, ')
          ..write('autoRemoveNotes: $autoRemoveNotes, ')
          ..write('highlightMatching: $highlightMatching, ')
          ..write('showTimer: $showTimer, ')
          ..write('mistakeLimit: $mistakeLimit, ')
          ..write('theme: $theme')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    autoRemoveNotes,
    highlightMatching,
    showTimer,
    mistakeLimit,
    theme,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GamePreferencesTableData &&
          other.id == this.id &&
          other.autoRemoveNotes == this.autoRemoveNotes &&
          other.highlightMatching == this.highlightMatching &&
          other.showTimer == this.showTimer &&
          other.mistakeLimit == this.mistakeLimit &&
          other.theme == this.theme);
}

class GamePreferencesTableCompanion
    extends UpdateCompanion<GamePreferencesTableData> {
  final Value<int> id;
  final Value<bool> autoRemoveNotes;
  final Value<bool> highlightMatching;
  final Value<bool> showTimer;
  final Value<int> mistakeLimit;
  final Value<String> theme;
  const GamePreferencesTableCompanion({
    this.id = const Value.absent(),
    this.autoRemoveNotes = const Value.absent(),
    this.highlightMatching = const Value.absent(),
    this.showTimer = const Value.absent(),
    this.mistakeLimit = const Value.absent(),
    this.theme = const Value.absent(),
  });
  GamePreferencesTableCompanion.insert({
    this.id = const Value.absent(),
    this.autoRemoveNotes = const Value.absent(),
    this.highlightMatching = const Value.absent(),
    this.showTimer = const Value.absent(),
    this.mistakeLimit = const Value.absent(),
    this.theme = const Value.absent(),
  });
  static Insertable<GamePreferencesTableData> custom({
    Expression<int>? id,
    Expression<bool>? autoRemoveNotes,
    Expression<bool>? highlightMatching,
    Expression<bool>? showTimer,
    Expression<int>? mistakeLimit,
    Expression<String>? theme,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (autoRemoveNotes != null) 'auto_remove_notes': autoRemoveNotes,
      if (highlightMatching != null) 'highlight_matching': highlightMatching,
      if (showTimer != null) 'show_timer': showTimer,
      if (mistakeLimit != null) 'mistake_limit': mistakeLimit,
      if (theme != null) 'theme': theme,
    });
  }

  GamePreferencesTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? autoRemoveNotes,
    Value<bool>? highlightMatching,
    Value<bool>? showTimer,
    Value<int>? mistakeLimit,
    Value<String>? theme,
  }) {
    return GamePreferencesTableCompanion(
      id: id ?? this.id,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      highlightMatching: highlightMatching ?? this.highlightMatching,
      showTimer: showTimer ?? this.showTimer,
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
      theme: theme ?? this.theme,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (autoRemoveNotes.present) {
      map['auto_remove_notes'] = Variable<bool>(autoRemoveNotes.value);
    }
    if (highlightMatching.present) {
      map['highlight_matching'] = Variable<bool>(highlightMatching.value);
    }
    if (showTimer.present) {
      map['show_timer'] = Variable<bool>(showTimer.value);
    }
    if (mistakeLimit.present) {
      map['mistake_limit'] = Variable<int>(mistakeLimit.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamePreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('autoRemoveNotes: $autoRemoveNotes, ')
          ..write('highlightMatching: $highlightMatching, ')
          ..write('showTimer: $showTimer, ')
          ..write('mistakeLimit: $mistakeLimit, ')
          ..write('theme: $theme')
          ..write(')'))
        .toString();
  }
}

class $DailyPuzzleCacheTable extends DailyPuzzleCache
    with TableInfo<$DailyPuzzleCacheTable, DailyPuzzleCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPuzzleCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cluesMeta = const VerificationMeta('clues');
  @override
  late final GeneratedColumn<String> clues = GeneratedColumn<String>(
    'clues',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solutionMeta = const VerificationMeta(
    'solution',
  );
  @override
  late final GeneratedColumn<String> solution = GeneratedColumn<String>(
    'solution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    clues,
    solution,
    difficulty,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_puzzle_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPuzzleCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('clues')) {
      context.handle(
        _cluesMeta,
        clues.isAcceptableOrUnknown(data['clues']!, _cluesMeta),
      );
    } else if (isInserting) {
      context.missing(_cluesMeta);
    }
    if (data.containsKey('solution')) {
      context.handle(
        _solutionMeta,
        solution.isAcceptableOrUnknown(data['solution']!, _solutionMeta),
      );
    } else if (isInserting) {
      context.missing(_solutionMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DailyPuzzleCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPuzzleCacheData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      clues: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clues'],
      )!,
      solution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solution'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $DailyPuzzleCacheTable createAlias(String alias) {
    return $DailyPuzzleCacheTable(attachedDatabase, alias);
  }
}

class DailyPuzzleCacheData extends DataClass
    implements Insertable<DailyPuzzleCacheData> {
  final String key;
  final String clues;
  final String solution;
  final String difficulty;
  final DateTime cachedAt;
  const DailyPuzzleCacheData({
    required this.key,
    required this.clues,
    required this.solution,
    required this.difficulty,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['clues'] = Variable<String>(clues);
    map['solution'] = Variable<String>(solution);
    map['difficulty'] = Variable<String>(difficulty);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  DailyPuzzleCacheCompanion toCompanion(bool nullToAbsent) {
    return DailyPuzzleCacheCompanion(
      key: Value(key),
      clues: Value(clues),
      solution: Value(solution),
      difficulty: Value(difficulty),
      cachedAt: Value(cachedAt),
    );
  }

  factory DailyPuzzleCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPuzzleCacheData(
      key: serializer.fromJson<String>(json['key']),
      clues: serializer.fromJson<String>(json['clues']),
      solution: serializer.fromJson<String>(json['solution']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'clues': serializer.toJson<String>(clues),
      'solution': serializer.toJson<String>(solution),
      'difficulty': serializer.toJson<String>(difficulty),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  DailyPuzzleCacheData copyWith({
    String? key,
    String? clues,
    String? solution,
    String? difficulty,
    DateTime? cachedAt,
  }) => DailyPuzzleCacheData(
    key: key ?? this.key,
    clues: clues ?? this.clues,
    solution: solution ?? this.solution,
    difficulty: difficulty ?? this.difficulty,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  DailyPuzzleCacheData copyWithCompanion(DailyPuzzleCacheCompanion data) {
    return DailyPuzzleCacheData(
      key: data.key.present ? data.key.value : this.key,
      clues: data.clues.present ? data.clues.value : this.clues,
      solution: data.solution.present ? data.solution.value : this.solution,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPuzzleCacheData(')
          ..write('key: $key, ')
          ..write('clues: $clues, ')
          ..write('solution: $solution, ')
          ..write('difficulty: $difficulty, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, clues, solution, difficulty, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPuzzleCacheData &&
          other.key == this.key &&
          other.clues == this.clues &&
          other.solution == this.solution &&
          other.difficulty == this.difficulty &&
          other.cachedAt == this.cachedAt);
}

class DailyPuzzleCacheCompanion extends UpdateCompanion<DailyPuzzleCacheData> {
  final Value<String> key;
  final Value<String> clues;
  final Value<String> solution;
  final Value<String> difficulty;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const DailyPuzzleCacheCompanion({
    this.key = const Value.absent(),
    this.clues = const Value.absent(),
    this.solution = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPuzzleCacheCompanion.insert({
    required String key,
    required String clues,
    required String solution,
    required String difficulty,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       clues = Value(clues),
       solution = Value(solution),
       difficulty = Value(difficulty),
       cachedAt = Value(cachedAt);
  static Insertable<DailyPuzzleCacheData> custom({
    Expression<String>? key,
    Expression<String>? clues,
    Expression<String>? solution,
    Expression<String>? difficulty,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (clues != null) 'clues': clues,
      if (solution != null) 'solution': solution,
      if (difficulty != null) 'difficulty': difficulty,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPuzzleCacheCompanion copyWith({
    Value<String>? key,
    Value<String>? clues,
    Value<String>? solution,
    Value<String>? difficulty,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return DailyPuzzleCacheCompanion(
      key: key ?? this.key,
      clues: clues ?? this.clues,
      solution: solution ?? this.solution,
      difficulty: difficulty ?? this.difficulty,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (clues.present) {
      map['clues'] = Variable<String>(clues.value);
    }
    if (solution.present) {
      map['solution'] = Variable<String>(solution.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPuzzleCacheCompanion(')
          ..write('key: $key, ')
          ..write('clues: $clues, ')
          ..write('solution: $solution, ')
          ..write('difficulty: $difficulty, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedGamesTable extends SavedGames
    with TableInfo<$SavedGamesTable, SavedGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedGamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDailyMeta = const VerificationMeta(
    'isDaily',
  );
  @override
  late final GeneratedColumn<bool> isDaily = GeneratedColumn<bool>(
    'is_daily',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_daily" IN (0, 1))',
    ),
  );
  static const VerificationMeta _givenCellsMeta = const VerificationMeta(
    'givenCells',
  );
  @override
  late final GeneratedColumn<String> givenCells = GeneratedColumn<String>(
    'given_cells',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solutionCellsMeta = const VerificationMeta(
    'solutionCells',
  );
  @override
  late final GeneratedColumn<String> solutionCells = GeneratedColumn<String>(
    'solution_cells',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardCellsMeta = const VerificationMeta(
    'boardCells',
  );
  @override
  late final GeneratedColumn<String> boardCells = GeneratedColumn<String>(
    'board_cells',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedSecondsMeta = const VerificationMeta(
    'elapsedSeconds',
  );
  @override
  late final GeneratedColumn<int> elapsedSeconds = GeneratedColumn<int>(
    'elapsed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsRemainingMeta = const VerificationMeta(
    'hintsRemaining',
  );
  @override
  late final GeneratedColumn<int> hintsRemaining = GeneratedColumn<int>(
    'hints_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mistakeCountMeta = const VerificationMeta(
    'mistakeCount',
  );
  @override
  late final GeneratedColumn<int> mistakeCount = GeneratedColumn<int>(
    'mistake_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isNotesModeMeta = const VerificationMeta(
    'isNotesMode',
  );
  @override
  late final GeneratedColumn<bool> isNotesMode = GeneratedColumn<bool>(
    'is_notes_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_notes_mode" IN (0, 1))',
    ),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    puzzleId,
    difficulty,
    isDaily,
    givenCells,
    solutionCells,
    boardCells,
    notes,
    elapsedSeconds,
    hintsRemaining,
    mistakeCount,
    isNotesMode,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_games';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedGame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('is_daily')) {
      context.handle(
        _isDailyMeta,
        isDaily.isAcceptableOrUnknown(data['is_daily']!, _isDailyMeta),
      );
    } else if (isInserting) {
      context.missing(_isDailyMeta);
    }
    if (data.containsKey('given_cells')) {
      context.handle(
        _givenCellsMeta,
        givenCells.isAcceptableOrUnknown(data['given_cells']!, _givenCellsMeta),
      );
    } else if (isInserting) {
      context.missing(_givenCellsMeta);
    }
    if (data.containsKey('solution_cells')) {
      context.handle(
        _solutionCellsMeta,
        solutionCells.isAcceptableOrUnknown(
          data['solution_cells']!,
          _solutionCellsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_solutionCellsMeta);
    }
    if (data.containsKey('board_cells')) {
      context.handle(
        _boardCellsMeta,
        boardCells.isAcceptableOrUnknown(data['board_cells']!, _boardCellsMeta),
      );
    } else if (isInserting) {
      context.missing(_boardCellsMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('elapsed_seconds')) {
      context.handle(
        _elapsedSecondsMeta,
        elapsedSeconds.isAcceptableOrUnknown(
          data['elapsed_seconds']!,
          _elapsedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_elapsedSecondsMeta);
    }
    if (data.containsKey('hints_remaining')) {
      context.handle(
        _hintsRemainingMeta,
        hintsRemaining.isAcceptableOrUnknown(
          data['hints_remaining']!,
          _hintsRemainingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hintsRemainingMeta);
    }
    if (data.containsKey('mistake_count')) {
      context.handle(
        _mistakeCountMeta,
        mistakeCount.isAcceptableOrUnknown(
          data['mistake_count']!,
          _mistakeCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mistakeCountMeta);
    }
    if (data.containsKey('is_notes_mode')) {
      context.handle(
        _isNotesModeMeta,
        isNotesMode.isAcceptableOrUnknown(
          data['is_notes_mode']!,
          _isNotesModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isNotesModeMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedGame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      isDaily: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_daily'],
      )!,
      givenCells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}given_cells'],
      )!,
      solutionCells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}solution_cells'],
      )!,
      boardCells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_cells'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      elapsedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_seconds'],
      )!,
      hintsRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_remaining'],
      )!,
      mistakeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mistake_count'],
      )!,
      isNotesMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_notes_mode'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedGamesTable createAlias(String alias) {
    return $SavedGamesTable(attachedDatabase, alias);
  }
}

class SavedGame extends DataClass implements Insertable<SavedGame> {
  final int id;
  final String puzzleId;
  final String difficulty;
  final bool isDaily;
  final String givenCells;
  final String solutionCells;
  final String boardCells;
  final String notes;
  final int elapsedSeconds;
  final int hintsRemaining;
  final int mistakeCount;
  final bool isNotesMode;
  final DateTime savedAt;
  const SavedGame({
    required this.id,
    required this.puzzleId,
    required this.difficulty,
    required this.isDaily,
    required this.givenCells,
    required this.solutionCells,
    required this.boardCells,
    required this.notes,
    required this.elapsedSeconds,
    required this.hintsRemaining,
    required this.mistakeCount,
    required this.isNotesMode,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['difficulty'] = Variable<String>(difficulty);
    map['is_daily'] = Variable<bool>(isDaily);
    map['given_cells'] = Variable<String>(givenCells);
    map['solution_cells'] = Variable<String>(solutionCells);
    map['board_cells'] = Variable<String>(boardCells);
    map['notes'] = Variable<String>(notes);
    map['elapsed_seconds'] = Variable<int>(elapsedSeconds);
    map['hints_remaining'] = Variable<int>(hintsRemaining);
    map['mistake_count'] = Variable<int>(mistakeCount);
    map['is_notes_mode'] = Variable<bool>(isNotesMode);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedGamesCompanion toCompanion(bool nullToAbsent) {
    return SavedGamesCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      difficulty: Value(difficulty),
      isDaily: Value(isDaily),
      givenCells: Value(givenCells),
      solutionCells: Value(solutionCells),
      boardCells: Value(boardCells),
      notes: Value(notes),
      elapsedSeconds: Value(elapsedSeconds),
      hintsRemaining: Value(hintsRemaining),
      mistakeCount: Value(mistakeCount),
      isNotesMode: Value(isNotesMode),
      savedAt: Value(savedAt),
    );
  }

  factory SavedGame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedGame(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      isDaily: serializer.fromJson<bool>(json['isDaily']),
      givenCells: serializer.fromJson<String>(json['givenCells']),
      solutionCells: serializer.fromJson<String>(json['solutionCells']),
      boardCells: serializer.fromJson<String>(json['boardCells']),
      notes: serializer.fromJson<String>(json['notes']),
      elapsedSeconds: serializer.fromJson<int>(json['elapsedSeconds']),
      hintsRemaining: serializer.fromJson<int>(json['hintsRemaining']),
      mistakeCount: serializer.fromJson<int>(json['mistakeCount']),
      isNotesMode: serializer.fromJson<bool>(json['isNotesMode']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'difficulty': serializer.toJson<String>(difficulty),
      'isDaily': serializer.toJson<bool>(isDaily),
      'givenCells': serializer.toJson<String>(givenCells),
      'solutionCells': serializer.toJson<String>(solutionCells),
      'boardCells': serializer.toJson<String>(boardCells),
      'notes': serializer.toJson<String>(notes),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'hintsRemaining': serializer.toJson<int>(hintsRemaining),
      'mistakeCount': serializer.toJson<int>(mistakeCount),
      'isNotesMode': serializer.toJson<bool>(isNotesMode),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedGame copyWith({
    int? id,
    String? puzzleId,
    String? difficulty,
    bool? isDaily,
    String? givenCells,
    String? solutionCells,
    String? boardCells,
    String? notes,
    int? elapsedSeconds,
    int? hintsRemaining,
    int? mistakeCount,
    bool? isNotesMode,
    DateTime? savedAt,
  }) => SavedGame(
    id: id ?? this.id,
    puzzleId: puzzleId ?? this.puzzleId,
    difficulty: difficulty ?? this.difficulty,
    isDaily: isDaily ?? this.isDaily,
    givenCells: givenCells ?? this.givenCells,
    solutionCells: solutionCells ?? this.solutionCells,
    boardCells: boardCells ?? this.boardCells,
    notes: notes ?? this.notes,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    hintsRemaining: hintsRemaining ?? this.hintsRemaining,
    mistakeCount: mistakeCount ?? this.mistakeCount,
    isNotesMode: isNotesMode ?? this.isNotesMode,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedGame copyWithCompanion(SavedGamesCompanion data) {
    return SavedGame(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      isDaily: data.isDaily.present ? data.isDaily.value : this.isDaily,
      givenCells: data.givenCells.present
          ? data.givenCells.value
          : this.givenCells,
      solutionCells: data.solutionCells.present
          ? data.solutionCells.value
          : this.solutionCells,
      boardCells: data.boardCells.present
          ? data.boardCells.value
          : this.boardCells,
      notes: data.notes.present ? data.notes.value : this.notes,
      elapsedSeconds: data.elapsedSeconds.present
          ? data.elapsedSeconds.value
          : this.elapsedSeconds,
      hintsRemaining: data.hintsRemaining.present
          ? data.hintsRemaining.value
          : this.hintsRemaining,
      mistakeCount: data.mistakeCount.present
          ? data.mistakeCount.value
          : this.mistakeCount,
      isNotesMode: data.isNotesMode.present
          ? data.isNotesMode.value
          : this.isNotesMode,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedGame(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('isDaily: $isDaily, ')
          ..write('givenCells: $givenCells, ')
          ..write('solutionCells: $solutionCells, ')
          ..write('boardCells: $boardCells, ')
          ..write('notes: $notes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('hintsRemaining: $hintsRemaining, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('isNotesMode: $isNotesMode, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    puzzleId,
    difficulty,
    isDaily,
    givenCells,
    solutionCells,
    boardCells,
    notes,
    elapsedSeconds,
    hintsRemaining,
    mistakeCount,
    isNotesMode,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedGame &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.difficulty == this.difficulty &&
          other.isDaily == this.isDaily &&
          other.givenCells == this.givenCells &&
          other.solutionCells == this.solutionCells &&
          other.boardCells == this.boardCells &&
          other.notes == this.notes &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.hintsRemaining == this.hintsRemaining &&
          other.mistakeCount == this.mistakeCount &&
          other.isNotesMode == this.isNotesMode &&
          other.savedAt == this.savedAt);
}

class SavedGamesCompanion extends UpdateCompanion<SavedGame> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> difficulty;
  final Value<bool> isDaily;
  final Value<String> givenCells;
  final Value<String> solutionCells;
  final Value<String> boardCells;
  final Value<String> notes;
  final Value<int> elapsedSeconds;
  final Value<int> hintsRemaining;
  final Value<int> mistakeCount;
  final Value<bool> isNotesMode;
  final Value<DateTime> savedAt;
  const SavedGamesCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isDaily = const Value.absent(),
    this.givenCells = const Value.absent(),
    this.solutionCells = const Value.absent(),
    this.boardCells = const Value.absent(),
    this.notes = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.hintsRemaining = const Value.absent(),
    this.mistakeCount = const Value.absent(),
    this.isNotesMode = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  SavedGamesCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String difficulty,
    required bool isDaily,
    required String givenCells,
    required String solutionCells,
    required String boardCells,
    required String notes,
    required int elapsedSeconds,
    required int hintsRemaining,
    required int mistakeCount,
    required bool isNotesMode,
    required DateTime savedAt,
  }) : puzzleId = Value(puzzleId),
       difficulty = Value(difficulty),
       isDaily = Value(isDaily),
       givenCells = Value(givenCells),
       solutionCells = Value(solutionCells),
       boardCells = Value(boardCells),
       notes = Value(notes),
       elapsedSeconds = Value(elapsedSeconds),
       hintsRemaining = Value(hintsRemaining),
       mistakeCount = Value(mistakeCount),
       isNotesMode = Value(isNotesMode),
       savedAt = Value(savedAt);
  static Insertable<SavedGame> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? difficulty,
    Expression<bool>? isDaily,
    Expression<String>? givenCells,
    Expression<String>? solutionCells,
    Expression<String>? boardCells,
    Expression<String>? notes,
    Expression<int>? elapsedSeconds,
    Expression<int>? hintsRemaining,
    Expression<int>? mistakeCount,
    Expression<bool>? isNotesMode,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (difficulty != null) 'difficulty': difficulty,
      if (isDaily != null) 'is_daily': isDaily,
      if (givenCells != null) 'given_cells': givenCells,
      if (solutionCells != null) 'solution_cells': solutionCells,
      if (boardCells != null) 'board_cells': boardCells,
      if (notes != null) 'notes': notes,
      if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      if (hintsRemaining != null) 'hints_remaining': hintsRemaining,
      if (mistakeCount != null) 'mistake_count': mistakeCount,
      if (isNotesMode != null) 'is_notes_mode': isNotesMode,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  SavedGamesCompanion copyWith({
    Value<int>? id,
    Value<String>? puzzleId,
    Value<String>? difficulty,
    Value<bool>? isDaily,
    Value<String>? givenCells,
    Value<String>? solutionCells,
    Value<String>? boardCells,
    Value<String>? notes,
    Value<int>? elapsedSeconds,
    Value<int>? hintsRemaining,
    Value<int>? mistakeCount,
    Value<bool>? isNotesMode,
    Value<DateTime>? savedAt,
  }) {
    return SavedGamesCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      difficulty: difficulty ?? this.difficulty,
      isDaily: isDaily ?? this.isDaily,
      givenCells: givenCells ?? this.givenCells,
      solutionCells: solutionCells ?? this.solutionCells,
      boardCells: boardCells ?? this.boardCells,
      notes: notes ?? this.notes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      isNotesMode: isNotesMode ?? this.isNotesMode,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (isDaily.present) {
      map['is_daily'] = Variable<bool>(isDaily.value);
    }
    if (givenCells.present) {
      map['given_cells'] = Variable<String>(givenCells.value);
    }
    if (solutionCells.present) {
      map['solution_cells'] = Variable<String>(solutionCells.value);
    }
    if (boardCells.present) {
      map['board_cells'] = Variable<String>(boardCells.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (elapsedSeconds.present) {
      map['elapsed_seconds'] = Variable<int>(elapsedSeconds.value);
    }
    if (hintsRemaining.present) {
      map['hints_remaining'] = Variable<int>(hintsRemaining.value);
    }
    if (mistakeCount.present) {
      map['mistake_count'] = Variable<int>(mistakeCount.value);
    }
    if (isNotesMode.present) {
      map['is_notes_mode'] = Variable<bool>(isNotesMode.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedGamesCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('isDaily: $isDaily, ')
          ..write('givenCells: $givenCells, ')
          ..write('solutionCells: $solutionCells, ')
          ..write('boardCells: $boardCells, ')
          ..write('notes: $notes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('hintsRemaining: $hintsRemaining, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('isNotesMode: $isNotesMode, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueItemsTable extends SyncQueueItems
    with TableInfo<$SyncQueueItemsTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, payload, queuedAt, attempts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $SyncQueueItemsTable createAlias(String alias) {
    return $SyncQueueItemsTable(attachedDatabase, alias);
  }
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int id;
  final String type;
  final String payload;
  final DateTime queuedAt;
  final int attempts;
  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.queuedAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  SyncQueueItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueItemsCompanion(
      id: Value(id),
      type: Value(type),
      payload: Value(payload),
      queuedAt: Value(queuedAt),
      attempts: Value(attempts),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  SyncQueueItem copyWith({
    int? id,
    String? type,
    String? payload,
    DateTime? queuedAt,
    int? attempts,
  }) => SyncQueueItem(
    id: id ?? this.id,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    queuedAt: queuedAt ?? this.queuedAt,
    attempts: attempts ?? this.attempts,
  );
  SyncQueueItem copyWithCompanion(SyncQueueItemsCompanion data) {
    return SyncQueueItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, payload, queuedAt, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.queuedAt == this.queuedAt &&
          other.attempts == this.attempts);
}

class SyncQueueItemsCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> payload;
  final Value<DateTime> queuedAt;
  final Value<int> attempts;
  const SyncQueueItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  SyncQueueItemsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String payload,
    required DateTime queuedAt,
    this.attempts = const Value.absent(),
  }) : type = Value(type),
       payload = Value(payload),
       queuedAt = Value(queuedAt);
  static Insertable<SyncQueueItem> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<DateTime>? queuedAt,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (attempts != null) 'attempts': attempts,
    });
  }

  SyncQueueItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? payload,
    Value<DateTime>? queuedAt,
    Value<int>? attempts,
  }) {
    return SyncQueueItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      queuedAt: queuedAt ?? this.queuedAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PuzzleRecordsTable puzzleRecords = $PuzzleRecordsTable(this);
  late final $PlayerProfilesTable playerProfiles = $PlayerProfilesTable(this);
  late final $GamePreferencesTableTable gamePreferencesTable =
      $GamePreferencesTableTable(this);
  late final $DailyPuzzleCacheTable dailyPuzzleCache = $DailyPuzzleCacheTable(
    this,
  );
  late final $SavedGamesTable savedGames = $SavedGamesTable(this);
  late final $SyncQueueItemsTable syncQueueItems = $SyncQueueItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    puzzleRecords,
    playerProfiles,
    gamePreferencesTable,
    dailyPuzzleCache,
    savedGames,
    syncQueueItems,
  ];
}

typedef $$PuzzleRecordsTableCreateCompanionBuilder =
    PuzzleRecordsCompanion Function({
      Value<int> id,
      required String puzzleId,
      required String difficulty,
      Value<bool> isDaily,
      required int timeSeconds,
      Value<int> hintsUsed,
      Value<int> mistakes,
      required DateTime completedAt,
      Value<String> solveTimes,
      Value<int> undosUsed,
      Value<bool> usedNotes,
      Value<int> longestPauseSeconds,
      Value<String> mistakeCells,
      Value<double> qualityScore,
    });
typedef $$PuzzleRecordsTableUpdateCompanionBuilder =
    PuzzleRecordsCompanion Function({
      Value<int> id,
      Value<String> puzzleId,
      Value<String> difficulty,
      Value<bool> isDaily,
      Value<int> timeSeconds,
      Value<int> hintsUsed,
      Value<int> mistakes,
      Value<DateTime> completedAt,
      Value<String> solveTimes,
      Value<int> undosUsed,
      Value<bool> usedNotes,
      Value<int> longestPauseSeconds,
      Value<String> mistakeCells,
      Value<double> qualityScore,
    });

class $$PuzzleRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleRecordsTable> {
  $$PuzzleRecordsTableFilterComposer({
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

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mistakes => $composableBuilder(
    column: $table.mistakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solveTimes => $composableBuilder(
    column: $table.solveTimes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get undosUsed => $composableBuilder(
    column: $table.undosUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get usedNotes => $composableBuilder(
    column: $table.usedNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestPauseSeconds => $composableBuilder(
    column: $table.longestPauseSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mistakeCells => $composableBuilder(
    column: $table.mistakeCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuzzleRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleRecordsTable> {
  $$PuzzleRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mistakes => $composableBuilder(
    column: $table.mistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solveTimes => $composableBuilder(
    column: $table.solveTimes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get undosUsed => $composableBuilder(
    column: $table.undosUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get usedNotes => $composableBuilder(
    column: $table.usedNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestPauseSeconds => $composableBuilder(
    column: $table.longestPauseSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mistakeCells => $composableBuilder(
    column: $table.mistakeCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzleRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleRecordsTable> {
  $$PuzzleRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDaily =>
      $composableBuilder(column: $table.isDaily, builder: (column) => column);

  GeneratedColumn<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get mistakes =>
      $composableBuilder(column: $table.mistakes, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get solveTimes => $composableBuilder(
    column: $table.solveTimes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get undosUsed =>
      $composableBuilder(column: $table.undosUsed, builder: (column) => column);

  GeneratedColumn<bool> get usedNotes =>
      $composableBuilder(column: $table.usedNotes, builder: (column) => column);

  GeneratedColumn<int> get longestPauseSeconds => $composableBuilder(
    column: $table.longestPauseSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mistakeCells => $composableBuilder(
    column: $table.mistakeCells,
    builder: (column) => column,
  );

  GeneratedColumn<double> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => column,
  );
}

class $$PuzzleRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleRecordsTable,
          PuzzleRecord,
          $$PuzzleRecordsTableFilterComposer,
          $$PuzzleRecordsTableOrderingComposer,
          $$PuzzleRecordsTableAnnotationComposer,
          $$PuzzleRecordsTableCreateCompanionBuilder,
          $$PuzzleRecordsTableUpdateCompanionBuilder,
          (
            PuzzleRecord,
            BaseReferences<_$AppDatabase, $PuzzleRecordsTable, PuzzleRecord>,
          ),
          PuzzleRecord,
          PrefetchHooks Function()
        > {
  $$PuzzleRecordsTableTableManager(_$AppDatabase db, $PuzzleRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<bool> isDaily = const Value.absent(),
                Value<int> timeSeconds = const Value.absent(),
                Value<int> hintsUsed = const Value.absent(),
                Value<int> mistakes = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> solveTimes = const Value.absent(),
                Value<int> undosUsed = const Value.absent(),
                Value<bool> usedNotes = const Value.absent(),
                Value<int> longestPauseSeconds = const Value.absent(),
                Value<String> mistakeCells = const Value.absent(),
                Value<double> qualityScore = const Value.absent(),
              }) => PuzzleRecordsCompanion(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                isDaily: isDaily,
                timeSeconds: timeSeconds,
                hintsUsed: hintsUsed,
                mistakes: mistakes,
                completedAt: completedAt,
                solveTimes: solveTimes,
                undosUsed: undosUsed,
                usedNotes: usedNotes,
                longestPauseSeconds: longestPauseSeconds,
                mistakeCells: mistakeCells,
                qualityScore: qualityScore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String puzzleId,
                required String difficulty,
                Value<bool> isDaily = const Value.absent(),
                required int timeSeconds,
                Value<int> hintsUsed = const Value.absent(),
                Value<int> mistakes = const Value.absent(),
                required DateTime completedAt,
                Value<String> solveTimes = const Value.absent(),
                Value<int> undosUsed = const Value.absent(),
                Value<bool> usedNotes = const Value.absent(),
                Value<int> longestPauseSeconds = const Value.absent(),
                Value<String> mistakeCells = const Value.absent(),
                Value<double> qualityScore = const Value.absent(),
              }) => PuzzleRecordsCompanion.insert(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                isDaily: isDaily,
                timeSeconds: timeSeconds,
                hintsUsed: hintsUsed,
                mistakes: mistakes,
                completedAt: completedAt,
                solveTimes: solveTimes,
                undosUsed: undosUsed,
                usedNotes: usedNotes,
                longestPauseSeconds: longestPauseSeconds,
                mistakeCells: mistakeCells,
                qualityScore: qualityScore,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuzzleRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleRecordsTable,
      PuzzleRecord,
      $$PuzzleRecordsTableFilterComposer,
      $$PuzzleRecordsTableOrderingComposer,
      $$PuzzleRecordsTableAnnotationComposer,
      $$PuzzleRecordsTableCreateCompanionBuilder,
      $$PuzzleRecordsTableUpdateCompanionBuilder,
      (
        PuzzleRecord,
        BaseReferences<_$AppDatabase, $PuzzleRecordsTable, PuzzleRecord>,
      ),
      PuzzleRecord,
      PrefetchHooks Function()
    >;
typedef $$PlayerProfilesTableCreateCompanionBuilder =
    PlayerProfilesCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<DateTime?> lastPlayedDate,
      Value<int> totalSolved,
      Value<int> totalStarted,
      Value<String> preferredDifficulty,
    });
typedef $$PlayerProfilesTableUpdateCompanionBuilder =
    PlayerProfilesCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<DateTime?> lastPlayedDate,
      Value<int> totalSolved,
      Value<int> totalStarted,
      Value<String> preferredDifficulty,
    });

class $$PlayerProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerProfilesTable> {
  $$PlayerProfilesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSolved => $composableBuilder(
    column: $table.totalSolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalStarted => $composableBuilder(
    column: $table.totalStarted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredDifficulty => $composableBuilder(
    column: $table.preferredDifficulty,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayerProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerProfilesTable> {
  $$PlayerProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSolved => $composableBuilder(
    column: $table.totalSolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalStarted => $composableBuilder(
    column: $table.totalStarted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredDifficulty => $composableBuilder(
    column: $table.preferredDifficulty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayerProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerProfilesTable> {
  $$PlayerProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSolved => $composableBuilder(
    column: $table.totalSolved,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalStarted => $composableBuilder(
    column: $table.totalStarted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredDifficulty => $composableBuilder(
    column: $table.preferredDifficulty,
    builder: (column) => column,
  );
}

class $$PlayerProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayerProfilesTable,
          PlayerProfile,
          $$PlayerProfilesTableFilterComposer,
          $$PlayerProfilesTableOrderingComposer,
          $$PlayerProfilesTableAnnotationComposer,
          $$PlayerProfilesTableCreateCompanionBuilder,
          $$PlayerProfilesTableUpdateCompanionBuilder,
          (
            PlayerProfile,
            BaseReferences<_$AppDatabase, $PlayerProfilesTable, PlayerProfile>,
          ),
          PlayerProfile,
          PrefetchHooks Function()
        > {
  $$PlayerProfilesTableTableManager(
    _$AppDatabase db,
    $PlayerProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<DateTime?> lastPlayedDate = const Value.absent(),
                Value<int> totalSolved = const Value.absent(),
                Value<int> totalStarted = const Value.absent(),
                Value<String> preferredDifficulty = const Value.absent(),
              }) => PlayerProfilesCompanion(
                id: id,
                displayName: displayName,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastPlayedDate: lastPlayedDate,
                totalSolved: totalSolved,
                totalStarted: totalStarted,
                preferredDifficulty: preferredDifficulty,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<DateTime?> lastPlayedDate = const Value.absent(),
                Value<int> totalSolved = const Value.absent(),
                Value<int> totalStarted = const Value.absent(),
                Value<String> preferredDifficulty = const Value.absent(),
              }) => PlayerProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastPlayedDate: lastPlayedDate,
                totalSolved: totalSolved,
                totalStarted: totalStarted,
                preferredDifficulty: preferredDifficulty,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayerProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayerProfilesTable,
      PlayerProfile,
      $$PlayerProfilesTableFilterComposer,
      $$PlayerProfilesTableOrderingComposer,
      $$PlayerProfilesTableAnnotationComposer,
      $$PlayerProfilesTableCreateCompanionBuilder,
      $$PlayerProfilesTableUpdateCompanionBuilder,
      (
        PlayerProfile,
        BaseReferences<_$AppDatabase, $PlayerProfilesTable, PlayerProfile>,
      ),
      PlayerProfile,
      PrefetchHooks Function()
    >;
typedef $$GamePreferencesTableTableCreateCompanionBuilder =
    GamePreferencesTableCompanion Function({
      Value<int> id,
      Value<bool> autoRemoveNotes,
      Value<bool> highlightMatching,
      Value<bool> showTimer,
      Value<int> mistakeLimit,
      Value<String> theme,
    });
typedef $$GamePreferencesTableTableUpdateCompanionBuilder =
    GamePreferencesTableCompanion Function({
      Value<int> id,
      Value<bool> autoRemoveNotes,
      Value<bool> highlightMatching,
      Value<bool> showTimer,
      Value<int> mistakeLimit,
      Value<String> theme,
    });

class $$GamePreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $GamePreferencesTableTable> {
  $$GamePreferencesTableTableFilterComposer({
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

  ColumnFilters<bool> get autoRemoveNotes => $composableBuilder(
    column: $table.autoRemoveNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get highlightMatching => $composableBuilder(
    column: $table.highlightMatching,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showTimer => $composableBuilder(
    column: $table.showTimer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mistakeLimit => $composableBuilder(
    column: $table.mistakeLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GamePreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GamePreferencesTableTable> {
  $$GamePreferencesTableTableOrderingComposer({
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

  ColumnOrderings<bool> get autoRemoveNotes => $composableBuilder(
    column: $table.autoRemoveNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get highlightMatching => $composableBuilder(
    column: $table.highlightMatching,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showTimer => $composableBuilder(
    column: $table.showTimer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mistakeLimit => $composableBuilder(
    column: $table.mistakeLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamePreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamePreferencesTableTable> {
  $$GamePreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get autoRemoveNotes => $composableBuilder(
    column: $table.autoRemoveNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get highlightMatching => $composableBuilder(
    column: $table.highlightMatching,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showTimer =>
      $composableBuilder(column: $table.showTimer, builder: (column) => column);

  GeneratedColumn<int> get mistakeLimit => $composableBuilder(
    column: $table.mistakeLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);
}

class $$GamePreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamePreferencesTableTable,
          GamePreferencesTableData,
          $$GamePreferencesTableTableFilterComposer,
          $$GamePreferencesTableTableOrderingComposer,
          $$GamePreferencesTableTableAnnotationComposer,
          $$GamePreferencesTableTableCreateCompanionBuilder,
          $$GamePreferencesTableTableUpdateCompanionBuilder,
          (
            GamePreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $GamePreferencesTableTable,
              GamePreferencesTableData
            >,
          ),
          GamePreferencesTableData,
          PrefetchHooks Function()
        > {
  $$GamePreferencesTableTableTableManager(
    _$AppDatabase db,
    $GamePreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamePreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamePreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GamePreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> autoRemoveNotes = const Value.absent(),
                Value<bool> highlightMatching = const Value.absent(),
                Value<bool> showTimer = const Value.absent(),
                Value<int> mistakeLimit = const Value.absent(),
                Value<String> theme = const Value.absent(),
              }) => GamePreferencesTableCompanion(
                id: id,
                autoRemoveNotes: autoRemoveNotes,
                highlightMatching: highlightMatching,
                showTimer: showTimer,
                mistakeLimit: mistakeLimit,
                theme: theme,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> autoRemoveNotes = const Value.absent(),
                Value<bool> highlightMatching = const Value.absent(),
                Value<bool> showTimer = const Value.absent(),
                Value<int> mistakeLimit = const Value.absent(),
                Value<String> theme = const Value.absent(),
              }) => GamePreferencesTableCompanion.insert(
                id: id,
                autoRemoveNotes: autoRemoveNotes,
                highlightMatching: highlightMatching,
                showTimer: showTimer,
                mistakeLimit: mistakeLimit,
                theme: theme,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GamePreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamePreferencesTableTable,
      GamePreferencesTableData,
      $$GamePreferencesTableTableFilterComposer,
      $$GamePreferencesTableTableOrderingComposer,
      $$GamePreferencesTableTableAnnotationComposer,
      $$GamePreferencesTableTableCreateCompanionBuilder,
      $$GamePreferencesTableTableUpdateCompanionBuilder,
      (
        GamePreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $GamePreferencesTableTable,
          GamePreferencesTableData
        >,
      ),
      GamePreferencesTableData,
      PrefetchHooks Function()
    >;
typedef $$DailyPuzzleCacheTableCreateCompanionBuilder =
    DailyPuzzleCacheCompanion Function({
      required String key,
      required String clues,
      required String solution,
      required String difficulty,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$DailyPuzzleCacheTableUpdateCompanionBuilder =
    DailyPuzzleCacheCompanion Function({
      Value<String> key,
      Value<String> clues,
      Value<String> solution,
      Value<String> difficulty,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$DailyPuzzleCacheTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPuzzleCacheTable> {
  $$DailyPuzzleCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clues => $composableBuilder(
    column: $table.clues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solution => $composableBuilder(
    column: $table.solution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPuzzleCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPuzzleCacheTable> {
  $$DailyPuzzleCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clues => $composableBuilder(
    column: $table.clues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solution => $composableBuilder(
    column: $table.solution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPuzzleCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPuzzleCacheTable> {
  $$DailyPuzzleCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get clues =>
      $composableBuilder(column: $table.clues, builder: (column) => column);

  GeneratedColumn<String> get solution =>
      $composableBuilder(column: $table.solution, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$DailyPuzzleCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPuzzleCacheTable,
          DailyPuzzleCacheData,
          $$DailyPuzzleCacheTableFilterComposer,
          $$DailyPuzzleCacheTableOrderingComposer,
          $$DailyPuzzleCacheTableAnnotationComposer,
          $$DailyPuzzleCacheTableCreateCompanionBuilder,
          $$DailyPuzzleCacheTableUpdateCompanionBuilder,
          (
            DailyPuzzleCacheData,
            BaseReferences<
              _$AppDatabase,
              $DailyPuzzleCacheTable,
              DailyPuzzleCacheData
            >,
          ),
          DailyPuzzleCacheData,
          PrefetchHooks Function()
        > {
  $$DailyPuzzleCacheTableTableManager(
    _$AppDatabase db,
    $DailyPuzzleCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPuzzleCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPuzzleCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPuzzleCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> clues = const Value.absent(),
                Value<String> solution = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPuzzleCacheCompanion(
                key: key,
                clues: clues,
                solution: solution,
                difficulty: difficulty,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String clues,
                required String solution,
                required String difficulty,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyPuzzleCacheCompanion.insert(
                key: key,
                clues: clues,
                solution: solution,
                difficulty: difficulty,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPuzzleCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPuzzleCacheTable,
      DailyPuzzleCacheData,
      $$DailyPuzzleCacheTableFilterComposer,
      $$DailyPuzzleCacheTableOrderingComposer,
      $$DailyPuzzleCacheTableAnnotationComposer,
      $$DailyPuzzleCacheTableCreateCompanionBuilder,
      $$DailyPuzzleCacheTableUpdateCompanionBuilder,
      (
        DailyPuzzleCacheData,
        BaseReferences<
          _$AppDatabase,
          $DailyPuzzleCacheTable,
          DailyPuzzleCacheData
        >,
      ),
      DailyPuzzleCacheData,
      PrefetchHooks Function()
    >;
typedef $$SavedGamesTableCreateCompanionBuilder =
    SavedGamesCompanion Function({
      Value<int> id,
      required String puzzleId,
      required String difficulty,
      required bool isDaily,
      required String givenCells,
      required String solutionCells,
      required String boardCells,
      required String notes,
      required int elapsedSeconds,
      required int hintsRemaining,
      required int mistakeCount,
      required bool isNotesMode,
      required DateTime savedAt,
    });
typedef $$SavedGamesTableUpdateCompanionBuilder =
    SavedGamesCompanion Function({
      Value<int> id,
      Value<String> puzzleId,
      Value<String> difficulty,
      Value<bool> isDaily,
      Value<String> givenCells,
      Value<String> solutionCells,
      Value<String> boardCells,
      Value<String> notes,
      Value<int> elapsedSeconds,
      Value<int> hintsRemaining,
      Value<int> mistakeCount,
      Value<bool> isNotesMode,
      Value<DateTime> savedAt,
    });

class $$SavedGamesTableFilterComposer
    extends Composer<_$AppDatabase, $SavedGamesTable> {
  $$SavedGamesTableFilterComposer({
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

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get givenCells => $composableBuilder(
    column: $table.givenCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get solutionCells => $composableBuilder(
    column: $table.solutionCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boardCells => $composableBuilder(
    column: $table.boardCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsRemaining => $composableBuilder(
    column: $table.hintsRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mistakeCount => $composableBuilder(
    column: $table.mistakeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNotesMode => $composableBuilder(
    column: $table.isNotesMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedGamesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedGamesTable> {
  $$SavedGamesTableOrderingComposer({
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

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get givenCells => $composableBuilder(
    column: $table.givenCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get solutionCells => $composableBuilder(
    column: $table.solutionCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boardCells => $composableBuilder(
    column: $table.boardCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsRemaining => $composableBuilder(
    column: $table.hintsRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mistakeCount => $composableBuilder(
    column: $table.mistakeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNotesMode => $composableBuilder(
    column: $table.isNotesMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedGamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedGamesTable> {
  $$SavedGamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDaily =>
      $composableBuilder(column: $table.isDaily, builder: (column) => column);

  GeneratedColumn<String> get givenCells => $composableBuilder(
    column: $table.givenCells,
    builder: (column) => column,
  );

  GeneratedColumn<String> get solutionCells => $composableBuilder(
    column: $table.solutionCells,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boardCells => $composableBuilder(
    column: $table.boardCells,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintsRemaining => $composableBuilder(
    column: $table.hintsRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mistakeCount => $composableBuilder(
    column: $table.mistakeCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNotesMode => $composableBuilder(
    column: $table.isNotesMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedGamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedGamesTable,
          SavedGame,
          $$SavedGamesTableFilterComposer,
          $$SavedGamesTableOrderingComposer,
          $$SavedGamesTableAnnotationComposer,
          $$SavedGamesTableCreateCompanionBuilder,
          $$SavedGamesTableUpdateCompanionBuilder,
          (
            SavedGame,
            BaseReferences<_$AppDatabase, $SavedGamesTable, SavedGame>,
          ),
          SavedGame,
          PrefetchHooks Function()
        > {
  $$SavedGamesTableTableManager(_$AppDatabase db, $SavedGamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedGamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedGamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedGamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<bool> isDaily = const Value.absent(),
                Value<String> givenCells = const Value.absent(),
                Value<String> solutionCells = const Value.absent(),
                Value<String> boardCells = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> elapsedSeconds = const Value.absent(),
                Value<int> hintsRemaining = const Value.absent(),
                Value<int> mistakeCount = const Value.absent(),
                Value<bool> isNotesMode = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => SavedGamesCompanion(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                isDaily: isDaily,
                givenCells: givenCells,
                solutionCells: solutionCells,
                boardCells: boardCells,
                notes: notes,
                elapsedSeconds: elapsedSeconds,
                hintsRemaining: hintsRemaining,
                mistakeCount: mistakeCount,
                isNotesMode: isNotesMode,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String puzzleId,
                required String difficulty,
                required bool isDaily,
                required String givenCells,
                required String solutionCells,
                required String boardCells,
                required String notes,
                required int elapsedSeconds,
                required int hintsRemaining,
                required int mistakeCount,
                required bool isNotesMode,
                required DateTime savedAt,
              }) => SavedGamesCompanion.insert(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                isDaily: isDaily,
                givenCells: givenCells,
                solutionCells: solutionCells,
                boardCells: boardCells,
                notes: notes,
                elapsedSeconds: elapsedSeconds,
                hintsRemaining: hintsRemaining,
                mistakeCount: mistakeCount,
                isNotesMode: isNotesMode,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedGamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedGamesTable,
      SavedGame,
      $$SavedGamesTableFilterComposer,
      $$SavedGamesTableOrderingComposer,
      $$SavedGamesTableAnnotationComposer,
      $$SavedGamesTableCreateCompanionBuilder,
      $$SavedGamesTableUpdateCompanionBuilder,
      (SavedGame, BaseReferences<_$AppDatabase, $SavedGamesTable, SavedGame>),
      SavedGame,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueItemsTableCreateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      required String type,
      required String payload,
      required DateTime queuedAt,
      Value<int> attempts,
    });
typedef $$SyncQueueItemsTableUpdateCompanionBuilder =
    SyncQueueItemsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> payload,
      Value<DateTime> queuedAt,
      Value<int> attempts,
    });

class $$SyncQueueItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueItemsTable> {
  $$SyncQueueItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$SyncQueueItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueItemsTable,
          SyncQueueItem,
          $$SyncQueueItemsTableFilterComposer,
          $$SyncQueueItemsTableOrderingComposer,
          $$SyncQueueItemsTableAnnotationComposer,
          $$SyncQueueItemsTableCreateCompanionBuilder,
          $$SyncQueueItemsTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueItemsTableTableManager(
    _$AppDatabase db,
    $SyncQueueItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => SyncQueueItemsCompanion(
                id: id,
                type: type,
                payload: payload,
                queuedAt: queuedAt,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String payload,
                required DateTime queuedAt,
                Value<int> attempts = const Value.absent(),
              }) => SyncQueueItemsCompanion.insert(
                id: id,
                type: type,
                payload: payload,
                queuedAt: queuedAt,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueItemsTable,
      SyncQueueItem,
      $$SyncQueueItemsTableFilterComposer,
      $$SyncQueueItemsTableOrderingComposer,
      $$SyncQueueItemsTableAnnotationComposer,
      $$SyncQueueItemsTableCreateCompanionBuilder,
      $$SyncQueueItemsTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$AppDatabase, $SyncQueueItemsTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PuzzleRecordsTableTableManager get puzzleRecords =>
      $$PuzzleRecordsTableTableManager(_db, _db.puzzleRecords);
  $$PlayerProfilesTableTableManager get playerProfiles =>
      $$PlayerProfilesTableTableManager(_db, _db.playerProfiles);
  $$GamePreferencesTableTableTableManager get gamePreferencesTable =>
      $$GamePreferencesTableTableTableManager(_db, _db.gamePreferencesTable);
  $$DailyPuzzleCacheTableTableManager get dailyPuzzleCache =>
      $$DailyPuzzleCacheTableTableManager(_db, _db.dailyPuzzleCache);
  $$SavedGamesTableTableManager get savedGames =>
      $$SavedGamesTableTableManager(_db, _db.savedGames);
  $$SyncQueueItemsTableTableManager get syncQueueItems =>
      $$SyncQueueItemsTableTableManager(_db, _db.syncQueueItems);
}
