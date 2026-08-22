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
  static const VerificationMeta _formulaVersionMeta = const VerificationMeta(
    'formulaVersion',
  );
  @override
  late final GeneratedColumn<int> formulaVersion = GeneratedColumn<int>(
    'formula_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _timingVersionMeta = const VerificationMeta(
    'timingVersion',
  );
  @override
  late final GeneratedColumn<int> timingVersion = GeneratedColumn<int>(
    'timing_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    formulaVersion,
    timingVersion,
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
    if (data.containsKey('formula_version')) {
      context.handle(
        _formulaVersionMeta,
        formulaVersion.isAcceptableOrUnknown(
          data['formula_version']!,
          _formulaVersionMeta,
        ),
      );
    }
    if (data.containsKey('timing_version')) {
      context.handle(
        _timingVersionMeta,
        timingVersion.isAcceptableOrUnknown(
          data['timing_version']!,
          _timingVersionMeta,
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
      formulaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}formula_version'],
      )!,
      timingVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timing_version'],
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
  final int formulaVersion;

  /// Which timing code produced [solveTimes].
  ///
  /// Version 1 measured inter-placement gaps against the wall clock, so a
  /// single overnight backgrounding wrote a 28800-second "thinking time".
  /// Stuck detection derives a personal p90 from these deltas, and one such
  /// value drags that threshold up permanently — the nudge would then never
  /// fire again for that player. Version 1 records are excluded from the
  /// pool rather than trusted.
  ///
  /// Deliberately separate from [formulaVersion], which is about the quality
  /// formula. Two unrelated things sharing one marker is how a later change
  /// to either quietly corrupts the other.
  final int timingVersion;
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
    required this.formulaVersion,
    required this.timingVersion,
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
    map['formula_version'] = Variable<int>(formulaVersion);
    map['timing_version'] = Variable<int>(timingVersion);
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
      formulaVersion: Value(formulaVersion),
      timingVersion: Value(timingVersion),
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
      formulaVersion: serializer.fromJson<int>(json['formulaVersion']),
      timingVersion: serializer.fromJson<int>(json['timingVersion']),
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
      'formulaVersion': serializer.toJson<int>(formulaVersion),
      'timingVersion': serializer.toJson<int>(timingVersion),
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
    int? formulaVersion,
    int? timingVersion,
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
    formulaVersion: formulaVersion ?? this.formulaVersion,
    timingVersion: timingVersion ?? this.timingVersion,
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
      formulaVersion: data.formulaVersion.present
          ? data.formulaVersion.value
          : this.formulaVersion,
      timingVersion: data.timingVersion.present
          ? data.timingVersion.value
          : this.timingVersion,
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
          ..write('qualityScore: $qualityScore, ')
          ..write('formulaVersion: $formulaVersion, ')
          ..write('timingVersion: $timingVersion')
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
    formulaVersion,
    timingVersion,
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
          other.qualityScore == this.qualityScore &&
          other.formulaVersion == this.formulaVersion &&
          other.timingVersion == this.timingVersion);
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
  final Value<int> formulaVersion;
  final Value<int> timingVersion;
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
    this.formulaVersion = const Value.absent(),
    this.timingVersion = const Value.absent(),
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
    this.formulaVersion = const Value.absent(),
    this.timingVersion = const Value.absent(),
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
    Expression<int>? formulaVersion,
    Expression<int>? timingVersion,
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
      if (formulaVersion != null) 'formula_version': formulaVersion,
      if (timingVersion != null) 'timing_version': timingVersion,
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
    Value<int>? formulaVersion,
    Value<int>? timingVersion,
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
      formulaVersion: formulaVersion ?? this.formulaVersion,
      timingVersion: timingVersion ?? this.timingVersion,
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
    if (formulaVersion.present) {
      map['formula_version'] = Variable<int>(formulaVersion.value);
    }
    if (timingVersion.present) {
      map['timing_version'] = Variable<int>(timingVersion.value);
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
          ..write('qualityScore: $qualityScore, ')
          ..write('formulaVersion: $formulaVersion, ')
          ..write('timingVersion: $timingVersion')
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
  static const VerificationMeta _lastFreezeUsedDateMeta =
      const VerificationMeta('lastFreezeUsedDate');
  @override
  late final GeneratedColumn<DateTime> lastFreezeUsedDate =
      GeneratedColumn<DateTime>(
        'last_freeze_used_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
    lastFreezeUsedDate,
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
    if (data.containsKey('last_freeze_used_date')) {
      context.handle(
        _lastFreezeUsedDateMeta,
        lastFreezeUsedDate.isAcceptableOrUnknown(
          data['last_freeze_used_date']!,
          _lastFreezeUsedDateMeta,
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
      lastFreezeUsedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_freeze_used_date'],
      ),
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
  final DateTime? lastFreezeUsedDate;
  const PlayerProfile({
    required this.id,
    required this.displayName,
    required this.currentStreak,
    required this.longestStreak,
    this.lastPlayedDate,
    required this.totalSolved,
    required this.totalStarted,
    required this.preferredDifficulty,
    this.lastFreezeUsedDate,
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
    if (!nullToAbsent || lastFreezeUsedDate != null) {
      map['last_freeze_used_date'] = Variable<DateTime>(lastFreezeUsedDate);
    }
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
      lastFreezeUsedDate: lastFreezeUsedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFreezeUsedDate),
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
      lastFreezeUsedDate: serializer.fromJson<DateTime?>(
        json['lastFreezeUsedDate'],
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
      'lastFreezeUsedDate': serializer.toJson<DateTime?>(lastFreezeUsedDate),
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
    Value<DateTime?> lastFreezeUsedDate = const Value.absent(),
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
    lastFreezeUsedDate: lastFreezeUsedDate.present
        ? lastFreezeUsedDate.value
        : this.lastFreezeUsedDate,
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
      lastFreezeUsedDate: data.lastFreezeUsedDate.present
          ? data.lastFreezeUsedDate.value
          : this.lastFreezeUsedDate,
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
          ..write('preferredDifficulty: $preferredDifficulty, ')
          ..write('lastFreezeUsedDate: $lastFreezeUsedDate')
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
    lastFreezeUsedDate,
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
          other.preferredDifficulty == this.preferredDifficulty &&
          other.lastFreezeUsedDate == this.lastFreezeUsedDate);
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
  final Value<DateTime?> lastFreezeUsedDate;
  const PlayerProfilesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastPlayedDate = const Value.absent(),
    this.totalSolved = const Value.absent(),
    this.totalStarted = const Value.absent(),
    this.preferredDifficulty = const Value.absent(),
    this.lastFreezeUsedDate = const Value.absent(),
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
    this.lastFreezeUsedDate = const Value.absent(),
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
    Expression<DateTime>? lastFreezeUsedDate,
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
      if (lastFreezeUsedDate != null)
        'last_freeze_used_date': lastFreezeUsedDate,
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
    Value<DateTime?>? lastFreezeUsedDate,
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
      lastFreezeUsedDate: lastFreezeUsedDate ?? this.lastFreezeUsedDate,
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
    if (lastFreezeUsedDate.present) {
      map['last_freeze_used_date'] = Variable<DateTime>(
        lastFreezeUsedDate.value,
      );
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
          ..write('preferredDifficulty: $preferredDifficulty, ')
          ..write('lastFreezeUsedDate: $lastFreezeUsedDate')
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
    defaultValue: const Constant('paper'),
  );
  static const VerificationMeta _digitFirstInputMeta = const VerificationMeta(
    'digitFirstInput',
  );
  @override
  late final GeneratedColumn<bool> digitFirstInput = GeneratedColumn<bool>(
    'digit_first_input',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("digit_first_input" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasSeenOnboardingMeta = const VerificationMeta(
    'hasSeenOnboarding',
  );
  @override
  late final GeneratedColumn<bool> hasSeenOnboarding = GeneratedColumn<bool>(
    'has_seen_onboarding',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_seen_onboarding" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hintsExplainMeta = const VerificationMeta(
    'hintsExplain',
  );
  @override
  late final GeneratedColumn<bool> hintsExplain = GeneratedColumn<bool>(
    'hints_explain',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hints_explain" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _flagMistakesInstantlyMeta =
      const VerificationMeta('flagMistakesInstantly');
  @override
  late final GeneratedColumn<bool> flagMistakesInstantly =
      GeneratedColumn<bool>(
        'flag_mistakes_instantly',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("flag_mistakes_instantly" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _nudgeWhenStuckMeta = const VerificationMeta(
    'nudgeWhenStuck',
  );
  @override
  late final GeneratedColumn<bool> nudgeWhenStuck = GeneratedColumn<bool>(
    'nudge_when_stuck',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("nudge_when_stuck" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showSolvePathMeta = const VerificationMeta(
    'showSolvePath',
  );
  @override
  late final GeneratedColumn<bool> showSolvePath = GeneratedColumn<bool>(
    'show_solve_path',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_solve_path" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReviewRequestAtMeta =
      const VerificationMeta('lastReviewRequestAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewRequestAt =
      GeneratedColumn<DateTime>(
        'last_review_request_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    autoRemoveNotes,
    highlightMatching,
    showTimer,
    mistakeLimit,
    theme,
    digitFirstInput,
    hasSeenOnboarding,
    hintsExplain,
    flagMistakesInstantly,
    nudgeWhenStuck,
    showSolvePath,
    lastReviewRequestAt,
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
    if (data.containsKey('digit_first_input')) {
      context.handle(
        _digitFirstInputMeta,
        digitFirstInput.isAcceptableOrUnknown(
          data['digit_first_input']!,
          _digitFirstInputMeta,
        ),
      );
    }
    if (data.containsKey('has_seen_onboarding')) {
      context.handle(
        _hasSeenOnboardingMeta,
        hasSeenOnboarding.isAcceptableOrUnknown(
          data['has_seen_onboarding']!,
          _hasSeenOnboardingMeta,
        ),
      );
    }
    if (data.containsKey('hints_explain')) {
      context.handle(
        _hintsExplainMeta,
        hintsExplain.isAcceptableOrUnknown(
          data['hints_explain']!,
          _hintsExplainMeta,
        ),
      );
    }
    if (data.containsKey('flag_mistakes_instantly')) {
      context.handle(
        _flagMistakesInstantlyMeta,
        flagMistakesInstantly.isAcceptableOrUnknown(
          data['flag_mistakes_instantly']!,
          _flagMistakesInstantlyMeta,
        ),
      );
    }
    if (data.containsKey('nudge_when_stuck')) {
      context.handle(
        _nudgeWhenStuckMeta,
        nudgeWhenStuck.isAcceptableOrUnknown(
          data['nudge_when_stuck']!,
          _nudgeWhenStuckMeta,
        ),
      );
    }
    if (data.containsKey('show_solve_path')) {
      context.handle(
        _showSolvePathMeta,
        showSolvePath.isAcceptableOrUnknown(
          data['show_solve_path']!,
          _showSolvePathMeta,
        ),
      );
    }
    if (data.containsKey('last_review_request_at')) {
      context.handle(
        _lastReviewRequestAtMeta,
        lastReviewRequestAt.isAcceptableOrUnknown(
          data['last_review_request_at']!,
          _lastReviewRequestAtMeta,
        ),
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
      digitFirstInput: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}digit_first_input'],
      )!,
      hasSeenOnboarding: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_seen_onboarding'],
      )!,
      hintsExplain: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hints_explain'],
      )!,
      flagMistakesInstantly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}flag_mistakes_instantly'],
      )!,
      nudgeWhenStuck: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}nudge_when_stuck'],
      )!,
      showSolvePath: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_solve_path'],
      )!,
      lastReviewRequestAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review_request_at'],
      ),
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
  final bool digitFirstInput;
  final bool hasSeenOnboarding;

  /// The three coaching switches. Defaults reproduce today's experience
  /// except that hints now explain, which is strictly more informative and
  /// cannot burn a scarce resource.
  final bool hintsExplain;
  final bool flagMistakesInstantly;
  final bool nudgeWhenStuck;

  /// Off by default, deliberately. A post-solve technique debrief reads as an
  /// interruption to most players; for the audience that wants it, it is the
  /// payoff. It must never appear unbidden.
  final bool showSolvePath;

  /// When the store rating prompt was last requested.
  ///
  /// Written whether or not the system actually showed anything, because it
  /// does not tell us — and treating "not shown" as "not asked" means asking
  /// on every single completion.
  final DateTime? lastReviewRequestAt;
  const GamePreferencesTableData({
    required this.id,
    required this.autoRemoveNotes,
    required this.highlightMatching,
    required this.showTimer,
    required this.mistakeLimit,
    required this.theme,
    required this.digitFirstInput,
    required this.hasSeenOnboarding,
    required this.hintsExplain,
    required this.flagMistakesInstantly,
    required this.nudgeWhenStuck,
    required this.showSolvePath,
    this.lastReviewRequestAt,
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
    map['digit_first_input'] = Variable<bool>(digitFirstInput);
    map['has_seen_onboarding'] = Variable<bool>(hasSeenOnboarding);
    map['hints_explain'] = Variable<bool>(hintsExplain);
    map['flag_mistakes_instantly'] = Variable<bool>(flagMistakesInstantly);
    map['nudge_when_stuck'] = Variable<bool>(nudgeWhenStuck);
    map['show_solve_path'] = Variable<bool>(showSolvePath);
    if (!nullToAbsent || lastReviewRequestAt != null) {
      map['last_review_request_at'] = Variable<DateTime>(lastReviewRequestAt);
    }
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
      digitFirstInput: Value(digitFirstInput),
      hasSeenOnboarding: Value(hasSeenOnboarding),
      hintsExplain: Value(hintsExplain),
      flagMistakesInstantly: Value(flagMistakesInstantly),
      nudgeWhenStuck: Value(nudgeWhenStuck),
      showSolvePath: Value(showSolvePath),
      lastReviewRequestAt: lastReviewRequestAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewRequestAt),
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
      digitFirstInput: serializer.fromJson<bool>(json['digitFirstInput']),
      hasSeenOnboarding: serializer.fromJson<bool>(json['hasSeenOnboarding']),
      hintsExplain: serializer.fromJson<bool>(json['hintsExplain']),
      flagMistakesInstantly: serializer.fromJson<bool>(
        json['flagMistakesInstantly'],
      ),
      nudgeWhenStuck: serializer.fromJson<bool>(json['nudgeWhenStuck']),
      showSolvePath: serializer.fromJson<bool>(json['showSolvePath']),
      lastReviewRequestAt: serializer.fromJson<DateTime?>(
        json['lastReviewRequestAt'],
      ),
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
      'digitFirstInput': serializer.toJson<bool>(digitFirstInput),
      'hasSeenOnboarding': serializer.toJson<bool>(hasSeenOnboarding),
      'hintsExplain': serializer.toJson<bool>(hintsExplain),
      'flagMistakesInstantly': serializer.toJson<bool>(flagMistakesInstantly),
      'nudgeWhenStuck': serializer.toJson<bool>(nudgeWhenStuck),
      'showSolvePath': serializer.toJson<bool>(showSolvePath),
      'lastReviewRequestAt': serializer.toJson<DateTime?>(lastReviewRequestAt),
    };
  }

  GamePreferencesTableData copyWith({
    int? id,
    bool? autoRemoveNotes,
    bool? highlightMatching,
    bool? showTimer,
    int? mistakeLimit,
    String? theme,
    bool? digitFirstInput,
    bool? hasSeenOnboarding,
    bool? hintsExplain,
    bool? flagMistakesInstantly,
    bool? nudgeWhenStuck,
    bool? showSolvePath,
    Value<DateTime?> lastReviewRequestAt = const Value.absent(),
  }) => GamePreferencesTableData(
    id: id ?? this.id,
    autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
    highlightMatching: highlightMatching ?? this.highlightMatching,
    showTimer: showTimer ?? this.showTimer,
    mistakeLimit: mistakeLimit ?? this.mistakeLimit,
    theme: theme ?? this.theme,
    digitFirstInput: digitFirstInput ?? this.digitFirstInput,
    hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    hintsExplain: hintsExplain ?? this.hintsExplain,
    flagMistakesInstantly: flagMistakesInstantly ?? this.flagMistakesInstantly,
    nudgeWhenStuck: nudgeWhenStuck ?? this.nudgeWhenStuck,
    showSolvePath: showSolvePath ?? this.showSolvePath,
    lastReviewRequestAt: lastReviewRequestAt.present
        ? lastReviewRequestAt.value
        : this.lastReviewRequestAt,
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
      digitFirstInput: data.digitFirstInput.present
          ? data.digitFirstInput.value
          : this.digitFirstInput,
      hasSeenOnboarding: data.hasSeenOnboarding.present
          ? data.hasSeenOnboarding.value
          : this.hasSeenOnboarding,
      hintsExplain: data.hintsExplain.present
          ? data.hintsExplain.value
          : this.hintsExplain,
      flagMistakesInstantly: data.flagMistakesInstantly.present
          ? data.flagMistakesInstantly.value
          : this.flagMistakesInstantly,
      nudgeWhenStuck: data.nudgeWhenStuck.present
          ? data.nudgeWhenStuck.value
          : this.nudgeWhenStuck,
      showSolvePath: data.showSolvePath.present
          ? data.showSolvePath.value
          : this.showSolvePath,
      lastReviewRequestAt: data.lastReviewRequestAt.present
          ? data.lastReviewRequestAt.value
          : this.lastReviewRequestAt,
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
          ..write('theme: $theme, ')
          ..write('digitFirstInput: $digitFirstInput, ')
          ..write('hasSeenOnboarding: $hasSeenOnboarding, ')
          ..write('hintsExplain: $hintsExplain, ')
          ..write('flagMistakesInstantly: $flagMistakesInstantly, ')
          ..write('nudgeWhenStuck: $nudgeWhenStuck, ')
          ..write('showSolvePath: $showSolvePath, ')
          ..write('lastReviewRequestAt: $lastReviewRequestAt')
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
    digitFirstInput,
    hasSeenOnboarding,
    hintsExplain,
    flagMistakesInstantly,
    nudgeWhenStuck,
    showSolvePath,
    lastReviewRequestAt,
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
          other.theme == this.theme &&
          other.digitFirstInput == this.digitFirstInput &&
          other.hasSeenOnboarding == this.hasSeenOnboarding &&
          other.hintsExplain == this.hintsExplain &&
          other.flagMistakesInstantly == this.flagMistakesInstantly &&
          other.nudgeWhenStuck == this.nudgeWhenStuck &&
          other.showSolvePath == this.showSolvePath &&
          other.lastReviewRequestAt == this.lastReviewRequestAt);
}

class GamePreferencesTableCompanion
    extends UpdateCompanion<GamePreferencesTableData> {
  final Value<int> id;
  final Value<bool> autoRemoveNotes;
  final Value<bool> highlightMatching;
  final Value<bool> showTimer;
  final Value<int> mistakeLimit;
  final Value<String> theme;
  final Value<bool> digitFirstInput;
  final Value<bool> hasSeenOnboarding;
  final Value<bool> hintsExplain;
  final Value<bool> flagMistakesInstantly;
  final Value<bool> nudgeWhenStuck;
  final Value<bool> showSolvePath;
  final Value<DateTime?> lastReviewRequestAt;
  const GamePreferencesTableCompanion({
    this.id = const Value.absent(),
    this.autoRemoveNotes = const Value.absent(),
    this.highlightMatching = const Value.absent(),
    this.showTimer = const Value.absent(),
    this.mistakeLimit = const Value.absent(),
    this.theme = const Value.absent(),
    this.digitFirstInput = const Value.absent(),
    this.hasSeenOnboarding = const Value.absent(),
    this.hintsExplain = const Value.absent(),
    this.flagMistakesInstantly = const Value.absent(),
    this.nudgeWhenStuck = const Value.absent(),
    this.showSolvePath = const Value.absent(),
    this.lastReviewRequestAt = const Value.absent(),
  });
  GamePreferencesTableCompanion.insert({
    this.id = const Value.absent(),
    this.autoRemoveNotes = const Value.absent(),
    this.highlightMatching = const Value.absent(),
    this.showTimer = const Value.absent(),
    this.mistakeLimit = const Value.absent(),
    this.theme = const Value.absent(),
    this.digitFirstInput = const Value.absent(),
    this.hasSeenOnboarding = const Value.absent(),
    this.hintsExplain = const Value.absent(),
    this.flagMistakesInstantly = const Value.absent(),
    this.nudgeWhenStuck = const Value.absent(),
    this.showSolvePath = const Value.absent(),
    this.lastReviewRequestAt = const Value.absent(),
  });
  static Insertable<GamePreferencesTableData> custom({
    Expression<int>? id,
    Expression<bool>? autoRemoveNotes,
    Expression<bool>? highlightMatching,
    Expression<bool>? showTimer,
    Expression<int>? mistakeLimit,
    Expression<String>? theme,
    Expression<bool>? digitFirstInput,
    Expression<bool>? hasSeenOnboarding,
    Expression<bool>? hintsExplain,
    Expression<bool>? flagMistakesInstantly,
    Expression<bool>? nudgeWhenStuck,
    Expression<bool>? showSolvePath,
    Expression<DateTime>? lastReviewRequestAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (autoRemoveNotes != null) 'auto_remove_notes': autoRemoveNotes,
      if (highlightMatching != null) 'highlight_matching': highlightMatching,
      if (showTimer != null) 'show_timer': showTimer,
      if (mistakeLimit != null) 'mistake_limit': mistakeLimit,
      if (theme != null) 'theme': theme,
      if (digitFirstInput != null) 'digit_first_input': digitFirstInput,
      if (hasSeenOnboarding != null) 'has_seen_onboarding': hasSeenOnboarding,
      if (hintsExplain != null) 'hints_explain': hintsExplain,
      if (flagMistakesInstantly != null)
        'flag_mistakes_instantly': flagMistakesInstantly,
      if (nudgeWhenStuck != null) 'nudge_when_stuck': nudgeWhenStuck,
      if (showSolvePath != null) 'show_solve_path': showSolvePath,
      if (lastReviewRequestAt != null)
        'last_review_request_at': lastReviewRequestAt,
    });
  }

  GamePreferencesTableCompanion copyWith({
    Value<int>? id,
    Value<bool>? autoRemoveNotes,
    Value<bool>? highlightMatching,
    Value<bool>? showTimer,
    Value<int>? mistakeLimit,
    Value<String>? theme,
    Value<bool>? digitFirstInput,
    Value<bool>? hasSeenOnboarding,
    Value<bool>? hintsExplain,
    Value<bool>? flagMistakesInstantly,
    Value<bool>? nudgeWhenStuck,
    Value<bool>? showSolvePath,
    Value<DateTime?>? lastReviewRequestAt,
  }) {
    return GamePreferencesTableCompanion(
      id: id ?? this.id,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      highlightMatching: highlightMatching ?? this.highlightMatching,
      showTimer: showTimer ?? this.showTimer,
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
      theme: theme ?? this.theme,
      digitFirstInput: digitFirstInput ?? this.digitFirstInput,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      hintsExplain: hintsExplain ?? this.hintsExplain,
      flagMistakesInstantly:
          flagMistakesInstantly ?? this.flagMistakesInstantly,
      nudgeWhenStuck: nudgeWhenStuck ?? this.nudgeWhenStuck,
      showSolvePath: showSolvePath ?? this.showSolvePath,
      lastReviewRequestAt: lastReviewRequestAt ?? this.lastReviewRequestAt,
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
    if (digitFirstInput.present) {
      map['digit_first_input'] = Variable<bool>(digitFirstInput.value);
    }
    if (hasSeenOnboarding.present) {
      map['has_seen_onboarding'] = Variable<bool>(hasSeenOnboarding.value);
    }
    if (hintsExplain.present) {
      map['hints_explain'] = Variable<bool>(hintsExplain.value);
    }
    if (flagMistakesInstantly.present) {
      map['flag_mistakes_instantly'] = Variable<bool>(
        flagMistakesInstantly.value,
      );
    }
    if (nudgeWhenStuck.present) {
      map['nudge_when_stuck'] = Variable<bool>(nudgeWhenStuck.value);
    }
    if (showSolvePath.present) {
      map['show_solve_path'] = Variable<bool>(showSolvePath.value);
    }
    if (lastReviewRequestAt.present) {
      map['last_review_request_at'] = Variable<DateTime>(
        lastReviewRequestAt.value,
      );
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
          ..write('theme: $theme, ')
          ..write('digitFirstInput: $digitFirstInput, ')
          ..write('hasSeenOnboarding: $hasSeenOnboarding, ')
          ..write('hintsExplain: $hintsExplain, ')
          ..write('flagMistakesInstantly: $flagMistakesInstantly, ')
          ..write('nudgeWhenStuck: $nudgeWhenStuck, ')
          ..write('showSolvePath: $showSolvePath, ')
          ..write('lastReviewRequestAt: $lastReviewRequestAt')
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
  static const VerificationMeta _hintDepthTotalMeta = const VerificationMeta(
    'hintDepthTotal',
  );
  @override
  late final GeneratedColumn<int> hintDepthTotal = GeneratedColumn<int>(
    'hint_depth_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _historyMeta = const VerificationMeta(
    'history',
  );
  @override
  late final GeneratedColumn<String> history = GeneratedColumn<String>(
    'history',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _placementDeltasMeta = const VerificationMeta(
    'placementDeltas',
  );
  @override
  late final GeneratedColumn<String> placementDeltas = GeneratedColumn<String>(
    'placement_deltas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _undoCountMeta = const VerificationMeta(
    'undoCount',
  );
  @override
  late final GeneratedColumn<int> undoCount = GeneratedColumn<int>(
    'undo_count',
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
  static const VerificationMeta _techniquesMeta = const VerificationMeta(
    'techniques',
  );
  @override
  late final GeneratedColumn<String> techniques = GeneratedColumn<String>(
    'techniques',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    hintsUsed,
    hintDepthTotal,
    mistakeCount,
    isNotesMode,
    savedAt,
    history,
    placementDeltas,
    mistakeCells,
    undoCount,
    usedNotes,
    longestPauseSeconds,
    techniques,
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
    if (data.containsKey('hints_used')) {
      context.handle(
        _hintsUsedMeta,
        hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta),
      );
    }
    if (data.containsKey('hint_depth_total')) {
      context.handle(
        _hintDepthTotalMeta,
        hintDepthTotal.isAcceptableOrUnknown(
          data['hint_depth_total']!,
          _hintDepthTotalMeta,
        ),
      );
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
    if (data.containsKey('history')) {
      context.handle(
        _historyMeta,
        history.isAcceptableOrUnknown(data['history']!, _historyMeta),
      );
    }
    if (data.containsKey('placement_deltas')) {
      context.handle(
        _placementDeltasMeta,
        placementDeltas.isAcceptableOrUnknown(
          data['placement_deltas']!,
          _placementDeltasMeta,
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
    if (data.containsKey('undo_count')) {
      context.handle(
        _undoCountMeta,
        undoCount.isAcceptableOrUnknown(data['undo_count']!, _undoCountMeta),
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
    if (data.containsKey('techniques')) {
      context.handle(
        _techniquesMeta,
        techniques.isAcceptableOrUnknown(data['techniques']!, _techniquesMeta),
      );
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
      hintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_used'],
      )!,
      hintDepthTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_depth_total'],
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
      history: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history'],
      )!,
      placementDeltas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}placement_deltas'],
      )!,
      mistakeCells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mistake_cells'],
      )!,
      undoCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}undo_count'],
      )!,
      usedNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used_notes'],
      )!,
      longestPauseSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_pause_seconds'],
      )!,
      techniques: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}techniques'],
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

  /// Dead since hints stopped being a scarce resource. Kept because the
  /// column is NOT NULL with no default, and dropping it would mean a table
  /// rewrite for nothing — every write puts a constant 0 here.
  final int hintsRemaining;

  /// How many hints were asked for, and how deep they were pushed. Without
  /// these a resumed puzzle would score as though it had been solved unaided.
  final int hintsUsed;
  final int hintDepthTotal;
  final int mistakeCount;
  final bool isNotesMode;
  final DateTime savedAt;

  /// Versioned JSON envelope from GameHistoryCodec.
  final String history;

  /// Comma-separated inter-placement deltas, in elapsed seconds.
  final String placementDeltas;

  /// Comma-separated cell indices (0-80) where a mistake was made.
  final String mistakeCells;
  final int undoCount;
  final bool usedNotes;
  final int longestPauseSeconds;

  /// Comma-separated Technique names. Lost on resume before v10, so a
  /// resumed puzzle showed an empty puzzleDna on the complete screen.
  ///
  /// Names written by an older build no longer resolve and are dropped on
  /// read, which costs the complete screen one line rather than failing the
  /// whole restore.
  final String techniques;
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
    required this.hintsUsed,
    required this.hintDepthTotal,
    required this.mistakeCount,
    required this.isNotesMode,
    required this.savedAt,
    required this.history,
    required this.placementDeltas,
    required this.mistakeCells,
    required this.undoCount,
    required this.usedNotes,
    required this.longestPauseSeconds,
    required this.techniques,
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
    map['hints_used'] = Variable<int>(hintsUsed);
    map['hint_depth_total'] = Variable<int>(hintDepthTotal);
    map['mistake_count'] = Variable<int>(mistakeCount);
    map['is_notes_mode'] = Variable<bool>(isNotesMode);
    map['saved_at'] = Variable<DateTime>(savedAt);
    map['history'] = Variable<String>(history);
    map['placement_deltas'] = Variable<String>(placementDeltas);
    map['mistake_cells'] = Variable<String>(mistakeCells);
    map['undo_count'] = Variable<int>(undoCount);
    map['used_notes'] = Variable<bool>(usedNotes);
    map['longest_pause_seconds'] = Variable<int>(longestPauseSeconds);
    map['techniques'] = Variable<String>(techniques);
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
      hintsUsed: Value(hintsUsed),
      hintDepthTotal: Value(hintDepthTotal),
      mistakeCount: Value(mistakeCount),
      isNotesMode: Value(isNotesMode),
      savedAt: Value(savedAt),
      history: Value(history),
      placementDeltas: Value(placementDeltas),
      mistakeCells: Value(mistakeCells),
      undoCount: Value(undoCount),
      usedNotes: Value(usedNotes),
      longestPauseSeconds: Value(longestPauseSeconds),
      techniques: Value(techniques),
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
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      hintDepthTotal: serializer.fromJson<int>(json['hintDepthTotal']),
      mistakeCount: serializer.fromJson<int>(json['mistakeCount']),
      isNotesMode: serializer.fromJson<bool>(json['isNotesMode']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      history: serializer.fromJson<String>(json['history']),
      placementDeltas: serializer.fromJson<String>(json['placementDeltas']),
      mistakeCells: serializer.fromJson<String>(json['mistakeCells']),
      undoCount: serializer.fromJson<int>(json['undoCount']),
      usedNotes: serializer.fromJson<bool>(json['usedNotes']),
      longestPauseSeconds: serializer.fromJson<int>(
        json['longestPauseSeconds'],
      ),
      techniques: serializer.fromJson<String>(json['techniques']),
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
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'hintDepthTotal': serializer.toJson<int>(hintDepthTotal),
      'mistakeCount': serializer.toJson<int>(mistakeCount),
      'isNotesMode': serializer.toJson<bool>(isNotesMode),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'history': serializer.toJson<String>(history),
      'placementDeltas': serializer.toJson<String>(placementDeltas),
      'mistakeCells': serializer.toJson<String>(mistakeCells),
      'undoCount': serializer.toJson<int>(undoCount),
      'usedNotes': serializer.toJson<bool>(usedNotes),
      'longestPauseSeconds': serializer.toJson<int>(longestPauseSeconds),
      'techniques': serializer.toJson<String>(techniques),
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
    int? hintsUsed,
    int? hintDepthTotal,
    int? mistakeCount,
    bool? isNotesMode,
    DateTime? savedAt,
    String? history,
    String? placementDeltas,
    String? mistakeCells,
    int? undoCount,
    bool? usedNotes,
    int? longestPauseSeconds,
    String? techniques,
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
    hintsUsed: hintsUsed ?? this.hintsUsed,
    hintDepthTotal: hintDepthTotal ?? this.hintDepthTotal,
    mistakeCount: mistakeCount ?? this.mistakeCount,
    isNotesMode: isNotesMode ?? this.isNotesMode,
    savedAt: savedAt ?? this.savedAt,
    history: history ?? this.history,
    placementDeltas: placementDeltas ?? this.placementDeltas,
    mistakeCells: mistakeCells ?? this.mistakeCells,
    undoCount: undoCount ?? this.undoCount,
    usedNotes: usedNotes ?? this.usedNotes,
    longestPauseSeconds: longestPauseSeconds ?? this.longestPauseSeconds,
    techniques: techniques ?? this.techniques,
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
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      hintDepthTotal: data.hintDepthTotal.present
          ? data.hintDepthTotal.value
          : this.hintDepthTotal,
      mistakeCount: data.mistakeCount.present
          ? data.mistakeCount.value
          : this.mistakeCount,
      isNotesMode: data.isNotesMode.present
          ? data.isNotesMode.value
          : this.isNotesMode,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      history: data.history.present ? data.history.value : this.history,
      placementDeltas: data.placementDeltas.present
          ? data.placementDeltas.value
          : this.placementDeltas,
      mistakeCells: data.mistakeCells.present
          ? data.mistakeCells.value
          : this.mistakeCells,
      undoCount: data.undoCount.present ? data.undoCount.value : this.undoCount,
      usedNotes: data.usedNotes.present ? data.usedNotes.value : this.usedNotes,
      longestPauseSeconds: data.longestPauseSeconds.present
          ? data.longestPauseSeconds.value
          : this.longestPauseSeconds,
      techniques: data.techniques.present
          ? data.techniques.value
          : this.techniques,
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
          ..write('hintsUsed: $hintsUsed, ')
          ..write('hintDepthTotal: $hintDepthTotal, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('isNotesMode: $isNotesMode, ')
          ..write('savedAt: $savedAt, ')
          ..write('history: $history, ')
          ..write('placementDeltas: $placementDeltas, ')
          ..write('mistakeCells: $mistakeCells, ')
          ..write('undoCount: $undoCount, ')
          ..write('usedNotes: $usedNotes, ')
          ..write('longestPauseSeconds: $longestPauseSeconds, ')
          ..write('techniques: $techniques')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    hintsUsed,
    hintDepthTotal,
    mistakeCount,
    isNotesMode,
    savedAt,
    history,
    placementDeltas,
    mistakeCells,
    undoCount,
    usedNotes,
    longestPauseSeconds,
    techniques,
  ]);
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
          other.hintsUsed == this.hintsUsed &&
          other.hintDepthTotal == this.hintDepthTotal &&
          other.mistakeCount == this.mistakeCount &&
          other.isNotesMode == this.isNotesMode &&
          other.savedAt == this.savedAt &&
          other.history == this.history &&
          other.placementDeltas == this.placementDeltas &&
          other.mistakeCells == this.mistakeCells &&
          other.undoCount == this.undoCount &&
          other.usedNotes == this.usedNotes &&
          other.longestPauseSeconds == this.longestPauseSeconds &&
          other.techniques == this.techniques);
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
  final Value<int> hintsUsed;
  final Value<int> hintDepthTotal;
  final Value<int> mistakeCount;
  final Value<bool> isNotesMode;
  final Value<DateTime> savedAt;
  final Value<String> history;
  final Value<String> placementDeltas;
  final Value<String> mistakeCells;
  final Value<int> undoCount;
  final Value<bool> usedNotes;
  final Value<int> longestPauseSeconds;
  final Value<String> techniques;
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
    this.hintsUsed = const Value.absent(),
    this.hintDepthTotal = const Value.absent(),
    this.mistakeCount = const Value.absent(),
    this.isNotesMode = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.history = const Value.absent(),
    this.placementDeltas = const Value.absent(),
    this.mistakeCells = const Value.absent(),
    this.undoCount = const Value.absent(),
    this.usedNotes = const Value.absent(),
    this.longestPauseSeconds = const Value.absent(),
    this.techniques = const Value.absent(),
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
    this.hintsUsed = const Value.absent(),
    this.hintDepthTotal = const Value.absent(),
    required int mistakeCount,
    required bool isNotesMode,
    required DateTime savedAt,
    this.history = const Value.absent(),
    this.placementDeltas = const Value.absent(),
    this.mistakeCells = const Value.absent(),
    this.undoCount = const Value.absent(),
    this.usedNotes = const Value.absent(),
    this.longestPauseSeconds = const Value.absent(),
    this.techniques = const Value.absent(),
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
    Expression<int>? hintsUsed,
    Expression<int>? hintDepthTotal,
    Expression<int>? mistakeCount,
    Expression<bool>? isNotesMode,
    Expression<DateTime>? savedAt,
    Expression<String>? history,
    Expression<String>? placementDeltas,
    Expression<String>? mistakeCells,
    Expression<int>? undoCount,
    Expression<bool>? usedNotes,
    Expression<int>? longestPauseSeconds,
    Expression<String>? techniques,
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
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (hintDepthTotal != null) 'hint_depth_total': hintDepthTotal,
      if (mistakeCount != null) 'mistake_count': mistakeCount,
      if (isNotesMode != null) 'is_notes_mode': isNotesMode,
      if (savedAt != null) 'saved_at': savedAt,
      if (history != null) 'history': history,
      if (placementDeltas != null) 'placement_deltas': placementDeltas,
      if (mistakeCells != null) 'mistake_cells': mistakeCells,
      if (undoCount != null) 'undo_count': undoCount,
      if (usedNotes != null) 'used_notes': usedNotes,
      if (longestPauseSeconds != null)
        'longest_pause_seconds': longestPauseSeconds,
      if (techniques != null) 'techniques': techniques,
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
    Value<int>? hintsUsed,
    Value<int>? hintDepthTotal,
    Value<int>? mistakeCount,
    Value<bool>? isNotesMode,
    Value<DateTime>? savedAt,
    Value<String>? history,
    Value<String>? placementDeltas,
    Value<String>? mistakeCells,
    Value<int>? undoCount,
    Value<bool>? usedNotes,
    Value<int>? longestPauseSeconds,
    Value<String>? techniques,
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
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintDepthTotal: hintDepthTotal ?? this.hintDepthTotal,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      isNotesMode: isNotesMode ?? this.isNotesMode,
      savedAt: savedAt ?? this.savedAt,
      history: history ?? this.history,
      placementDeltas: placementDeltas ?? this.placementDeltas,
      mistakeCells: mistakeCells ?? this.mistakeCells,
      undoCount: undoCount ?? this.undoCount,
      usedNotes: usedNotes ?? this.usedNotes,
      longestPauseSeconds: longestPauseSeconds ?? this.longestPauseSeconds,
      techniques: techniques ?? this.techniques,
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
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (hintDepthTotal.present) {
      map['hint_depth_total'] = Variable<int>(hintDepthTotal.value);
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
    if (history.present) {
      map['history'] = Variable<String>(history.value);
    }
    if (placementDeltas.present) {
      map['placement_deltas'] = Variable<String>(placementDeltas.value);
    }
    if (mistakeCells.present) {
      map['mistake_cells'] = Variable<String>(mistakeCells.value);
    }
    if (undoCount.present) {
      map['undo_count'] = Variable<int>(undoCount.value);
    }
    if (usedNotes.present) {
      map['used_notes'] = Variable<bool>(usedNotes.value);
    }
    if (longestPauseSeconds.present) {
      map['longest_pause_seconds'] = Variable<int>(longestPauseSeconds.value);
    }
    if (techniques.present) {
      map['techniques'] = Variable<String>(techniques.value);
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
          ..write('hintsUsed: $hintsUsed, ')
          ..write('hintDepthTotal: $hintDepthTotal, ')
          ..write('mistakeCount: $mistakeCount, ')
          ..write('isNotesMode: $isNotesMode, ')
          ..write('savedAt: $savedAt, ')
          ..write('history: $history, ')
          ..write('placementDeltas: $placementDeltas, ')
          ..write('mistakeCells: $mistakeCells, ')
          ..write('undoCount: $undoCount, ')
          ..write('usedNotes: $usedNotes, ')
          ..write('longestPauseSeconds: $longestPauseSeconds, ')
          ..write('techniques: $techniques')
          ..write(')'))
        .toString();
  }
}

class $TechniqueMasteryTableTable extends TechniqueMasteryTable
    with TableInfo<$TechniqueMasteryTableTable, TechniqueMasteryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TechniqueMasteryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _techniqueMeta = const VerificationMeta(
    'technique',
  );
  @override
  late final GeneratedColumn<String> technique = GeneratedColumn<String>(
    'technique',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drillsAttemptedMeta = const VerificationMeta(
    'drillsAttempted',
  );
  @override
  late final GeneratedColumn<int> drillsAttempted = GeneratedColumn<int>(
    'drills_attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _drillsUnaidedMeta = const VerificationMeta(
    'drillsUnaided',
  );
  @override
  late final GeneratedColumn<int> drillsUnaided = GeneratedColumn<int>(
    'drills_unaided',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _encounteredMeta = const VerificationMeta(
    'encountered',
  );
  @override
  late final GeneratedColumn<int> encountered = GeneratedColumn<int>(
    'encountered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _assistedMeta = const VerificationMeta(
    'assisted',
  );
  @override
  late final GeneratedColumn<int> assisted = GeneratedColumn<int>(
    'assisted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestSecondsMeta = const VerificationMeta(
    'bestSeconds',
  );
  @override
  late final GeneratedColumn<int> bestSeconds = GeneratedColumn<int>(
    'best_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPractisedAtMeta = const VerificationMeta(
    'lastPractisedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPractisedAt =
      GeneratedColumn<DateTime>(
        'last_practised_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    technique,
    drillsAttempted,
    drillsUnaided,
    encountered,
    assisted,
    bestSeconds,
    lastPractisedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'technique_mastery_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TechniqueMasteryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('technique')) {
      context.handle(
        _techniqueMeta,
        technique.isAcceptableOrUnknown(data['technique']!, _techniqueMeta),
      );
    } else if (isInserting) {
      context.missing(_techniqueMeta);
    }
    if (data.containsKey('drills_attempted')) {
      context.handle(
        _drillsAttemptedMeta,
        drillsAttempted.isAcceptableOrUnknown(
          data['drills_attempted']!,
          _drillsAttemptedMeta,
        ),
      );
    }
    if (data.containsKey('drills_unaided')) {
      context.handle(
        _drillsUnaidedMeta,
        drillsUnaided.isAcceptableOrUnknown(
          data['drills_unaided']!,
          _drillsUnaidedMeta,
        ),
      );
    }
    if (data.containsKey('encountered')) {
      context.handle(
        _encounteredMeta,
        encountered.isAcceptableOrUnknown(
          data['encountered']!,
          _encounteredMeta,
        ),
      );
    }
    if (data.containsKey('assisted')) {
      context.handle(
        _assistedMeta,
        assisted.isAcceptableOrUnknown(data['assisted']!, _assistedMeta),
      );
    }
    if (data.containsKey('best_seconds')) {
      context.handle(
        _bestSecondsMeta,
        bestSeconds.isAcceptableOrUnknown(
          data['best_seconds']!,
          _bestSecondsMeta,
        ),
      );
    }
    if (data.containsKey('last_practised_at')) {
      context.handle(
        _lastPractisedAtMeta,
        lastPractisedAt.isAcceptableOrUnknown(
          data['last_practised_at']!,
          _lastPractisedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {technique};
  @override
  TechniqueMasteryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TechniqueMasteryTableData(
      technique: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}technique'],
      )!,
      drillsAttempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drills_attempted'],
      )!,
      drillsUnaided: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drills_unaided'],
      )!,
      encountered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}encountered'],
      )!,
      assisted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assisted'],
      )!,
      bestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_seconds'],
      ),
      lastPractisedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_practised_at'],
      ),
    );
  }

  @override
  $TechniqueMasteryTableTable createAlias(String alias) {
    return $TechniqueMasteryTableTable(attachedDatabase, alias);
  }
}

class TechniqueMasteryTableData extends DataClass
    implements Insertable<TechniqueMasteryTableData> {
  /// The Technique enum name. Stable, and the same string the analytics and
  /// the saved-game techniques column already use.
  final String technique;
  final int drillsAttempted;
  final int drillsUnaided;

  /// Times it appeared in a puzzle the player completed.
  final int encountered;

  /// Times a hint explained it.
  final int assisted;
  final int? bestSeconds;
  final DateTime? lastPractisedAt;
  const TechniqueMasteryTableData({
    required this.technique,
    required this.drillsAttempted,
    required this.drillsUnaided,
    required this.encountered,
    required this.assisted,
    this.bestSeconds,
    this.lastPractisedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['technique'] = Variable<String>(technique);
    map['drills_attempted'] = Variable<int>(drillsAttempted);
    map['drills_unaided'] = Variable<int>(drillsUnaided);
    map['encountered'] = Variable<int>(encountered);
    map['assisted'] = Variable<int>(assisted);
    if (!nullToAbsent || bestSeconds != null) {
      map['best_seconds'] = Variable<int>(bestSeconds);
    }
    if (!nullToAbsent || lastPractisedAt != null) {
      map['last_practised_at'] = Variable<DateTime>(lastPractisedAt);
    }
    return map;
  }

  TechniqueMasteryTableCompanion toCompanion(bool nullToAbsent) {
    return TechniqueMasteryTableCompanion(
      technique: Value(technique),
      drillsAttempted: Value(drillsAttempted),
      drillsUnaided: Value(drillsUnaided),
      encountered: Value(encountered),
      assisted: Value(assisted),
      bestSeconds: bestSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(bestSeconds),
      lastPractisedAt: lastPractisedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPractisedAt),
    );
  }

  factory TechniqueMasteryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TechniqueMasteryTableData(
      technique: serializer.fromJson<String>(json['technique']),
      drillsAttempted: serializer.fromJson<int>(json['drillsAttempted']),
      drillsUnaided: serializer.fromJson<int>(json['drillsUnaided']),
      encountered: serializer.fromJson<int>(json['encountered']),
      assisted: serializer.fromJson<int>(json['assisted']),
      bestSeconds: serializer.fromJson<int?>(json['bestSeconds']),
      lastPractisedAt: serializer.fromJson<DateTime?>(json['lastPractisedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'technique': serializer.toJson<String>(technique),
      'drillsAttempted': serializer.toJson<int>(drillsAttempted),
      'drillsUnaided': serializer.toJson<int>(drillsUnaided),
      'encountered': serializer.toJson<int>(encountered),
      'assisted': serializer.toJson<int>(assisted),
      'bestSeconds': serializer.toJson<int?>(bestSeconds),
      'lastPractisedAt': serializer.toJson<DateTime?>(lastPractisedAt),
    };
  }

  TechniqueMasteryTableData copyWith({
    String? technique,
    int? drillsAttempted,
    int? drillsUnaided,
    int? encountered,
    int? assisted,
    Value<int?> bestSeconds = const Value.absent(),
    Value<DateTime?> lastPractisedAt = const Value.absent(),
  }) => TechniqueMasteryTableData(
    technique: technique ?? this.technique,
    drillsAttempted: drillsAttempted ?? this.drillsAttempted,
    drillsUnaided: drillsUnaided ?? this.drillsUnaided,
    encountered: encountered ?? this.encountered,
    assisted: assisted ?? this.assisted,
    bestSeconds: bestSeconds.present ? bestSeconds.value : this.bestSeconds,
    lastPractisedAt: lastPractisedAt.present
        ? lastPractisedAt.value
        : this.lastPractisedAt,
  );
  TechniqueMasteryTableData copyWithCompanion(
    TechniqueMasteryTableCompanion data,
  ) {
    return TechniqueMasteryTableData(
      technique: data.technique.present ? data.technique.value : this.technique,
      drillsAttempted: data.drillsAttempted.present
          ? data.drillsAttempted.value
          : this.drillsAttempted,
      drillsUnaided: data.drillsUnaided.present
          ? data.drillsUnaided.value
          : this.drillsUnaided,
      encountered: data.encountered.present
          ? data.encountered.value
          : this.encountered,
      assisted: data.assisted.present ? data.assisted.value : this.assisted,
      bestSeconds: data.bestSeconds.present
          ? data.bestSeconds.value
          : this.bestSeconds,
      lastPractisedAt: data.lastPractisedAt.present
          ? data.lastPractisedAt.value
          : this.lastPractisedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TechniqueMasteryTableData(')
          ..write('technique: $technique, ')
          ..write('drillsAttempted: $drillsAttempted, ')
          ..write('drillsUnaided: $drillsUnaided, ')
          ..write('encountered: $encountered, ')
          ..write('assisted: $assisted, ')
          ..write('bestSeconds: $bestSeconds, ')
          ..write('lastPractisedAt: $lastPractisedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    technique,
    drillsAttempted,
    drillsUnaided,
    encountered,
    assisted,
    bestSeconds,
    lastPractisedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TechniqueMasteryTableData &&
          other.technique == this.technique &&
          other.drillsAttempted == this.drillsAttempted &&
          other.drillsUnaided == this.drillsUnaided &&
          other.encountered == this.encountered &&
          other.assisted == this.assisted &&
          other.bestSeconds == this.bestSeconds &&
          other.lastPractisedAt == this.lastPractisedAt);
}

class TechniqueMasteryTableCompanion
    extends UpdateCompanion<TechniqueMasteryTableData> {
  final Value<String> technique;
  final Value<int> drillsAttempted;
  final Value<int> drillsUnaided;
  final Value<int> encountered;
  final Value<int> assisted;
  final Value<int?> bestSeconds;
  final Value<DateTime?> lastPractisedAt;
  final Value<int> rowid;
  const TechniqueMasteryTableCompanion({
    this.technique = const Value.absent(),
    this.drillsAttempted = const Value.absent(),
    this.drillsUnaided = const Value.absent(),
    this.encountered = const Value.absent(),
    this.assisted = const Value.absent(),
    this.bestSeconds = const Value.absent(),
    this.lastPractisedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TechniqueMasteryTableCompanion.insert({
    required String technique,
    this.drillsAttempted = const Value.absent(),
    this.drillsUnaided = const Value.absent(),
    this.encountered = const Value.absent(),
    this.assisted = const Value.absent(),
    this.bestSeconds = const Value.absent(),
    this.lastPractisedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : technique = Value(technique);
  static Insertable<TechniqueMasteryTableData> custom({
    Expression<String>? technique,
    Expression<int>? drillsAttempted,
    Expression<int>? drillsUnaided,
    Expression<int>? encountered,
    Expression<int>? assisted,
    Expression<int>? bestSeconds,
    Expression<DateTime>? lastPractisedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (technique != null) 'technique': technique,
      if (drillsAttempted != null) 'drills_attempted': drillsAttempted,
      if (drillsUnaided != null) 'drills_unaided': drillsUnaided,
      if (encountered != null) 'encountered': encountered,
      if (assisted != null) 'assisted': assisted,
      if (bestSeconds != null) 'best_seconds': bestSeconds,
      if (lastPractisedAt != null) 'last_practised_at': lastPractisedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TechniqueMasteryTableCompanion copyWith({
    Value<String>? technique,
    Value<int>? drillsAttempted,
    Value<int>? drillsUnaided,
    Value<int>? encountered,
    Value<int>? assisted,
    Value<int?>? bestSeconds,
    Value<DateTime?>? lastPractisedAt,
    Value<int>? rowid,
  }) {
    return TechniqueMasteryTableCompanion(
      technique: technique ?? this.technique,
      drillsAttempted: drillsAttempted ?? this.drillsAttempted,
      drillsUnaided: drillsUnaided ?? this.drillsUnaided,
      encountered: encountered ?? this.encountered,
      assisted: assisted ?? this.assisted,
      bestSeconds: bestSeconds ?? this.bestSeconds,
      lastPractisedAt: lastPractisedAt ?? this.lastPractisedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (technique.present) {
      map['technique'] = Variable<String>(technique.value);
    }
    if (drillsAttempted.present) {
      map['drills_attempted'] = Variable<int>(drillsAttempted.value);
    }
    if (drillsUnaided.present) {
      map['drills_unaided'] = Variable<int>(drillsUnaided.value);
    }
    if (encountered.present) {
      map['encountered'] = Variable<int>(encountered.value);
    }
    if (assisted.present) {
      map['assisted'] = Variable<int>(assisted.value);
    }
    if (bestSeconds.present) {
      map['best_seconds'] = Variable<int>(bestSeconds.value);
    }
    if (lastPractisedAt.present) {
      map['last_practised_at'] = Variable<DateTime>(lastPractisedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TechniqueMasteryTableCompanion(')
          ..write('technique: $technique, ')
          ..write('drillsAttempted: $drillsAttempted, ')
          ..write('drillsUnaided: $drillsUnaided, ')
          ..write('encountered: $encountered, ')
          ..write('assisted: $assisted, ')
          ..write('bestSeconds: $bestSeconds, ')
          ..write('lastPractisedAt: $lastPractisedAt, ')
          ..write('rowid: $rowid')
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
  late final $SavedGamesTable savedGames = $SavedGamesTable(this);
  late final $TechniqueMasteryTableTable techniqueMasteryTable =
      $TechniqueMasteryTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    puzzleRecords,
    playerProfiles,
    gamePreferencesTable,
    savedGames,
    techniqueMasteryTable,
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
      Value<int> formulaVersion,
      Value<int> timingVersion,
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
      Value<int> formulaVersion,
      Value<int> timingVersion,
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

  ColumnFilters<int> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timingVersion => $composableBuilder(
    column: $table.timingVersion,
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

  ColumnOrderings<int> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timingVersion => $composableBuilder(
    column: $table.timingVersion,
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

  GeneratedColumn<int> get formulaVersion => $composableBuilder(
    column: $table.formulaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timingVersion => $composableBuilder(
    column: $table.timingVersion,
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
                Value<int> formulaVersion = const Value.absent(),
                Value<int> timingVersion = const Value.absent(),
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
                formulaVersion: formulaVersion,
                timingVersion: timingVersion,
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
                Value<int> formulaVersion = const Value.absent(),
                Value<int> timingVersion = const Value.absent(),
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
                formulaVersion: formulaVersion,
                timingVersion: timingVersion,
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
      Value<DateTime?> lastFreezeUsedDate,
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
      Value<DateTime?> lastFreezeUsedDate,
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

  ColumnFilters<DateTime> get lastFreezeUsedDate => $composableBuilder(
    column: $table.lastFreezeUsedDate,
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

  ColumnOrderings<DateTime> get lastFreezeUsedDate => $composableBuilder(
    column: $table.lastFreezeUsedDate,
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

  GeneratedColumn<DateTime> get lastFreezeUsedDate => $composableBuilder(
    column: $table.lastFreezeUsedDate,
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
                Value<DateTime?> lastFreezeUsedDate = const Value.absent(),
              }) => PlayerProfilesCompanion(
                id: id,
                displayName: displayName,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastPlayedDate: lastPlayedDate,
                totalSolved: totalSolved,
                totalStarted: totalStarted,
                preferredDifficulty: preferredDifficulty,
                lastFreezeUsedDate: lastFreezeUsedDate,
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
                Value<DateTime?> lastFreezeUsedDate = const Value.absent(),
              }) => PlayerProfilesCompanion.insert(
                id: id,
                displayName: displayName,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastPlayedDate: lastPlayedDate,
                totalSolved: totalSolved,
                totalStarted: totalStarted,
                preferredDifficulty: preferredDifficulty,
                lastFreezeUsedDate: lastFreezeUsedDate,
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
      Value<bool> digitFirstInput,
      Value<bool> hasSeenOnboarding,
      Value<bool> hintsExplain,
      Value<bool> flagMistakesInstantly,
      Value<bool> nudgeWhenStuck,
      Value<bool> showSolvePath,
      Value<DateTime?> lastReviewRequestAt,
    });
typedef $$GamePreferencesTableTableUpdateCompanionBuilder =
    GamePreferencesTableCompanion Function({
      Value<int> id,
      Value<bool> autoRemoveNotes,
      Value<bool> highlightMatching,
      Value<bool> showTimer,
      Value<int> mistakeLimit,
      Value<String> theme,
      Value<bool> digitFirstInput,
      Value<bool> hasSeenOnboarding,
      Value<bool> hintsExplain,
      Value<bool> flagMistakesInstantly,
      Value<bool> nudgeWhenStuck,
      Value<bool> showSolvePath,
      Value<DateTime?> lastReviewRequestAt,
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

  ColumnFilters<bool> get digitFirstInput => $composableBuilder(
    column: $table.digitFirstInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSeenOnboarding => $composableBuilder(
    column: $table.hasSeenOnboarding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hintsExplain => $composableBuilder(
    column: $table.hintsExplain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get flagMistakesInstantly => $composableBuilder(
    column: $table.flagMistakesInstantly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nudgeWhenStuck => $composableBuilder(
    column: $table.nudgeWhenStuck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showSolvePath => $composableBuilder(
    column: $table.showSolvePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewRequestAt => $composableBuilder(
    column: $table.lastReviewRequestAt,
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

  ColumnOrderings<bool> get digitFirstInput => $composableBuilder(
    column: $table.digitFirstInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSeenOnboarding => $composableBuilder(
    column: $table.hasSeenOnboarding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hintsExplain => $composableBuilder(
    column: $table.hintsExplain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get flagMistakesInstantly => $composableBuilder(
    column: $table.flagMistakesInstantly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nudgeWhenStuck => $composableBuilder(
    column: $table.nudgeWhenStuck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showSolvePath => $composableBuilder(
    column: $table.showSolvePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewRequestAt => $composableBuilder(
    column: $table.lastReviewRequestAt,
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

  GeneratedColumn<bool> get digitFirstInput => $composableBuilder(
    column: $table.digitFirstInput,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasSeenOnboarding => $composableBuilder(
    column: $table.hasSeenOnboarding,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hintsExplain => $composableBuilder(
    column: $table.hintsExplain,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get flagMistakesInstantly => $composableBuilder(
    column: $table.flagMistakesInstantly,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get nudgeWhenStuck => $composableBuilder(
    column: $table.nudgeWhenStuck,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showSolvePath => $composableBuilder(
    column: $table.showSolvePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewRequestAt => $composableBuilder(
    column: $table.lastReviewRequestAt,
    builder: (column) => column,
  );
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
                Value<bool> digitFirstInput = const Value.absent(),
                Value<bool> hasSeenOnboarding = const Value.absent(),
                Value<bool> hintsExplain = const Value.absent(),
                Value<bool> flagMistakesInstantly = const Value.absent(),
                Value<bool> nudgeWhenStuck = const Value.absent(),
                Value<bool> showSolvePath = const Value.absent(),
                Value<DateTime?> lastReviewRequestAt = const Value.absent(),
              }) => GamePreferencesTableCompanion(
                id: id,
                autoRemoveNotes: autoRemoveNotes,
                highlightMatching: highlightMatching,
                showTimer: showTimer,
                mistakeLimit: mistakeLimit,
                theme: theme,
                digitFirstInput: digitFirstInput,
                hasSeenOnboarding: hasSeenOnboarding,
                hintsExplain: hintsExplain,
                flagMistakesInstantly: flagMistakesInstantly,
                nudgeWhenStuck: nudgeWhenStuck,
                showSolvePath: showSolvePath,
                lastReviewRequestAt: lastReviewRequestAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> autoRemoveNotes = const Value.absent(),
                Value<bool> highlightMatching = const Value.absent(),
                Value<bool> showTimer = const Value.absent(),
                Value<int> mistakeLimit = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<bool> digitFirstInput = const Value.absent(),
                Value<bool> hasSeenOnboarding = const Value.absent(),
                Value<bool> hintsExplain = const Value.absent(),
                Value<bool> flagMistakesInstantly = const Value.absent(),
                Value<bool> nudgeWhenStuck = const Value.absent(),
                Value<bool> showSolvePath = const Value.absent(),
                Value<DateTime?> lastReviewRequestAt = const Value.absent(),
              }) => GamePreferencesTableCompanion.insert(
                id: id,
                autoRemoveNotes: autoRemoveNotes,
                highlightMatching: highlightMatching,
                showTimer: showTimer,
                mistakeLimit: mistakeLimit,
                theme: theme,
                digitFirstInput: digitFirstInput,
                hasSeenOnboarding: hasSeenOnboarding,
                hintsExplain: hintsExplain,
                flagMistakesInstantly: flagMistakesInstantly,
                nudgeWhenStuck: nudgeWhenStuck,
                showSolvePath: showSolvePath,
                lastReviewRequestAt: lastReviewRequestAt,
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
      Value<int> hintsUsed,
      Value<int> hintDepthTotal,
      required int mistakeCount,
      required bool isNotesMode,
      required DateTime savedAt,
      Value<String> history,
      Value<String> placementDeltas,
      Value<String> mistakeCells,
      Value<int> undoCount,
      Value<bool> usedNotes,
      Value<int> longestPauseSeconds,
      Value<String> techniques,
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
      Value<int> hintsUsed,
      Value<int> hintDepthTotal,
      Value<int> mistakeCount,
      Value<bool> isNotesMode,
      Value<DateTime> savedAt,
      Value<String> history,
      Value<String> placementDeltas,
      Value<String> mistakeCells,
      Value<int> undoCount,
      Value<bool> usedNotes,
      Value<int> longestPauseSeconds,
      Value<String> techniques,
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

  ColumnFilters<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintDepthTotal => $composableBuilder(
    column: $table.hintDepthTotal,
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

  ColumnFilters<String> get history => $composableBuilder(
    column: $table.history,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placementDeltas => $composableBuilder(
    column: $table.placementDeltas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mistakeCells => $composableBuilder(
    column: $table.mistakeCells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get undoCount => $composableBuilder(
    column: $table.undoCount,
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

  ColumnFilters<String> get techniques => $composableBuilder(
    column: $table.techniques,
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

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintDepthTotal => $composableBuilder(
    column: $table.hintDepthTotal,
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

  ColumnOrderings<String> get history => $composableBuilder(
    column: $table.history,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placementDeltas => $composableBuilder(
    column: $table.placementDeltas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mistakeCells => $composableBuilder(
    column: $table.mistakeCells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get undoCount => $composableBuilder(
    column: $table.undoCount,
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

  ColumnOrderings<String> get techniques => $composableBuilder(
    column: $table.techniques,
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

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get hintDepthTotal => $composableBuilder(
    column: $table.hintDepthTotal,
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

  GeneratedColumn<String> get history =>
      $composableBuilder(column: $table.history, builder: (column) => column);

  GeneratedColumn<String> get placementDeltas => $composableBuilder(
    column: $table.placementDeltas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mistakeCells => $composableBuilder(
    column: $table.mistakeCells,
    builder: (column) => column,
  );

  GeneratedColumn<int> get undoCount =>
      $composableBuilder(column: $table.undoCount, builder: (column) => column);

  GeneratedColumn<bool> get usedNotes =>
      $composableBuilder(column: $table.usedNotes, builder: (column) => column);

  GeneratedColumn<int> get longestPauseSeconds => $composableBuilder(
    column: $table.longestPauseSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get techniques => $composableBuilder(
    column: $table.techniques,
    builder: (column) => column,
  );
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
                Value<int> hintsUsed = const Value.absent(),
                Value<int> hintDepthTotal = const Value.absent(),
                Value<int> mistakeCount = const Value.absent(),
                Value<bool> isNotesMode = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<String> history = const Value.absent(),
                Value<String> placementDeltas = const Value.absent(),
                Value<String> mistakeCells = const Value.absent(),
                Value<int> undoCount = const Value.absent(),
                Value<bool> usedNotes = const Value.absent(),
                Value<int> longestPauseSeconds = const Value.absent(),
                Value<String> techniques = const Value.absent(),
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
                hintsUsed: hintsUsed,
                hintDepthTotal: hintDepthTotal,
                mistakeCount: mistakeCount,
                isNotesMode: isNotesMode,
                savedAt: savedAt,
                history: history,
                placementDeltas: placementDeltas,
                mistakeCells: mistakeCells,
                undoCount: undoCount,
                usedNotes: usedNotes,
                longestPauseSeconds: longestPauseSeconds,
                techniques: techniques,
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
                Value<int> hintsUsed = const Value.absent(),
                Value<int> hintDepthTotal = const Value.absent(),
                required int mistakeCount,
                required bool isNotesMode,
                required DateTime savedAt,
                Value<String> history = const Value.absent(),
                Value<String> placementDeltas = const Value.absent(),
                Value<String> mistakeCells = const Value.absent(),
                Value<int> undoCount = const Value.absent(),
                Value<bool> usedNotes = const Value.absent(),
                Value<int> longestPauseSeconds = const Value.absent(),
                Value<String> techniques = const Value.absent(),
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
                hintsUsed: hintsUsed,
                hintDepthTotal: hintDepthTotal,
                mistakeCount: mistakeCount,
                isNotesMode: isNotesMode,
                savedAt: savedAt,
                history: history,
                placementDeltas: placementDeltas,
                mistakeCells: mistakeCells,
                undoCount: undoCount,
                usedNotes: usedNotes,
                longestPauseSeconds: longestPauseSeconds,
                techniques: techniques,
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
typedef $$TechniqueMasteryTableTableCreateCompanionBuilder =
    TechniqueMasteryTableCompanion Function({
      required String technique,
      Value<int> drillsAttempted,
      Value<int> drillsUnaided,
      Value<int> encountered,
      Value<int> assisted,
      Value<int?> bestSeconds,
      Value<DateTime?> lastPractisedAt,
      Value<int> rowid,
    });
typedef $$TechniqueMasteryTableTableUpdateCompanionBuilder =
    TechniqueMasteryTableCompanion Function({
      Value<String> technique,
      Value<int> drillsAttempted,
      Value<int> drillsUnaided,
      Value<int> encountered,
      Value<int> assisted,
      Value<int?> bestSeconds,
      Value<DateTime?> lastPractisedAt,
      Value<int> rowid,
    });

class $$TechniqueMasteryTableTableFilterComposer
    extends Composer<_$AppDatabase, $TechniqueMasteryTableTable> {
  $$TechniqueMasteryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get technique => $composableBuilder(
    column: $table.technique,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get drillsAttempted => $composableBuilder(
    column: $table.drillsAttempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get drillsUnaided => $composableBuilder(
    column: $table.drillsUnaided,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get encountered => $composableBuilder(
    column: $table.encountered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assisted => $composableBuilder(
    column: $table.assisted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestSeconds => $composableBuilder(
    column: $table.bestSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPractisedAt => $composableBuilder(
    column: $table.lastPractisedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TechniqueMasteryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TechniqueMasteryTableTable> {
  $$TechniqueMasteryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get technique => $composableBuilder(
    column: $table.technique,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get drillsAttempted => $composableBuilder(
    column: $table.drillsAttempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get drillsUnaided => $composableBuilder(
    column: $table.drillsUnaided,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get encountered => $composableBuilder(
    column: $table.encountered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assisted => $composableBuilder(
    column: $table.assisted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestSeconds => $composableBuilder(
    column: $table.bestSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPractisedAt => $composableBuilder(
    column: $table.lastPractisedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TechniqueMasteryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TechniqueMasteryTableTable> {
  $$TechniqueMasteryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get technique =>
      $composableBuilder(column: $table.technique, builder: (column) => column);

  GeneratedColumn<int> get drillsAttempted => $composableBuilder(
    column: $table.drillsAttempted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get drillsUnaided => $composableBuilder(
    column: $table.drillsUnaided,
    builder: (column) => column,
  );

  GeneratedColumn<int> get encountered => $composableBuilder(
    column: $table.encountered,
    builder: (column) => column,
  );

  GeneratedColumn<int> get assisted =>
      $composableBuilder(column: $table.assisted, builder: (column) => column);

  GeneratedColumn<int> get bestSeconds => $composableBuilder(
    column: $table.bestSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPractisedAt => $composableBuilder(
    column: $table.lastPractisedAt,
    builder: (column) => column,
  );
}

class $$TechniqueMasteryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TechniqueMasteryTableTable,
          TechniqueMasteryTableData,
          $$TechniqueMasteryTableTableFilterComposer,
          $$TechniqueMasteryTableTableOrderingComposer,
          $$TechniqueMasteryTableTableAnnotationComposer,
          $$TechniqueMasteryTableTableCreateCompanionBuilder,
          $$TechniqueMasteryTableTableUpdateCompanionBuilder,
          (
            TechniqueMasteryTableData,
            BaseReferences<
              _$AppDatabase,
              $TechniqueMasteryTableTable,
              TechniqueMasteryTableData
            >,
          ),
          TechniqueMasteryTableData,
          PrefetchHooks Function()
        > {
  $$TechniqueMasteryTableTableTableManager(
    _$AppDatabase db,
    $TechniqueMasteryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TechniqueMasteryTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TechniqueMasteryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TechniqueMasteryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> technique = const Value.absent(),
                Value<int> drillsAttempted = const Value.absent(),
                Value<int> drillsUnaided = const Value.absent(),
                Value<int> encountered = const Value.absent(),
                Value<int> assisted = const Value.absent(),
                Value<int?> bestSeconds = const Value.absent(),
                Value<DateTime?> lastPractisedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TechniqueMasteryTableCompanion(
                technique: technique,
                drillsAttempted: drillsAttempted,
                drillsUnaided: drillsUnaided,
                encountered: encountered,
                assisted: assisted,
                bestSeconds: bestSeconds,
                lastPractisedAt: lastPractisedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String technique,
                Value<int> drillsAttempted = const Value.absent(),
                Value<int> drillsUnaided = const Value.absent(),
                Value<int> encountered = const Value.absent(),
                Value<int> assisted = const Value.absent(),
                Value<int?> bestSeconds = const Value.absent(),
                Value<DateTime?> lastPractisedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TechniqueMasteryTableCompanion.insert(
                technique: technique,
                drillsAttempted: drillsAttempted,
                drillsUnaided: drillsUnaided,
                encountered: encountered,
                assisted: assisted,
                bestSeconds: bestSeconds,
                lastPractisedAt: lastPractisedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TechniqueMasteryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TechniqueMasteryTableTable,
      TechniqueMasteryTableData,
      $$TechniqueMasteryTableTableFilterComposer,
      $$TechniqueMasteryTableTableOrderingComposer,
      $$TechniqueMasteryTableTableAnnotationComposer,
      $$TechniqueMasteryTableTableCreateCompanionBuilder,
      $$TechniqueMasteryTableTableUpdateCompanionBuilder,
      (
        TechniqueMasteryTableData,
        BaseReferences<
          _$AppDatabase,
          $TechniqueMasteryTableTable,
          TechniqueMasteryTableData
        >,
      ),
      TechniqueMasteryTableData,
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
  $$SavedGamesTableTableManager get savedGames =>
      $$SavedGamesTableTableManager(_db, _db.savedGames);
  $$TechniqueMasteryTableTableTableManager get techniqueMasteryTable =>
      $$TechniqueMasteryTableTableTableManager(_db, _db.techniqueMasteryTable);
}
