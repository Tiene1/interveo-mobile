// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_dao.dart';

// ignore_for_file: type=lint
mixin _$PhotoDaoMixin on DatabaseAccessor<AppDatabase> {
  $InterventionsTable get interventions => attachedDatabase.interventions;
  $PhotosTable get photos => attachedDatabase.photos;
  PhotoDaoManager get managers => PhotoDaoManager(this);
}

class PhotoDaoManager {
  final _$PhotoDaoMixin _db;
  PhotoDaoManager(this._db);
  $$InterventionsTableTableManager get interventions =>
      $$InterventionsTableTableManager(_db.attachedDatabase, _db.interventions);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db.attachedDatabase, _db.photos);
}
