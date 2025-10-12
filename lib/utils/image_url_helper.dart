import '../config/api_config.dart';

/// Classe utilitaire pour gérer les URLs d'images
class ImageUrlHelper {
  /// Construit une URL complète pour une image
  /// Gère automatiquement les cas où le chemin commence ou non par un slash
  static String buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // Si le chemin est déjà une URL complète, le retourner tel quel
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    final baseUrl = ApiConfig.imageBaseUrl;
    
    // Normaliser les slashes pour éviter les doubles slashes
    // Si le baseUrl se termine par / et que le path commence par /, enlever l'un des deux
    // Si ni l'un ni l'autre n'a de slash, en ajouter un
    
    final baseEndsWithSlash = baseUrl.endsWith('/');
    final pathStartsWithSlash = imagePath.startsWith('/');
    
    if (baseEndsWithSlash && pathStartsWithSlash) {
      // Enlever le slash du début du path
      return '$baseUrl${imagePath.substring(1)}';
    } else if (!baseEndsWithSlash && !pathStartsWithSlash) {
      // Ajouter un slash entre les deux
      return '$baseUrl/$imagePath';
    } else {
      // Un seul des deux a un slash, c'est bon
      return '$baseUrl$imagePath';
    }
  }

  /// Construit une URL pour un fichier PHP de prévisualisation
  static String buildPreviewUrl(String phpFile, int id) {
    final baseUrl = ApiConfig.imageBaseUrl;
    final file = phpFile.startsWith('/') ? phpFile : '/$phpFile';
    return '$baseUrl$file?id=$id';
  }
}
