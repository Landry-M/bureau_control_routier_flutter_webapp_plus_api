import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ImageUtils {
  /// Classe pour gérer les images de manière compatible web et mobile
  static Widget buildImageWidget(dynamic imageSource, {BoxFit fit = BoxFit.cover}) {
    if (imageSource == null) {
      return const Icon(Icons.add_a_photo, size: 40, color: Colors.grey);
    }

    if (kIsWeb) {
      // Sur le web, utiliser Image.network ou Image.memory
      if (imageSource is XFile) {
        return FutureBuilder<Uint8List>(
          future: imageSource.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(snapshot.data!, fit: fit);
            }
            return const CircularProgressIndicator();
          },
        );
      } else if (imageSource is Uint8List) {
        return Image.memory(imageSource, fit: fit);
      }
    } else {
      // Sur mobile, utiliser Image.file
      if (imageSource is File) {
        return Image.file(imageSource, fit: fit);
      } else if (imageSource is XFile) {
        return Image.file(File(imageSource.path), fit: fit);
      }
    }

    return const Icon(Icons.error, color: Colors.red);
  }

  /// Convertit un XFile en File pour mobile ou garde XFile pour web
  static dynamic processPickedImage(XFile pickedFile) {
    if (kIsWeb) {
      return pickedFile; // Garde XFile pour le web
    } else {
      return File(pickedFile.path); // Convertit en File pour mobile
    }
  }

  /// Prépare les fichiers pour l'upload HTTP
  static Future<http.MultipartFile> createMultipartFile(dynamic imageSource, String fieldName) async {
    if (kIsWeb && imageSource is XFile) {
      final bytes = await imageSource.readAsBytes();
      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: imageSource.name,
      );
    } else if (!kIsWeb && imageSource is File) {
      return await http.MultipartFile.fromPath(fieldName, imageSource.path);
    } else if (imageSource is XFile) {
      // Fallback pour XFile sur mobile
      return await http.MultipartFile.fromPath(fieldName, imageSource.path);
    }
    
    throw Exception('Type d\'image non supporté pour l\'upload');
  }
}
