// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
      'name_ar', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameBnMeta = const VerificationMeta('nameBn');
  @override
  late final GeneratedColumn<String> nameBn = GeneratedColumn<String>(
      'name_bn', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionBnMeta =
      const VerificationMeta('descriptionBn');
  @override
  late final GeneratedColumn<String> descriptionBn = GeneratedColumn<String>(
      'description_bn', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, slug, nameAr, nameBn, nameEn, descriptionBn, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(Insertable<Track> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('name_ar')) {
      context.handle(_nameArMeta,
          nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta));
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_bn')) {
      context.handle(_nameBnMeta,
          nameBn.isAcceptableOrUnknown(data['name_bn']!, _nameBnMeta));
    } else if (isInserting) {
      context.missing(_nameBnMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('description_bn')) {
      context.handle(
          _descriptionBnMeta,
          descriptionBn.isAcceptableOrUnknown(
              data['description_bn']!, _descriptionBnMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      nameAr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ar'])!,
      nameBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_bn'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      descriptionBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description_bn']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends DataClass implements Insertable<Track> {
  final String id;
  final String slug;
  final String nameAr;
  final String nameBn;
  final String nameEn;
  final String? descriptionBn;
  final int sortOrder;
  final DateTime createdAt;
  const Track(
      {required this.id,
      required this.slug,
      required this.nameAr,
      required this.nameBn,
      required this.nameEn,
      this.descriptionBn,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slug'] = Variable<String>(slug);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_bn'] = Variable<String>(nameBn);
    map['name_en'] = Variable<String>(nameEn);
    if (!nullToAbsent || descriptionBn != null) {
      map['description_bn'] = Variable<String>(descriptionBn);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      slug: Value(slug),
      nameAr: Value(nameAr),
      nameBn: Value(nameBn),
      nameEn: Value(nameEn),
      descriptionBn: descriptionBn == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionBn),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Track.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<String>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameBn: serializer.fromJson<String>(json['nameBn']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      descriptionBn: serializer.fromJson<String?>(json['descriptionBn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slug': serializer.toJson<String>(slug),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameBn': serializer.toJson<String>(nameBn),
      'nameEn': serializer.toJson<String>(nameEn),
      'descriptionBn': serializer.toJson<String?>(descriptionBn),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Track copyWith(
          {String? id,
          String? slug,
          String? nameAr,
          String? nameBn,
          String? nameEn,
          Value<String?> descriptionBn = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt}) =>
      Track(
        id: id ?? this.id,
        slug: slug ?? this.slug,
        nameAr: nameAr ?? this.nameAr,
        nameBn: nameBn ?? this.nameBn,
        nameEn: nameEn ?? this.nameEn,
        descriptionBn:
            descriptionBn.present ? descriptionBn.value : this.descriptionBn,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameBn: data.nameBn.present ? data.nameBn.value : this.nameBn,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      descriptionBn: data.descriptionBn.present
          ? data.descriptionBn.value
          : this.descriptionBn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameBn: $nameBn, ')
          ..write('nameEn: $nameEn, ')
          ..write('descriptionBn: $descriptionBn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, slug, nameAr, nameBn, nameEn, descriptionBn, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.nameAr == this.nameAr &&
          other.nameBn == this.nameBn &&
          other.nameEn == this.nameEn &&
          other.descriptionBn == this.descriptionBn &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> id;
  final Value<String> slug;
  final Value<String> nameAr;
  final Value<String> nameBn;
  final Value<String> nameEn;
  final Value<String?> descriptionBn;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameBn = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.descriptionBn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required String slug,
    required String nameAr,
    required String nameBn,
    required String nameEn,
    this.descriptionBn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        slug = Value(slug),
        nameAr = Value(nameAr),
        nameBn = Value(nameBn),
        nameEn = Value(nameEn);
  static Insertable<Track> custom({
    Expression<String>? id,
    Expression<String>? slug,
    Expression<String>? nameAr,
    Expression<String>? nameBn,
    Expression<String>? nameEn,
    Expression<String>? descriptionBn,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameBn != null) 'name_bn': nameBn,
      if (nameEn != null) 'name_en': nameEn,
      if (descriptionBn != null) 'description_bn': descriptionBn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith(
      {Value<String>? id,
      Value<String>? slug,
      Value<String>? nameAr,
      Value<String>? nameBn,
      Value<String>? nameEn,
      Value<String?>? descriptionBn,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TracksCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      nameAr: nameAr ?? this.nameAr,
      nameBn: nameBn ?? this.nameBn,
      nameEn: nameEn ?? this.nameEn,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameBn.present) {
      map['name_bn'] = Variable<String>(nameBn.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (descriptionBn.present) {
      map['description_bn'] = Variable<String>(descriptionBn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameBn: $nameBn, ')
          ..write('nameEn: $nameEn, ')
          ..write('descriptionBn: $descriptionBn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, Unit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trackIdMeta =
      const VerificationMeta('trackId');
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
      'track_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tracks (id)'));
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleArMeta =
      const VerificationMeta('titleAr');
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
      'title_ar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleBnMeta =
      const VerificationMeta('titleBn');
  @override
  late final GeneratedColumn<String> titleBn = GeneratedColumn<String>(
      'title_bn', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleEnMeta =
      const VerificationMeta('titleEn');
  @override
  late final GeneratedColumn<String> titleEn = GeneratedColumn<String>(
      'title_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionBnMeta =
      const VerificationMeta('descriptionBn');
  @override
  late final GeneratedColumn<String> descriptionBn = GeneratedColumn<String>(
      'description_bn', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _sourceMaterialIdMeta =
      const VerificationMeta('sourceMaterialId');
  @override
  late final GeneratedColumn<String> sourceMaterialId = GeneratedColumn<String>(
      'source_material_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        trackId,
        slug,
        titleAr,
        titleBn,
        titleEn,
        descriptionBn,
        sortOrder,
        status,
        sourceMaterialId,
        createdAt,
        downloadedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<Unit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(_trackIdMeta,
          trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta));
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(_titleArMeta,
          titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta));
    }
    if (data.containsKey('title_bn')) {
      context.handle(_titleBnMeta,
          titleBn.isAcceptableOrUnknown(data['title_bn']!, _titleBnMeta));
    } else if (isInserting) {
      context.missing(_titleBnMeta);
    }
    if (data.containsKey('title_en')) {
      context.handle(_titleEnMeta,
          titleEn.isAcceptableOrUnknown(data['title_en']!, _titleEnMeta));
    }
    if (data.containsKey('description_bn')) {
      context.handle(
          _descriptionBnMeta,
          descriptionBn.isAcceptableOrUnknown(
              data['description_bn']!, _descriptionBnMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('source_material_id')) {
      context.handle(
          _sourceMaterialIdMeta,
          sourceMaterialId.isAcceptableOrUnknown(
              data['source_material_id']!, _sourceMaterialIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Unit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Unit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      trackId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}track_id'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      titleAr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_ar']),
      titleBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_bn'])!,
      titleEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_en']),
      descriptionBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description_bn']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      sourceMaterialId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_material_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      downloadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at']),
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class Unit extends DataClass implements Insertable<Unit> {
  final String id;
  final String trackId;
  final String slug;
  final String? titleAr;
  final String titleBn;
  final String? titleEn;
  final String? descriptionBn;
  final int sortOrder;
  final String status;
  final String? sourceMaterialId;
  final DateTime createdAt;
  final DateTime? downloadedAt;
  const Unit(
      {required this.id,
      required this.trackId,
      required this.slug,
      this.titleAr,
      required this.titleBn,
      this.titleEn,
      this.descriptionBn,
      required this.sortOrder,
      required this.status,
      this.sourceMaterialId,
      required this.createdAt,
      this.downloadedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['track_id'] = Variable<String>(trackId);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || titleAr != null) {
      map['title_ar'] = Variable<String>(titleAr);
    }
    map['title_bn'] = Variable<String>(titleBn);
    if (!nullToAbsent || titleEn != null) {
      map['title_en'] = Variable<String>(titleEn);
    }
    if (!nullToAbsent || descriptionBn != null) {
      map['description_bn'] = Variable<String>(descriptionBn);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || sourceMaterialId != null) {
      map['source_material_id'] = Variable<String>(sourceMaterialId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      slug: Value(slug),
      titleAr: titleAr == null && nullToAbsent
          ? const Value.absent()
          : Value(titleAr),
      titleBn: Value(titleBn),
      titleEn: titleEn == null && nullToAbsent
          ? const Value.absent()
          : Value(titleEn),
      descriptionBn: descriptionBn == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionBn),
      sortOrder: Value(sortOrder),
      status: Value(status),
      sourceMaterialId: sourceMaterialId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMaterialId),
      createdAt: Value(createdAt),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
    );
  }

  factory Unit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Unit(
      id: serializer.fromJson<String>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      slug: serializer.fromJson<String>(json['slug']),
      titleAr: serializer.fromJson<String?>(json['titleAr']),
      titleBn: serializer.fromJson<String>(json['titleBn']),
      titleEn: serializer.fromJson<String?>(json['titleEn']),
      descriptionBn: serializer.fromJson<String?>(json['descriptionBn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      status: serializer.fromJson<String>(json['status']),
      sourceMaterialId: serializer.fromJson<String?>(json['sourceMaterialId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trackId': serializer.toJson<String>(trackId),
      'slug': serializer.toJson<String>(slug),
      'titleAr': serializer.toJson<String?>(titleAr),
      'titleBn': serializer.toJson<String>(titleBn),
      'titleEn': serializer.toJson<String?>(titleEn),
      'descriptionBn': serializer.toJson<String?>(descriptionBn),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'status': serializer.toJson<String>(status),
      'sourceMaterialId': serializer.toJson<String?>(sourceMaterialId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
    };
  }

  Unit copyWith(
          {String? id,
          String? trackId,
          String? slug,
          Value<String?> titleAr = const Value.absent(),
          String? titleBn,
          Value<String?> titleEn = const Value.absent(),
          Value<String?> descriptionBn = const Value.absent(),
          int? sortOrder,
          String? status,
          Value<String?> sourceMaterialId = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> downloadedAt = const Value.absent()}) =>
      Unit(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        slug: slug ?? this.slug,
        titleAr: titleAr.present ? titleAr.value : this.titleAr,
        titleBn: titleBn ?? this.titleBn,
        titleEn: titleEn.present ? titleEn.value : this.titleEn,
        descriptionBn:
            descriptionBn.present ? descriptionBn.value : this.descriptionBn,
        sortOrder: sortOrder ?? this.sortOrder,
        status: status ?? this.status,
        sourceMaterialId: sourceMaterialId.present
            ? sourceMaterialId.value
            : this.sourceMaterialId,
        createdAt: createdAt ?? this.createdAt,
        downloadedAt:
            downloadedAt.present ? downloadedAt.value : this.downloadedAt,
      );
  Unit copyWithCompanion(UnitsCompanion data) {
    return Unit(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      slug: data.slug.present ? data.slug.value : this.slug,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      titleBn: data.titleBn.present ? data.titleBn.value : this.titleBn,
      titleEn: data.titleEn.present ? data.titleEn.value : this.titleEn,
      descriptionBn: data.descriptionBn.present
          ? data.descriptionBn.value
          : this.descriptionBn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      status: data.status.present ? data.status.value : this.status,
      sourceMaterialId: data.sourceMaterialId.present
          ? data.sourceMaterialId.value
          : this.sourceMaterialId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Unit(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('slug: $slug, ')
          ..write('titleAr: $titleAr, ')
          ..write('titleBn: $titleBn, ')
          ..write('titleEn: $titleEn, ')
          ..write('descriptionBn: $descriptionBn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('status: $status, ')
          ..write('sourceMaterialId: $sourceMaterialId, ')
          ..write('createdAt: $createdAt, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      trackId,
      slug,
      titleAr,
      titleBn,
      titleEn,
      descriptionBn,
      sortOrder,
      status,
      sourceMaterialId,
      createdAt,
      downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Unit &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.slug == this.slug &&
          other.titleAr == this.titleAr &&
          other.titleBn == this.titleBn &&
          other.titleEn == this.titleEn &&
          other.descriptionBn == this.descriptionBn &&
          other.sortOrder == this.sortOrder &&
          other.status == this.status &&
          other.sourceMaterialId == this.sourceMaterialId &&
          other.createdAt == this.createdAt &&
          other.downloadedAt == this.downloadedAt);
}

class UnitsCompanion extends UpdateCompanion<Unit> {
  final Value<String> id;
  final Value<String> trackId;
  final Value<String> slug;
  final Value<String?> titleAr;
  final Value<String> titleBn;
  final Value<String?> titleEn;
  final Value<String?> descriptionBn;
  final Value<int> sortOrder;
  final Value<String> status;
  final Value<String?> sourceMaterialId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> downloadedAt;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.slug = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.titleBn = const Value.absent(),
    this.titleEn = const Value.absent(),
    this.descriptionBn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.status = const Value.absent(),
    this.sourceMaterialId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String trackId,
    required String slug,
    this.titleAr = const Value.absent(),
    required String titleBn,
    this.titleEn = const Value.absent(),
    this.descriptionBn = const Value.absent(),
    required int sortOrder,
    this.status = const Value.absent(),
    this.sourceMaterialId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        trackId = Value(trackId),
        slug = Value(slug),
        titleBn = Value(titleBn),
        sortOrder = Value(sortOrder);
  static Insertable<Unit> custom({
    Expression<String>? id,
    Expression<String>? trackId,
    Expression<String>? slug,
    Expression<String>? titleAr,
    Expression<String>? titleBn,
    Expression<String>? titleEn,
    Expression<String>? descriptionBn,
    Expression<int>? sortOrder,
    Expression<String>? status,
    Expression<String>? sourceMaterialId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (slug != null) 'slug': slug,
      if (titleAr != null) 'title_ar': titleAr,
      if (titleBn != null) 'title_bn': titleBn,
      if (titleEn != null) 'title_en': titleEn,
      if (descriptionBn != null) 'description_bn': descriptionBn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (status != null) 'status': status,
      if (sourceMaterialId != null) 'source_material_id': sourceMaterialId,
      if (createdAt != null) 'created_at': createdAt,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? trackId,
      Value<String>? slug,
      Value<String?>? titleAr,
      Value<String>? titleBn,
      Value<String?>? titleEn,
      Value<String?>? descriptionBn,
      Value<int>? sortOrder,
      Value<String>? status,
      Value<String?>? sourceMaterialId,
      Value<DateTime>? createdAt,
      Value<DateTime?>? downloadedAt,
      Value<int>? rowid}) {
    return UnitsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      slug: slug ?? this.slug,
      titleAr: titleAr ?? this.titleAr,
      titleBn: titleBn ?? this.titleBn,
      titleEn: titleEn ?? this.titleEn,
      descriptionBn: descriptionBn ?? this.descriptionBn,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
      sourceMaterialId: sourceMaterialId ?? this.sourceMaterialId,
      createdAt: createdAt ?? this.createdAt,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (titleBn.present) {
      map['title_bn'] = Variable<String>(titleBn.value);
    }
    if (titleEn.present) {
      map['title_en'] = Variable<String>(titleEn.value);
    }
    if (descriptionBn.present) {
      map['description_bn'] = Variable<String>(descriptionBn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sourceMaterialId.present) {
      map['source_material_id'] = Variable<String>(sourceMaterialId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('slug: $slug, ')
          ..write('titleAr: $titleAr, ')
          ..write('titleBn: $titleBn, ')
          ..write('titleEn: $titleEn, ')
          ..write('descriptionBn: $descriptionBn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('status: $status, ')
          ..write('sourceMaterialId: $sourceMaterialId, ')
          ..write('createdAt: $createdAt, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, Lesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<String> unitId = GeneratedColumn<String>(
      'unit_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _titleBnMeta =
      const VerificationMeta('titleBn');
  @override
  late final GeneratedColumn<String> titleBn = GeneratedColumn<String>(
      'title_bn', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleArMeta =
      const VerificationMeta('titleAr');
  @override
  late final GeneratedColumn<String> titleAr = GeneratedColumn<String>(
      'title_ar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _xpRewardMeta =
      const VerificationMeta('xpReward');
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
      'xp_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
      'level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('beginner'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        unitId,
        titleBn,
        titleAr,
        sortOrder,
        xpReward,
        status,
        level,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons';
  @override
  VerificationContext validateIntegrity(Insertable<Lesson> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    } else if (isInserting) {
      context.missing(_unitIdMeta);
    }
    if (data.containsKey('title_bn')) {
      context.handle(_titleBnMeta,
          titleBn.isAcceptableOrUnknown(data['title_bn']!, _titleBnMeta));
    } else if (isInserting) {
      context.missing(_titleBnMeta);
    }
    if (data.containsKey('title_ar')) {
      context.handle(_titleArMeta,
          titleAr.isAcceptableOrUnknown(data['title_ar']!, _titleArMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('xp_reward')) {
      context.handle(_xpRewardMeta,
          xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lesson(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_id'])!,
      titleBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_bn'])!,
      titleAr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_ar']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      xpReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_reward'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LessonsTable createAlias(String alias) {
    return $LessonsTable(attachedDatabase, alias);
  }
}

class Lesson extends DataClass implements Insertable<Lesson> {
  final String id;
  final String unitId;
  final String titleBn;
  final String? titleAr;
  final int sortOrder;
  final int xpReward;
  final String status;
  final String level;
  final DateTime createdAt;
  const Lesson(
      {required this.id,
      required this.unitId,
      required this.titleBn,
      this.titleAr,
      required this.sortOrder,
      required this.xpReward,
      required this.status,
      required this.level,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unit_id'] = Variable<String>(unitId);
    map['title_bn'] = Variable<String>(titleBn);
    if (!nullToAbsent || titleAr != null) {
      map['title_ar'] = Variable<String>(titleAr);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['xp_reward'] = Variable<int>(xpReward);
    map['status'] = Variable<String>(status);
    map['level'] = Variable<String>(level);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LessonsCompanion toCompanion(bool nullToAbsent) {
    return LessonsCompanion(
      id: Value(id),
      unitId: Value(unitId),
      titleBn: Value(titleBn),
      titleAr: titleAr == null && nullToAbsent
          ? const Value.absent()
          : Value(titleAr),
      sortOrder: Value(sortOrder),
      xpReward: Value(xpReward),
      status: Value(status),
      level: Value(level),
      createdAt: Value(createdAt),
    );
  }

  factory Lesson.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lesson(
      id: serializer.fromJson<String>(json['id']),
      unitId: serializer.fromJson<String>(json['unitId']),
      titleBn: serializer.fromJson<String>(json['titleBn']),
      titleAr: serializer.fromJson<String?>(json['titleAr']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      status: serializer.fromJson<String>(json['status']),
      level: serializer.fromJson<String>(json['level']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unitId': serializer.toJson<String>(unitId),
      'titleBn': serializer.toJson<String>(titleBn),
      'titleAr': serializer.toJson<String?>(titleAr),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'xpReward': serializer.toJson<int>(xpReward),
      'status': serializer.toJson<String>(status),
      'level': serializer.toJson<String>(level),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Lesson copyWith(
          {String? id,
          String? unitId,
          String? titleBn,
          Value<String?> titleAr = const Value.absent(),
          int? sortOrder,
          int? xpReward,
          String? status,
          String? level,
          DateTime? createdAt}) =>
      Lesson(
        id: id ?? this.id,
        unitId: unitId ?? this.unitId,
        titleBn: titleBn ?? this.titleBn,
        titleAr: titleAr.present ? titleAr.value : this.titleAr,
        sortOrder: sortOrder ?? this.sortOrder,
        xpReward: xpReward ?? this.xpReward,
        status: status ?? this.status,
        level: level ?? this.level,
        createdAt: createdAt ?? this.createdAt,
      );
  Lesson copyWithCompanion(LessonsCompanion data) {
    return Lesson(
      id: data.id.present ? data.id.value : this.id,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      titleBn: data.titleBn.present ? data.titleBn.value : this.titleBn,
      titleAr: data.titleAr.present ? data.titleAr.value : this.titleAr,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      status: data.status.present ? data.status.value : this.status,
      level: data.level.present ? data.level.value : this.level,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lesson(')
          ..write('id: $id, ')
          ..write('unitId: $unitId, ')
          ..write('titleBn: $titleBn, ')
          ..write('titleAr: $titleAr, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('xpReward: $xpReward, ')
          ..write('status: $status, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, unitId, titleBn, titleAr, sortOrder,
      xpReward, status, level, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lesson &&
          other.id == this.id &&
          other.unitId == this.unitId &&
          other.titleBn == this.titleBn &&
          other.titleAr == this.titleAr &&
          other.sortOrder == this.sortOrder &&
          other.xpReward == this.xpReward &&
          other.status == this.status &&
          other.level == this.level &&
          other.createdAt == this.createdAt);
}

class LessonsCompanion extends UpdateCompanion<Lesson> {
  final Value<String> id;
  final Value<String> unitId;
  final Value<String> titleBn;
  final Value<String?> titleAr;
  final Value<int> sortOrder;
  final Value<int> xpReward;
  final Value<String> status;
  final Value<String> level;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LessonsCompanion({
    this.id = const Value.absent(),
    this.unitId = const Value.absent(),
    this.titleBn = const Value.absent(),
    this.titleAr = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.status = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonsCompanion.insert({
    required String id,
    required String unitId,
    required String titleBn,
    this.titleAr = const Value.absent(),
    required int sortOrder,
    this.xpReward = const Value.absent(),
    this.status = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        unitId = Value(unitId),
        titleBn = Value(titleBn),
        sortOrder = Value(sortOrder);
  static Insertable<Lesson> custom({
    Expression<String>? id,
    Expression<String>? unitId,
    Expression<String>? titleBn,
    Expression<String>? titleAr,
    Expression<int>? sortOrder,
    Expression<int>? xpReward,
    Expression<String>? status,
    Expression<String>? level,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unitId != null) 'unit_id': unitId,
      if (titleBn != null) 'title_bn': titleBn,
      if (titleAr != null) 'title_ar': titleAr,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (xpReward != null) 'xp_reward': xpReward,
      if (status != null) 'status': status,
      if (level != null) 'level': level,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonsCompanion copyWith(
      {Value<String>? id,
      Value<String>? unitId,
      Value<String>? titleBn,
      Value<String?>? titleAr,
      Value<int>? sortOrder,
      Value<int>? xpReward,
      Value<String>? status,
      Value<String>? level,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LessonsCompanion(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      titleBn: titleBn ?? this.titleBn,
      titleAr: titleAr ?? this.titleAr,
      sortOrder: sortOrder ?? this.sortOrder,
      xpReward: xpReward ?? this.xpReward,
      status: status ?? this.status,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<String>(unitId.value);
    }
    if (titleBn.present) {
      map['title_bn'] = Variable<String>(titleBn.value);
    }
    if (titleAr.present) {
      map['title_ar'] = Variable<String>(titleAr.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsCompanion(')
          ..write('id: $id, ')
          ..write('unitId: $unitId, ')
          ..write('titleBn: $titleBn, ')
          ..write('titleAr: $titleAr, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('xpReward: $xpReward, ')
          ..write('status: $status, ')
          ..write('level: $level, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _promptArMeta =
      const VerificationMeta('promptAr');
  @override
  late final GeneratedColumn<String> promptAr = GeneratedColumn<String>(
      'prompt_ar', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _promptBnMeta =
      const VerificationMeta('promptBn');
  @override
  late final GeneratedColumn<String> promptBn = GeneratedColumn<String>(
      'prompt_bn', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _promptEnMeta =
      const VerificationMeta('promptEn');
  @override
  late final GeneratedColumn<String> promptEn = GeneratedColumn<String>(
      'prompt_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _correctAnswerMeta =
      const VerificationMeta('correctAnswer');
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
      'correct_answer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distractorsMeta =
      const VerificationMeta('distractors');
  @override
  late final GeneratedColumn<String> distractors = GeneratedColumn<String>(
      'distractors', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioUrlMeta =
      const VerificationMeta('audioUrl');
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
      'audio_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _grammarNoteBnMeta =
      const VerificationMeta('grammarNoteBn');
  @override
  late final GeneratedColumn<String> grammarNoteBn = GeneratedColumn<String>(
      'grammar_note_bn', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _grammarNoteEnMeta =
      const VerificationMeta('grammarNoteEn');
  @override
  late final GeneratedColumn<String> grammarNoteEn = GeneratedColumn<String>(
      'grammar_note_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        lessonId,
        type,
        sortOrder,
        promptAr,
        promptBn,
        promptEn,
        correctAnswer,
        distractors,
        audioUrl,
        grammarNoteBn,
        grammarNoteEn,
        difficulty,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('prompt_ar')) {
      context.handle(_promptArMeta,
          promptAr.isAcceptableOrUnknown(data['prompt_ar']!, _promptArMeta));
    }
    if (data.containsKey('prompt_bn')) {
      context.handle(_promptBnMeta,
          promptBn.isAcceptableOrUnknown(data['prompt_bn']!, _promptBnMeta));
    }
    if (data.containsKey('prompt_en')) {
      context.handle(_promptEnMeta,
          promptEn.isAcceptableOrUnknown(data['prompt_en']!, _promptEnMeta));
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
          _correctAnswerMeta,
          correctAnswer.isAcceptableOrUnknown(
              data['correct_answer']!, _correctAnswerMeta));
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('distractors')) {
      context.handle(
          _distractorsMeta,
          distractors.isAcceptableOrUnknown(
              data['distractors']!, _distractorsMeta));
    }
    if (data.containsKey('audio_url')) {
      context.handle(_audioUrlMeta,
          audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta));
    }
    if (data.containsKey('grammar_note_bn')) {
      context.handle(
          _grammarNoteBnMeta,
          grammarNoteBn.isAcceptableOrUnknown(
              data['grammar_note_bn']!, _grammarNoteBnMeta));
    }
    if (data.containsKey('grammar_note_en')) {
      context.handle(
          _grammarNoteEnMeta,
          grammarNoteEn.isAcceptableOrUnknown(
              data['grammar_note_en']!, _grammarNoteEnMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      promptAr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_ar']),
      promptBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_bn']),
      promptEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_en']),
      correctAnswer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}correct_answer'])!,
      distractors: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}distractors']),
      audioUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_url']),
      grammarNoteBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grammar_note_bn']),
      grammarNoteEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}grammar_note_en']),
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String lessonId;
  final String type;
  final int sortOrder;
  final String? promptAr;
  final String? promptBn;
  final String? promptEn;
  final String correctAnswer;
  final String? distractors;
  final String? audioUrl;
  final String? grammarNoteBn;
  final String? grammarNoteEn;
  final int difficulty;
  final DateTime createdAt;
  const Exercise(
      {required this.id,
      required this.lessonId,
      required this.type,
      required this.sortOrder,
      this.promptAr,
      this.promptBn,
      this.promptEn,
      required this.correctAnswer,
      this.distractors,
      this.audioUrl,
      this.grammarNoteBn,
      this.grammarNoteEn,
      required this.difficulty,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lesson_id'] = Variable<String>(lessonId);
    map['type'] = Variable<String>(type);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || promptAr != null) {
      map['prompt_ar'] = Variable<String>(promptAr);
    }
    if (!nullToAbsent || promptBn != null) {
      map['prompt_bn'] = Variable<String>(promptBn);
    }
    if (!nullToAbsent || promptEn != null) {
      map['prompt_en'] = Variable<String>(promptEn);
    }
    map['correct_answer'] = Variable<String>(correctAnswer);
    if (!nullToAbsent || distractors != null) {
      map['distractors'] = Variable<String>(distractors);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || grammarNoteBn != null) {
      map['grammar_note_bn'] = Variable<String>(grammarNoteBn);
    }
    if (!nullToAbsent || grammarNoteEn != null) {
      map['grammar_note_en'] = Variable<String>(grammarNoteEn);
    }
    map['difficulty'] = Variable<int>(difficulty);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      type: Value(type),
      sortOrder: Value(sortOrder),
      promptAr: promptAr == null && nullToAbsent
          ? const Value.absent()
          : Value(promptAr),
      promptBn: promptBn == null && nullToAbsent
          ? const Value.absent()
          : Value(promptBn),
      promptEn: promptEn == null && nullToAbsent
          ? const Value.absent()
          : Value(promptEn),
      correctAnswer: Value(correctAnswer),
      distractors: distractors == null && nullToAbsent
          ? const Value.absent()
          : Value(distractors),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      grammarNoteBn: grammarNoteBn == null && nullToAbsent
          ? const Value.absent()
          : Value(grammarNoteBn),
      grammarNoteEn: grammarNoteEn == null && nullToAbsent
          ? const Value.absent()
          : Value(grammarNoteEn),
      difficulty: Value(difficulty),
      createdAt: Value(createdAt),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      type: serializer.fromJson<String>(json['type']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      promptAr: serializer.fromJson<String?>(json['promptAr']),
      promptBn: serializer.fromJson<String?>(json['promptBn']),
      promptEn: serializer.fromJson<String?>(json['promptEn']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      distractors: serializer.fromJson<String?>(json['distractors']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      grammarNoteBn: serializer.fromJson<String?>(json['grammarNoteBn']),
      grammarNoteEn: serializer.fromJson<String?>(json['grammarNoteEn']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lessonId': serializer.toJson<String>(lessonId),
      'type': serializer.toJson<String>(type),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'promptAr': serializer.toJson<String?>(promptAr),
      'promptBn': serializer.toJson<String?>(promptBn),
      'promptEn': serializer.toJson<String?>(promptEn),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'distractors': serializer.toJson<String?>(distractors),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'grammarNoteBn': serializer.toJson<String?>(grammarNoteBn),
      'grammarNoteEn': serializer.toJson<String?>(grammarNoteEn),
      'difficulty': serializer.toJson<int>(difficulty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Exercise copyWith(
          {String? id,
          String? lessonId,
          String? type,
          int? sortOrder,
          Value<String?> promptAr = const Value.absent(),
          Value<String?> promptBn = const Value.absent(),
          Value<String?> promptEn = const Value.absent(),
          String? correctAnswer,
          Value<String?> distractors = const Value.absent(),
          Value<String?> audioUrl = const Value.absent(),
          Value<String?> grammarNoteBn = const Value.absent(),
          Value<String?> grammarNoteEn = const Value.absent(),
          int? difficulty,
          DateTime? createdAt}) =>
      Exercise(
        id: id ?? this.id,
        lessonId: lessonId ?? this.lessonId,
        type: type ?? this.type,
        sortOrder: sortOrder ?? this.sortOrder,
        promptAr: promptAr.present ? promptAr.value : this.promptAr,
        promptBn: promptBn.present ? promptBn.value : this.promptBn,
        promptEn: promptEn.present ? promptEn.value : this.promptEn,
        correctAnswer: correctAnswer ?? this.correctAnswer,
        distractors: distractors.present ? distractors.value : this.distractors,
        audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
        grammarNoteBn:
            grammarNoteBn.present ? grammarNoteBn.value : this.grammarNoteBn,
        grammarNoteEn:
            grammarNoteEn.present ? grammarNoteEn.value : this.grammarNoteEn,
        difficulty: difficulty ?? this.difficulty,
        createdAt: createdAt ?? this.createdAt,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      type: data.type.present ? data.type.value : this.type,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      promptAr: data.promptAr.present ? data.promptAr.value : this.promptAr,
      promptBn: data.promptBn.present ? data.promptBn.value : this.promptBn,
      promptEn: data.promptEn.present ? data.promptEn.value : this.promptEn,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      distractors:
          data.distractors.present ? data.distractors.value : this.distractors,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      grammarNoteBn: data.grammarNoteBn.present
          ? data.grammarNoteBn.value
          : this.grammarNoteBn,
      grammarNoteEn: data.grammarNoteEn.present
          ? data.grammarNoteEn.value
          : this.grammarNoteEn,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('promptAr: $promptAr, ')
          ..write('promptBn: $promptBn, ')
          ..write('promptEn: $promptEn, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('distractors: $distractors, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('grammarNoteBn: $grammarNoteBn, ')
          ..write('grammarNoteEn: $grammarNoteEn, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      lessonId,
      type,
      sortOrder,
      promptAr,
      promptBn,
      promptEn,
      correctAnswer,
      distractors,
      audioUrl,
      grammarNoteBn,
      grammarNoteEn,
      difficulty,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.type == this.type &&
          other.sortOrder == this.sortOrder &&
          other.promptAr == this.promptAr &&
          other.promptBn == this.promptBn &&
          other.promptEn == this.promptEn &&
          other.correctAnswer == this.correctAnswer &&
          other.distractors == this.distractors &&
          other.audioUrl == this.audioUrl &&
          other.grammarNoteBn == this.grammarNoteBn &&
          other.grammarNoteEn == this.grammarNoteEn &&
          other.difficulty == this.difficulty &&
          other.createdAt == this.createdAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> lessonId;
  final Value<String> type;
  final Value<int> sortOrder;
  final Value<String?> promptAr;
  final Value<String?> promptBn;
  final Value<String?> promptEn;
  final Value<String> correctAnswer;
  final Value<String?> distractors;
  final Value<String?> audioUrl;
  final Value<String?> grammarNoteBn;
  final Value<String?> grammarNoteEn;
  final Value<int> difficulty;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.promptAr = const Value.absent(),
    this.promptBn = const Value.absent(),
    this.promptEn = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.distractors = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.grammarNoteBn = const Value.absent(),
    this.grammarNoteEn = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String lessonId,
    required String type,
    required int sortOrder,
    this.promptAr = const Value.absent(),
    this.promptBn = const Value.absent(),
    this.promptEn = const Value.absent(),
    required String correctAnswer,
    this.distractors = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.grammarNoteBn = const Value.absent(),
    this.grammarNoteEn = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        lessonId = Value(lessonId),
        type = Value(type),
        sortOrder = Value(sortOrder),
        correctAnswer = Value(correctAnswer);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? lessonId,
    Expression<String>? type,
    Expression<int>? sortOrder,
    Expression<String>? promptAr,
    Expression<String>? promptBn,
    Expression<String>? promptEn,
    Expression<String>? correctAnswer,
    Expression<String>? distractors,
    Expression<String>? audioUrl,
    Expression<String>? grammarNoteBn,
    Expression<String>? grammarNoteEn,
    Expression<int>? difficulty,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (type != null) 'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (promptAr != null) 'prompt_ar': promptAr,
      if (promptBn != null) 'prompt_bn': promptBn,
      if (promptEn != null) 'prompt_en': promptEn,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (distractors != null) 'distractors': distractors,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (grammarNoteBn != null) 'grammar_note_bn': grammarNoteBn,
      if (grammarNoteEn != null) 'grammar_note_en': grammarNoteEn,
      if (difficulty != null) 'difficulty': difficulty,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? lessonId,
      Value<String>? type,
      Value<int>? sortOrder,
      Value<String?>? promptAr,
      Value<String?>? promptBn,
      Value<String?>? promptEn,
      Value<String>? correctAnswer,
      Value<String?>? distractors,
      Value<String?>? audioUrl,
      Value<String?>? grammarNoteBn,
      Value<String?>? grammarNoteEn,
      Value<int>? difficulty,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      promptAr: promptAr ?? this.promptAr,
      promptBn: promptBn ?? this.promptBn,
      promptEn: promptEn ?? this.promptEn,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      distractors: distractors ?? this.distractors,
      audioUrl: audioUrl ?? this.audioUrl,
      grammarNoteBn: grammarNoteBn ?? this.grammarNoteBn,
      grammarNoteEn: grammarNoteEn ?? this.grammarNoteEn,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (promptAr.present) {
      map['prompt_ar'] = Variable<String>(promptAr.value);
    }
    if (promptBn.present) {
      map['prompt_bn'] = Variable<String>(promptBn.value);
    }
    if (promptEn.present) {
      map['prompt_en'] = Variable<String>(promptEn.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (distractors.present) {
      map['distractors'] = Variable<String>(distractors.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (grammarNoteBn.present) {
      map['grammar_note_bn'] = Variable<String>(grammarNoteBn.value);
    }
    if (grammarNoteEn.present) {
      map['grammar_note_en'] = Variable<String>(grammarNoteEn.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('promptAr: $promptAr, ')
          ..write('promptBn: $promptBn, ')
          ..write('promptEn: $promptEn, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('distractors: $distractors, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('grammarNoteBn: $grammarNoteBn, ')
          ..write('grammarNoteEn: $grammarNoteEn, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabularyTable extends Vocabulary
    with TableInfo<$VocabularyTable, VocabEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arabicMeta = const VerificationMeta('arabic');
  @override
  late final GeneratedColumn<String> arabic = GeneratedColumn<String>(
      'arabic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transliterationMeta =
      const VerificationMeta('transliteration');
  @override
  late final GeneratedColumn<String> transliteration = GeneratedColumn<String>(
      'transliteration', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _meaningBnMeta =
      const VerificationMeta('meaningBn');
  @override
  late final GeneratedColumn<String> meaningBn = GeneratedColumn<String>(
      'meaning_bn', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningEnMeta =
      const VerificationMeta('meaningEn');
  @override
  late final GeneratedColumn<String> meaningEn = GeneratedColumn<String>(
      'meaning_en', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rootLettersMeta =
      const VerificationMeta('rootLetters');
  @override
  late final GeneratedColumn<String> rootLetters = GeneratedColumn<String>(
      'root_letters', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _wordTypeMeta =
      const VerificationMeta('wordType');
  @override
  late final GeneratedColumn<String> wordType = GeneratedColumn<String>(
      'word_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
      'gender', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioUrlMeta =
      const VerificationMeta('audioUrl');
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
      'audio_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _frequencyRankMeta =
      const VerificationMeta('frequencyRank');
  @override
  late final GeneratedColumn<int> frequencyRank = GeneratedColumn<int>(
      'frequency_rank', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        arabic,
        transliteration,
        meaningBn,
        meaningEn,
        rootLetters,
        wordType,
        gender,
        audioUrl,
        lessonId,
        frequencyRank,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary';
  @override
  VerificationContext validateIntegrity(Insertable<VocabEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('arabic')) {
      context.handle(_arabicMeta,
          arabic.isAcceptableOrUnknown(data['arabic']!, _arabicMeta));
    } else if (isInserting) {
      context.missing(_arabicMeta);
    }
    if (data.containsKey('transliteration')) {
      context.handle(
          _transliterationMeta,
          transliteration.isAcceptableOrUnknown(
              data['transliteration']!, _transliterationMeta));
    }
    if (data.containsKey('meaning_bn')) {
      context.handle(_meaningBnMeta,
          meaningBn.isAcceptableOrUnknown(data['meaning_bn']!, _meaningBnMeta));
    } else if (isInserting) {
      context.missing(_meaningBnMeta);
    }
    if (data.containsKey('meaning_en')) {
      context.handle(_meaningEnMeta,
          meaningEn.isAcceptableOrUnknown(data['meaning_en']!, _meaningEnMeta));
    }
    if (data.containsKey('root_letters')) {
      context.handle(
          _rootLettersMeta,
          rootLetters.isAcceptableOrUnknown(
              data['root_letters']!, _rootLettersMeta));
    }
    if (data.containsKey('word_type')) {
      context.handle(_wordTypeMeta,
          wordType.isAcceptableOrUnknown(data['word_type']!, _wordTypeMeta));
    }
    if (data.containsKey('gender')) {
      context.handle(_genderMeta,
          gender.isAcceptableOrUnknown(data['gender']!, _genderMeta));
    }
    if (data.containsKey('audio_url')) {
      context.handle(_audioUrlMeta,
          audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    }
    if (data.containsKey('frequency_rank')) {
      context.handle(
          _frequencyRankMeta,
          frequencyRank.isAcceptableOrUnknown(
              data['frequency_rank']!, _frequencyRankMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      arabic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}arabic'])!,
      transliteration: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transliteration']),
      meaningBn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning_bn'])!,
      meaningEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning_en']),
      rootLetters: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}root_letters']),
      wordType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word_type']),
      gender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}gender']),
      audioUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_url']),
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id']),
      frequencyRank: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frequency_rank']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $VocabularyTable createAlias(String alias) {
    return $VocabularyTable(attachedDatabase, alias);
  }
}

class VocabEntry extends DataClass implements Insertable<VocabEntry> {
  final String id;
  final String arabic;
  final String? transliteration;
  final String meaningBn;
  final String? meaningEn;
  final String? rootLetters;
  final String? wordType;
  final String? gender;
  final String? audioUrl;
  final String? lessonId;
  final int? frequencyRank;
  final DateTime createdAt;
  const VocabEntry(
      {required this.id,
      required this.arabic,
      this.transliteration,
      required this.meaningBn,
      this.meaningEn,
      this.rootLetters,
      this.wordType,
      this.gender,
      this.audioUrl,
      this.lessonId,
      this.frequencyRank,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['arabic'] = Variable<String>(arabic);
    if (!nullToAbsent || transliteration != null) {
      map['transliteration'] = Variable<String>(transliteration);
    }
    map['meaning_bn'] = Variable<String>(meaningBn);
    if (!nullToAbsent || meaningEn != null) {
      map['meaning_en'] = Variable<String>(meaningEn);
    }
    if (!nullToAbsent || rootLetters != null) {
      map['root_letters'] = Variable<String>(rootLetters);
    }
    if (!nullToAbsent || wordType != null) {
      map['word_type'] = Variable<String>(wordType);
    }
    if (!nullToAbsent || gender != null) {
      map['gender'] = Variable<String>(gender);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<String>(lessonId);
    }
    if (!nullToAbsent || frequencyRank != null) {
      map['frequency_rank'] = Variable<int>(frequencyRank);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VocabularyCompanion toCompanion(bool nullToAbsent) {
    return VocabularyCompanion(
      id: Value(id),
      arabic: Value(arabic),
      transliteration: transliteration == null && nullToAbsent
          ? const Value.absent()
          : Value(transliteration),
      meaningBn: Value(meaningBn),
      meaningEn: meaningEn == null && nullToAbsent
          ? const Value.absent()
          : Value(meaningEn),
      rootLetters: rootLetters == null && nullToAbsent
          ? const Value.absent()
          : Value(rootLetters),
      wordType: wordType == null && nullToAbsent
          ? const Value.absent()
          : Value(wordType),
      gender:
          gender == null && nullToAbsent ? const Value.absent() : Value(gender),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      frequencyRank: frequencyRank == null && nullToAbsent
          ? const Value.absent()
          : Value(frequencyRank),
      createdAt: Value(createdAt),
    );
  }

  factory VocabEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabEntry(
      id: serializer.fromJson<String>(json['id']),
      arabic: serializer.fromJson<String>(json['arabic']),
      transliteration: serializer.fromJson<String?>(json['transliteration']),
      meaningBn: serializer.fromJson<String>(json['meaningBn']),
      meaningEn: serializer.fromJson<String?>(json['meaningEn']),
      rootLetters: serializer.fromJson<String?>(json['rootLetters']),
      wordType: serializer.fromJson<String?>(json['wordType']),
      gender: serializer.fromJson<String?>(json['gender']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      lessonId: serializer.fromJson<String?>(json['lessonId']),
      frequencyRank: serializer.fromJson<int?>(json['frequencyRank']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'arabic': serializer.toJson<String>(arabic),
      'transliteration': serializer.toJson<String?>(transliteration),
      'meaningBn': serializer.toJson<String>(meaningBn),
      'meaningEn': serializer.toJson<String?>(meaningEn),
      'rootLetters': serializer.toJson<String?>(rootLetters),
      'wordType': serializer.toJson<String?>(wordType),
      'gender': serializer.toJson<String?>(gender),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'lessonId': serializer.toJson<String?>(lessonId),
      'frequencyRank': serializer.toJson<int?>(frequencyRank),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VocabEntry copyWith(
          {String? id,
          String? arabic,
          Value<String?> transliteration = const Value.absent(),
          String? meaningBn,
          Value<String?> meaningEn = const Value.absent(),
          Value<String?> rootLetters = const Value.absent(),
          Value<String?> wordType = const Value.absent(),
          Value<String?> gender = const Value.absent(),
          Value<String?> audioUrl = const Value.absent(),
          Value<String?> lessonId = const Value.absent(),
          Value<int?> frequencyRank = const Value.absent(),
          DateTime? createdAt}) =>
      VocabEntry(
        id: id ?? this.id,
        arabic: arabic ?? this.arabic,
        transliteration: transliteration.present
            ? transliteration.value
            : this.transliteration,
        meaningBn: meaningBn ?? this.meaningBn,
        meaningEn: meaningEn.present ? meaningEn.value : this.meaningEn,
        rootLetters: rootLetters.present ? rootLetters.value : this.rootLetters,
        wordType: wordType.present ? wordType.value : this.wordType,
        gender: gender.present ? gender.value : this.gender,
        audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
        lessonId: lessonId.present ? lessonId.value : this.lessonId,
        frequencyRank:
            frequencyRank.present ? frequencyRank.value : this.frequencyRank,
        createdAt: createdAt ?? this.createdAt,
      );
  VocabEntry copyWithCompanion(VocabularyCompanion data) {
    return VocabEntry(
      id: data.id.present ? data.id.value : this.id,
      arabic: data.arabic.present ? data.arabic.value : this.arabic,
      transliteration: data.transliteration.present
          ? data.transliteration.value
          : this.transliteration,
      meaningBn: data.meaningBn.present ? data.meaningBn.value : this.meaningBn,
      meaningEn: data.meaningEn.present ? data.meaningEn.value : this.meaningEn,
      rootLetters:
          data.rootLetters.present ? data.rootLetters.value : this.rootLetters,
      wordType: data.wordType.present ? data.wordType.value : this.wordType,
      gender: data.gender.present ? data.gender.value : this.gender,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      frequencyRank: data.frequencyRank.present
          ? data.frequencyRank.value
          : this.frequencyRank,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabEntry(')
          ..write('id: $id, ')
          ..write('arabic: $arabic, ')
          ..write('transliteration: $transliteration, ')
          ..write('meaningBn: $meaningBn, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('rootLetters: $rootLetters, ')
          ..write('wordType: $wordType, ')
          ..write('gender: $gender, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('lessonId: $lessonId, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      arabic,
      transliteration,
      meaningBn,
      meaningEn,
      rootLetters,
      wordType,
      gender,
      audioUrl,
      lessonId,
      frequencyRank,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabEntry &&
          other.id == this.id &&
          other.arabic == this.arabic &&
          other.transliteration == this.transliteration &&
          other.meaningBn == this.meaningBn &&
          other.meaningEn == this.meaningEn &&
          other.rootLetters == this.rootLetters &&
          other.wordType == this.wordType &&
          other.gender == this.gender &&
          other.audioUrl == this.audioUrl &&
          other.lessonId == this.lessonId &&
          other.frequencyRank == this.frequencyRank &&
          other.createdAt == this.createdAt);
}

class VocabularyCompanion extends UpdateCompanion<VocabEntry> {
  final Value<String> id;
  final Value<String> arabic;
  final Value<String?> transliteration;
  final Value<String> meaningBn;
  final Value<String?> meaningEn;
  final Value<String?> rootLetters;
  final Value<String?> wordType;
  final Value<String?> gender;
  final Value<String?> audioUrl;
  final Value<String?> lessonId;
  final Value<int?> frequencyRank;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VocabularyCompanion({
    this.id = const Value.absent(),
    this.arabic = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.meaningBn = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.rootLetters = const Value.absent(),
    this.wordType = const Value.absent(),
    this.gender = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyCompanion.insert({
    required String id,
    required String arabic,
    this.transliteration = const Value.absent(),
    required String meaningBn,
    this.meaningEn = const Value.absent(),
    this.rootLetters = const Value.absent(),
    this.wordType = const Value.absent(),
    this.gender = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.frequencyRank = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        arabic = Value(arabic),
        meaningBn = Value(meaningBn);
  static Insertable<VocabEntry> custom({
    Expression<String>? id,
    Expression<String>? arabic,
    Expression<String>? transliteration,
    Expression<String>? meaningBn,
    Expression<String>? meaningEn,
    Expression<String>? rootLetters,
    Expression<String>? wordType,
    Expression<String>? gender,
    Expression<String>? audioUrl,
    Expression<String>? lessonId,
    Expression<int>? frequencyRank,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (arabic != null) 'arabic': arabic,
      if (transliteration != null) 'transliteration': transliteration,
      if (meaningBn != null) 'meaning_bn': meaningBn,
      if (meaningEn != null) 'meaning_en': meaningEn,
      if (rootLetters != null) 'root_letters': rootLetters,
      if (wordType != null) 'word_type': wordType,
      if (gender != null) 'gender': gender,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (lessonId != null) 'lesson_id': lessonId,
      if (frequencyRank != null) 'frequency_rank': frequencyRank,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyCompanion copyWith(
      {Value<String>? id,
      Value<String>? arabic,
      Value<String?>? transliteration,
      Value<String>? meaningBn,
      Value<String?>? meaningEn,
      Value<String?>? rootLetters,
      Value<String?>? wordType,
      Value<String?>? gender,
      Value<String?>? audioUrl,
      Value<String?>? lessonId,
      Value<int?>? frequencyRank,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return VocabularyCompanion(
      id: id ?? this.id,
      arabic: arabic ?? this.arabic,
      transliteration: transliteration ?? this.transliteration,
      meaningBn: meaningBn ?? this.meaningBn,
      meaningEn: meaningEn ?? this.meaningEn,
      rootLetters: rootLetters ?? this.rootLetters,
      wordType: wordType ?? this.wordType,
      gender: gender ?? this.gender,
      audioUrl: audioUrl ?? this.audioUrl,
      lessonId: lessonId ?? this.lessonId,
      frequencyRank: frequencyRank ?? this.frequencyRank,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (arabic.present) {
      map['arabic'] = Variable<String>(arabic.value);
    }
    if (transliteration.present) {
      map['transliteration'] = Variable<String>(transliteration.value);
    }
    if (meaningBn.present) {
      map['meaning_bn'] = Variable<String>(meaningBn.value);
    }
    if (meaningEn.present) {
      map['meaning_en'] = Variable<String>(meaningEn.value);
    }
    if (rootLetters.present) {
      map['root_letters'] = Variable<String>(rootLetters.value);
    }
    if (wordType.present) {
      map['word_type'] = Variable<String>(wordType.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (frequencyRank.present) {
      map['frequency_rank'] = Variable<int>(frequencyRank.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyCompanion(')
          ..write('id: $id, ')
          ..write('arabic: $arabic, ')
          ..write('transliteration: $transliteration, ')
          ..write('meaningBn: $meaningBn, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('rootLetters: $rootLetters, ')
          ..write('wordType: $wordType, ')
          ..write('gender: $gender, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('lessonId: $lessonId, ')
          ..write('frequencyRank: $frequencyRank, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SrsCardsTable extends SrsCards with TableInfo<$SrsCardsTable, SrsCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vocabularyIdMeta =
      const VerificationMeta('vocabularyId');
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
      'vocabulary_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES vocabulary (id)'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _stabilityMeta =
      const VerificationMeta('stability');
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
      'stability', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _elapsedDaysMeta =
      const VerificationMeta('elapsedDays');
  @override
  late final GeneratedColumn<int> elapsedDays = GeneratedColumn<int>(
      'elapsed_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _scheduledDaysMeta =
      const VerificationMeta('scheduledDays');
  @override
  late final GeneratedColumn<int> scheduledDays = GeneratedColumn<int>(
      'scheduled_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
      'lapses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
      'state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewMeta =
      const VerificationMeta('lastReview');
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
      'last_review', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        vocabularyId,
        dueDate,
        stability,
        difficulty,
        elapsedDays,
        scheduledDays,
        reps,
        lapses,
        state,
        lastReview,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_cards';
  @override
  VerificationContext validateIntegrity(Insertable<SrsCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
          _vocabularyIdMeta,
          vocabularyId.isAcceptableOrUnknown(
              data['vocabulary_id']!, _vocabularyIdMeta));
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('stability')) {
      context.handle(_stabilityMeta,
          stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('elapsed_days')) {
      context.handle(
          _elapsedDaysMeta,
          elapsedDays.isAcceptableOrUnknown(
              data['elapsed_days']!, _elapsedDaysMeta));
    }
    if (data.containsKey('scheduled_days')) {
      context.handle(
          _scheduledDaysMeta,
          scheduledDays.isAcceptableOrUnknown(
              data['scheduled_days']!, _scheduledDaysMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta,
          lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    }
    if (data.containsKey('last_review')) {
      context.handle(
          _lastReviewMeta,
          lastReview.isAcceptableOrUnknown(
              data['last_review']!, _lastReviewMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SrsCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      vocabularyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vocabulary_id'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date'])!,
      stability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stability'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difficulty'])!,
      elapsedDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_days'])!,
      scheduledDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}scheduled_days'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      lapses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state'])!,
      lastReview: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_review']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $SrsCardsTable createAlias(String alias) {
    return $SrsCardsTable(attachedDatabase, alias);
  }
}

class SrsCard extends DataClass implements Insertable<SrsCard> {
  final String id;
  final String userId;
  final String vocabularyId;
  final DateTime dueDate;
  final double stability;
  final double difficulty;
  final int elapsedDays;
  final int scheduledDays;
  final int reps;
  final int lapses;
  final int state;
  final DateTime? lastReview;
  final DateTime? syncedAt;
  const SrsCard(
      {required this.id,
      required this.userId,
      required this.vocabularyId,
      required this.dueDate,
      required this.stability,
      required this.difficulty,
      required this.elapsedDays,
      required this.scheduledDays,
      required this.reps,
      required this.lapses,
      required this.state,
      this.lastReview,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['elapsed_days'] = Variable<int>(elapsedDays);
    map['scheduled_days'] = Variable<int>(scheduledDays);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['state'] = Variable<int>(state);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  SrsCardsCompanion toCompanion(bool nullToAbsent) {
    return SrsCardsCompanion(
      id: Value(id),
      userId: Value(userId),
      vocabularyId: Value(vocabularyId),
      dueDate: Value(dueDate),
      stability: Value(stability),
      difficulty: Value(difficulty),
      elapsedDays: Value(elapsedDays),
      scheduledDays: Value(scheduledDays),
      reps: Value(reps),
      lapses: Value(lapses),
      state: Value(state),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SrsCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsCard(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      elapsedDays: serializer.fromJson<int>(json['elapsedDays']),
      scheduledDays: serializer.fromJson<int>(json['scheduledDays']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      state: serializer.fromJson<int>(json['state']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'elapsedDays': serializer.toJson<int>(elapsedDays),
      'scheduledDays': serializer.toJson<int>(scheduledDays),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'state': serializer.toJson<int>(state),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  SrsCard copyWith(
          {String? id,
          String? userId,
          String? vocabularyId,
          DateTime? dueDate,
          double? stability,
          double? difficulty,
          int? elapsedDays,
          int? scheduledDays,
          int? reps,
          int? lapses,
          int? state,
          Value<DateTime?> lastReview = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      SrsCard(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        vocabularyId: vocabularyId ?? this.vocabularyId,
        dueDate: dueDate ?? this.dueDate,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        elapsedDays: elapsedDays ?? this.elapsedDays,
        scheduledDays: scheduledDays ?? this.scheduledDays,
        reps: reps ?? this.reps,
        lapses: lapses ?? this.lapses,
        state: state ?? this.state,
        lastReview: lastReview.present ? lastReview.value : this.lastReview,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  SrsCard copyWithCompanion(SrsCardsCompanion data) {
    return SrsCard(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      elapsedDays:
          data.elapsedDays.present ? data.elapsedDays.value : this.elapsedDays,
      scheduledDays: data.scheduledDays.present
          ? data.scheduledDays.value
          : this.scheduledDays,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      state: data.state.present ? data.state.value : this.state,
      lastReview:
          data.lastReview.present ? data.lastReview.value : this.lastReview,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsCard(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('dueDate: $dueDate, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('state: $state, ')
          ..write('lastReview: $lastReview, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      vocabularyId,
      dueDate,
      stability,
      difficulty,
      elapsedDays,
      scheduledDays,
      reps,
      lapses,
      state,
      lastReview,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsCard &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.vocabularyId == this.vocabularyId &&
          other.dueDate == this.dueDate &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.elapsedDays == this.elapsedDays &&
          other.scheduledDays == this.scheduledDays &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.state == this.state &&
          other.lastReview == this.lastReview &&
          other.syncedAt == this.syncedAt);
}

class SrsCardsCompanion extends UpdateCompanion<SrsCard> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> vocabularyId;
  final Value<DateTime> dueDate;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<int> elapsedDays;
  final Value<int> scheduledDays;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> state;
  final Value<DateTime?> lastReview;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const SrsCardsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.state = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SrsCardsCompanion.insert({
    required String id,
    required String userId,
    required String vocabularyId,
    this.dueDate = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.elapsedDays = const Value.absent(),
    this.scheduledDays = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.state = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        vocabularyId = Value(vocabularyId);
  static Insertable<SrsCard> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? vocabularyId,
    Expression<DateTime>? dueDate,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<int>? elapsedDays,
    Expression<int>? scheduledDays,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? state,
    Expression<DateTime>? lastReview,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (dueDate != null) 'due_date': dueDate,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (elapsedDays != null) 'elapsed_days': elapsedDays,
      if (scheduledDays != null) 'scheduled_days': scheduledDays,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (state != null) 'state': state,
      if (lastReview != null) 'last_review': lastReview,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SrsCardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? vocabularyId,
      Value<DateTime>? dueDate,
      Value<double>? stability,
      Value<double>? difficulty,
      Value<int>? elapsedDays,
      Value<int>? scheduledDays,
      Value<int>? reps,
      Value<int>? lapses,
      Value<int>? state,
      Value<DateTime?>? lastReview,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return SrsCardsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      dueDate: dueDate ?? this.dueDate,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      elapsedDays: elapsedDays ?? this.elapsedDays,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      state: state ?? this.state,
      lastReview: lastReview ?? this.lastReview,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (elapsedDays.present) {
      map['elapsed_days'] = Variable<int>(elapsedDays.value);
    }
    if (scheduledDays.present) {
      map['scheduled_days'] = Variable<int>(scheduledDays.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('dueDate: $dueDate, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('elapsedDays: $elapsedDays, ')
          ..write('scheduledDays: $scheduledDays, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('state: $state, ')
          ..write('lastReview: $lastReview, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProgressTable extends UserProgress
    with TableInfo<$UserProgressTable, UserProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _xpEarnedMeta =
      const VerificationMeta('xpEarned');
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
      'xp_earned', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _accuracyPctMeta =
      const VerificationMeta('accuracyPct');
  @override
  late final GeneratedColumn<int> accuracyPct = GeneratedColumn<int>(
      'accuracy_pct', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _heartsRemainingMeta =
      const VerificationMeta('heartsRemaining');
  @override
  late final GeneratedColumn<int> heartsRemaining = GeneratedColumn<int>(
      'hearts_remaining', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        lessonId,
        completedAt,
        xpEarned,
        accuracyPct,
        heartsRemaining,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_progress';
  @override
  VerificationContext validateIntegrity(Insertable<UserProgressEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('xp_earned')) {
      context.handle(_xpEarnedMeta,
          xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta));
    }
    if (data.containsKey('accuracy_pct')) {
      context.handle(
          _accuracyPctMeta,
          accuracyPct.isAcceptableOrUnknown(
              data['accuracy_pct']!, _accuracyPctMeta));
    }
    if (data.containsKey('hearts_remaining')) {
      context.handle(
          _heartsRemainingMeta,
          heartsRemaining.isAcceptableOrUnknown(
              data['hearts_remaining']!, _heartsRemainingMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProgressEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      xpEarned: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_earned'])!,
      accuracyPct: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accuracy_pct'])!,
      heartsRemaining: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hearts_remaining'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $UserProgressTable createAlias(String alias) {
    return $UserProgressTable(attachedDatabase, alias);
  }
}

class UserProgressEntry extends DataClass
    implements Insertable<UserProgressEntry> {
  final String id;
  final String userId;
  final String lessonId;
  final DateTime completedAt;
  final int xpEarned;
  final int accuracyPct;
  final int heartsRemaining;
  final DateTime? syncedAt;
  const UserProgressEntry(
      {required this.id,
      required this.userId,
      required this.lessonId,
      required this.completedAt,
      required this.xpEarned,
      required this.accuracyPct,
      required this.heartsRemaining,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['xp_earned'] = Variable<int>(xpEarned);
    map['accuracy_pct'] = Variable<int>(accuracyPct);
    map['hearts_remaining'] = Variable<int>(heartsRemaining);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  UserProgressCompanion toCompanion(bool nullToAbsent) {
    return UserProgressCompanion(
      id: Value(id),
      userId: Value(userId),
      lessonId: Value(lessonId),
      completedAt: Value(completedAt),
      xpEarned: Value(xpEarned),
      accuracyPct: Value(accuracyPct),
      heartsRemaining: Value(heartsRemaining),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory UserProgressEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProgressEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      accuracyPct: serializer.fromJson<int>(json['accuracyPct']),
      heartsRemaining: serializer.fromJson<int>(json['heartsRemaining']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'lessonId': serializer.toJson<String>(lessonId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'accuracyPct': serializer.toJson<int>(accuracyPct),
      'heartsRemaining': serializer.toJson<int>(heartsRemaining),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  UserProgressEntry copyWith(
          {String? id,
          String? userId,
          String? lessonId,
          DateTime? completedAt,
          int? xpEarned,
          int? accuracyPct,
          int? heartsRemaining,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      UserProgressEntry(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        lessonId: lessonId ?? this.lessonId,
        completedAt: completedAt ?? this.completedAt,
        xpEarned: xpEarned ?? this.xpEarned,
        accuracyPct: accuracyPct ?? this.accuracyPct,
        heartsRemaining: heartsRemaining ?? this.heartsRemaining,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  UserProgressEntry copyWithCompanion(UserProgressCompanion data) {
    return UserProgressEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      accuracyPct:
          data.accuracyPct.present ? data.accuracyPct.value : this.accuracyPct,
      heartsRemaining: data.heartsRemaining.present
          ? data.heartsRemaining.value
          : this.heartsRemaining,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('lessonId: $lessonId, ')
          ..write('completedAt: $completedAt, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('accuracyPct: $accuracyPct, ')
          ..write('heartsRemaining: $heartsRemaining, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, lessonId, completedAt, xpEarned,
      accuracyPct, heartsRemaining, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProgressEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.lessonId == this.lessonId &&
          other.completedAt == this.completedAt &&
          other.xpEarned == this.xpEarned &&
          other.accuracyPct == this.accuracyPct &&
          other.heartsRemaining == this.heartsRemaining &&
          other.syncedAt == this.syncedAt);
}

class UserProgressCompanion extends UpdateCompanion<UserProgressEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> lessonId;
  final Value<DateTime> completedAt;
  final Value<int> xpEarned;
  final Value<int> accuracyPct;
  final Value<int> heartsRemaining;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const UserProgressCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.accuracyPct = const Value.absent(),
    this.heartsRemaining = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProgressCompanion.insert({
    required String id,
    required String userId,
    required String lessonId,
    this.completedAt = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.accuracyPct = const Value.absent(),
    this.heartsRemaining = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        lessonId = Value(lessonId);
  static Insertable<UserProgressEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? lessonId,
    Expression<DateTime>? completedAt,
    Expression<int>? xpEarned,
    Expression<int>? accuracyPct,
    Expression<int>? heartsRemaining,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (completedAt != null) 'completed_at': completedAt,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (accuracyPct != null) 'accuracy_pct': accuracyPct,
      if (heartsRemaining != null) 'hearts_remaining': heartsRemaining,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProgressCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? lessonId,
      Value<DateTime>? completedAt,
      Value<int>? xpEarned,
      Value<int>? accuracyPct,
      Value<int>? heartsRemaining,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return UserProgressCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      completedAt: completedAt ?? this.completedAt,
      xpEarned: xpEarned ?? this.xpEarned,
      accuracyPct: accuracyPct ?? this.accuracyPct,
      heartsRemaining: heartsRemaining ?? this.heartsRemaining,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (accuracyPct.present) {
      map['accuracy_pct'] = Variable<int>(accuracyPct.value);
    }
    if (heartsRemaining.present) {
      map['hearts_remaining'] = Variable<int>(heartsRemaining.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProgressCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('lessonId: $lessonId, ')
          ..write('completedAt: $completedAt, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('accuracyPct: $accuracyPct, ')
          ..write('heartsRemaining: $heartsRemaining, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreaksTable extends Streaks with TableInfo<$StreaksTable, Streak> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentStreakMeta =
      const VerificationMeta('currentStreak');
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
      'current_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _longestStreakMeta =
      const VerificationMeta('longestStreak');
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
      'longest_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastActivityDateMeta =
      const VerificationMeta('lastActivityDate');
  @override
  late final GeneratedColumn<DateTime> lastActivityDate =
      GeneratedColumn<DateTime>('last_activity_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalXpMeta =
      const VerificationMeta('totalXp');
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
      'total_xp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _freezeCountMeta =
      const VerificationMeta('freezeCount');
  @override
  late final GeneratedColumn<int> freezeCount = GeneratedColumn<int>(
      'freeze_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastFreezedAtMeta =
      const VerificationMeta('lastFreezedAt');
  @override
  late final GeneratedColumn<DateTime> lastFreezedAt =
      GeneratedColumn<DateTime>('last_freezed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        currentStreak,
        longestStreak,
        lastActivityDate,
        totalXp,
        freezeCount,
        lastFreezedAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streaks';
  @override
  VerificationContext validateIntegrity(Insertable<Streak> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('current_streak')) {
      context.handle(
          _currentStreakMeta,
          currentStreak.isAcceptableOrUnknown(
              data['current_streak']!, _currentStreakMeta));
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
          _longestStreakMeta,
          longestStreak.isAcceptableOrUnknown(
              data['longest_streak']!, _longestStreakMeta));
    }
    if (data.containsKey('last_activity_date')) {
      context.handle(
          _lastActivityDateMeta,
          lastActivityDate.isAcceptableOrUnknown(
              data['last_activity_date']!, _lastActivityDateMeta));
    }
    if (data.containsKey('total_xp')) {
      context.handle(_totalXpMeta,
          totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta));
    }
    if (data.containsKey('freeze_count')) {
      context.handle(
          _freezeCountMeta,
          freezeCount.isAcceptableOrUnknown(
              data['freeze_count']!, _freezeCountMeta));
    }
    if (data.containsKey('last_freezed_at')) {
      context.handle(
          _lastFreezedAtMeta,
          lastFreezedAt.isAcceptableOrUnknown(
              data['last_freezed_at']!, _lastFreezedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  Streak map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Streak(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      currentStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_streak'])!,
      longestStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}longest_streak'])!,
      lastActivityDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_activity_date']),
      totalXp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_xp'])!,
      freezeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}freeze_count'])!,
      lastFreezedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_freezed_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StreaksTable createAlias(String alias) {
    return $StreaksTable(attachedDatabase, alias);
  }
}

class Streak extends DataClass implements Insertable<Streak> {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalXp;
  final int freezeCount;
  final DateTime? lastFreezedAt;
  final DateTime updatedAt;
  const Streak(
      {required this.userId,
      required this.currentStreak,
      required this.longestStreak,
      this.lastActivityDate,
      required this.totalXp,
      required this.freezeCount,
      this.lastFreezedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['current_streak'] = Variable<int>(currentStreak);
    map['longest_streak'] = Variable<int>(longestStreak);
    if (!nullToAbsent || lastActivityDate != null) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate);
    }
    map['total_xp'] = Variable<int>(totalXp);
    map['freeze_count'] = Variable<int>(freezeCount);
    if (!nullToAbsent || lastFreezedAt != null) {
      map['last_freezed_at'] = Variable<DateTime>(lastFreezedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StreaksCompanion toCompanion(bool nullToAbsent) {
    return StreaksCompanion(
      userId: Value(userId),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      lastActivityDate: lastActivityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityDate),
      totalXp: Value(totalXp),
      freezeCount: Value(freezeCount),
      lastFreezedAt: lastFreezedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFreezedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Streak.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Streak(
      userId: serializer.fromJson<String>(json['userId']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      lastActivityDate:
          serializer.fromJson<DateTime?>(json['lastActivityDate']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      freezeCount: serializer.fromJson<int>(json['freezeCount']),
      lastFreezedAt: serializer.fromJson<DateTime?>(json['lastFreezedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'lastActivityDate': serializer.toJson<DateTime?>(lastActivityDate),
      'totalXp': serializer.toJson<int>(totalXp),
      'freezeCount': serializer.toJson<int>(freezeCount),
      'lastFreezedAt': serializer.toJson<DateTime?>(lastFreezedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Streak copyWith(
          {String? userId,
          int? currentStreak,
          int? longestStreak,
          Value<DateTime?> lastActivityDate = const Value.absent(),
          int? totalXp,
          int? freezeCount,
          Value<DateTime?> lastFreezedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      Streak(
        userId: userId ?? this.userId,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastActivityDate: lastActivityDate.present
            ? lastActivityDate.value
            : this.lastActivityDate,
        totalXp: totalXp ?? this.totalXp,
        freezeCount: freezeCount ?? this.freezeCount,
        lastFreezedAt:
            lastFreezedAt.present ? lastFreezedAt.value : this.lastFreezedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Streak copyWithCompanion(StreaksCompanion data) {
    return Streak(
      userId: data.userId.present ? data.userId.value : this.userId,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      lastActivityDate: data.lastActivityDate.present
          ? data.lastActivityDate.value
          : this.lastActivityDate,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      freezeCount:
          data.freezeCount.present ? data.freezeCount.value : this.freezeCount,
      lastFreezedAt: data.lastFreezedAt.present
          ? data.lastFreezedAt.value
          : this.lastFreezedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Streak(')
          ..write('userId: $userId, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('totalXp: $totalXp, ')
          ..write('freezeCount: $freezeCount, ')
          ..write('lastFreezedAt: $lastFreezedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, currentStreak, longestStreak,
      lastActivityDate, totalXp, freezeCount, lastFreezedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Streak &&
          other.userId == this.userId &&
          other.currentStreak == this.currentStreak &&
          other.longestStreak == this.longestStreak &&
          other.lastActivityDate == this.lastActivityDate &&
          other.totalXp == this.totalXp &&
          other.freezeCount == this.freezeCount &&
          other.lastFreezedAt == this.lastFreezedAt &&
          other.updatedAt == this.updatedAt);
}

class StreaksCompanion extends UpdateCompanion<Streak> {
  final Value<String> userId;
  final Value<int> currentStreak;
  final Value<int> longestStreak;
  final Value<DateTime?> lastActivityDate;
  final Value<int> totalXp;
  final Value<int> freezeCount;
  final Value<DateTime?> lastFreezedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StreaksCompanion({
    this.userId = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.freezeCount = const Value.absent(),
    this.lastFreezedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreaksCompanion.insert({
    required String userId,
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.freezeCount = const Value.absent(),
    this.lastFreezedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<Streak> custom({
    Expression<String>? userId,
    Expression<int>? currentStreak,
    Expression<int>? longestStreak,
    Expression<DateTime>? lastActivityDate,
    Expression<int>? totalXp,
    Expression<int>? freezeCount,
    Expression<DateTime>? lastFreezedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (lastActivityDate != null) 'last_activity_date': lastActivityDate,
      if (totalXp != null) 'total_xp': totalXp,
      if (freezeCount != null) 'freeze_count': freezeCount,
      if (lastFreezedAt != null) 'last_freezed_at': lastFreezedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreaksCompanion copyWith(
      {Value<String>? userId,
      Value<int>? currentStreak,
      Value<int>? longestStreak,
      Value<DateTime?>? lastActivityDate,
      Value<int>? totalXp,
      Value<int>? freezeCount,
      Value<DateTime?>? lastFreezedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StreaksCompanion(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalXp: totalXp ?? this.totalXp,
      freezeCount: freezeCount ?? this.freezeCount,
      lastFreezedAt: lastFreezedAt ?? this.lastFreezedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (lastActivityDate.present) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (freezeCount.present) {
      map['freeze_count'] = Variable<int>(freezeCount.value);
    }
    if (lastFreezedAt.present) {
      map['last_freezed_at'] = Variable<DateTime>(lastFreezedAt.value);
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
    return (StringBuffer('StreaksCompanion(')
          ..write('userId: $userId, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('totalXp: $totalXp, ')
          ..write('freezeCount: $freezeCount, ')
          ..write('lastFreezedAt: $lastFreezedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncTable extends PendingSync
    with TableInfo<$PendingSyncTable, PendingSyncEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _isProcessingMeta =
      const VerificationMeta('isProcessing');
  @override
  late final GeneratedColumn<bool> isProcessing = GeneratedColumn<bool>(
      'is_processing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_processing" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, action, payload, createdAt, isProcessing];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync';
  @override
  VerificationContext validateIntegrity(Insertable<PendingSyncEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('is_processing')) {
      context.handle(
          _isProcessingMeta,
          isProcessing.isAcceptableOrUnknown(
              data['is_processing']!, _isProcessingMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      isProcessing: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_processing'])!,
    );
  }

  @override
  $PendingSyncTable createAlias(String alias) {
    return $PendingSyncTable(attachedDatabase, alias);
  }
}

class PendingSyncEntry extends DataClass
    implements Insertable<PendingSyncEntry> {
  final int id;
  final String action;
  final String payload;
  final DateTime createdAt;
  final bool isProcessing;
  const PendingSyncEntry(
      {required this.id,
      required this.action,
      required this.payload,
      required this.createdAt,
      required this.isProcessing});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_processing'] = Variable<bool>(isProcessing);
    return map;
  }

  PendingSyncCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncCompanion(
      id: Value(id),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
      isProcessing: Value(isProcessing),
    );
  }

  factory PendingSyncEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncEntry(
      id: serializer.fromJson<int>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isProcessing: serializer.fromJson<bool>(json['isProcessing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isProcessing': serializer.toJson<bool>(isProcessing),
    };
  }

  PendingSyncEntry copyWith(
          {int? id,
          String? action,
          String? payload,
          DateTime? createdAt,
          bool? isProcessing}) =>
      PendingSyncEntry(
        id: id ?? this.id,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        isProcessing: isProcessing ?? this.isProcessing,
      );
  PendingSyncEntry copyWithCompanion(PendingSyncCompanion data) {
    return PendingSyncEntry(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isProcessing: data.isProcessing.present
          ? data.isProcessing.value
          : this.isProcessing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncEntry(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('isProcessing: $isProcessing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, action, payload, createdAt, isProcessing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncEntry &&
          other.id == this.id &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.isProcessing == this.isProcessing);
}

class PendingSyncCompanion extends UpdateCompanion<PendingSyncEntry> {
  final Value<int> id;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<bool> isProcessing;
  const PendingSyncCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isProcessing = const Value.absent(),
  });
  PendingSyncCompanion.insert({
    this.id = const Value.absent(),
    required String action,
    required String payload,
    this.createdAt = const Value.absent(),
    this.isProcessing = const Value.absent(),
  })  : action = Value(action),
        payload = Value(payload);
  static Insertable<PendingSyncEntry> custom({
    Expression<int>? id,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<bool>? isProcessing,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (isProcessing != null) 'is_processing': isProcessing,
    });
  }

  PendingSyncCompanion copyWith(
      {Value<int>? id,
      Value<String>? action,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<bool>? isProcessing}) {
    return PendingSyncCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isProcessing.present) {
      map['is_processing'] = Variable<bool>(isProcessing.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('isProcessing: $isProcessing')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES lessons (id)'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, userId, lessonId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String userId;
  final String lessonId;
  final DateTime createdAt;
  const Bookmark(
      {required this.id,
      required this.userId,
      required this.lessonId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      userId: Value(userId),
      lessonId: Value(lessonId),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'lessonId': serializer.toJson<String>(lessonId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith(
          {String? id,
          String? userId,
          String? lessonId,
          DateTime? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        lessonId: lessonId ?? this.lessonId,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('lessonId: $lessonId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, lessonId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.lessonId == this.lessonId &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> lessonId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String userId,
    required String lessonId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        lessonId = Value(lessonId);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? lessonId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? lessonId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return BookmarksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('lessonId: $lessonId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $VocabularyTable vocabulary = $VocabularyTable(this);
  late final $SrsCardsTable srsCards = $SrsCardsTable(this);
  late final $UserProgressTable userProgress = $UserProgressTable(this);
  late final $StreaksTable streaks = $StreaksTable(this);
  late final $PendingSyncTable pendingSync = $PendingSyncTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        tracks,
        units,
        lessons,
        exercises,
        vocabulary,
        srsCards,
        userProgress,
        streaks,
        pendingSync,
        bookmarks
      ];
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  required String id,
  required String slug,
  required String nameAr,
  required String nameBn,
  required String nameEn,
  Value<String?> descriptionBn,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> id,
  Value<String> slug,
  Value<String> nameAr,
  Value<String> nameBn,
  Value<String> nameEn,
  Value<String?> descriptionBn,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UnitsTable, List<Unit>> _unitsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.units,
          aliasName: $_aliasNameGenerator(db.tracks.id, db.units.trackId));

  $$UnitsTableProcessedTableManager get unitsRefs {
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_unitsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameAr => $composableBuilder(
      column: $table.nameAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameBn => $composableBuilder(
      column: $table.nameBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descriptionBn => $composableBuilder(
      column: $table.descriptionBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> unitsRefs(
      Expression<bool> Function($$UnitsTableFilterComposer f) f) {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.trackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameAr => $composableBuilder(
      column: $table.nameAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameBn => $composableBuilder(
      column: $table.nameBn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descriptionBn => $composableBuilder(
      column: $table.descriptionBn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameBn =>
      $composableBuilder(column: $table.nameBn, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get descriptionBn => $composableBuilder(
      column: $table.descriptionBn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> unitsRefs<T extends Object>(
      Expression<T> Function($$UnitsTableAnnotationComposer a) f) {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.trackId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TracksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableAnnotationComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder,
    (Track, $$TracksTableReferences),
    Track,
    PrefetchHooks Function({bool unitsRefs})> {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String> nameAr = const Value.absent(),
            Value<String> nameBn = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String?> descriptionBn = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TracksCompanion(
            id: id,
            slug: slug,
            nameAr: nameAr,
            nameBn: nameBn,
            nameEn: nameEn,
            descriptionBn: descriptionBn,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String slug,
            required String nameAr,
            required String nameBn,
            required String nameEn,
            Value<String?> descriptionBn = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TracksCompanion.insert(
            id: id,
            slug: slug,
            nameAr: nameAr,
            nameBn: nameBn,
            nameEn: nameEn,
            descriptionBn: descriptionBn,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TracksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({unitsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (unitsRefs) db.units],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (unitsRefs)
                    await $_getPrefetchedData<Track, $TracksTable, Unit>(
                        currentTable: table,
                        referencedTable:
                            $$TracksTableReferences._unitsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TracksTableReferences(db, table, p0).unitsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.trackId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TracksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TracksTable,
    Track,
    $$TracksTableFilterComposer,
    $$TracksTableOrderingComposer,
    $$TracksTableAnnotationComposer,
    $$TracksTableCreateCompanionBuilder,
    $$TracksTableUpdateCompanionBuilder,
    (Track, $$TracksTableReferences),
    Track,
    PrefetchHooks Function({bool unitsRefs})>;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  required String id,
  required String trackId,
  required String slug,
  Value<String?> titleAr,
  required String titleBn,
  Value<String?> titleEn,
  Value<String?> descriptionBn,
  required int sortOrder,
  Value<String> status,
  Value<String?> sourceMaterialId,
  Value<DateTime> createdAt,
  Value<DateTime?> downloadedAt,
  Value<int> rowid,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<String> id,
  Value<String> trackId,
  Value<String> slug,
  Value<String?> titleAr,
  Value<String> titleBn,
  Value<String?> titleEn,
  Value<String?> descriptionBn,
  Value<int> sortOrder,
  Value<String> status,
  Value<String?> sourceMaterialId,
  Value<DateTime> createdAt,
  Value<DateTime?> downloadedAt,
  Value<int> rowid,
});

final class $$UnitsTableReferences
    extends BaseReferences<_$AppDatabase, $UnitsTable, Unit> {
  $$UnitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks
      .createAlias($_aliasNameGenerator(db.units.trackId, db.tracks.id));

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableManager($_db, $_db.tracks)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LessonsTable, List<Lesson>> _lessonsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.lessons,
          aliasName: $_aliasNameGenerator(db.units.id, db.lessons.unitId));

  $$LessonsTableProcessedTableManager get lessonsRefs {
    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleAr => $composableBuilder(
      column: $table.titleAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleBn => $composableBuilder(
      column: $table.titleBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleEn => $composableBuilder(
      column: $table.titleEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descriptionBn => $composableBuilder(
      column: $table.descriptionBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceMaterialId => $composableBuilder(
      column: $table.sourceMaterialId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.trackId,
        referencedTable: $db.tracks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TracksTableFilterComposer(
              $db: $db,
              $table: $db.tracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> lessonsRefs(
      Expression<bool> Function($$LessonsTableFilterComposer f) f) {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleAr => $composableBuilder(
      column: $table.titleAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleBn => $composableBuilder(
      column: $table.titleBn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleEn => $composableBuilder(
      column: $table.titleEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descriptionBn => $composableBuilder(
      column: $table.descriptionBn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceMaterialId => $composableBuilder(
      column: $table.sourceMaterialId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.trackId,
        referencedTable: $db.tracks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TracksTableOrderingComposer(
              $db: $db,
              $table: $db.tracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<String> get titleBn =>
      $composableBuilder(column: $table.titleBn, builder: (column) => column);

  GeneratedColumn<String> get titleEn =>
      $composableBuilder(column: $table.titleEn, builder: (column) => column);

  GeneratedColumn<String> get descriptionBn => $composableBuilder(
      column: $table.descriptionBn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sourceMaterialId => $composableBuilder(
      column: $table.sourceMaterialId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.trackId,
        referencedTable: $db.tracks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TracksTableAnnotationComposer(
              $db: $db,
              $table: $db.tracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> lessonsRefs<T extends Object>(
      Expression<T> Function($$LessonsTableAnnotationComposer a) f) {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (Unit, $$UnitsTableReferences),
    Unit,
    PrefetchHooks Function({bool trackId, bool lessonsRefs})> {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> trackId = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<String?> titleAr = const Value.absent(),
            Value<String> titleBn = const Value.absent(),
            Value<String?> titleEn = const Value.absent(),
            Value<String?> descriptionBn = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> sourceMaterialId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            trackId: trackId,
            slug: slug,
            titleAr: titleAr,
            titleBn: titleBn,
            titleEn: titleEn,
            descriptionBn: descriptionBn,
            sortOrder: sortOrder,
            status: status,
            sourceMaterialId: sourceMaterialId,
            createdAt: createdAt,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String trackId,
            required String slug,
            Value<String?> titleAr = const Value.absent(),
            required String titleBn,
            Value<String?> titleEn = const Value.absent(),
            Value<String?> descriptionBn = const Value.absent(),
            required int sortOrder,
            Value<String> status = const Value.absent(),
            Value<String?> sourceMaterialId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> downloadedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UnitsCompanion.insert(
            id: id,
            trackId: trackId,
            slug: slug,
            titleAr: titleAr,
            titleBn: titleBn,
            titleEn: titleEn,
            descriptionBn: descriptionBn,
            sortOrder: sortOrder,
            status: status,
            sourceMaterialId: sourceMaterialId,
            createdAt: createdAt,
            downloadedAt: downloadedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UnitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({trackId = false, lessonsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lessonsRefs) db.lessons],
              addJoins: <
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
                      dynamic>>(state) {
                if (trackId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.trackId,
                    referencedTable: $$UnitsTableReferences._trackIdTable(db),
                    referencedColumn:
                        $$UnitsTableReferences._trackIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lessonsRefs)
                    await $_getPrefetchedData<Unit, $UnitsTable, Lesson>(
                        currentTable: table,
                        referencedTable:
                            $$UnitsTableReferences._lessonsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0).lessonsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UnitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UnitsTable,
    Unit,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (Unit, $$UnitsTableReferences),
    Unit,
    PrefetchHooks Function({bool trackId, bool lessonsRefs})>;
typedef $$LessonsTableCreateCompanionBuilder = LessonsCompanion Function({
  required String id,
  required String unitId,
  required String titleBn,
  Value<String?> titleAr,
  required int sortOrder,
  Value<int> xpReward,
  Value<String> status,
  Value<String> level,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$LessonsTableUpdateCompanionBuilder = LessonsCompanion Function({
  Value<String> id,
  Value<String> unitId,
  Value<String> titleBn,
  Value<String?> titleAr,
  Value<int> sortOrder,
  Value<int> xpReward,
  Value<String> status,
  Value<String> level,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$LessonsTableReferences
    extends BaseReferences<_$AppDatabase, $LessonsTable, Lesson> {
  $$LessonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UnitsTable _unitIdTable(_$AppDatabase db) => db.units
      .createAlias($_aliasNameGenerator(db.lessons.unitId, db.units.id));

  $$UnitsTableProcessedTableManager get unitId {
    final $_column = $_itemColumn<String>('unit_id')!;

    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ExercisesTable, List<Exercise>>
      _exercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.exercises,
              aliasName:
                  $_aliasNameGenerator(db.lessons.id, db.exercises.lessonId));

  $$ExercisesTableProcessedTableManager get exercisesRefs {
    final manager = $$ExercisesTableTableManager($_db, $_db.exercises)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$VocabularyTable, List<VocabEntry>>
      _vocabularyRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vocabulary,
              aliasName:
                  $_aliasNameGenerator(db.lessons.id, db.vocabulary.lessonId));

  $$VocabularyTableProcessedTableManager get vocabularyRefs {
    final manager = $$VocabularyTableTableManager($_db, $_db.vocabulary)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vocabularyRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserProgressTable, List<UserProgressEntry>>
      _userProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.userProgress,
          aliasName:
              $_aliasNameGenerator(db.lessons.id, db.userProgress.lessonId));

  $$UserProgressTableProcessedTableManager get userProgressRefs {
    final manager = $$UserProgressTableTableManager($_db, $_db.userProgress)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userProgressRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
      _bookmarksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.bookmarks,
              aliasName:
                  $_aliasNameGenerator(db.lessons.id, db.bookmarks.lessonId));

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager($_db, $_db.bookmarks)
        .filter((f) => f.lessonId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$LessonsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleBn => $composableBuilder(
      column: $table.titleBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleAr => $composableBuilder(
      column: $table.titleAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> exercisesRefs(
      Expression<bool> Function($$ExercisesTableFilterComposer f) f) {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableFilterComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> vocabularyRefs(
      Expression<bool> Function($$VocabularyTableFilterComposer f) f) {
    final $$VocabularyTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabulary,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTableFilterComposer(
              $db: $db,
              $table: $db.vocabulary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userProgressRefs(
      Expression<bool> Function($$UserProgressTableFilterComposer f) f) {
    final $$UserProgressTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userProgress,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserProgressTableFilterComposer(
              $db: $db,
              $table: $db.userProgress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
      Expression<bool> Function($$BookmarksTableFilterComposer f) f) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableFilterComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleBn => $composableBuilder(
      column: $table.titleBn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleAr => $composableBuilder(
      column: $table.titleAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$LessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titleBn =>
      $composableBuilder(column: $table.titleBn, builder: (column) => column);

  GeneratedColumn<String> get titleAr =>
      $composableBuilder(column: $table.titleAr, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> exercisesRefs<T extends Object>(
      Expression<T> Function($$ExercisesTableAnnotationComposer a) f) {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.exercises,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExercisesTableAnnotationComposer(
              $db: $db,
              $table: $db.exercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> vocabularyRefs<T extends Object>(
      Expression<T> Function($$VocabularyTableAnnotationComposer a) f) {
    final $$VocabularyTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabulary,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTableAnnotationComposer(
              $db: $db,
              $table: $db.vocabulary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userProgressRefs<T extends Object>(
      Expression<T> Function($$UserProgressTableAnnotationComposer a) f) {
    final $$UserProgressTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userProgress,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserProgressTableAnnotationComposer(
              $db: $db,
              $table: $db.userProgress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
      Expression<T> Function($$BookmarksTableAnnotationComposer a) f) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.lessonId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableAnnotationComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$LessonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonsTable,
    Lesson,
    $$LessonsTableFilterComposer,
    $$LessonsTableOrderingComposer,
    $$LessonsTableAnnotationComposer,
    $$LessonsTableCreateCompanionBuilder,
    $$LessonsTableUpdateCompanionBuilder,
    (Lesson, $$LessonsTableReferences),
    Lesson,
    PrefetchHooks Function(
        {bool unitId,
        bool exercisesRefs,
        bool vocabularyRefs,
        bool userProgressRefs,
        bool bookmarksRefs})> {
  $$LessonsTableTableManager(_$AppDatabase db, $LessonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> unitId = const Value.absent(),
            Value<String> titleBn = const Value.absent(),
            Value<String?> titleAr = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> level = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonsCompanion(
            id: id,
            unitId: unitId,
            titleBn: titleBn,
            titleAr: titleAr,
            sortOrder: sortOrder,
            xpReward: xpReward,
            status: status,
            level: level,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String unitId,
            required String titleBn,
            Value<String?> titleAr = const Value.absent(),
            required int sortOrder,
            Value<int> xpReward = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> level = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonsCompanion.insert(
            id: id,
            unitId: unitId,
            titleBn: titleBn,
            titleAr: titleAr,
            sortOrder: sortOrder,
            xpReward: xpReward,
            status: status,
            level: level,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$LessonsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {unitId = false,
              exercisesRefs = false,
              vocabularyRefs = false,
              userProgressRefs = false,
              bookmarksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exercisesRefs) db.exercises,
                if (vocabularyRefs) db.vocabulary,
                if (userProgressRefs) db.userProgress,
                if (bookmarksRefs) db.bookmarks
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable: $$LessonsTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$LessonsTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exercisesRefs)
                    await $_getPrefetchedData<Lesson, $LessonsTable, Exercise>(
                        currentTable: table,
                        referencedTable:
                            $$LessonsTableReferences._exercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0)
                                .exercisesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items),
                  if (vocabularyRefs)
                    await $_getPrefetchedData<Lesson, $LessonsTable,
                            VocabEntry>(
                        currentTable: table,
                        referencedTable:
                            $$LessonsTableReferences._vocabularyRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0)
                                .vocabularyRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items),
                  if (userProgressRefs)
                    await $_getPrefetchedData<Lesson, $LessonsTable,
                            UserProgressEntry>(
                        currentTable: table,
                        referencedTable:
                            $$LessonsTableReferences._userProgressRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0)
                                .userProgressRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items),
                  if (bookmarksRefs)
                    await $_getPrefetchedData<Lesson, $LessonsTable, Bookmark>(
                        currentTable: table,
                        referencedTable:
                            $$LessonsTableReferences._bookmarksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$LessonsTableReferences(db, table, p0)
                                .bookmarksRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.lessonId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$LessonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonsTable,
    Lesson,
    $$LessonsTableFilterComposer,
    $$LessonsTableOrderingComposer,
    $$LessonsTableAnnotationComposer,
    $$LessonsTableCreateCompanionBuilder,
    $$LessonsTableUpdateCompanionBuilder,
    (Lesson, $$LessonsTableReferences),
    Lesson,
    PrefetchHooks Function(
        {bool unitId,
        bool exercisesRefs,
        bool vocabularyRefs,
        bool userProgressRefs,
        bool bookmarksRefs})>;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String lessonId,
  required String type,
  required int sortOrder,
  Value<String?> promptAr,
  Value<String?> promptBn,
  Value<String?> promptEn,
  required String correctAnswer,
  Value<String?> distractors,
  Value<String?> audioUrl,
  Value<String?> grammarNoteBn,
  Value<String?> grammarNoteEn,
  Value<int> difficulty,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> lessonId,
  Value<String> type,
  Value<int> sortOrder,
  Value<String?> promptAr,
  Value<String?> promptBn,
  Value<String?> promptEn,
  Value<String> correctAnswer,
  Value<String?> distractors,
  Value<String?> audioUrl,
  Value<String?> grammarNoteBn,
  Value<String?> grammarNoteEn,
  Value<int> difficulty,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) => db.lessons
      .createAlias($_aliasNameGenerator(db.exercises.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptAr => $composableBuilder(
      column: $table.promptAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptBn => $composableBuilder(
      column: $table.promptBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptEn => $composableBuilder(
      column: $table.promptEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get distractors => $composableBuilder(
      column: $table.distractors, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grammarNoteBn => $composableBuilder(
      column: $table.grammarNoteBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get grammarNoteEn => $composableBuilder(
      column: $table.grammarNoteEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptAr => $composableBuilder(
      column: $table.promptAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptBn => $composableBuilder(
      column: $table.promptBn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptEn => $composableBuilder(
      column: $table.promptEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get distractors => $composableBuilder(
      column: $table.distractors, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grammarNoteBn => $composableBuilder(
      column: $table.grammarNoteBn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get grammarNoteEn => $composableBuilder(
      column: $table.grammarNoteEn,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get promptAr =>
      $composableBuilder(column: $table.promptAr, builder: (column) => column);

  GeneratedColumn<String> get promptBn =>
      $composableBuilder(column: $table.promptBn, builder: (column) => column);

  GeneratedColumn<String> get promptEn =>
      $composableBuilder(column: $table.promptEn, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
      column: $table.correctAnswer, builder: (column) => column);

  GeneratedColumn<String> get distractors => $composableBuilder(
      column: $table.distractors, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get grammarNoteBn => $composableBuilder(
      column: $table.grammarNoteBn, builder: (column) => column);

  GeneratedColumn<String> get grammarNoteEn => $composableBuilder(
      column: $table.grammarNoteEn, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function({bool lessonId})> {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> promptAr = const Value.absent(),
            Value<String?> promptBn = const Value.absent(),
            Value<String?> promptEn = const Value.absent(),
            Value<String> correctAnswer = const Value.absent(),
            Value<String?> distractors = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> grammarNoteBn = const Value.absent(),
            Value<String?> grammarNoteEn = const Value.absent(),
            Value<int> difficulty = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            lessonId: lessonId,
            type: type,
            sortOrder: sortOrder,
            promptAr: promptAr,
            promptBn: promptBn,
            promptEn: promptEn,
            correctAnswer: correctAnswer,
            distractors: distractors,
            audioUrl: audioUrl,
            grammarNoteBn: grammarNoteBn,
            grammarNoteEn: grammarNoteEn,
            difficulty: difficulty,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String lessonId,
            required String type,
            required int sortOrder,
            Value<String?> promptAr = const Value.absent(),
            Value<String?> promptBn = const Value.absent(),
            Value<String?> promptEn = const Value.absent(),
            required String correctAnswer,
            Value<String?> distractors = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> grammarNoteBn = const Value.absent(),
            Value<String?> grammarNoteEn = const Value.absent(),
            Value<int> difficulty = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            lessonId: lessonId,
            type: type,
            sortOrder: sortOrder,
            promptAr: promptAr,
            promptBn: promptBn,
            promptEn: promptEn,
            correctAnswer: correctAnswer,
            distractors: distractors,
            audioUrl: audioUrl,
            grammarNoteBn: grammarNoteBn,
            grammarNoteEn: grammarNoteEn,
            difficulty: difficulty,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable:
                        $$ExercisesTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$ExercisesTableReferences._lessonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, $$ExercisesTableReferences),
    Exercise,
    PrefetchHooks Function({bool lessonId})>;
typedef $$VocabularyTableCreateCompanionBuilder = VocabularyCompanion Function({
  required String id,
  required String arabic,
  Value<String?> transliteration,
  required String meaningBn,
  Value<String?> meaningEn,
  Value<String?> rootLetters,
  Value<String?> wordType,
  Value<String?> gender,
  Value<String?> audioUrl,
  Value<String?> lessonId,
  Value<int?> frequencyRank,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$VocabularyTableUpdateCompanionBuilder = VocabularyCompanion Function({
  Value<String> id,
  Value<String> arabic,
  Value<String?> transliteration,
  Value<String> meaningBn,
  Value<String?> meaningEn,
  Value<String?> rootLetters,
  Value<String?> wordType,
  Value<String?> gender,
  Value<String?> audioUrl,
  Value<String?> lessonId,
  Value<int?> frequencyRank,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$VocabularyTableReferences
    extends BaseReferences<_$AppDatabase, $VocabularyTable, VocabEntry> {
  $$VocabularyTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) => db.lessons
      .createAlias($_aliasNameGenerator(db.vocabulary.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager? get lessonId {
    final $_column = $_itemColumn<String>('lesson_id');
    if ($_column == null) return null;
    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SrsCardsTable, List<SrsCard>> _srsCardsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.srsCards,
          aliasName:
              $_aliasNameGenerator(db.vocabulary.id, db.srsCards.vocabularyId));

  $$SrsCardsTableProcessedTableManager get srsCardsRefs {
    final manager = $$SrsCardsTableTableManager($_db, $_db.srsCards).filter(
        (f) => f.vocabularyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_srsCardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VocabularyTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyTable> {
  $$VocabularyTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arabic => $composableBuilder(
      column: $table.arabic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transliteration => $composableBuilder(
      column: $table.transliteration,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningBn => $composableBuilder(
      column: $table.meaningBn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningEn => $composableBuilder(
      column: $table.meaningEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootLetters => $composableBuilder(
      column: $table.rootLetters, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wordType => $composableBuilder(
      column: $table.wordType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> srsCardsRefs(
      Expression<bool> Function($$SrsCardsTableFilterComposer f) f) {
    final $$SrsCardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.srsCards,
        getReferencedColumn: (t) => t.vocabularyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SrsCardsTableFilterComposer(
              $db: $db,
              $table: $db.srsCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VocabularyTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyTable> {
  $$VocabularyTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arabic => $composableBuilder(
      column: $table.arabic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transliteration => $composableBuilder(
      column: $table.transliteration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningBn => $composableBuilder(
      column: $table.meaningBn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningEn => $composableBuilder(
      column: $table.meaningEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootLetters => $composableBuilder(
      column: $table.rootLetters, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wordType => $composableBuilder(
      column: $table.wordType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gender => $composableBuilder(
      column: $table.gender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyTable> {
  $$VocabularyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get arabic =>
      $composableBuilder(column: $table.arabic, builder: (column) => column);

  GeneratedColumn<String> get transliteration => $composableBuilder(
      column: $table.transliteration, builder: (column) => column);

  GeneratedColumn<String> get meaningBn =>
      $composableBuilder(column: $table.meaningBn, builder: (column) => column);

  GeneratedColumn<String> get meaningEn =>
      $composableBuilder(column: $table.meaningEn, builder: (column) => column);

  GeneratedColumn<String> get rootLetters => $composableBuilder(
      column: $table.rootLetters, builder: (column) => column);

  GeneratedColumn<String> get wordType =>
      $composableBuilder(column: $table.wordType, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<int> get frequencyRank => $composableBuilder(
      column: $table.frequencyRank, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> srsCardsRefs<T extends Object>(
      Expression<T> Function($$SrsCardsTableAnnotationComposer a) f) {
    final $$SrsCardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.srsCards,
        getReferencedColumn: (t) => t.vocabularyId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SrsCardsTableAnnotationComposer(
              $db: $db,
              $table: $db.srsCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VocabularyTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyTable,
    VocabEntry,
    $$VocabularyTableFilterComposer,
    $$VocabularyTableOrderingComposer,
    $$VocabularyTableAnnotationComposer,
    $$VocabularyTableCreateCompanionBuilder,
    $$VocabularyTableUpdateCompanionBuilder,
    (VocabEntry, $$VocabularyTableReferences),
    VocabEntry,
    PrefetchHooks Function({bool lessonId, bool srsCardsRefs})> {
  $$VocabularyTableTableManager(_$AppDatabase db, $VocabularyTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> arabic = const Value.absent(),
            Value<String?> transliteration = const Value.absent(),
            Value<String> meaningBn = const Value.absent(),
            Value<String?> meaningEn = const Value.absent(),
            Value<String?> rootLetters = const Value.absent(),
            Value<String?> wordType = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> lessonId = const Value.absent(),
            Value<int?> frequencyRank = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyCompanion(
            id: id,
            arabic: arabic,
            transliteration: transliteration,
            meaningBn: meaningBn,
            meaningEn: meaningEn,
            rootLetters: rootLetters,
            wordType: wordType,
            gender: gender,
            audioUrl: audioUrl,
            lessonId: lessonId,
            frequencyRank: frequencyRank,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String arabic,
            Value<String?> transliteration = const Value.absent(),
            required String meaningBn,
            Value<String?> meaningEn = const Value.absent(),
            Value<String?> rootLetters = const Value.absent(),
            Value<String?> wordType = const Value.absent(),
            Value<String?> gender = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String?> lessonId = const Value.absent(),
            Value<int?> frequencyRank = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyCompanion.insert(
            id: id,
            arabic: arabic,
            transliteration: transliteration,
            meaningBn: meaningBn,
            meaningEn: meaningEn,
            rootLetters: rootLetters,
            wordType: wordType,
            gender: gender,
            audioUrl: audioUrl,
            lessonId: lessonId,
            frequencyRank: frequencyRank,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VocabularyTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonId = false, srsCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (srsCardsRefs) db.srsCards],
              addJoins: <
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
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable:
                        $$VocabularyTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$VocabularyTableReferences._lessonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (srsCardsRefs)
                    await $_getPrefetchedData<VocabEntry, $VocabularyTable,
                            SrsCard>(
                        currentTable: table,
                        referencedTable:
                            $$VocabularyTableReferences._srsCardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VocabularyTableReferences(db, table, p0)
                                .srsCardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.vocabularyId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$VocabularyTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VocabularyTable,
    VocabEntry,
    $$VocabularyTableFilterComposer,
    $$VocabularyTableOrderingComposer,
    $$VocabularyTableAnnotationComposer,
    $$VocabularyTableCreateCompanionBuilder,
    $$VocabularyTableUpdateCompanionBuilder,
    (VocabEntry, $$VocabularyTableReferences),
    VocabEntry,
    PrefetchHooks Function({bool lessonId, bool srsCardsRefs})>;
typedef $$SrsCardsTableCreateCompanionBuilder = SrsCardsCompanion Function({
  required String id,
  required String userId,
  required String vocabularyId,
  Value<DateTime> dueDate,
  Value<double> stability,
  Value<double> difficulty,
  Value<int> elapsedDays,
  Value<int> scheduledDays,
  Value<int> reps,
  Value<int> lapses,
  Value<int> state,
  Value<DateTime?> lastReview,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$SrsCardsTableUpdateCompanionBuilder = SrsCardsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> vocabularyId,
  Value<DateTime> dueDate,
  Value<double> stability,
  Value<double> difficulty,
  Value<int> elapsedDays,
  Value<int> scheduledDays,
  Value<int> reps,
  Value<int> lapses,
  Value<int> state,
  Value<DateTime?> lastReview,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

final class $$SrsCardsTableReferences
    extends BaseReferences<_$AppDatabase, $SrsCardsTable, SrsCard> {
  $$SrsCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VocabularyTable _vocabularyIdTable(_$AppDatabase db) =>
      db.vocabulary.createAlias(
          $_aliasNameGenerator(db.srsCards.vocabularyId, db.vocabulary.id));

  $$VocabularyTableProcessedTableManager get vocabularyId {
    final $_column = $_itemColumn<String>('vocabulary_id')!;

    final manager = $$VocabularyTableTableManager($_db, $_db.vocabulary)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vocabularyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SrsCardsTableFilterComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduledDays => $composableBuilder(
      column: $table.scheduledDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
      column: $table.lastReview, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$VocabularyTableFilterComposer get vocabularyId {
    final $$VocabularyTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vocabularyId,
        referencedTable: $db.vocabulary,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTableFilterComposer(
              $db: $db,
              $table: $db.vocabulary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SrsCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduledDays => $composableBuilder(
      column: $table.scheduledDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
      column: $table.lastReview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$VocabularyTableOrderingComposer get vocabularyId {
    final $$VocabularyTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vocabularyId,
        referencedTable: $db.vocabulary,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTableOrderingComposer(
              $db: $db,
              $table: $db.vocabulary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SrsCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SrsCardsTable> {
  $$SrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<int> get elapsedDays => $composableBuilder(
      column: $table.elapsedDays, builder: (column) => column);

  GeneratedColumn<int> get scheduledDays => $composableBuilder(
      column: $table.scheduledDays, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
      column: $table.lastReview, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$VocabularyTableAnnotationComposer get vocabularyId {
    final $$VocabularyTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vocabularyId,
        referencedTable: $db.vocabulary,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTableAnnotationComposer(
              $db: $db,
              $table: $db.vocabulary,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SrsCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SrsCardsTable,
    SrsCard,
    $$SrsCardsTableFilterComposer,
    $$SrsCardsTableOrderingComposer,
    $$SrsCardsTableAnnotationComposer,
    $$SrsCardsTableCreateCompanionBuilder,
    $$SrsCardsTableUpdateCompanionBuilder,
    (SrsCard, $$SrsCardsTableReferences),
    SrsCard,
    PrefetchHooks Function({bool vocabularyId})> {
  $$SrsCardsTableTableManager(_$AppDatabase db, $SrsCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> vocabularyId = const Value.absent(),
            Value<DateTime> dueDate = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<int> elapsedDays = const Value.absent(),
            Value<int> scheduledDays = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<DateTime?> lastReview = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SrsCardsCompanion(
            id: id,
            userId: userId,
            vocabularyId: vocabularyId,
            dueDate: dueDate,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            reps: reps,
            lapses: lapses,
            state: state,
            lastReview: lastReview,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String vocabularyId,
            Value<DateTime> dueDate = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<int> elapsedDays = const Value.absent(),
            Value<int> scheduledDays = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> state = const Value.absent(),
            Value<DateTime?> lastReview = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SrsCardsCompanion.insert(
            id: id,
            userId: userId,
            vocabularyId: vocabularyId,
            dueDate: dueDate,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            reps: reps,
            lapses: lapses,
            state: state,
            lastReview: lastReview,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SrsCardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vocabularyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (vocabularyId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.vocabularyId,
                    referencedTable:
                        $$SrsCardsTableReferences._vocabularyIdTable(db),
                    referencedColumn:
                        $$SrsCardsTableReferences._vocabularyIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SrsCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SrsCardsTable,
    SrsCard,
    $$SrsCardsTableFilterComposer,
    $$SrsCardsTableOrderingComposer,
    $$SrsCardsTableAnnotationComposer,
    $$SrsCardsTableCreateCompanionBuilder,
    $$SrsCardsTableUpdateCompanionBuilder,
    (SrsCard, $$SrsCardsTableReferences),
    SrsCard,
    PrefetchHooks Function({bool vocabularyId})>;
typedef $$UserProgressTableCreateCompanionBuilder = UserProgressCompanion
    Function({
  required String id,
  required String userId,
  required String lessonId,
  Value<DateTime> completedAt,
  Value<int> xpEarned,
  Value<int> accuracyPct,
  Value<int> heartsRemaining,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$UserProgressTableUpdateCompanionBuilder = UserProgressCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> lessonId,
  Value<DateTime> completedAt,
  Value<int> xpEarned,
  Value<int> accuracyPct,
  Value<int> heartsRemaining,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

final class $$UserProgressTableReferences extends BaseReferences<_$AppDatabase,
    $UserProgressTable, UserProgressEntry> {
  $$UserProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) =>
      db.lessons.createAlias(
          $_aliasNameGenerator(db.userProgress.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserProgressTableFilterComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpEarned => $composableBuilder(
      column: $table.xpEarned, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accuracyPct => $composableBuilder(
      column: $table.accuracyPct, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heartsRemaining => $composableBuilder(
      column: $table.heartsRemaining,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpEarned => $composableBuilder(
      column: $table.xpEarned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accuracyPct => $composableBuilder(
      column: $table.accuracyPct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heartsRemaining => $composableBuilder(
      column: $table.heartsRemaining,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProgressTable> {
  $$UserProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<int> get accuracyPct => $composableBuilder(
      column: $table.accuracyPct, builder: (column) => column);

  GeneratedColumn<int> get heartsRemaining => $composableBuilder(
      column: $table.heartsRemaining, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserProgressTable,
    UserProgressEntry,
    $$UserProgressTableFilterComposer,
    $$UserProgressTableOrderingComposer,
    $$UserProgressTableAnnotationComposer,
    $$UserProgressTableCreateCompanionBuilder,
    $$UserProgressTableUpdateCompanionBuilder,
    (UserProgressEntry, $$UserProgressTableReferences),
    UserProgressEntry,
    PrefetchHooks Function({bool lessonId})> {
  $$UserProgressTableTableManager(_$AppDatabase db, $UserProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int> xpEarned = const Value.absent(),
            Value<int> accuracyPct = const Value.absent(),
            Value<int> heartsRemaining = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProgressCompanion(
            id: id,
            userId: userId,
            lessonId: lessonId,
            completedAt: completedAt,
            xpEarned: xpEarned,
            accuracyPct: accuracyPct,
            heartsRemaining: heartsRemaining,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String lessonId,
            Value<DateTime> completedAt = const Value.absent(),
            Value<int> xpEarned = const Value.absent(),
            Value<int> accuracyPct = const Value.absent(),
            Value<int> heartsRemaining = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserProgressCompanion.insert(
            id: id,
            userId: userId,
            lessonId: lessonId,
            completedAt: completedAt,
            xpEarned: xpEarned,
            accuracyPct: accuracyPct,
            heartsRemaining: heartsRemaining,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserProgressTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable:
                        $$UserProgressTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$UserProgressTableReferences._lessonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserProgressTable,
    UserProgressEntry,
    $$UserProgressTableFilterComposer,
    $$UserProgressTableOrderingComposer,
    $$UserProgressTableAnnotationComposer,
    $$UserProgressTableCreateCompanionBuilder,
    $$UserProgressTableUpdateCompanionBuilder,
    (UserProgressEntry, $$UserProgressTableReferences),
    UserProgressEntry,
    PrefetchHooks Function({bool lessonId})>;
typedef $$StreaksTableCreateCompanionBuilder = StreaksCompanion Function({
  required String userId,
  Value<int> currentStreak,
  Value<int> longestStreak,
  Value<DateTime?> lastActivityDate,
  Value<int> totalXp,
  Value<int> freezeCount,
  Value<DateTime?> lastFreezedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$StreaksTableUpdateCompanionBuilder = StreaksCompanion Function({
  Value<String> userId,
  Value<int> currentStreak,
  Value<int> longestStreak,
  Value<DateTime?> lastActivityDate,
  Value<int> totalXp,
  Value<int> freezeCount,
  Value<DateTime?> lastFreezedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StreaksTableFilterComposer
    extends Composer<_$AppDatabase, $StreaksTable> {
  $$StreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longestStreak => $composableBuilder(
      column: $table.longestStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActivityDate => $composableBuilder(
      column: $table.lastActivityDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalXp => $composableBuilder(
      column: $table.totalXp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get freezeCount => $composableBuilder(
      column: $table.freezeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastFreezedAt => $composableBuilder(
      column: $table.lastFreezedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$StreaksTableOrderingComposer
    extends Composer<_$AppDatabase, $StreaksTable> {
  $$StreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longestStreak => $composableBuilder(
      column: $table.longestStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActivityDate => $composableBuilder(
      column: $table.lastActivityDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalXp => $composableBuilder(
      column: $table.totalXp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get freezeCount => $composableBuilder(
      column: $table.freezeCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastFreezedAt => $composableBuilder(
      column: $table.lastFreezedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$StreaksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StreaksTable> {
  $$StreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => column);

  GeneratedColumn<int> get longestStreak => $composableBuilder(
      column: $table.longestStreak, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActivityDate => $composableBuilder(
      column: $table.lastActivityDate, builder: (column) => column);

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get freezeCount => $composableBuilder(
      column: $table.freezeCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFreezedAt => $composableBuilder(
      column: $table.lastFreezedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StreaksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StreaksTable,
    Streak,
    $$StreaksTableFilterComposer,
    $$StreaksTableOrderingComposer,
    $$StreaksTableAnnotationComposer,
    $$StreaksTableCreateCompanionBuilder,
    $$StreaksTableUpdateCompanionBuilder,
    (Streak, BaseReferences<_$AppDatabase, $StreaksTable, Streak>),
    Streak,
    PrefetchHooks Function()> {
  $$StreaksTableTableManager(_$AppDatabase db, $StreaksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<int> longestStreak = const Value.absent(),
            Value<DateTime?> lastActivityDate = const Value.absent(),
            Value<int> totalXp = const Value.absent(),
            Value<int> freezeCount = const Value.absent(),
            Value<DateTime?> lastFreezedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StreaksCompanion(
            userId: userId,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastActivityDate: lastActivityDate,
            totalXp: totalXp,
            freezeCount: freezeCount,
            lastFreezedAt: lastFreezedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<int> currentStreak = const Value.absent(),
            Value<int> longestStreak = const Value.absent(),
            Value<DateTime?> lastActivityDate = const Value.absent(),
            Value<int> totalXp = const Value.absent(),
            Value<int> freezeCount = const Value.absent(),
            Value<DateTime?> lastFreezedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StreaksCompanion.insert(
            userId: userId,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastActivityDate: lastActivityDate,
            totalXp: totalXp,
            freezeCount: freezeCount,
            lastFreezedAt: lastFreezedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StreaksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StreaksTable,
    Streak,
    $$StreaksTableFilterComposer,
    $$StreaksTableOrderingComposer,
    $$StreaksTableAnnotationComposer,
    $$StreaksTableCreateCompanionBuilder,
    $$StreaksTableUpdateCompanionBuilder,
    (Streak, BaseReferences<_$AppDatabase, $StreaksTable, Streak>),
    Streak,
    PrefetchHooks Function()>;
typedef $$PendingSyncTableCreateCompanionBuilder = PendingSyncCompanion
    Function({
  Value<int> id,
  required String action,
  required String payload,
  Value<DateTime> createdAt,
  Value<bool> isProcessing,
});
typedef $$PendingSyncTableUpdateCompanionBuilder = PendingSyncCompanion
    Function({
  Value<int> id,
  Value<String> action,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<bool> isProcessing,
});

class $$PendingSyncTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncTable> {
  $$PendingSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isProcessing => $composableBuilder(
      column: $table.isProcessing, builder: (column) => ColumnFilters(column));
}

class $$PendingSyncTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncTable> {
  $$PendingSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isProcessing => $composableBuilder(
      column: $table.isProcessing,
      builder: (column) => ColumnOrderings(column));
}

class $$PendingSyncTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncTable> {
  $$PendingSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isProcessing => $composableBuilder(
      column: $table.isProcessing, builder: (column) => column);
}

class $$PendingSyncTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingSyncTable,
    PendingSyncEntry,
    $$PendingSyncTableFilterComposer,
    $$PendingSyncTableOrderingComposer,
    $$PendingSyncTableAnnotationComposer,
    $$PendingSyncTableCreateCompanionBuilder,
    $$PendingSyncTableUpdateCompanionBuilder,
    (
      PendingSyncEntry,
      BaseReferences<_$AppDatabase, $PendingSyncTable, PendingSyncEntry>
    ),
    PendingSyncEntry,
    PrefetchHooks Function()> {
  $$PendingSyncTableTableManager(_$AppDatabase db, $PendingSyncTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isProcessing = const Value.absent(),
          }) =>
              PendingSyncCompanion(
            id: id,
            action: action,
            payload: payload,
            createdAt: createdAt,
            isProcessing: isProcessing,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String action,
            required String payload,
            Value<DateTime> createdAt = const Value.absent(),
            Value<bool> isProcessing = const Value.absent(),
          }) =>
              PendingSyncCompanion.insert(
            id: id,
            action: action,
            payload: payload,
            createdAt: createdAt,
            isProcessing: isProcessing,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingSyncTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingSyncTable,
    PendingSyncEntry,
    $$PendingSyncTableFilterComposer,
    $$PendingSyncTableOrderingComposer,
    $$PendingSyncTableAnnotationComposer,
    $$PendingSyncTableCreateCompanionBuilder,
    $$PendingSyncTableUpdateCompanionBuilder,
    (
      PendingSyncEntry,
      BaseReferences<_$AppDatabase, $PendingSyncTable, PendingSyncEntry>
    ),
    PendingSyncEntry,
    PrefetchHooks Function()>;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  required String id,
  required String userId,
  required String lessonId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> lessonId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$AppDatabase db) => db.lessons
      .createAlias($_aliasNameGenerator(db.bookmarks.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<String>('lesson_id')!;

    final manager = $$LessonsTableTableManager($_db, $_db.lessons)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableFilterComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableOrderingComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.lessonId,
        referencedTable: $db.lessons,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$LessonsTableAnnotationComposer(
              $db: $db,
              $table: $db.lessons,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, $$BookmarksTableReferences),
    Bookmark,
    PrefetchHooks Function({bool lessonId})> {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion(
            id: id,
            userId: userId,
            lessonId: lessonId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String lessonId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion.insert(
            id: id,
            userId: userId,
            lessonId: lessonId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BookmarksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (lessonId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.lessonId,
                    referencedTable:
                        $$BookmarksTableReferences._lessonIdTable(db),
                    referencedColumn:
                        $$BookmarksTableReferences._lessonIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, $$BookmarksTableReferences),
    Bookmark,
    PrefetchHooks Function({bool lessonId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$VocabularyTableTableManager get vocabulary =>
      $$VocabularyTableTableManager(_db, _db.vocabulary);
  $$SrsCardsTableTableManager get srsCards =>
      $$SrsCardsTableTableManager(_db, _db.srsCards);
  $$UserProgressTableTableManager get userProgress =>
      $$UserProgressTableTableManager(_db, _db.userProgress);
  $$StreaksTableTableManager get streaks =>
      $$StreaksTableTableManager(_db, _db.streaks);
  $$PendingSyncTableTableManager get pendingSync =>
      $$PendingSyncTableTableManager(_db, _db.pendingSync);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
}
