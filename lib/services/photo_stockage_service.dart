import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as chemin;
import 'package:path_provider/path_provider.dart';

/// US2.7/US2.8 : capture une photo (appareil photo ou galerie) et la copie
/// dans le stockage permanent de l'app. Le fichier temporaire renvoye par
/// image_picker n'est pas garanti de survivre (cache systeme nettoye), d'ou
/// la copie immediate.
class PhotoStockageService {
  PhotoStockageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Renvoie le chemin local definitif de la photo, ou null si l'utilisateur
  /// annule la selection sans choisir de fichier.
  Future<String?> capturer(ImageSource source) async {
    final fichierSource = await _picker.pickImage(source: source, imageQuality: 80);
    if (fichierSource == null) return null;

    final dossierPhotos = Directory(
      chemin.join((await getApplicationDocumentsDirectory()).path, 'photos'),
    );
    await dossierPhotos.create(recursive: true);

    final destination = chemin.join(
      dossierPhotos.path,
      '${DateTime.now().microsecondsSinceEpoch}${chemin.extension(fichierSource.path)}',
    );
    await File(fichierSource.path).copy(destination);
    return destination;
  }

  /// Supprime le fichier local d'une photo. Best effort : ne fait rien si le
  /// fichier a deja disparu (nettoyage manuel du stockage par exemple).
  Future<void> supprimerFichier(String cheminLocal) async {
    final fichier = File(cheminLocal);
    if (await fichier.exists()) {
      await fichier.delete();
    }
  }
}
