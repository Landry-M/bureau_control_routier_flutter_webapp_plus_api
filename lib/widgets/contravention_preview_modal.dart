import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class ContraventionPreviewModal extends StatefulWidget {
  final int contraventionId;
  final VoidCallback? onClose;

  const ContraventionPreviewModal({
    super.key,
    required this.contraventionId,
    this.onClose,
  });

  @override
  State<ContraventionPreviewModal> createState() =>
      _ContraventionPreviewModalState();
}

class _ContraventionPreviewModalState extends State<ContraventionPreviewModal> {
  @override
  void initState() {
    super.initState();
    // Ouvrir automatiquement la prévisualisation dans le navigateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPreview();
    });
  }

  Future<void> _openPreview() async {
    final displayUrl = ApiConfig.getContraventionDisplayUrl(widget.contraventionId);

    try {
      final uri = Uri.parse(displayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccess('Contravention ouverte dans le navigateur');
      } else {
        _showError('Impossible d\'ouvrir la contravention');
      }
    } catch (e) {
      _showError('Erreur lors de l\'ouverture: $e');
    }
  }

  void _showError(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Erreur'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text('Succès'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Contravention #${widget.contraventionId} créée',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),

            // Contenu principal scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Contravention créée avec succès !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'La contravention #${widget.contraventionId} a été enregistrée.\nVous pouvez maintenant consulter l\'affichage complet de la contravention.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _openPreview,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir la contravention'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    // Ajouter de l'espace en bas pour assurer le scroll
                    const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Pied de page
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                    child: const Text('Fermer'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
