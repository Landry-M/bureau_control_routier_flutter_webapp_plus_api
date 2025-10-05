import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ParticulierActionsModal extends StatelessWidget {
  final Map<String, dynamic> particulier;
  final VoidCallback? onEmettrePermis;
  final VoidCallback? onAssocierVehicule;
  final VoidCallback? onCreerContravention;
  final VoidCallback? onConsignerArrestation;
  final VoidCallback? onEmettreAvisRecherche;

  const ParticulierActionsModal({
    Key? key,
    required this.particulier,
    this.onEmettrePermis,
    this.onAssocierVehicule,
    this.onCreerContravention,
    this.onConsignerArrestation,
    this.onEmettreAvisRecherche,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: 400,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions pour:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${particulier['nom']} ${particulier['prenom'] ?? ''}'.trim(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '(N° ${particulier['id']})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: colorScheme.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: 12),

            // Contenu scrollable avec grille simple
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.badge,
                        iconColor: Colors.indigo,
                        title: 'Émettre un permis de conduire temporaire',
                        subtitle: 'Créer un permis provisoire pour une durée limitée.',
                        buttonText: 'Émettre maintenant',
                        buttonColor: Colors.indigo,
                        onTap: onEmettrePermis,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.directions_car,
                        iconColor: Colors.blue,
                        title: 'Associer un véhicule',
                        subtitle: 'Lier un véhicule existant à cet individu.',
                        buttonText: 'Associer un véhicule',
                        buttonColor: Colors.blue,
                        onTap: onAssocierVehicule,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.notifications_active_outlined,
                        iconColor: Colors.amber,
                        title: 'Sanctionner l\'individu',
                        subtitle: 'Enregistrer une sanction administrative.',
                        buttonText: 'Créer une contravention',
                        buttonColor: Colors.amber,
                        onTap: onCreerContravention,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.gavel_outlined,
                        iconColor: Colors.red,
                        title: 'Arrestation de l\'individu',
                        subtitle: 'Consigner une interpellation et motif.',
                        buttonText: 'Consigner une arrestation',
                        buttonColor: Colors.red,
                        onTap: onConsignerArrestation,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.crop_square,
                        iconColor: colorScheme.outline,
                        title: 'Lancer un avis de recherche',
                        subtitle: 'Déclencher un avis de recherche pour cet individu.',
                        buttonText: 'Émettre un avis de recherche',
                        buttonColor: Colors.red,
                        onTap: onEmettreAvisRecherche,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton fermer
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),

            // Titre
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Sous-titre
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap ?? () {
                  Navigator.of(context).pop();
                  toastification.show(
                    context: context,
                    type: ToastificationType.warning,
                    style: ToastificationStyle.fillColored,
                    title: const Text('Fonctionnalité en développement'),
                    description: Text('La fonctionnalité "$buttonText" est en cours de développement'),
                    alignment: Alignment.topRight,
                    autoCloseDuration: const Duration(seconds: 4),
                    showProgressBar: true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
