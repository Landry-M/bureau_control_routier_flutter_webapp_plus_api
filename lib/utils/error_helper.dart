/// Helper pour nettoyer les messages d'erreur
class ErrorHelper {
  /// Extrait un message d'erreur propre sans le préfixe "Exception:"
  /// et sans codes d'erreur techniques
  static String cleanErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    
    // Enlever le préfixe "Exception: " si présent
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring(11);
    }
    
    // Enlever tout ce qui ressemble à un code HTTP ou technique
    // Exemple: "Erreur HTTP 409: ..." -> ne garder que ce qui suit
    final httpPattern = RegExp(r'HTTP \d{3}:\s*');
    errorMessage = errorMessage.replaceAll(httpPattern, '');
    
    return errorMessage.trim();
  }
}
