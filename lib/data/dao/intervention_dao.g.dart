// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_dao.dart';

// ignore_for_file: type=lint
mixin _$InterventionDaoMixin on DatabaseAccessor<AppDatabase> {
  $InterventionsTable get interventions => attachedDatabase.interventions;
  InterventionDaoManager get managers => InterventionDaoManager(this);
}

class InterventionDaoManager {
  final _$InterventionDaoMixin _db;
  InterventionDaoManager(this._db);
  $$InterventionsTableTableManager get interventions =>
      $$InterventionsTableTableManager(_db.attachedDatabase, _db.interventions);
}
