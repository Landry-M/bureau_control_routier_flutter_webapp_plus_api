<?php
/**
 * Vérifier les limites d'upload et MySQL
 */

header('Content-Type: text/plain; charset=UTF-8');

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║        LIMITES D'UPLOAD - DIAGNOSTIC COMPLET              ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

// 1. Limites PHP
echo "═══════════════════════════════════════════════════════════\n";
echo "📋 LIMITES PHP\n";
echo "═══════════════════════════════════════════════════════════\n\n";

$phpLimits = [
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'post_max_size' => ini_get('post_max_size'),
    'memory_limit' => ini_get('memory_limit'),
    'max_execution_time' => ini_get('max_execution_time'),
    'max_input_time' => ini_get('max_input_time')
];

function convertToBytes($val) {
    $val = trim($val);
    $last = strtolower($val[strlen($val)-1]);
    $val = (int)$val;
    switch($last) {
        case 'g': $val *= 1024;
        case 'm': $val *= 1024;
        case 'k': $val *= 1024;
    }
    return $val;
}

$uploadMaxBytes = convertToBytes($phpLimits['upload_max_filesize']);
$postMaxBytes = convertToBytes($phpLimits['post_max_size']);

foreach ($phpLimits as $key => $value) {
    $status = '✅';
    $comment = '';
    
    if ($key === 'upload_max_filesize' && convertToBytes($value) < 10 * 1024 * 1024) {
        $status = '⚠️ ';
        $comment = '(< 10 MB - Risque avec grosses images)';
    }
    if ($key === 'post_max_size' && convertToBytes($value) < 20 * 1024 * 1024) {
        $status = '⚠️ ';
        $comment = '(< 20 MB - Risque upload multiple)';
    }
    if ($key === 'max_execution_time' && (int)$value < 60) {
        $status = '⚠️ ';
        $comment = '(< 60s - Risque timeout)';
    }
    
    printf("%-25s : %s %-15s %s\n", $key, $status, $value, $comment);
}

echo "\n";

// 2. Limites MySQL
echo "═══════════════════════════════════════════════════════════\n";
echo "🗄️  LIMITES MYSQL\n";
echo "═══════════════════════════════════════════════════════════\n\n";

try {
    require_once __DIR__ . '/config/database.php';
    $database = new Database();
    $db = $database->getConnection();
    
    if ($db) {
        // max_allowed_packet
        $maxPacket = $db->query("SELECT @@max_allowed_packet")->fetchColumn();
        $maxPacketMB = round($maxPacket / 1024 / 1024, 2);
        
        $status = $maxPacketMB >= 64 ? '✅' : '⚠️ ';
        $comment = $maxPacketMB < 64 ? '(< 64 MB - Limité)' : '(Optimal)';
        
        echo sprintf("%-25s : %s %-15s %s\n", 
            'max_allowed_packet',
            $status,
            $maxPacketMB . ' MB',
            $comment
        );
        
        // wait_timeout
        $waitTimeout = $db->query("SELECT @@wait_timeout")->fetchColumn();
        $status = $waitTimeout >= 300 ? '✅' : '⚠️ ';
        echo sprintf("%-25s : %s %-15s\n", 
            'wait_timeout',
            $status,
            $waitTimeout . ' sec'
        );
        
        // Version MySQL
        $version = $db->query("SELECT VERSION()")->fetchColumn();
        echo sprintf("%-25s : ✅ %-15s\n", 'MySQL Version', $version);
    }
    
} catch (Exception $e) {
    echo "❌ Erreur MySQL: " . $e->getMessage() . "\n";
}

echo "\n";

// 3. Résumé et recommandations
echo "═══════════════════════════════════════════════════════════\n";
echo "📊 RÉSUMÉ ET CAPACITÉS D'UPLOAD\n";
echo "═══════════════════════════════════════════════════════════\n\n";

$minLimit = min($uploadMaxBytes, $postMaxBytes, isset($maxPacket) ? $maxPacket : PHP_INT_MAX);
$minLimitMB = round($minLimit / 1024 / 1024, 2);

echo "Taille MAX par fichier    : " . round($uploadMaxBytes / 1024 / 1024, 2) . " MB\n";
echo "Taille MAX requête POST   : " . round($postMaxBytes / 1024 / 1024, 2) . " MB\n";
if (isset($maxPacket)) {
    echo "Taille MAX paquet MySQL   : $maxPacketMB MB\n";
}
echo "\n";
echo "🎯 CAPACITÉ RÉELLE        : $minLimitMB MB par upload\n";
echo "\n";

// Recommendations
echo "═══════════════════════════════════════════════════════════\n";
echo "💡 RECOMMANDATIONS\n";
echo "═══════════════════════════════════════════════════════════\n\n";

if ($minLimitMB < 10) {
    echo "❌ CAPACITÉ INSUFFISANTE POUR GROSSES IMAGES\n\n";
    echo "Solutions :\n\n";
    echo "1. 📱 CÔTÉ FLUTTER (Recommandé) :\n";
    echo "   • Compresser les images avant upload\n";
    echo "   • Utiliser flutter_image_compress\n";
    echo "   • Limiter à 2-3 MB par image\n";
    echo "   • Exemple de code fourni ci-dessous\n\n";
    
    echo "2. 🔧 CÔTÉ SERVEUR (Nécessite accès cPanel) :\n";
    echo "   • Créer/modifier .htaccess dans /api/\n";
    echo "   • Ajouter :\n";
    echo "     php_value upload_max_filesize 20M\n";
    echo "     php_value post_max_size 25M\n";
    echo "     php_value max_execution_time 300\n\n";
    
    echo "3. 📞 CONTACTER L'HÉBERGEUR :\n";
    echo "   • Demander l'augmentation de max_allowed_packet à 64M\n";
    echo "   • Demander l'augmentation de upload_max_filesize à 20M\n\n";
    
} elseif ($minLimitMB < 20) {
    echo "⚠️  CAPACITÉ MOYENNE ($minLimitMB MB)\n\n";
    echo "• Fonctionnera pour images normales (< 5 MB)\n";
    echo "• Risque avec photos haute résolution\n";
    echo "• Recommandé : Compression côté Flutter\n\n";
    
} else {
    echo "✅ CAPACITÉ SUFFISANTE ($minLimitMB MB)\n\n";
    echo "• Upload de grosses images possible\n";
    echo "• Compression recommandée quand même pour performance\n\n";
}

// Code exemple Flutter
echo "═══════════════════════════════════════════════════════════\n";
echo "📱 CODE FLUTTER POUR COMPRESSION D'IMAGES\n";
echo "═══════════════════════════════════════════════════════════\n\n";

echo <<<'FLUTTER'
// 1. Ajouter la dépendance dans pubspec.yaml
dependencies:
  flutter_image_compress: ^2.1.0

// 2. Fonction de compression
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

Future<File?> compressImage(File file) async {
  // Vérifier la taille
  final fileSizeInBytes = await file.length();
  final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
  
  print('Taille originale: ${fileSizeInMB.toStringAsFixed(2)} MB');
  
  // Si < 2 MB, pas besoin de compresser
  if (fileSizeInMB < 2) {
    return file;
  }
  
  // Compression
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    file.absolute.path.replaceAll('.jpg', '_compressed.jpg'),
    quality: 85,           // 85% qualité (bon compromis)
    minWidth: 1920,        // Max 1920px largeur
    minHeight: 1080,       // Max 1080px hauteur
  );
  
  if (result != null) {
    final compressedSize = await result.length();
    final compressedMB = compressedSize / (1024 * 1024);
    print('Taille compressée: ${compressedMB.toStringAsFixed(2)} MB');
    return File(result.path);
  }
  
  return file;
}

// 3. Utiliser avant upload
Future<void> uploadImage() async {
  // Sélection image
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    File imageFile = File(pickedFile.path);
    
    // Compression automatique
    imageFile = await compressImage(imageFile) ?? imageFile;
    
    // Upload du fichier compressé
    // ... votre code d'upload
  }
}

FLUTTER;

echo "\n\n⚠️  SUPPRIMEZ ce fichier après consultation :\n";
echo "   rm " . __FILE__ . "\n";

?>
