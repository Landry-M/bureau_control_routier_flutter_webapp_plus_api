import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Service de compression d'images avant upload
/// Réduit la taille des fichiers pour éviter les problèmes d'upload
class ImageCompressor {
  
  /// Taille maximale cible en MB
  static const double _targetSizeMB = 2.0;
  
  /// Qualité de compression par défaut (0-100)
  static const int _defaultQuality = 85;
  
  /// Dimensions maximales
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1080;
  
  /// Compresse une image si nécessaire
  /// Retourne le fichier compressé ou l'original si pas besoin
  static Future<File> compressIfNeeded(File file) async {
    try {
      // Vérifier la taille du fichier
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      debugPrint('📸 Image originale: ${fileSizeInMB.toStringAsFixed(2)} MB');
      
      // Si l'image est déjà petite, pas besoin de compresser
      if (fileSizeInMB <= _targetSizeMB) {
        debugPrint('✅ Taille OK, pas de compression nécessaire');
        return file;
      }
      
      // Compression nécessaire
      debugPrint('🔄 Compression en cours...');
      
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: _defaultQuality,
        minWidth: _maxWidth,
        minHeight: _maxHeight,
        format: CompressFormat.jpeg,
      );
      
      if (compressedFile != null) {
        final compressedSize = await File(compressedFile.path).length();
        final compressedMB = compressedSize / (1024 * 1024);
        
        debugPrint('✅ Compression réussie: ${compressedMB.toStringAsFixed(2)} MB');
        debugPrint('📉 Réduction: ${((fileSizeInMB - compressedMB) / fileSizeInMB * 100).toStringAsFixed(1)}%');
        
        return File(compressedFile.path);
      }
      
      // Si la compression échoue, retourner l'original
      debugPrint('⚠️ Compression échouée, utilisation de l\'original');
      return file;
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la compression: $e');
      // En cas d'erreur, retourner l'original
      return file;
    }
  }
  
  /// Compresse une liste d'images
  static Future<List<File>> compressMultiple(List<File> files) async {
    final compressed = <File>[];
    
    for (var i = 0; i < files.length; i++) {
      debugPrint('📸 Traitement image ${i + 1}/${files.length}');
      final compressedFile = await compressIfNeeded(files[i]);
      compressed.add(compressedFile);
    }
    
    return compressed;
  }
  
  /// Vérifie si un fichier dépasse la taille maximale
  static Future<bool> isFileTooLarge(File file, {double maxSizeMB = 5.0}) async {
    final sizeInBytes = await file.length();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB > maxSizeMB;
  }
  
  /// Retourne la taille d'un fichier en MB
  static Future<double> getFileSizeMB(File file) async {
    final sizeInBytes = await file.length();
    return sizeInBytes / (1024 * 1024);
  }
}
