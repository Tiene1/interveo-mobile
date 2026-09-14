// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $InterventionsTable extends Interventions
    with TableInfo<$InterventionsTable, Intervention> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InterventionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idServeurMeta = const VerificationMeta(
    'idServeur',
  );
  @override
  late final GeneratedColumn<String> idServeur = GeneratedColumn<String>(
    'id_serveur',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomClientMeta = const VerificationMeta(
    'nomClient',
  );
  @override
  late final GeneratedColumn<String> nomClient = GeneratedColumn<String>(
    'nom_client',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adresseMeta = const VerificationMeta(
    'adresse',
  );
  @override
  late final GeneratedColumn<String> adresse = GeneratedColumn<String>(
    'adresse',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telephone1Meta = const VerificationMeta(
    'telephone1',
  );
  @override
  late final GeneratedColumn<String> telephone1 = GeneratedColumn<String>(
    'telephone1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telephone2Meta = const VerificationMeta(
    'telephone2',
  );
  @override
  late final GeneratedColumn<String> telephone2 = GeneratedColumn<String>(
    'telephone2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geolocalisationMeta = const VerificationMeta(
    'geolocalisation',
  );
  @override
  late final GeneratedColumn<String> geolocalisation = GeneratedColumn<String>(
    'geolocalisation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motifSignaleMeta = const VerificationMeta(
    'motifSignale',
  );
  @override
  late final GeneratedColumn<String> motifSignale = GeneratedColumn<String>(
    'motif_signale',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _datePrevueMeta = const VerificationMeta(
    'datePrevue',
  );
  @override
  late final GeneratedColumn<DateTime> datePrevue = GeneratedColumn<DateTime>(
    'date_prevue',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _technicienIdMeta = const VerificationMeta(
    'technicienId',
  );
  @override
  late final GeneratedColumn<String> technicienId = GeneratedColumn<String>(
    'technicien_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creeParIdMeta = const VerificationMeta(
    'creeParId',
  );
  @override
  late final GeneratedColumn<String> creeParId = GeneratedColumn<String>(
    'cree_par_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TypeEquipement?, String>
  typeEquipement =
      GeneratedColumn<String>(
        'type_equipement',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TypeEquipement?>(
        $InterventionsTable.$convertertypeEquipementn,
      );
  static const VerificationMeta _problemeConstateMeta = const VerificationMeta(
    'problemeConstate',
  );
  @override
  late final GeneratedColumn<String> problemeConstate = GeneratedColumn<String>(
    'probleme_constate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _travauxRealisesMeta = const VerificationMeta(
    'travauxRealises',
  );
  @override
  late final GeneratedColumn<String> travauxRealises = GeneratedColumn<String>(
    'travaux_realises',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StatutIntervention, String>
  statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<StatutIntervention>($InterventionsTable.$converterstatut);
  static const VerificationMeta _dateRealisationMeta = const VerificationMeta(
    'dateRealisation',
  );
  @override
  late final GeneratedColumn<DateTime> dateRealisation =
      GeneratedColumn<DateTime>(
        'date_realisation',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _misAJourLeMeta = const VerificationMeta(
    'misAJourLe',
  );
  @override
  late final GeneratedColumn<DateTime> misAJourLe = GeneratedColumn<DateTime>(
    'mis_a_jour_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StatutSync, String> statutSync =
      GeneratedColumn<String>(
        'statut_sync',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StatutSync>($InterventionsTable.$converterstatutSync);
  static const VerificationMeta _modifieLocalementLeMeta =
      const VerificationMeta('modifieLocalementLe');
  @override
  late final GeneratedColumn<DateTime> modifieLocalementLe =
      GeneratedColumn<DateTime>(
        'modifie_localement_le',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _vueLeMeta = const VerificationMeta('vueLe');
  @override
  late final GeneratedColumn<DateTime> vueLe = GeneratedColumn<DateTime>(
    'vue_le',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idServeur,
    nomClient,
    adresse,
    telephone1,
    telephone2,
    geolocalisation,
    motifSignale,
    datePrevue,
    technicienId,
    creeParId,
    typeEquipement,
    problemeConstate,
    travauxRealises,
    statut,
    dateRealisation,
    creeLe,
    misAJourLe,
    statutSync,
    modifieLocalementLe,
    vueLe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interventions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Intervention> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_serveur')) {
      context.handle(
        _idServeurMeta,
        idServeur.isAcceptableOrUnknown(data['id_serveur']!, _idServeurMeta),
      );
    } else if (isInserting) {
      context.missing(_idServeurMeta);
    }
    if (data.containsKey('nom_client')) {
      context.handle(
        _nomClientMeta,
        nomClient.isAcceptableOrUnknown(data['nom_client']!, _nomClientMeta),
      );
    } else if (isInserting) {
      context.missing(_nomClientMeta);
    }
    if (data.containsKey('adresse')) {
      context.handle(
        _adresseMeta,
        adresse.isAcceptableOrUnknown(data['adresse']!, _adresseMeta),
      );
    } else if (isInserting) {
      context.missing(_adresseMeta);
    }
    if (data.containsKey('telephone1')) {
      context.handle(
        _telephone1Meta,
        telephone1.isAcceptableOrUnknown(data['telephone1']!, _telephone1Meta),
      );
    } else if (isInserting) {
      context.missing(_telephone1Meta);
    }
    if (data.containsKey('telephone2')) {
      context.handle(
        _telephone2Meta,
        telephone2.isAcceptableOrUnknown(data['telephone2']!, _telephone2Meta),
      );
    }
    if (data.containsKey('geolocalisation')) {
      context.handle(
        _geolocalisationMeta,
        geolocalisation.isAcceptableOrUnknown(
          data['geolocalisation']!,
          _geolocalisationMeta,
        ),
      );
    }
    if (data.containsKey('motif_signale')) {
      context.handle(
        _motifSignaleMeta,
        motifSignale.isAcceptableOrUnknown(
          data['motif_signale']!,
          _motifSignaleMeta,
        ),
      );
    }
    if (data.containsKey('date_prevue')) {
      context.handle(
        _datePrevueMeta,
        datePrevue.isAcceptableOrUnknown(data['date_prevue']!, _datePrevueMeta),
      );
    } else if (isInserting) {
      context.missing(_datePrevueMeta);
    }
    if (data.containsKey('technicien_id')) {
      context.handle(
        _technicienIdMeta,
        technicienId.isAcceptableOrUnknown(
          data['technicien_id']!,
          _technicienIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_technicienIdMeta);
    }
    if (data.containsKey('cree_par_id')) {
      context.handle(
        _creeParIdMeta,
        creeParId.isAcceptableOrUnknown(data['cree_par_id']!, _creeParIdMeta),
      );
    } else if (isInserting) {
      context.missing(_creeParIdMeta);
    }
    if (data.containsKey('probleme_constate')) {
      context.handle(
        _problemeConstateMeta,
        problemeConstate.isAcceptableOrUnknown(
          data['probleme_constate']!,
          _problemeConstateMeta,
        ),
      );
    }
    if (data.containsKey('travaux_realises')) {
      context.handle(
        _travauxRealisesMeta,
        travauxRealises.isAcceptableOrUnknown(
          data['travaux_realises']!,
          _travauxRealisesMeta,
        ),
      );
    }
    if (data.containsKey('date_realisation')) {
      context.handle(
        _dateRealisationMeta,
        dateRealisation.isAcceptableOrUnknown(
          data['date_realisation']!,
          _dateRealisationMeta,
        ),
      );
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    } else if (isInserting) {
      context.missing(_creeLeMeta);
    }
    if (data.containsKey('mis_a_jour_le')) {
      context.handle(
        _misAJourLeMeta,
        misAJourLe.isAcceptableOrUnknown(
          data['mis_a_jour_le']!,
          _misAJourLeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_misAJourLeMeta);
    }
    if (data.containsKey('modifie_localement_le')) {
      context.handle(
        _modifieLocalementLeMeta,
        modifieLocalementLe.isAcceptableOrUnknown(
          data['modifie_localement_le']!,
          _modifieLocalementLeMeta,
        ),
      );
    }
    if (data.containsKey('vue_le')) {
      context.handle(
        _vueLeMeta,
        vueLe.isAcceptableOrUnknown(data['vue_le']!, _vueLeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idServeur};
  @override
  Intervention map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Intervention(
      idServeur: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_serveur'],
      )!,
      nomClient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom_client'],
      )!,
      adresse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adresse'],
      )!,
      telephone1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telephone1'],
      )!,
      telephone2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telephone2'],
      ),
      geolocalisation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geolocalisation'],
      ),
      motifSignale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motif_signale'],
      ),
      datePrevue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_prevue'],
      )!,
      technicienId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}technicien_id'],
      )!,
      creeParId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cree_par_id'],
      )!,
      typeEquipement: $InterventionsTable.$convertertypeEquipementn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type_equipement'],
        ),
      ),
      problemeConstate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}probleme_constate'],
      ),
      travauxRealises: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}travaux_realises'],
      ),
      statut: $InterventionsTable.$converterstatut.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}statut'],
        )!,
      ),
      dateRealisation: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_realisation'],
      ),
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      misAJourLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mis_a_jour_le'],
      )!,
      statutSync: $InterventionsTable.$converterstatutSync.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}statut_sync'],
        )!,
      ),
      modifieLocalementLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modifie_localement_le'],
      ),
      vueLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}vue_le'],
      ),
    );
  }

  @override
  $InterventionsTable createAlias(String alias) {
    return $InterventionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TypeEquipement, String, String>
  $convertertypeEquipement = const EnumNameConverter<TypeEquipement>(
    TypeEquipement.values,
  );
  static JsonTypeConverter2<TypeEquipement?, String?, String?>
  $convertertypeEquipementn = JsonTypeConverter2.asNullable(
    $convertertypeEquipement,
  );
  static JsonTypeConverter2<StatutIntervention, String, String>
  $converterstatut = const EnumNameConverter<StatutIntervention>(
    StatutIntervention.values,
  );
  static JsonTypeConverter2<StatutSync, String, String> $converterstatutSync =
      const EnumNameConverter<StatutSync>(StatutSync.values);
}

class Intervention extends DataClass implements Insertable<Intervention> {
  final String idServeur;
  final String nomClient;
  final String adresse;
  final String telephone1;
  final String? telephone2;
  final String? geolocalisation;
  final String? motifSignale;
  final DateTime datePrevue;
  final String technicienId;
  final String creeParId;
  final TypeEquipement? typeEquipement;
  final String? problemeConstate;
  final String? travauxRealises;
  final StatutIntervention statut;
  final DateTime? dateRealisation;
  final DateTime creeLe;
  final DateTime misAJourLe;
  final StatutSync statutSync;
  final DateTime? modifieLocalementLe;

  /// Horodatage de premiere consultation du detail par le technicien (purement
  /// local, jamais synchronise) : sert a masquer le badge "Nouveau" une fois
  /// l'intervention lue (schemaVersion 2, cf. AppDatabase.migration).
  final DateTime? vueLe;
  const Intervention({
    required this.idServeur,
    required this.nomClient,
    required this.adresse,
    required this.telephone1,
    this.telephone2,
    this.geolocalisation,
    this.motifSignale,
    required this.datePrevue,
    required this.technicienId,
    required this.creeParId,
    this.typeEquipement,
    this.problemeConstate,
    this.travauxRealises,
    required this.statut,
    this.dateRealisation,
    required this.creeLe,
    required this.misAJourLe,
    required this.statutSync,
    this.modifieLocalementLe,
    this.vueLe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_serveur'] = Variable<String>(idServeur);
    map['nom_client'] = Variable<String>(nomClient);
    map['adresse'] = Variable<String>(adresse);
    map['telephone1'] = Variable<String>(telephone1);
    if (!nullToAbsent || telephone2 != null) {
      map['telephone2'] = Variable<String>(telephone2);
    }
    if (!nullToAbsent || geolocalisation != null) {
      map['geolocalisation'] = Variable<String>(geolocalisation);
    }
    if (!nullToAbsent || motifSignale != null) {
      map['motif_signale'] = Variable<String>(motifSignale);
    }
    map['date_prevue'] = Variable<DateTime>(datePrevue);
    map['technicien_id'] = Variable<String>(technicienId);
    map['cree_par_id'] = Variable<String>(creeParId);
    if (!nullToAbsent || typeEquipement != null) {
      map['type_equipement'] = Variable<String>(
        $InterventionsTable.$convertertypeEquipementn.toSql(typeEquipement),
      );
    }
    if (!nullToAbsent || problemeConstate != null) {
      map['probleme_constate'] = Variable<String>(problemeConstate);
    }
    if (!nullToAbsent || travauxRealises != null) {
      map['travaux_realises'] = Variable<String>(travauxRealises);
    }
    {
      map['statut'] = Variable<String>(
        $InterventionsTable.$converterstatut.toSql(statut),
      );
    }
    if (!nullToAbsent || dateRealisation != null) {
      map['date_realisation'] = Variable<DateTime>(dateRealisation);
    }
    map['cree_le'] = Variable<DateTime>(creeLe);
    map['mis_a_jour_le'] = Variable<DateTime>(misAJourLe);
    {
      map['statut_sync'] = Variable<String>(
        $InterventionsTable.$converterstatutSync.toSql(statutSync),
      );
    }
    if (!nullToAbsent || modifieLocalementLe != null) {
      map['modifie_localement_le'] = Variable<DateTime>(modifieLocalementLe);
    }
    if (!nullToAbsent || vueLe != null) {
      map['vue_le'] = Variable<DateTime>(vueLe);
    }
    return map;
  }

  InterventionsCompanion toCompanion(bool nullToAbsent) {
    return InterventionsCompanion(
      idServeur: Value(idServeur),
      nomClient: Value(nomClient),
      adresse: Value(adresse),
      telephone1: Value(telephone1),
      telephone2: telephone2 == null && nullToAbsent
          ? const Value.absent()
          : Value(telephone2),
      geolocalisation: geolocalisation == null && nullToAbsent
          ? const Value.absent()
          : Value(geolocalisation),
      motifSignale: motifSignale == null && nullToAbsent
          ? const Value.absent()
          : Value(motifSignale),
      datePrevue: Value(datePrevue),
      technicienId: Value(technicienId),
      creeParId: Value(creeParId),
      typeEquipement: typeEquipement == null && nullToAbsent
          ? const Value.absent()
          : Value(typeEquipement),
      problemeConstate: problemeConstate == null && nullToAbsent
          ? const Value.absent()
          : Value(problemeConstate),
      travauxRealises: travauxRealises == null && nullToAbsent
          ? const Value.absent()
          : Value(travauxRealises),
      statut: Value(statut),
      dateRealisation: dateRealisation == null && nullToAbsent
          ? const Value.absent()
          : Value(dateRealisation),
      creeLe: Value(creeLe),
      misAJourLe: Value(misAJourLe),
      statutSync: Value(statutSync),
      modifieLocalementLe: modifieLocalementLe == null && nullToAbsent
          ? const Value.absent()
          : Value(modifieLocalementLe),
      vueLe: vueLe == null && nullToAbsent
          ? const Value.absent()
          : Value(vueLe),
    );
  }

  factory Intervention.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Intervention(
      idServeur: serializer.fromJson<String>(json['idServeur']),
      nomClient: serializer.fromJson<String>(json['nomClient']),
      adresse: serializer.fromJson<String>(json['adresse']),
      telephone1: serializer.fromJson<String>(json['telephone1']),
      telephone2: serializer.fromJson<String?>(json['telephone2']),
      geolocalisation: serializer.fromJson<String?>(json['geolocalisation']),
      motifSignale: serializer.fromJson<String?>(json['motifSignale']),
      datePrevue: serializer.fromJson<DateTime>(json['datePrevue']),
      technicienId: serializer.fromJson<String>(json['technicienId']),
      creeParId: serializer.fromJson<String>(json['creeParId']),
      typeEquipement: $InterventionsTable.$convertertypeEquipementn.fromJson(
        serializer.fromJson<String?>(json['typeEquipement']),
      ),
      problemeConstate: serializer.fromJson<String?>(json['problemeConstate']),
      travauxRealises: serializer.fromJson<String?>(json['travauxRealises']),
      statut: $InterventionsTable.$converterstatut.fromJson(
        serializer.fromJson<String>(json['statut']),
      ),
      dateRealisation: serializer.fromJson<DateTime?>(json['dateRealisation']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      misAJourLe: serializer.fromJson<DateTime>(json['misAJourLe']),
      statutSync: $InterventionsTable.$converterstatutSync.fromJson(
        serializer.fromJson<String>(json['statutSync']),
      ),
      modifieLocalementLe: serializer.fromJson<DateTime?>(
        json['modifieLocalementLe'],
      ),
      vueLe: serializer.fromJson<DateTime?>(json['vueLe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idServeur': serializer.toJson<String>(idServeur),
      'nomClient': serializer.toJson<String>(nomClient),
      'adresse': serializer.toJson<String>(adresse),
      'telephone1': serializer.toJson<String>(telephone1),
      'telephone2': serializer.toJson<String?>(telephone2),
      'geolocalisation': serializer.toJson<String?>(geolocalisation),
      'motifSignale': serializer.toJson<String?>(motifSignale),
      'datePrevue': serializer.toJson<DateTime>(datePrevue),
      'technicienId': serializer.toJson<String>(technicienId),
      'creeParId': serializer.toJson<String>(creeParId),
      'typeEquipement': serializer.toJson<String?>(
        $InterventionsTable.$convertertypeEquipementn.toJson(typeEquipement),
      ),
      'problemeConstate': serializer.toJson<String?>(problemeConstate),
      'travauxRealises': serializer.toJson<String?>(travauxRealises),
      'statut': serializer.toJson<String>(
        $InterventionsTable.$converterstatut.toJson(statut),
      ),
      'dateRealisation': serializer.toJson<DateTime?>(dateRealisation),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'misAJourLe': serializer.toJson<DateTime>(misAJourLe),
      'statutSync': serializer.toJson<String>(
        $InterventionsTable.$converterstatutSync.toJson(statutSync),
      ),
      'modifieLocalementLe': serializer.toJson<DateTime?>(modifieLocalementLe),
      'vueLe': serializer.toJson<DateTime?>(vueLe),
    };
  }

  Intervention copyWith({
    String? idServeur,
    String? nomClient,
    String? adresse,
    String? telephone1,
    Value<String?> telephone2 = const Value.absent(),
    Value<String?> geolocalisation = const Value.absent(),
    Value<String?> motifSignale = const Value.absent(),
    DateTime? datePrevue,
    String? technicienId,
    String? creeParId,
    Value<TypeEquipement?> typeEquipement = const Value.absent(),
    Value<String?> problemeConstate = const Value.absent(),
    Value<String?> travauxRealises = const Value.absent(),
    StatutIntervention? statut,
    Value<DateTime?> dateRealisation = const Value.absent(),
    DateTime? creeLe,
    DateTime? misAJourLe,
    StatutSync? statutSync,
    Value<DateTime?> modifieLocalementLe = const Value.absent(),
    Value<DateTime?> vueLe = const Value.absent(),
  }) => Intervention(
    idServeur: idServeur ?? this.idServeur,
    nomClient: nomClient ?? this.nomClient,
    adresse: adresse ?? this.adresse,
    telephone1: telephone1 ?? this.telephone1,
    telephone2: telephone2.present ? telephone2.value : this.telephone2,
    geolocalisation: geolocalisation.present
        ? geolocalisation.value
        : this.geolocalisation,
    motifSignale: motifSignale.present ? motifSignale.value : this.motifSignale,
    datePrevue: datePrevue ?? this.datePrevue,
    technicienId: technicienId ?? this.technicienId,
    creeParId: creeParId ?? this.creeParId,
    typeEquipement: typeEquipement.present
        ? typeEquipement.value
        : this.typeEquipement,
    problemeConstate: problemeConstate.present
        ? problemeConstate.value
        : this.problemeConstate,
    travauxRealises: travauxRealises.present
        ? travauxRealises.value
        : this.travauxRealises,
    statut: statut ?? this.statut,
    dateRealisation: dateRealisation.present
        ? dateRealisation.value
        : this.dateRealisation,
    creeLe: creeLe ?? this.creeLe,
    misAJourLe: misAJourLe ?? this.misAJourLe,
    statutSync: statutSync ?? this.statutSync,
    modifieLocalementLe: modifieLocalementLe.present
        ? modifieLocalementLe.value
        : this.modifieLocalementLe,
    vueLe: vueLe.present ? vueLe.value : this.vueLe,
  );
  Intervention copyWithCompanion(InterventionsCompanion data) {
    return Intervention(
      idServeur: data.idServeur.present ? data.idServeur.value : this.idServeur,
      nomClient: data.nomClient.present ? data.nomClient.value : this.nomClient,
      adresse: data.adresse.present ? data.adresse.value : this.adresse,
      telephone1: data.telephone1.present
          ? data.telephone1.value
          : this.telephone1,
      telephone2: data.telephone2.present
          ? data.telephone2.value
          : this.telephone2,
      geolocalisation: data.geolocalisation.present
          ? data.geolocalisation.value
          : this.geolocalisation,
      motifSignale: data.motifSignale.present
          ? data.motifSignale.value
          : this.motifSignale,
      datePrevue: data.datePrevue.present
          ? data.datePrevue.value
          : this.datePrevue,
      technicienId: data.technicienId.present
          ? data.technicienId.value
          : this.technicienId,
      creeParId: data.creeParId.present ? data.creeParId.value : this.creeParId,
      typeEquipement: data.typeEquipement.present
          ? data.typeEquipement.value
          : this.typeEquipement,
      problemeConstate: data.problemeConstate.present
          ? data.problemeConstate.value
          : this.problemeConstate,
      travauxRealises: data.travauxRealises.present
          ? data.travauxRealises.value
          : this.travauxRealises,
      statut: data.statut.present ? data.statut.value : this.statut,
      dateRealisation: data.dateRealisation.present
          ? data.dateRealisation.value
          : this.dateRealisation,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      misAJourLe: data.misAJourLe.present
          ? data.misAJourLe.value
          : this.misAJourLe,
      statutSync: data.statutSync.present
          ? data.statutSync.value
          : this.statutSync,
      modifieLocalementLe: data.modifieLocalementLe.present
          ? data.modifieLocalementLe.value
          : this.modifieLocalementLe,
      vueLe: data.vueLe.present ? data.vueLe.value : this.vueLe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Intervention(')
          ..write('idServeur: $idServeur, ')
          ..write('nomClient: $nomClient, ')
          ..write('adresse: $adresse, ')
          ..write('telephone1: $telephone1, ')
          ..write('telephone2: $telephone2, ')
          ..write('geolocalisation: $geolocalisation, ')
          ..write('motifSignale: $motifSignale, ')
          ..write('datePrevue: $datePrevue, ')
          ..write('technicienId: $technicienId, ')
          ..write('creeParId: $creeParId, ')
          ..write('typeEquipement: $typeEquipement, ')
          ..write('problemeConstate: $problemeConstate, ')
          ..write('travauxRealises: $travauxRealises, ')
          ..write('statut: $statut, ')
          ..write('dateRealisation: $dateRealisation, ')
          ..write('creeLe: $creeLe, ')
          ..write('misAJourLe: $misAJourLe, ')
          ..write('statutSync: $statutSync, ')
          ..write('modifieLocalementLe: $modifieLocalementLe, ')
          ..write('vueLe: $vueLe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idServeur,
    nomClient,
    adresse,
    telephone1,
    telephone2,
    geolocalisation,
    motifSignale,
    datePrevue,
    technicienId,
    creeParId,
    typeEquipement,
    problemeConstate,
    travauxRealises,
    statut,
    dateRealisation,
    creeLe,
    misAJourLe,
    statutSync,
    modifieLocalementLe,
    vueLe,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Intervention &&
          other.idServeur == this.idServeur &&
          other.nomClient == this.nomClient &&
          other.adresse == this.adresse &&
          other.telephone1 == this.telephone1 &&
          other.telephone2 == this.telephone2 &&
          other.geolocalisation == this.geolocalisation &&
          other.motifSignale == this.motifSignale &&
          other.datePrevue == this.datePrevue &&
          other.technicienId == this.technicienId &&
          other.creeParId == this.creeParId &&
          other.typeEquipement == this.typeEquipement &&
          other.problemeConstate == this.problemeConstate &&
          other.travauxRealises == this.travauxRealises &&
          other.statut == this.statut &&
          other.dateRealisation == this.dateRealisation &&
          other.creeLe == this.creeLe &&
          other.misAJourLe == this.misAJourLe &&
          other.statutSync == this.statutSync &&
          other.modifieLocalementLe == this.modifieLocalementLe &&
          other.vueLe == this.vueLe);
}

class InterventionsCompanion extends UpdateCompanion<Intervention> {
  final Value<String> idServeur;
  final Value<String> nomClient;
  final Value<String> adresse;
  final Value<String> telephone1;
  final Value<String?> telephone2;
  final Value<String?> geolocalisation;
  final Value<String?> motifSignale;
  final Value<DateTime> datePrevue;
  final Value<String> technicienId;
  final Value<String> creeParId;
  final Value<TypeEquipement?> typeEquipement;
  final Value<String?> problemeConstate;
  final Value<String?> travauxRealises;
  final Value<StatutIntervention> statut;
  final Value<DateTime?> dateRealisation;
  final Value<DateTime> creeLe;
  final Value<DateTime> misAJourLe;
  final Value<StatutSync> statutSync;
  final Value<DateTime?> modifieLocalementLe;
  final Value<DateTime?> vueLe;
  final Value<int> rowid;
  const InterventionsCompanion({
    this.idServeur = const Value.absent(),
    this.nomClient = const Value.absent(),
    this.adresse = const Value.absent(),
    this.telephone1 = const Value.absent(),
    this.telephone2 = const Value.absent(),
    this.geolocalisation = const Value.absent(),
    this.motifSignale = const Value.absent(),
    this.datePrevue = const Value.absent(),
    this.technicienId = const Value.absent(),
    this.creeParId = const Value.absent(),
    this.typeEquipement = const Value.absent(),
    this.problemeConstate = const Value.absent(),
    this.travauxRealises = const Value.absent(),
    this.statut = const Value.absent(),
    this.dateRealisation = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.misAJourLe = const Value.absent(),
    this.statutSync = const Value.absent(),
    this.modifieLocalementLe = const Value.absent(),
    this.vueLe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InterventionsCompanion.insert({
    required String idServeur,
    required String nomClient,
    required String adresse,
    required String telephone1,
    this.telephone2 = const Value.absent(),
    this.geolocalisation = const Value.absent(),
    this.motifSignale = const Value.absent(),
    required DateTime datePrevue,
    required String technicienId,
    required String creeParId,
    this.typeEquipement = const Value.absent(),
    this.problemeConstate = const Value.absent(),
    this.travauxRealises = const Value.absent(),
    required StatutIntervention statut,
    this.dateRealisation = const Value.absent(),
    required DateTime creeLe,
    required DateTime misAJourLe,
    required StatutSync statutSync,
    this.modifieLocalementLe = const Value.absent(),
    this.vueLe = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idServeur = Value(idServeur),
       nomClient = Value(nomClient),
       adresse = Value(adresse),
       telephone1 = Value(telephone1),
       datePrevue = Value(datePrevue),
       technicienId = Value(technicienId),
       creeParId = Value(creeParId),
       statut = Value(statut),
       creeLe = Value(creeLe),
       misAJourLe = Value(misAJourLe),
       statutSync = Value(statutSync);
  static Insertable<Intervention> custom({
    Expression<String>? idServeur,
    Expression<String>? nomClient,
    Expression<String>? adresse,
    Expression<String>? telephone1,
    Expression<String>? telephone2,
    Expression<String>? geolocalisation,
    Expression<String>? motifSignale,
    Expression<DateTime>? datePrevue,
    Expression<String>? technicienId,
    Expression<String>? creeParId,
    Expression<String>? typeEquipement,
    Expression<String>? problemeConstate,
    Expression<String>? travauxRealises,
    Expression<String>? statut,
    Expression<DateTime>? dateRealisation,
    Expression<DateTime>? creeLe,
    Expression<DateTime>? misAJourLe,
    Expression<String>? statutSync,
    Expression<DateTime>? modifieLocalementLe,
    Expression<DateTime>? vueLe,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idServeur != null) 'id_serveur': idServeur,
      if (nomClient != null) 'nom_client': nomClient,
      if (adresse != null) 'adresse': adresse,
      if (telephone1 != null) 'telephone1': telephone1,
      if (telephone2 != null) 'telephone2': telephone2,
      if (geolocalisation != null) 'geolocalisation': geolocalisation,
      if (motifSignale != null) 'motif_signale': motifSignale,
      if (datePrevue != null) 'date_prevue': datePrevue,
      if (technicienId != null) 'technicien_id': technicienId,
      if (creeParId != null) 'cree_par_id': creeParId,
      if (typeEquipement != null) 'type_equipement': typeEquipement,
      if (problemeConstate != null) 'probleme_constate': problemeConstate,
      if (travauxRealises != null) 'travaux_realises': travauxRealises,
      if (statut != null) 'statut': statut,
      if (dateRealisation != null) 'date_realisation': dateRealisation,
      if (creeLe != null) 'cree_le': creeLe,
      if (misAJourLe != null) 'mis_a_jour_le': misAJourLe,
      if (statutSync != null) 'statut_sync': statutSync,
      if (modifieLocalementLe != null)
        'modifie_localement_le': modifieLocalementLe,
      if (vueLe != null) 'vue_le': vueLe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InterventionsCompanion copyWith({
    Value<String>? idServeur,
    Value<String>? nomClient,
    Value<String>? adresse,
    Value<String>? telephone1,
    Value<String?>? telephone2,
    Value<String?>? geolocalisation,
    Value<String?>? motifSignale,
    Value<DateTime>? datePrevue,
    Value<String>? technicienId,
    Value<String>? creeParId,
    Value<TypeEquipement?>? typeEquipement,
    Value<String?>? problemeConstate,
    Value<String?>? travauxRealises,
    Value<StatutIntervention>? statut,
    Value<DateTime?>? dateRealisation,
    Value<DateTime>? creeLe,
    Value<DateTime>? misAJourLe,
    Value<StatutSync>? statutSync,
    Value<DateTime?>? modifieLocalementLe,
    Value<DateTime?>? vueLe,
    Value<int>? rowid,
  }) {
    return InterventionsCompanion(
      idServeur: idServeur ?? this.idServeur,
      nomClient: nomClient ?? this.nomClient,
      adresse: adresse ?? this.adresse,
      telephone1: telephone1 ?? this.telephone1,
      telephone2: telephone2 ?? this.telephone2,
      geolocalisation: geolocalisation ?? this.geolocalisation,
      motifSignale: motifSignale ?? this.motifSignale,
      datePrevue: datePrevue ?? this.datePrevue,
      technicienId: technicienId ?? this.technicienId,
      creeParId: creeParId ?? this.creeParId,
      typeEquipement: typeEquipement ?? this.typeEquipement,
      problemeConstate: problemeConstate ?? this.problemeConstate,
      travauxRealises: travauxRealises ?? this.travauxRealises,
      statut: statut ?? this.statut,
      dateRealisation: dateRealisation ?? this.dateRealisation,
      creeLe: creeLe ?? this.creeLe,
      misAJourLe: misAJourLe ?? this.misAJourLe,
      statutSync: statutSync ?? this.statutSync,
      modifieLocalementLe: modifieLocalementLe ?? this.modifieLocalementLe,
      vueLe: vueLe ?? this.vueLe,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idServeur.present) {
      map['id_serveur'] = Variable<String>(idServeur.value);
    }
    if (nomClient.present) {
      map['nom_client'] = Variable<String>(nomClient.value);
    }
    if (adresse.present) {
      map['adresse'] = Variable<String>(adresse.value);
    }
    if (telephone1.present) {
      map['telephone1'] = Variable<String>(telephone1.value);
    }
    if (telephone2.present) {
      map['telephone2'] = Variable<String>(telephone2.value);
    }
    if (geolocalisation.present) {
      map['geolocalisation'] = Variable<String>(geolocalisation.value);
    }
    if (motifSignale.present) {
      map['motif_signale'] = Variable<String>(motifSignale.value);
    }
    if (datePrevue.present) {
      map['date_prevue'] = Variable<DateTime>(datePrevue.value);
    }
    if (technicienId.present) {
      map['technicien_id'] = Variable<String>(technicienId.value);
    }
    if (creeParId.present) {
      map['cree_par_id'] = Variable<String>(creeParId.value);
    }
    if (typeEquipement.present) {
      map['type_equipement'] = Variable<String>(
        $InterventionsTable.$convertertypeEquipementn.toSql(
          typeEquipement.value,
        ),
      );
    }
    if (problemeConstate.present) {
      map['probleme_constate'] = Variable<String>(problemeConstate.value);
    }
    if (travauxRealises.present) {
      map['travaux_realises'] = Variable<String>(travauxRealises.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(
        $InterventionsTable.$converterstatut.toSql(statut.value),
      );
    }
    if (dateRealisation.present) {
      map['date_realisation'] = Variable<DateTime>(dateRealisation.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (misAJourLe.present) {
      map['mis_a_jour_le'] = Variable<DateTime>(misAJourLe.value);
    }
    if (statutSync.present) {
      map['statut_sync'] = Variable<String>(
        $InterventionsTable.$converterstatutSync.toSql(statutSync.value),
      );
    }
    if (modifieLocalementLe.present) {
      map['modifie_localement_le'] = Variable<DateTime>(
        modifieLocalementLe.value,
      );
    }
    if (vueLe.present) {
      map['vue_le'] = Variable<DateTime>(vueLe.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InterventionsCompanion(')
          ..write('idServeur: $idServeur, ')
          ..write('nomClient: $nomClient, ')
          ..write('adresse: $adresse, ')
          ..write('telephone1: $telephone1, ')
          ..write('telephone2: $telephone2, ')
          ..write('geolocalisation: $geolocalisation, ')
          ..write('motifSignale: $motifSignale, ')
          ..write('datePrevue: $datePrevue, ')
          ..write('technicienId: $technicienId, ')
          ..write('creeParId: $creeParId, ')
          ..write('typeEquipement: $typeEquipement, ')
          ..write('problemeConstate: $problemeConstate, ')
          ..write('travauxRealises: $travauxRealises, ')
          ..write('statut: $statut, ')
          ..write('dateRealisation: $dateRealisation, ')
          ..write('creeLe: $creeLe, ')
          ..write('misAJourLe: $misAJourLe, ')
          ..write('statutSync: $statutSync, ')
          ..write('modifieLocalementLe: $modifieLocalementLe, ')
          ..write('vueLe: $vueLe, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idLocalMeta = const VerificationMeta(
    'idLocal',
  );
  @override
  late final GeneratedColumn<int> idLocal = GeneratedColumn<int>(
    'id_local',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idServeurMeta = const VerificationMeta(
    'idServeur',
  );
  @override
  late final GeneratedColumn<String> idServeur = GeneratedColumn<String>(
    'id_serveur',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interventionIdLocalMeta =
      const VerificationMeta('interventionIdLocal');
  @override
  late final GeneratedColumn<String> interventionIdLocal =
      GeneratedColumn<String>(
        'intervention_id_local',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES interventions (id_serveur)',
        ),
      );
  @override
  late final GeneratedColumnWithTypeConverter<CategoriePhoto, String>
  categorie = GeneratedColumn<String>(
    'categorie',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CategoriePhoto>($PhotosTable.$convertercategorie);
  static const VerificationMeta _cheminLocalMeta = const VerificationMeta(
    'cheminLocal',
  );
  @override
  late final GeneratedColumn<String> cheminLocal = GeneratedColumn<String>(
    'chemin_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creeLeMeta = const VerificationMeta('creeLe');
  @override
  late final GeneratedColumn<DateTime> creeLe = GeneratedColumn<DateTime>(
    'cree_le',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StatutSync, String> statutSync =
      GeneratedColumn<String>(
        'statut_sync',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StatutSync>($PhotosTable.$converterstatutSync);
  @override
  List<GeneratedColumn> get $columns => [
    idLocal,
    idServeur,
    interventionIdLocal,
    categorie,
    cheminLocal,
    creeLe,
    statutSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id_local')) {
      context.handle(
        _idLocalMeta,
        idLocal.isAcceptableOrUnknown(data['id_local']!, _idLocalMeta),
      );
    }
    if (data.containsKey('id_serveur')) {
      context.handle(
        _idServeurMeta,
        idServeur.isAcceptableOrUnknown(data['id_serveur']!, _idServeurMeta),
      );
    }
    if (data.containsKey('intervention_id_local')) {
      context.handle(
        _interventionIdLocalMeta,
        interventionIdLocal.isAcceptableOrUnknown(
          data['intervention_id_local']!,
          _interventionIdLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interventionIdLocalMeta);
    }
    if (data.containsKey('chemin_local')) {
      context.handle(
        _cheminLocalMeta,
        cheminLocal.isAcceptableOrUnknown(
          data['chemin_local']!,
          _cheminLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cheminLocalMeta);
    }
    if (data.containsKey('cree_le')) {
      context.handle(
        _creeLeMeta,
        creeLe.isAcceptableOrUnknown(data['cree_le']!, _creeLeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idLocal};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      idLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id_local'],
      )!,
      idServeur: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_serveur'],
      ),
      interventionIdLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intervention_id_local'],
      )!,
      categorie: $PhotosTable.$convertercategorie.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}categorie'],
        )!,
      ),
      cheminLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chemin_local'],
      )!,
      creeLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le'],
      )!,
      statutSync: $PhotosTable.$converterstatutSync.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}statut_sync'],
        )!,
      ),
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoriePhoto, String, String>
  $convertercategorie = const EnumNameConverter<CategoriePhoto>(
    CategoriePhoto.values,
  );
  static JsonTypeConverter2<StatutSync, String, String> $converterstatutSync =
      const EnumNameConverter<StatutSync>(StatutSync.values);
}

class Photo extends DataClass implements Insertable<Photo> {
  final int idLocal;
  final String? idServeur;
  final String interventionIdLocal;
  final CategoriePhoto categorie;
  final String cheminLocal;
  final DateTime creeLe;
  final StatutSync statutSync;
  const Photo({
    required this.idLocal,
    this.idServeur,
    required this.interventionIdLocal,
    required this.categorie,
    required this.cheminLocal,
    required this.creeLe,
    required this.statutSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id_local'] = Variable<int>(idLocal);
    if (!nullToAbsent || idServeur != null) {
      map['id_serveur'] = Variable<String>(idServeur);
    }
    map['intervention_id_local'] = Variable<String>(interventionIdLocal);
    {
      map['categorie'] = Variable<String>(
        $PhotosTable.$convertercategorie.toSql(categorie),
      );
    }
    map['chemin_local'] = Variable<String>(cheminLocal);
    map['cree_le'] = Variable<DateTime>(creeLe);
    {
      map['statut_sync'] = Variable<String>(
        $PhotosTable.$converterstatutSync.toSql(statutSync),
      );
    }
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      idLocal: Value(idLocal),
      idServeur: idServeur == null && nullToAbsent
          ? const Value.absent()
          : Value(idServeur),
      interventionIdLocal: Value(interventionIdLocal),
      categorie: Value(categorie),
      cheminLocal: Value(cheminLocal),
      creeLe: Value(creeLe),
      statutSync: Value(statutSync),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      idLocal: serializer.fromJson<int>(json['idLocal']),
      idServeur: serializer.fromJson<String?>(json['idServeur']),
      interventionIdLocal: serializer.fromJson<String>(
        json['interventionIdLocal'],
      ),
      categorie: $PhotosTable.$convertercategorie.fromJson(
        serializer.fromJson<String>(json['categorie']),
      ),
      cheminLocal: serializer.fromJson<String>(json['cheminLocal']),
      creeLe: serializer.fromJson<DateTime>(json['creeLe']),
      statutSync: $PhotosTable.$converterstatutSync.fromJson(
        serializer.fromJson<String>(json['statutSync']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idLocal': serializer.toJson<int>(idLocal),
      'idServeur': serializer.toJson<String?>(idServeur),
      'interventionIdLocal': serializer.toJson<String>(interventionIdLocal),
      'categorie': serializer.toJson<String>(
        $PhotosTable.$convertercategorie.toJson(categorie),
      ),
      'cheminLocal': serializer.toJson<String>(cheminLocal),
      'creeLe': serializer.toJson<DateTime>(creeLe),
      'statutSync': serializer.toJson<String>(
        $PhotosTable.$converterstatutSync.toJson(statutSync),
      ),
    };
  }

  Photo copyWith({
    int? idLocal,
    Value<String?> idServeur = const Value.absent(),
    String? interventionIdLocal,
    CategoriePhoto? categorie,
    String? cheminLocal,
    DateTime? creeLe,
    StatutSync? statutSync,
  }) => Photo(
    idLocal: idLocal ?? this.idLocal,
    idServeur: idServeur.present ? idServeur.value : this.idServeur,
    interventionIdLocal: interventionIdLocal ?? this.interventionIdLocal,
    categorie: categorie ?? this.categorie,
    cheminLocal: cheminLocal ?? this.cheminLocal,
    creeLe: creeLe ?? this.creeLe,
    statutSync: statutSync ?? this.statutSync,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      idLocal: data.idLocal.present ? data.idLocal.value : this.idLocal,
      idServeur: data.idServeur.present ? data.idServeur.value : this.idServeur,
      interventionIdLocal: data.interventionIdLocal.present
          ? data.interventionIdLocal.value
          : this.interventionIdLocal,
      categorie: data.categorie.present ? data.categorie.value : this.categorie,
      cheminLocal: data.cheminLocal.present
          ? data.cheminLocal.value
          : this.cheminLocal,
      creeLe: data.creeLe.present ? data.creeLe.value : this.creeLe,
      statutSync: data.statutSync.present
          ? data.statutSync.value
          : this.statutSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('idLocal: $idLocal, ')
          ..write('idServeur: $idServeur, ')
          ..write('interventionIdLocal: $interventionIdLocal, ')
          ..write('categorie: $categorie, ')
          ..write('cheminLocal: $cheminLocal, ')
          ..write('creeLe: $creeLe, ')
          ..write('statutSync: $statutSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idLocal,
    idServeur,
    interventionIdLocal,
    categorie,
    cheminLocal,
    creeLe,
    statutSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.idLocal == this.idLocal &&
          other.idServeur == this.idServeur &&
          other.interventionIdLocal == this.interventionIdLocal &&
          other.categorie == this.categorie &&
          other.cheminLocal == this.cheminLocal &&
          other.creeLe == this.creeLe &&
          other.statutSync == this.statutSync);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<int> idLocal;
  final Value<String?> idServeur;
  final Value<String> interventionIdLocal;
  final Value<CategoriePhoto> categorie;
  final Value<String> cheminLocal;
  final Value<DateTime> creeLe;
  final Value<StatutSync> statutSync;
  const PhotosCompanion({
    this.idLocal = const Value.absent(),
    this.idServeur = const Value.absent(),
    this.interventionIdLocal = const Value.absent(),
    this.categorie = const Value.absent(),
    this.cheminLocal = const Value.absent(),
    this.creeLe = const Value.absent(),
    this.statutSync = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.idLocal = const Value.absent(),
    this.idServeur = const Value.absent(),
    required String interventionIdLocal,
    required CategoriePhoto categorie,
    required String cheminLocal,
    this.creeLe = const Value.absent(),
    required StatutSync statutSync,
  }) : interventionIdLocal = Value(interventionIdLocal),
       categorie = Value(categorie),
       cheminLocal = Value(cheminLocal),
       statutSync = Value(statutSync);
  static Insertable<Photo> custom({
    Expression<int>? idLocal,
    Expression<String>? idServeur,
    Expression<String>? interventionIdLocal,
    Expression<String>? categorie,
    Expression<String>? cheminLocal,
    Expression<DateTime>? creeLe,
    Expression<String>? statutSync,
  }) {
    return RawValuesInsertable({
      if (idLocal != null) 'id_local': idLocal,
      if (idServeur != null) 'id_serveur': idServeur,
      if (interventionIdLocal != null)
        'intervention_id_local': interventionIdLocal,
      if (categorie != null) 'categorie': categorie,
      if (cheminLocal != null) 'chemin_local': cheminLocal,
      if (creeLe != null) 'cree_le': creeLe,
      if (statutSync != null) 'statut_sync': statutSync,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? idLocal,
    Value<String?>? idServeur,
    Value<String>? interventionIdLocal,
    Value<CategoriePhoto>? categorie,
    Value<String>? cheminLocal,
    Value<DateTime>? creeLe,
    Value<StatutSync>? statutSync,
  }) {
    return PhotosCompanion(
      idLocal: idLocal ?? this.idLocal,
      idServeur: idServeur ?? this.idServeur,
      interventionIdLocal: interventionIdLocal ?? this.interventionIdLocal,
      categorie: categorie ?? this.categorie,
      cheminLocal: cheminLocal ?? this.cheminLocal,
      creeLe: creeLe ?? this.creeLe,
      statutSync: statutSync ?? this.statutSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idLocal.present) {
      map['id_local'] = Variable<int>(idLocal.value);
    }
    if (idServeur.present) {
      map['id_serveur'] = Variable<String>(idServeur.value);
    }
    if (interventionIdLocal.present) {
      map['intervention_id_local'] = Variable<String>(
        interventionIdLocal.value,
      );
    }
    if (categorie.present) {
      map['categorie'] = Variable<String>(
        $PhotosTable.$convertercategorie.toSql(categorie.value),
      );
    }
    if (cheminLocal.present) {
      map['chemin_local'] = Variable<String>(cheminLocal.value);
    }
    if (creeLe.present) {
      map['cree_le'] = Variable<DateTime>(creeLe.value);
    }
    if (statutSync.present) {
      map['statut_sync'] = Variable<String>(
        $PhotosTable.$converterstatutSync.toSql(statutSync.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('idLocal: $idLocal, ')
          ..write('idServeur: $idServeur, ')
          ..write('interventionIdLocal: $interventionIdLocal, ')
          ..write('categorie: $categorie, ')
          ..write('cheminLocal: $cheminLocal, ')
          ..write('creeLe: $creeLe, ')
          ..write('statutSync: $statutSync')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InterventionsTable interventions = $InterventionsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final InterventionDao interventionDao = InterventionDao(
    this as AppDatabase,
  );
  late final PhotoDao photoDao = PhotoDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [interventions, photos];
}

typedef $$InterventionsTableCreateCompanionBuilder =
    InterventionsCompanion Function({
      required String idServeur,
      required String nomClient,
      required String adresse,
      required String telephone1,
      Value<String?> telephone2,
      Value<String?> geolocalisation,
      Value<String?> motifSignale,
      required DateTime datePrevue,
      required String technicienId,
      required String creeParId,
      Value<TypeEquipement?> typeEquipement,
      Value<String?> problemeConstate,
      Value<String?> travauxRealises,
      required StatutIntervention statut,
      Value<DateTime?> dateRealisation,
      required DateTime creeLe,
      required DateTime misAJourLe,
      required StatutSync statutSync,
      Value<DateTime?> modifieLocalementLe,
      Value<DateTime?> vueLe,
      Value<int> rowid,
    });
typedef $$InterventionsTableUpdateCompanionBuilder =
    InterventionsCompanion Function({
      Value<String> idServeur,
      Value<String> nomClient,
      Value<String> adresse,
      Value<String> telephone1,
      Value<String?> telephone2,
      Value<String?> geolocalisation,
      Value<String?> motifSignale,
      Value<DateTime> datePrevue,
      Value<String> technicienId,
      Value<String> creeParId,
      Value<TypeEquipement?> typeEquipement,
      Value<String?> problemeConstate,
      Value<String?> travauxRealises,
      Value<StatutIntervention> statut,
      Value<DateTime?> dateRealisation,
      Value<DateTime> creeLe,
      Value<DateTime> misAJourLe,
      Value<StatutSync> statutSync,
      Value<DateTime?> modifieLocalementLe,
      Value<DateTime?> vueLe,
      Value<int> rowid,
    });

final class $$InterventionsTableReferences
    extends BaseReferences<_$AppDatabase, $InterventionsTable, Intervention> {
  $$InterventionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PhotosTable, List<Photo>> _photosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.photos,
    aliasName: 'interventions__id_serveur__photos__intervention_id_local',
  );

  $$PhotosTableProcessedTableManager get photosRefs {
    final manager = $$PhotosTableTableManager($_db, $_db.photos).filter(
      (f) => f.interventionIdLocal.idServeur.sqlEquals(
        $_itemColumn<String>('id_serveur')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InterventionsTableFilterComposer
    extends Composer<_$AppDatabase, $InterventionsTable> {
  $$InterventionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idServeur => $composableBuilder(
    column: $table.idServeur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nomClient => $composableBuilder(
    column: $table.nomClient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adresse => $composableBuilder(
    column: $table.adresse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telephone1 => $composableBuilder(
    column: $table.telephone1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telephone2 => $composableBuilder(
    column: $table.telephone2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geolocalisation => $composableBuilder(
    column: $table.geolocalisation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motifSignale => $composableBuilder(
    column: $table.motifSignale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get datePrevue => $composableBuilder(
    column: $table.datePrevue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get technicienId => $composableBuilder(
    column: $table.technicienId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creeParId => $composableBuilder(
    column: $table.creeParId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TypeEquipement?, TypeEquipement, String>
  get typeEquipement => $composableBuilder(
    column: $table.typeEquipement,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get problemeConstate => $composableBuilder(
    column: $table.problemeConstate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get travauxRealises => $composableBuilder(
    column: $table.travauxRealises,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StatutIntervention, StatutIntervention, String>
  get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get dateRealisation => $composableBuilder(
    column: $table.dateRealisation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get misAJourLe => $composableBuilder(
    column: $table.misAJourLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StatutSync, StatutSync, String>
  get statutSync => $composableBuilder(
    column: $table.statutSync,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get modifieLocalementLe => $composableBuilder(
    column: $table.modifieLocalementLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get vueLe => $composableBuilder(
    column: $table.vueLe,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> photosRefs(
    Expression<bool> Function($$PhotosTableFilterComposer f) f,
  ) {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idServeur,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.interventionIdLocal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InterventionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InterventionsTable> {
  $$InterventionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idServeur => $composableBuilder(
    column: $table.idServeur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nomClient => $composableBuilder(
    column: $table.nomClient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adresse => $composableBuilder(
    column: $table.adresse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telephone1 => $composableBuilder(
    column: $table.telephone1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telephone2 => $composableBuilder(
    column: $table.telephone2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geolocalisation => $composableBuilder(
    column: $table.geolocalisation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motifSignale => $composableBuilder(
    column: $table.motifSignale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get datePrevue => $composableBuilder(
    column: $table.datePrevue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get technicienId => $composableBuilder(
    column: $table.technicienId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creeParId => $composableBuilder(
    column: $table.creeParId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeEquipement => $composableBuilder(
    column: $table.typeEquipement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get problemeConstate => $composableBuilder(
    column: $table.problemeConstate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get travauxRealises => $composableBuilder(
    column: $table.travauxRealises,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateRealisation => $composableBuilder(
    column: $table.dateRealisation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get misAJourLe => $composableBuilder(
    column: $table.misAJourLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statutSync => $composableBuilder(
    column: $table.statutSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifieLocalementLe => $composableBuilder(
    column: $table.modifieLocalementLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get vueLe => $composableBuilder(
    column: $table.vueLe,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InterventionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InterventionsTable> {
  $$InterventionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idServeur =>
      $composableBuilder(column: $table.idServeur, builder: (column) => column);

  GeneratedColumn<String> get nomClient =>
      $composableBuilder(column: $table.nomClient, builder: (column) => column);

  GeneratedColumn<String> get adresse =>
      $composableBuilder(column: $table.adresse, builder: (column) => column);

  GeneratedColumn<String> get telephone1 => $composableBuilder(
    column: $table.telephone1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get telephone2 => $composableBuilder(
    column: $table.telephone2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geolocalisation => $composableBuilder(
    column: $table.geolocalisation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motifSignale => $composableBuilder(
    column: $table.motifSignale,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get datePrevue => $composableBuilder(
    column: $table.datePrevue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get technicienId => $composableBuilder(
    column: $table.technicienId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creeParId =>
      $composableBuilder(column: $table.creeParId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TypeEquipement?, String>
  get typeEquipement => $composableBuilder(
    column: $table.typeEquipement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get problemeConstate => $composableBuilder(
    column: $table.problemeConstate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get travauxRealises => $composableBuilder(
    column: $table.travauxRealises,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<StatutIntervention, String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get dateRealisation => $composableBuilder(
    column: $table.dateRealisation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumn<DateTime> get misAJourLe => $composableBuilder(
    column: $table.misAJourLe,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<StatutSync, String> get statutSync =>
      $composableBuilder(
        column: $table.statutSync,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get modifieLocalementLe => $composableBuilder(
    column: $table.modifieLocalementLe,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get vueLe =>
      $composableBuilder(column: $table.vueLe, builder: (column) => column);

  Expression<T> photosRefs<T extends Object>(
    Expression<T> Function($$PhotosTableAnnotationComposer a) f,
  ) {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.idServeur,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.interventionIdLocal,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InterventionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InterventionsTable,
          Intervention,
          $$InterventionsTableFilterComposer,
          $$InterventionsTableOrderingComposer,
          $$InterventionsTableAnnotationComposer,
          $$InterventionsTableCreateCompanionBuilder,
          $$InterventionsTableUpdateCompanionBuilder,
          (Intervention, $$InterventionsTableReferences),
          Intervention,
          PrefetchHooks Function({bool photosRefs})
        > {
  $$InterventionsTableTableManager(_$AppDatabase db, $InterventionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InterventionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InterventionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InterventionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> idServeur = const Value.absent(),
                Value<String> nomClient = const Value.absent(),
                Value<String> adresse = const Value.absent(),
                Value<String> telephone1 = const Value.absent(),
                Value<String?> telephone2 = const Value.absent(),
                Value<String?> geolocalisation = const Value.absent(),
                Value<String?> motifSignale = const Value.absent(),
                Value<DateTime> datePrevue = const Value.absent(),
                Value<String> technicienId = const Value.absent(),
                Value<String> creeParId = const Value.absent(),
                Value<TypeEquipement?> typeEquipement = const Value.absent(),
                Value<String?> problemeConstate = const Value.absent(),
                Value<String?> travauxRealises = const Value.absent(),
                Value<StatutIntervention> statut = const Value.absent(),
                Value<DateTime?> dateRealisation = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<DateTime> misAJourLe = const Value.absent(),
                Value<StatutSync> statutSync = const Value.absent(),
                Value<DateTime?> modifieLocalementLe = const Value.absent(),
                Value<DateTime?> vueLe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InterventionsCompanion(
                idServeur: idServeur,
                nomClient: nomClient,
                adresse: adresse,
                telephone1: telephone1,
                telephone2: telephone2,
                geolocalisation: geolocalisation,
                motifSignale: motifSignale,
                datePrevue: datePrevue,
                technicienId: technicienId,
                creeParId: creeParId,
                typeEquipement: typeEquipement,
                problemeConstate: problemeConstate,
                travauxRealises: travauxRealises,
                statut: statut,
                dateRealisation: dateRealisation,
                creeLe: creeLe,
                misAJourLe: misAJourLe,
                statutSync: statutSync,
                modifieLocalementLe: modifieLocalementLe,
                vueLe: vueLe,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idServeur,
                required String nomClient,
                required String adresse,
                required String telephone1,
                Value<String?> telephone2 = const Value.absent(),
                Value<String?> geolocalisation = const Value.absent(),
                Value<String?> motifSignale = const Value.absent(),
                required DateTime datePrevue,
                required String technicienId,
                required String creeParId,
                Value<TypeEquipement?> typeEquipement = const Value.absent(),
                Value<String?> problemeConstate = const Value.absent(),
                Value<String?> travauxRealises = const Value.absent(),
                required StatutIntervention statut,
                Value<DateTime?> dateRealisation = const Value.absent(),
                required DateTime creeLe,
                required DateTime misAJourLe,
                required StatutSync statutSync,
                Value<DateTime?> modifieLocalementLe = const Value.absent(),
                Value<DateTime?> vueLe = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InterventionsCompanion.insert(
                idServeur: idServeur,
                nomClient: nomClient,
                adresse: adresse,
                telephone1: telephone1,
                telephone2: telephone2,
                geolocalisation: geolocalisation,
                motifSignale: motifSignale,
                datePrevue: datePrevue,
                technicienId: technicienId,
                creeParId: creeParId,
                typeEquipement: typeEquipement,
                problemeConstate: problemeConstate,
                travauxRealises: travauxRealises,
                statut: statut,
                dateRealisation: dateRealisation,
                creeLe: creeLe,
                misAJourLe: misAJourLe,
                statutSync: statutSync,
                modifieLocalementLe: modifieLocalementLe,
                vueLe: vueLe,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InterventionsTable, Intervention>(table),
                  $$InterventionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({photosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (photosRefs) db.photos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (photosRefs)
                    await $_getPrefetchedData<
                      Intervention,
                      $InterventionsTable,
                      Photo
                    >(
                      currentTable: table,
                      referencedTable: $$InterventionsTableReferences
                          ._photosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InterventionsTableReferences(
                            db,
                            table,
                            p0,
                          ).photosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.interventionIdLocal == item.idServeur,
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

typedef $$InterventionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InterventionsTable,
      Intervention,
      $$InterventionsTableFilterComposer,
      $$InterventionsTableOrderingComposer,
      $$InterventionsTableAnnotationComposer,
      $$InterventionsTableCreateCompanionBuilder,
      $$InterventionsTableUpdateCompanionBuilder,
      (Intervention, $$InterventionsTableReferences),
      Intervention,
      PrefetchHooks Function({bool photosRefs})
    >;
typedef $$PhotosTableCreateCompanionBuilder = PhotosCompanion Function({
  Value<int> idLocal,
  Value<String?> idServeur,
  required String interventionIdLocal,
  required CategoriePhoto categorie,
  required String cheminLocal,
  Value<DateTime> creeLe,
  required StatutSync statutSync,
});
typedef $$PhotosTableUpdateCompanionBuilder = PhotosCompanion Function({
  Value<int> idLocal,
  Value<String?> idServeur,
  Value<String> interventionIdLocal,
  Value<CategoriePhoto> categorie,
  Value<String> cheminLocal,
  Value<DateTime> creeLe,
  Value<StatutSync> statutSync,
});

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, Photo> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InterventionsTable _interventionIdLocalTable(_$AppDatabase db) => db
      .interventions
      .createAlias('photos__intervention_id_local__interventions__id_serveur');

  $$InterventionsTableProcessedTableManager get interventionIdLocal {
    final $_column = $_itemColumn<String>('intervention_id_local')!;

    final manager = $$InterventionsTableTableManager(
      $_db,
      $_db.interventions,
    ).filter((f) => f.idServeur.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_interventionIdLocalTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get idLocal => $composableBuilder(
    column: $table.idLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idServeur => $composableBuilder(
    column: $table.idServeur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoriePhoto, CategoriePhoto, String>
  get categorie => $composableBuilder(
    column: $table.categorie,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get cheminLocal => $composableBuilder(
    column: $table.cheminLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StatutSync, StatutSync, String>
  get statutSync => $composableBuilder(
    column: $table.statutSync,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$InterventionsTableFilterComposer get interventionIdLocal {
    final $$InterventionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.interventionIdLocal,
      referencedTable: $db.interventions,
      getReferencedColumn: (t) => t.idServeur,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InterventionsTableFilterComposer(
            $db: $db,
            $table: $db.interventions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get idLocal => $composableBuilder(
    column: $table.idLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idServeur => $composableBuilder(
    column: $table.idServeur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorie => $composableBuilder(
    column: $table.categorie,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cheminLocal => $composableBuilder(
    column: $table.cheminLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLe => $composableBuilder(
    column: $table.creeLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statutSync => $composableBuilder(
    column: $table.statutSync,
    builder: (column) => ColumnOrderings(column),
  );

  $$InterventionsTableOrderingComposer get interventionIdLocal {
    final $$InterventionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.interventionIdLocal,
      referencedTable: $db.interventions,
      getReferencedColumn: (t) => t.idServeur,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InterventionsTableOrderingComposer(
            $db: $db,
            $table: $db.interventions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get idLocal =>
      $composableBuilder(column: $table.idLocal, builder: (column) => column);

  GeneratedColumn<String> get idServeur =>
      $composableBuilder(column: $table.idServeur, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoriePhoto, String> get categorie =>
      $composableBuilder(column: $table.categorie, builder: (column) => column);

  GeneratedColumn<String> get cheminLocal => $composableBuilder(
    column: $table.cheminLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLe =>
      $composableBuilder(column: $table.creeLe, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StatutSync, String> get statutSync =>
      $composableBuilder(
        column: $table.statutSync,
        builder: (column) => column,
      );

  $$InterventionsTableAnnotationComposer get interventionIdLocal {
    final $$InterventionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.interventionIdLocal,
      referencedTable: $db.interventions,
      getReferencedColumn: (t) => t.idServeur,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InterventionsTableAnnotationComposer(
            $db: $db,
            $table: $db.interventions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, $$PhotosTableReferences),
          Photo,
          PrefetchHooks Function({bool interventionIdLocal})
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> idLocal = const Value.absent(),
                Value<String?> idServeur = const Value.absent(),
                Value<String> interventionIdLocal = const Value.absent(),
                Value<CategoriePhoto> categorie = const Value.absent(),
                Value<String> cheminLocal = const Value.absent(),
                Value<DateTime> creeLe = const Value.absent(),
                Value<StatutSync> statutSync = const Value.absent(),
              }) => PhotosCompanion(
                idLocal: idLocal,
                idServeur: idServeur,
                interventionIdLocal: interventionIdLocal,
                categorie: categorie,
                cheminLocal: cheminLocal,
                creeLe: creeLe,
                statutSync: statutSync,
              ),
          createCompanionCallback:
              ({
                Value<int> idLocal = const Value.absent(),
                Value<String?> idServeur = const Value.absent(),
                required String interventionIdLocal,
                required CategoriePhoto categorie,
                required String cheminLocal,
                Value<DateTime> creeLe = const Value.absent(),
                required StatutSync statutSync,
              }) => PhotosCompanion.insert(
                idLocal: idLocal,
                idServeur: idServeur,
                interventionIdLocal: interventionIdLocal,
                categorie: categorie,
                cheminLocal: cheminLocal,
                creeLe: creeLe,
                statutSync: statutSync,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhotosTable, Photo>(table),
                  $$PhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({interventionIdLocal = false}) {
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
                    if (interventionIdLocal) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.interventionIdLocal,
                        referencedTable: $$PhotosTableReferences
                            ._interventionIdLocalTable(db),
                        referencedColumn: $$PhotosTableReferences
                            ._interventionIdLocalTable(db)
                            .idServeur,
                      ) as T;
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

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, $$PhotosTableReferences),
      Photo,
      PrefetchHooks Function({bool interventionIdLocal})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InterventionsTableTableManager get interventions =>
      $$InterventionsTableTableManager(_db, _db.interventions);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
}
