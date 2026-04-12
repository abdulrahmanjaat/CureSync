// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedMedicationsTable extends CachedMedications
    with TableInfo<$CachedMedicationsTable, CachedMedication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
    'dosage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    name,
    dosage,
    frequency,
    reminderTime,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMedication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(
        _dosageMeta,
        dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta),
      );
    } else if (isInserting) {
      context.missing(_dosageMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderTimeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMedication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMedication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dosage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosage'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedMedicationsTable createAlias(String alias) {
    return $CachedMedicationsTable(attachedDatabase, alias);
  }
}

class CachedMedication extends DataClass
    implements Insertable<CachedMedication> {
  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String frequency;
  final String reminderTime;
  final bool isActive;
  final DateTime updatedAt;
  const CachedMedication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTime,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['name'] = Variable<String>(name);
    map['dosage'] = Variable<String>(dosage);
    map['frequency'] = Variable<String>(frequency);
    map['reminder_time'] = Variable<String>(reminderTime);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedMedicationsCompanion toCompanion(bool nullToAbsent) {
    return CachedMedicationsCompanion(
      id: Value(id),
      patientId: Value(patientId),
      name: Value(name),
      dosage: Value(dosage),
      frequency: Value(frequency),
      reminderTime: Value(reminderTime),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedMedication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMedication(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      name: serializer.fromJson<String>(json['name']),
      dosage: serializer.fromJson<String>(json['dosage']),
      frequency: serializer.fromJson<String>(json['frequency']),
      reminderTime: serializer.fromJson<String>(json['reminderTime']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'name': serializer.toJson<String>(name),
      'dosage': serializer.toJson<String>(dosage),
      'frequency': serializer.toJson<String>(frequency),
      'reminderTime': serializer.toJson<String>(reminderTime),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedMedication copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dosage,
    String? frequency,
    String? reminderTime,
    bool? isActive,
    DateTime? updatedAt,
  }) => CachedMedication(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    frequency: frequency ?? this.frequency,
    reminderTime: reminderTime ?? this.reminderTime,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedMedication copyWithCompanion(CachedMedicationsCompanion data) {
    return CachedMedication(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      name: data.name.present ? data.name.value : this.name,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedication(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('frequency: $frequency, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    name,
    dosage,
    frequency,
    reminderTime,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMedication &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.name == this.name &&
          other.dosage == this.dosage &&
          other.frequency == this.frequency &&
          other.reminderTime == this.reminderTime &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class CachedMedicationsCompanion extends UpdateCompanion<CachedMedication> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> name;
  final Value<String> dosage;
  final Value<String> frequency;
  final Value<String> reminderTime;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedMedicationsCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.name = const Value.absent(),
    this.dosage = const Value.absent(),
    this.frequency = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMedicationsCompanion.insert({
    required String id,
    required String patientId,
    required String name,
    required String dosage,
    required String frequency,
    required String reminderTime,
    this.isActive = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       name = Value(name),
       dosage = Value(dosage),
       frequency = Value(frequency),
       reminderTime = Value(reminderTime),
       updatedAt = Value(updatedAt);
  static Insertable<CachedMedication> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? name,
    Expression<String>? dosage,
    Expression<String>? frequency,
    Expression<String>? reminderTime,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? name,
    Value<String>? dosage,
    Value<String>? frequency,
    Value<String>? reminderTime,
    Value<bool>? isActive,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedMedicationsCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
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
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMedicationsCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('frequency: $frequency, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingDoseLogsTable extends PendingDoseLogs
    with TableInfo<$PendingDoseLogsTable, PendingDoseLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingDoseLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
    'local_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medIdMeta = const VerificationMeta('medId');
  @override
  late final GeneratedColumn<String> medId = GeneratedColumn<String>(
    'med_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medNameMeta = const VerificationMeta(
    'medName',
  );
  @override
  late final GeneratedColumn<String> medName = GeneratedColumn<String>(
    'med_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
    'scheduled_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    patientId,
    medId,
    medName,
    scheduledTime,
    takenAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_dose_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingDoseLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('med_id')) {
      context.handle(
        _medIdMeta,
        medId.isAcceptableOrUnknown(data['med_id']!, _medIdMeta),
      );
    } else if (isInserting) {
      context.missing(_medIdMeta);
    }
    if (data.containsKey('med_name')) {
      context.handle(
        _medNameMeta,
        medName.isAcceptableOrUnknown(data['med_name']!, _medNameMeta),
      );
    } else if (isInserting) {
      context.missing(_medNameMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledTimeMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingDoseLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingDoseLog(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      medId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}med_id'],
      )!,
      medName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}med_name'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_time'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PendingDoseLogsTable createAlias(String alias) {
    return $PendingDoseLogsTable(attachedDatabase, alias);
  }
}

class PendingDoseLog extends DataClass implements Insertable<PendingDoseLog> {
  final int localId;
  final String patientId;
  final String medId;
  final String medName;
  final String scheduledTime;
  final DateTime takenAt;
  final bool synced;
  const PendingDoseLog({
    required this.localId,
    required this.patientId,
    required this.medId,
    required this.medName,
    required this.scheduledTime,
    required this.takenAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['patient_id'] = Variable<String>(patientId);
    map['med_id'] = Variable<String>(medId);
    map['med_name'] = Variable<String>(medName);
    map['scheduled_time'] = Variable<String>(scheduledTime);
    map['taken_at'] = Variable<DateTime>(takenAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  PendingDoseLogsCompanion toCompanion(bool nullToAbsent) {
    return PendingDoseLogsCompanion(
      localId: Value(localId),
      patientId: Value(patientId),
      medId: Value(medId),
      medName: Value(medName),
      scheduledTime: Value(scheduledTime),
      takenAt: Value(takenAt),
      synced: Value(synced),
    );
  }

  factory PendingDoseLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingDoseLog(
      localId: serializer.fromJson<int>(json['localId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      medId: serializer.fromJson<String>(json['medId']),
      medName: serializer.fromJson<String>(json['medName']),
      scheduledTime: serializer.fromJson<String>(json['scheduledTime']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'patientId': serializer.toJson<String>(patientId),
      'medId': serializer.toJson<String>(medId),
      'medName': serializer.toJson<String>(medName),
      'scheduledTime': serializer.toJson<String>(scheduledTime),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  PendingDoseLog copyWith({
    int? localId,
    String? patientId,
    String? medId,
    String? medName,
    String? scheduledTime,
    DateTime? takenAt,
    bool? synced,
  }) => PendingDoseLog(
    localId: localId ?? this.localId,
    patientId: patientId ?? this.patientId,
    medId: medId ?? this.medId,
    medName: medName ?? this.medName,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    takenAt: takenAt ?? this.takenAt,
    synced: synced ?? this.synced,
  );
  PendingDoseLog copyWithCompanion(PendingDoseLogsCompanion data) {
    return PendingDoseLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      medId: data.medId.present ? data.medId.value : this.medId,
      medName: data.medName.present ? data.medName.value : this.medName,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingDoseLog(')
          ..write('localId: $localId, ')
          ..write('patientId: $patientId, ')
          ..write('medId: $medId, ')
          ..write('medName: $medName, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('takenAt: $takenAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    patientId,
    medId,
    medName,
    scheduledTime,
    takenAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingDoseLog &&
          other.localId == this.localId &&
          other.patientId == this.patientId &&
          other.medId == this.medId &&
          other.medName == this.medName &&
          other.scheduledTime == this.scheduledTime &&
          other.takenAt == this.takenAt &&
          other.synced == this.synced);
}

class PendingDoseLogsCompanion extends UpdateCompanion<PendingDoseLog> {
  final Value<int> localId;
  final Value<String> patientId;
  final Value<String> medId;
  final Value<String> medName;
  final Value<String> scheduledTime;
  final Value<DateTime> takenAt;
  final Value<bool> synced;
  const PendingDoseLogsCompanion({
    this.localId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.medId = const Value.absent(),
    this.medName = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  PendingDoseLogsCompanion.insert({
    this.localId = const Value.absent(),
    required String patientId,
    required String medId,
    required String medName,
    required String scheduledTime,
    required DateTime takenAt,
    this.synced = const Value.absent(),
  }) : patientId = Value(patientId),
       medId = Value(medId),
       medName = Value(medName),
       scheduledTime = Value(scheduledTime),
       takenAt = Value(takenAt);
  static Insertable<PendingDoseLog> custom({
    Expression<int>? localId,
    Expression<String>? patientId,
    Expression<String>? medId,
    Expression<String>? medName,
    Expression<String>? scheduledTime,
    Expression<DateTime>? takenAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (patientId != null) 'patient_id': patientId,
      if (medId != null) 'med_id': medId,
      if (medName != null) 'med_name': medName,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (takenAt != null) 'taken_at': takenAt,
      if (synced != null) 'synced': synced,
    });
  }

  PendingDoseLogsCompanion copyWith({
    Value<int>? localId,
    Value<String>? patientId,
    Value<String>? medId,
    Value<String>? medName,
    Value<String>? scheduledTime,
    Value<DateTime>? takenAt,
    Value<bool>? synced,
  }) {
    return PendingDoseLogsCompanion(
      localId: localId ?? this.localId,
      patientId: patientId ?? this.patientId,
      medId: medId ?? this.medId,
      medName: medName ?? this.medName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenAt: takenAt ?? this.takenAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (medId.present) {
      map['med_id'] = Variable<String>(medId.value);
    }
    if (medName.present) {
      map['med_name'] = Variable<String>(medName.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingDoseLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('patientId: $patientId, ')
          ..write('medId: $medId, ')
          ..write('medName: $medName, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('takenAt: $takenAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $CachedVitalsTable extends CachedVitals
    with TableInfo<$CachedVitalsTable, CachedVital> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedVitalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heartRateMeta = const VerificationMeta(
    'heartRate',
  );
  @override
  late final GeneratedColumn<double> heartRate = GeneratedColumn<double>(
    'heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bloodPressureSystolicMeta =
      const VerificationMeta('bloodPressureSystolic');
  @override
  late final GeneratedColumn<double> bloodPressureSystolic =
      GeneratedColumn<double>(
        'blood_pressure_systolic',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bloodPressureDiastolicMeta =
      const VerificationMeta('bloodPressureDiastolic');
  @override
  late final GeneratedColumn<double> bloodPressureDiastolic =
      GeneratedColumn<double>(
        'blood_pressure_diastolic',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _oxygenSaturationMeta = const VerificationMeta(
    'oxygenSaturation',
  );
  @override
  late final GeneratedColumn<double> oxygenSaturation = GeneratedColumn<double>(
    'oxygen_saturation',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    patientId,
    heartRate,
    bloodPressureSystolic,
    bloodPressureDiastolic,
    oxygenSaturation,
    temperature,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_vitals';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedVital> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('heart_rate')) {
      context.handle(
        _heartRateMeta,
        heartRate.isAcceptableOrUnknown(data['heart_rate']!, _heartRateMeta),
      );
    }
    if (data.containsKey('blood_pressure_systolic')) {
      context.handle(
        _bloodPressureSystolicMeta,
        bloodPressureSystolic.isAcceptableOrUnknown(
          data['blood_pressure_systolic']!,
          _bloodPressureSystolicMeta,
        ),
      );
    }
    if (data.containsKey('blood_pressure_diastolic')) {
      context.handle(
        _bloodPressureDiastolicMeta,
        bloodPressureDiastolic.isAcceptableOrUnknown(
          data['blood_pressure_diastolic']!,
          _bloodPressureDiastolicMeta,
        ),
      );
    }
    if (data.containsKey('oxygen_saturation')) {
      context.handle(
        _oxygenSaturationMeta,
        oxygenSaturation.isAcceptableOrUnknown(
          data['oxygen_saturation']!,
          _oxygenSaturationMeta,
        ),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {patientId};
  @override
  CachedVital map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVital(
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      heartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heart_rate'],
      ),
      bloodPressureSystolic: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blood_pressure_systolic'],
      ),
      bloodPressureDiastolic: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blood_pressure_diastolic'],
      ),
      oxygenSaturation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}oxygen_saturation'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $CachedVitalsTable createAlias(String alias) {
    return $CachedVitalsTable(attachedDatabase, alias);
  }
}

class CachedVital extends DataClass implements Insertable<CachedVital> {
  final String patientId;
  final double? heartRate;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? oxygenSaturation;
  final double? temperature;
  final DateTime recordedAt;
  const CachedVital({
    required this.patientId,
    this.heartRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.oxygenSaturation,
    this.temperature,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || heartRate != null) {
      map['heart_rate'] = Variable<double>(heartRate);
    }
    if (!nullToAbsent || bloodPressureSystolic != null) {
      map['blood_pressure_systolic'] = Variable<double>(bloodPressureSystolic);
    }
    if (!nullToAbsent || bloodPressureDiastolic != null) {
      map['blood_pressure_diastolic'] = Variable<double>(
        bloodPressureDiastolic,
      );
    }
    if (!nullToAbsent || oxygenSaturation != null) {
      map['oxygen_saturation'] = Variable<double>(oxygenSaturation);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  CachedVitalsCompanion toCompanion(bool nullToAbsent) {
    return CachedVitalsCompanion(
      patientId: Value(patientId),
      heartRate: heartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRate),
      bloodPressureSystolic: bloodPressureSystolic == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodPressureSystolic),
      bloodPressureDiastolic: bloodPressureDiastolic == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodPressureDiastolic),
      oxygenSaturation: oxygenSaturation == null && nullToAbsent
          ? const Value.absent()
          : Value(oxygenSaturation),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      recordedAt: Value(recordedAt),
    );
  }

  factory CachedVital.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVital(
      patientId: serializer.fromJson<String>(json['patientId']),
      heartRate: serializer.fromJson<double?>(json['heartRate']),
      bloodPressureSystolic: serializer.fromJson<double?>(
        json['bloodPressureSystolic'],
      ),
      bloodPressureDiastolic: serializer.fromJson<double?>(
        json['bloodPressureDiastolic'],
      ),
      oxygenSaturation: serializer.fromJson<double?>(json['oxygenSaturation']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'patientId': serializer.toJson<String>(patientId),
      'heartRate': serializer.toJson<double?>(heartRate),
      'bloodPressureSystolic': serializer.toJson<double?>(
        bloodPressureSystolic,
      ),
      'bloodPressureDiastolic': serializer.toJson<double?>(
        bloodPressureDiastolic,
      ),
      'oxygenSaturation': serializer.toJson<double?>(oxygenSaturation),
      'temperature': serializer.toJson<double?>(temperature),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  CachedVital copyWith({
    String? patientId,
    Value<double?> heartRate = const Value.absent(),
    Value<double?> bloodPressureSystolic = const Value.absent(),
    Value<double?> bloodPressureDiastolic = const Value.absent(),
    Value<double?> oxygenSaturation = const Value.absent(),
    Value<double?> temperature = const Value.absent(),
    DateTime? recordedAt,
  }) => CachedVital(
    patientId: patientId ?? this.patientId,
    heartRate: heartRate.present ? heartRate.value : this.heartRate,
    bloodPressureSystolic: bloodPressureSystolic.present
        ? bloodPressureSystolic.value
        : this.bloodPressureSystolic,
    bloodPressureDiastolic: bloodPressureDiastolic.present
        ? bloodPressureDiastolic.value
        : this.bloodPressureDiastolic,
    oxygenSaturation: oxygenSaturation.present
        ? oxygenSaturation.value
        : this.oxygenSaturation,
    temperature: temperature.present ? temperature.value : this.temperature,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  CachedVital copyWithCompanion(CachedVitalsCompanion data) {
    return CachedVital(
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      heartRate: data.heartRate.present ? data.heartRate.value : this.heartRate,
      bloodPressureSystolic: data.bloodPressureSystolic.present
          ? data.bloodPressureSystolic.value
          : this.bloodPressureSystolic,
      bloodPressureDiastolic: data.bloodPressureDiastolic.present
          ? data.bloodPressureDiastolic.value
          : this.bloodPressureDiastolic,
      oxygenSaturation: data.oxygenSaturation.present
          ? data.oxygenSaturation.value
          : this.oxygenSaturation,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVital(')
          ..write('patientId: $patientId, ')
          ..write('heartRate: $heartRate, ')
          ..write('bloodPressureSystolic: $bloodPressureSystolic, ')
          ..write('bloodPressureDiastolic: $bloodPressureDiastolic, ')
          ..write('oxygenSaturation: $oxygenSaturation, ')
          ..write('temperature: $temperature, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    patientId,
    heartRate,
    bloodPressureSystolic,
    bloodPressureDiastolic,
    oxygenSaturation,
    temperature,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVital &&
          other.patientId == this.patientId &&
          other.heartRate == this.heartRate &&
          other.bloodPressureSystolic == this.bloodPressureSystolic &&
          other.bloodPressureDiastolic == this.bloodPressureDiastolic &&
          other.oxygenSaturation == this.oxygenSaturation &&
          other.temperature == this.temperature &&
          other.recordedAt == this.recordedAt);
}

class CachedVitalsCompanion extends UpdateCompanion<CachedVital> {
  final Value<String> patientId;
  final Value<double?> heartRate;
  final Value<double?> bloodPressureSystolic;
  final Value<double?> bloodPressureDiastolic;
  final Value<double?> oxygenSaturation;
  final Value<double?> temperature;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const CachedVitalsCompanion({
    this.patientId = const Value.absent(),
    this.heartRate = const Value.absent(),
    this.bloodPressureSystolic = const Value.absent(),
    this.bloodPressureDiastolic = const Value.absent(),
    this.oxygenSaturation = const Value.absent(),
    this.temperature = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedVitalsCompanion.insert({
    required String patientId,
    this.heartRate = const Value.absent(),
    this.bloodPressureSystolic = const Value.absent(),
    this.bloodPressureDiastolic = const Value.absent(),
    this.oxygenSaturation = const Value.absent(),
    this.temperature = const Value.absent(),
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  }) : patientId = Value(patientId),
       recordedAt = Value(recordedAt);
  static Insertable<CachedVital> custom({
    Expression<String>? patientId,
    Expression<double>? heartRate,
    Expression<double>? bloodPressureSystolic,
    Expression<double>? bloodPressureDiastolic,
    Expression<double>? oxygenSaturation,
    Expression<double>? temperature,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (patientId != null) 'patient_id': patientId,
      if (heartRate != null) 'heart_rate': heartRate,
      if (bloodPressureSystolic != null)
        'blood_pressure_systolic': bloodPressureSystolic,
      if (bloodPressureDiastolic != null)
        'blood_pressure_diastolic': bloodPressureDiastolic,
      if (oxygenSaturation != null) 'oxygen_saturation': oxygenSaturation,
      if (temperature != null) 'temperature': temperature,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedVitalsCompanion copyWith({
    Value<String>? patientId,
    Value<double?>? heartRate,
    Value<double?>? bloodPressureSystolic,
    Value<double?>? bloodPressureDiastolic,
    Value<double?>? oxygenSaturation,
    Value<double?>? temperature,
    Value<DateTime>? recordedAt,
    Value<int>? rowid,
  }) {
    return CachedVitalsCompanion(
      patientId: patientId ?? this.patientId,
      heartRate: heartRate ?? this.heartRate,
      bloodPressureSystolic:
          bloodPressureSystolic ?? this.bloodPressureSystolic,
      bloodPressureDiastolic:
          bloodPressureDiastolic ?? this.bloodPressureDiastolic,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      temperature: temperature ?? this.temperature,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (heartRate.present) {
      map['heart_rate'] = Variable<double>(heartRate.value);
    }
    if (bloodPressureSystolic.present) {
      map['blood_pressure_systolic'] = Variable<double>(
        bloodPressureSystolic.value,
      );
    }
    if (bloodPressureDiastolic.present) {
      map['blood_pressure_diastolic'] = Variable<double>(
        bloodPressureDiastolic.value,
      );
    }
    if (oxygenSaturation.present) {
      map['oxygen_saturation'] = Variable<double>(oxygenSaturation.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVitalsCompanion(')
          ..write('patientId: $patientId, ')
          ..write('heartRate: $heartRate, ')
          ..write('bloodPressureSystolic: $bloodPressureSystolic, ')
          ..write('bloodPressureDiastolic: $bloodPressureDiastolic, ')
          ..write('oxygenSaturation: $oxygenSaturation, ')
          ..write('temperature: $temperature, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileImagesTable extends ProfileImages
    with TableInfo<$ProfileImagesTable, ProfileImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarIndexMeta = const VerificationMeta(
    'avatarIndex',
  );
  @override
  late final GeneratedColumn<int> avatarIndex = GeneratedColumn<int>(
    'avatar_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [uid, role, avatarIndex, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('avatar_index')) {
      context.handle(
        _avatarIndexMeta,
        avatarIndex.isAcceptableOrUnknown(
          data['avatar_index']!,
          _avatarIndexMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, role};
  @override
  ProfileImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileImage(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      avatarIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_index'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfileImagesTable createAlias(String alias) {
    return $ProfileImagesTable(attachedDatabase, alias);
  }
}

class ProfileImage extends DataClass implements Insertable<ProfileImage> {
  final String uid;
  final String role;
  final int avatarIndex;
  final DateTime updatedAt;
  const ProfileImage({
    required this.uid,
    required this.role,
    required this.avatarIndex,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['role'] = Variable<String>(role);
    map['avatar_index'] = Variable<int>(avatarIndex);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfileImagesCompanion toCompanion(bool nullToAbsent) {
    return ProfileImagesCompanion(
      uid: Value(uid),
      role: Value(role),
      avatarIndex: Value(avatarIndex),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileImage(
      uid: serializer.fromJson<String>(json['uid']),
      role: serializer.fromJson<String>(json['role']),
      avatarIndex: serializer.fromJson<int>(json['avatarIndex']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'role': serializer.toJson<String>(role),
      'avatarIndex': serializer.toJson<int>(avatarIndex),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileImage copyWith({
    String? uid,
    String? role,
    int? avatarIndex,
    DateTime? updatedAt,
  }) => ProfileImage(
    uid: uid ?? this.uid,
    role: role ?? this.role,
    avatarIndex: avatarIndex ?? this.avatarIndex,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileImage copyWithCompanion(ProfileImagesCompanion data) {
    return ProfileImage(
      uid: data.uid.present ? data.uid.value : this.uid,
      role: data.role.present ? data.role.value : this.role,
      avatarIndex: data.avatarIndex.present
          ? data.avatarIndex.value
          : this.avatarIndex,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileImage(')
          ..write('uid: $uid, ')
          ..write('role: $role, ')
          ..write('avatarIndex: $avatarIndex, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, role, avatarIndex, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileImage &&
          other.uid == this.uid &&
          other.role == this.role &&
          other.avatarIndex == this.avatarIndex &&
          other.updatedAt == this.updatedAt);
}

class ProfileImagesCompanion extends UpdateCompanion<ProfileImage> {
  final Value<String> uid;
  final Value<String> role;
  final Value<int> avatarIndex;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfileImagesCompanion({
    this.uid = const Value.absent(),
    this.role = const Value.absent(),
    this.avatarIndex = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileImagesCompanion.insert({
    required String uid,
    required String role,
    this.avatarIndex = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       role = Value(role),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileImage> custom({
    Expression<String>? uid,
    Expression<String>? role,
    Expression<int>? avatarIndex,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (role != null) 'role': role,
      if (avatarIndex != null) 'avatar_index': avatarIndex,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileImagesCompanion copyWith({
    Value<String>? uid,
    Value<String>? role,
    Value<int>? avatarIndex,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfileImagesCompanion(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (avatarIndex.present) {
      map['avatar_index'] = Variable<int>(avatarIndex.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileImagesCompanion(')
          ..write('uid: $uid, ')
          ..write('role: $role, ')
          ..write('avatarIndex: $avatarIndex, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedMedicationsTable cachedMedications =
      $CachedMedicationsTable(this);
  late final $PendingDoseLogsTable pendingDoseLogs = $PendingDoseLogsTable(
    this,
  );
  late final $CachedVitalsTable cachedVitals = $CachedVitalsTable(this);
  late final $ProfileImagesTable profileImages = $ProfileImagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMedications,
    pendingDoseLogs,
    cachedVitals,
    profileImages,
  ];
}

typedef $$CachedMedicationsTableCreateCompanionBuilder =
    CachedMedicationsCompanion Function({
      required String id,
      required String patientId,
      required String name,
      required String dosage,
      required String frequency,
      required String reminderTime,
      Value<bool> isActive,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedMedicationsTableUpdateCompanionBuilder =
    CachedMedicationsCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> name,
      Value<String> dosage,
      Value<String> frequency,
      Value<String> reminderTime,
      Value<bool> isActive,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedMedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMedicationsTable> {
  $$CachedMedicationsTableFilterComposer({
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

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMedicationsTable> {
  $$CachedMedicationsTableOrderingComposer({
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

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMedicationsTable> {
  $$CachedMedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedMedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMedicationsTable,
          CachedMedication,
          $$CachedMedicationsTableFilterComposer,
          $$CachedMedicationsTableOrderingComposer,
          $$CachedMedicationsTableAnnotationComposer,
          $$CachedMedicationsTableCreateCompanionBuilder,
          $$CachedMedicationsTableUpdateCompanionBuilder,
          (
            CachedMedication,
            BaseReferences<
              _$AppDatabase,
              $CachedMedicationsTable,
              CachedMedication
            >,
          ),
          CachedMedication,
          PrefetchHooks Function()
        > {
  $$CachedMedicationsTableTableManager(
    _$AppDatabase db,
    $CachedMedicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMedicationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dosage = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> reminderTime = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMedicationsCompanion(
                id: id,
                patientId: patientId,
                name: name,
                dosage: dosage,
                frequency: frequency,
                reminderTime: reminderTime,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String name,
                required String dosage,
                required String frequency,
                required String reminderTime,
                Value<bool> isActive = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedMedicationsCompanion.insert(
                id: id,
                patientId: patientId,
                name: name,
                dosage: dosage,
                frequency: frequency,
                reminderTime: reminderTime,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMedicationsTable,
      CachedMedication,
      $$CachedMedicationsTableFilterComposer,
      $$CachedMedicationsTableOrderingComposer,
      $$CachedMedicationsTableAnnotationComposer,
      $$CachedMedicationsTableCreateCompanionBuilder,
      $$CachedMedicationsTableUpdateCompanionBuilder,
      (
        CachedMedication,
        BaseReferences<
          _$AppDatabase,
          $CachedMedicationsTable,
          CachedMedication
        >,
      ),
      CachedMedication,
      PrefetchHooks Function()
    >;
typedef $$PendingDoseLogsTableCreateCompanionBuilder =
    PendingDoseLogsCompanion Function({
      Value<int> localId,
      required String patientId,
      required String medId,
      required String medName,
      required String scheduledTime,
      required DateTime takenAt,
      Value<bool> synced,
    });
typedef $$PendingDoseLogsTableUpdateCompanionBuilder =
    PendingDoseLogsCompanion Function({
      Value<int> localId,
      Value<String> patientId,
      Value<String> medId,
      Value<String> medName,
      Value<String> scheduledTime,
      Value<DateTime> takenAt,
      Value<bool> synced,
    });

class $$PendingDoseLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingDoseLogsTable> {
  $$PendingDoseLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medId => $composableBuilder(
    column: $table.medId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medName => $composableBuilder(
    column: $table.medName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingDoseLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingDoseLogsTable> {
  $$PendingDoseLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medId => $composableBuilder(
    column: $table.medId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medName => $composableBuilder(
    column: $table.medName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingDoseLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingDoseLogsTable> {
  $$PendingDoseLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get medId =>
      $composableBuilder(column: $table.medId, builder: (column) => column);

  GeneratedColumn<String> get medName =>
      $composableBuilder(column: $table.medName, builder: (column) => column);

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PendingDoseLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingDoseLogsTable,
          PendingDoseLog,
          $$PendingDoseLogsTableFilterComposer,
          $$PendingDoseLogsTableOrderingComposer,
          $$PendingDoseLogsTableAnnotationComposer,
          $$PendingDoseLogsTableCreateCompanionBuilder,
          $$PendingDoseLogsTableUpdateCompanionBuilder,
          (
            PendingDoseLog,
            BaseReferences<
              _$AppDatabase,
              $PendingDoseLogsTable,
              PendingDoseLog
            >,
          ),
          PendingDoseLog,
          PrefetchHooks Function()
        > {
  $$PendingDoseLogsTableTableManager(
    _$AppDatabase db,
    $PendingDoseLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingDoseLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingDoseLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingDoseLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> medId = const Value.absent(),
                Value<String> medName = const Value.absent(),
                Value<String> scheduledTime = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => PendingDoseLogsCompanion(
                localId: localId,
                patientId: patientId,
                medId: medId,
                medName: medName,
                scheduledTime: scheduledTime,
                takenAt: takenAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> localId = const Value.absent(),
                required String patientId,
                required String medId,
                required String medName,
                required String scheduledTime,
                required DateTime takenAt,
                Value<bool> synced = const Value.absent(),
              }) => PendingDoseLogsCompanion.insert(
                localId: localId,
                patientId: patientId,
                medId: medId,
                medName: medName,
                scheduledTime: scheduledTime,
                takenAt: takenAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingDoseLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingDoseLogsTable,
      PendingDoseLog,
      $$PendingDoseLogsTableFilterComposer,
      $$PendingDoseLogsTableOrderingComposer,
      $$PendingDoseLogsTableAnnotationComposer,
      $$PendingDoseLogsTableCreateCompanionBuilder,
      $$PendingDoseLogsTableUpdateCompanionBuilder,
      (
        PendingDoseLog,
        BaseReferences<_$AppDatabase, $PendingDoseLogsTable, PendingDoseLog>,
      ),
      PendingDoseLog,
      PrefetchHooks Function()
    >;
typedef $$CachedVitalsTableCreateCompanionBuilder =
    CachedVitalsCompanion Function({
      required String patientId,
      Value<double?> heartRate,
      Value<double?> bloodPressureSystolic,
      Value<double?> bloodPressureDiastolic,
      Value<double?> oxygenSaturation,
      Value<double?> temperature,
      required DateTime recordedAt,
      Value<int> rowid,
    });
typedef $$CachedVitalsTableUpdateCompanionBuilder =
    CachedVitalsCompanion Function({
      Value<String> patientId,
      Value<double?> heartRate,
      Value<double?> bloodPressureSystolic,
      Value<double?> bloodPressureDiastolic,
      Value<double?> oxygenSaturation,
      Value<double?> temperature,
      Value<DateTime> recordedAt,
      Value<int> rowid,
    });

class $$CachedVitalsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedVitalsTable> {
  $$CachedVitalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloodPressureSystolic => $composableBuilder(
    column: $table.bloodPressureSystolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloodPressureDiastolic => $composableBuilder(
    column: $table.bloodPressureDiastolic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get oxygenSaturation => $composableBuilder(
    column: $table.oxygenSaturation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedVitalsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedVitalsTable> {
  $$CachedVitalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heartRate => $composableBuilder(
    column: $table.heartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloodPressureSystolic => $composableBuilder(
    column: $table.bloodPressureSystolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloodPressureDiastolic => $composableBuilder(
    column: $table.bloodPressureDiastolic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get oxygenSaturation => $composableBuilder(
    column: $table.oxygenSaturation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedVitalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedVitalsTable> {
  $$CachedVitalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<double> get heartRate =>
      $composableBuilder(column: $table.heartRate, builder: (column) => column);

  GeneratedColumn<double> get bloodPressureSystolic => $composableBuilder(
    column: $table.bloodPressureSystolic,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bloodPressureDiastolic => $composableBuilder(
    column: $table.bloodPressureDiastolic,
    builder: (column) => column,
  );

  GeneratedColumn<double> get oxygenSaturation => $composableBuilder(
    column: $table.oxygenSaturation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$CachedVitalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedVitalsTable,
          CachedVital,
          $$CachedVitalsTableFilterComposer,
          $$CachedVitalsTableOrderingComposer,
          $$CachedVitalsTableAnnotationComposer,
          $$CachedVitalsTableCreateCompanionBuilder,
          $$CachedVitalsTableUpdateCompanionBuilder,
          (
            CachedVital,
            BaseReferences<_$AppDatabase, $CachedVitalsTable, CachedVital>,
          ),
          CachedVital,
          PrefetchHooks Function()
        > {
  $$CachedVitalsTableTableManager(_$AppDatabase db, $CachedVitalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedVitalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedVitalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedVitalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> patientId = const Value.absent(),
                Value<double?> heartRate = const Value.absent(),
                Value<double?> bloodPressureSystolic = const Value.absent(),
                Value<double?> bloodPressureDiastolic = const Value.absent(),
                Value<double?> oxygenSaturation = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVitalsCompanion(
                patientId: patientId,
                heartRate: heartRate,
                bloodPressureSystolic: bloodPressureSystolic,
                bloodPressureDiastolic: bloodPressureDiastolic,
                oxygenSaturation: oxygenSaturation,
                temperature: temperature,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String patientId,
                Value<double?> heartRate = const Value.absent(),
                Value<double?> bloodPressureSystolic = const Value.absent(),
                Value<double?> bloodPressureDiastolic = const Value.absent(),
                Value<double?> oxygenSaturation = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                required DateTime recordedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedVitalsCompanion.insert(
                patientId: patientId,
                heartRate: heartRate,
                bloodPressureSystolic: bloodPressureSystolic,
                bloodPressureDiastolic: bloodPressureDiastolic,
                oxygenSaturation: oxygenSaturation,
                temperature: temperature,
                recordedAt: recordedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedVitalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedVitalsTable,
      CachedVital,
      $$CachedVitalsTableFilterComposer,
      $$CachedVitalsTableOrderingComposer,
      $$CachedVitalsTableAnnotationComposer,
      $$CachedVitalsTableCreateCompanionBuilder,
      $$CachedVitalsTableUpdateCompanionBuilder,
      (
        CachedVital,
        BaseReferences<_$AppDatabase, $CachedVitalsTable, CachedVital>,
      ),
      CachedVital,
      PrefetchHooks Function()
    >;
typedef $$ProfileImagesTableCreateCompanionBuilder =
    ProfileImagesCompanion Function({
      required String uid,
      required String role,
      Value<int> avatarIndex,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProfileImagesTableUpdateCompanionBuilder =
    ProfileImagesCompanion Function({
      Value<String> uid,
      Value<String> role,
      Value<int> avatarIndex,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProfileImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileImagesTable> {
  $$ProfileImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarIndex => $composableBuilder(
    column: $table.avatarIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileImagesTable> {
  $$ProfileImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarIndex => $composableBuilder(
    column: $table.avatarIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileImagesTable> {
  $$ProfileImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get avatarIndex => $composableBuilder(
    column: $table.avatarIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfileImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileImagesTable,
          ProfileImage,
          $$ProfileImagesTableFilterComposer,
          $$ProfileImagesTableOrderingComposer,
          $$ProfileImagesTableAnnotationComposer,
          $$ProfileImagesTableCreateCompanionBuilder,
          $$ProfileImagesTableUpdateCompanionBuilder,
          (
            ProfileImage,
            BaseReferences<_$AppDatabase, $ProfileImagesTable, ProfileImage>,
          ),
          ProfileImage,
          PrefetchHooks Function()
        > {
  $$ProfileImagesTableTableManager(_$AppDatabase db, $ProfileImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> avatarIndex = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileImagesCompanion(
                uid: uid,
                role: role,
                avatarIndex: avatarIndex,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String role,
                Value<int> avatarIndex = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfileImagesCompanion.insert(
                uid: uid,
                role: role,
                avatarIndex: avatarIndex,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileImagesTable,
      ProfileImage,
      $$ProfileImagesTableFilterComposer,
      $$ProfileImagesTableOrderingComposer,
      $$ProfileImagesTableAnnotationComposer,
      $$ProfileImagesTableCreateCompanionBuilder,
      $$ProfileImagesTableUpdateCompanionBuilder,
      (
        ProfileImage,
        BaseReferences<_$AppDatabase, $ProfileImagesTable, ProfileImage>,
      ),
      ProfileImage,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMedicationsTableTableManager get cachedMedications =>
      $$CachedMedicationsTableTableManager(_db, _db.cachedMedications);
  $$PendingDoseLogsTableTableManager get pendingDoseLogs =>
      $$PendingDoseLogsTableTableManager(_db, _db.pendingDoseLogs);
  $$CachedVitalsTableTableManager get cachedVitals =>
      $$CachedVitalsTableTableManager(_db, _db.cachedVitals);
  $$ProfileImagesTableTableManager get profileImages =>
      $$ProfileImagesTableTableManager(_db, _db.profileImages);
}
