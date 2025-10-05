import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class VehiculeActionsModal extends StatelessWidget {
  final Map<String, dynamic> vehicule;
  final VoidCallback? onSanctionner;
  final VoidCallback? onChangerProprietaire;
  final VoidCallback? onRetirerVehicule;
  final VoidCallback? onRetirerPlaque;
  final VoidCallback? onPlaqueTemporaire;
  final VoidCallback? onEmettreAvis;

  const VehiculeActionsModal({
    Key? key,
    required this.vehicule,
    this.onSanctionner,
    this.onChangerProprietaire,
    this.onRetirerVehicule,
    this.onRetirerPlaque,
    this.onPlaqueTemporaire,
    this.onEmettreAvis,
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
                  Icons.directions_car,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions véhicule / plaque',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        vehicule['plaque'] ?? 'N/A',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${vehicule['marque'] ?? ''} ${vehicule['modele'] ?? ''}'.trim(),
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
                        icon: Icons.warning,
                        iconColor: Colors.red,
                        title: 'Sanctionner le véhicule',
                        subtitle: 'Ouvrir le formulaire de contravention pour ce véhicule.',
                        buttonText: 'Sanctionner',
                        buttonColor: Colors.red,
                        onTap: onSanctionner,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.swap_horiz,
                        iconColor: Colors.indigo,
                        title: 'Changer de propriétaire',
                        subtitle: 'Transférer la propriété du véhicule.',
                        buttonText: 'Transférer',
                        buttonColor: Colors.indigo,
                        onTap: onChangerProprietaire,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.remove_circle_outline,
                        iconColor: Colors.orange,
                        title: 'Retirer le véhicule',
                        subtitle: 'Retirer le véhicule de la circulation.',
                        buttonText: 'Retirer véhicule',
                        buttonColor: Colors.orange,
                        onTap: onRetirerVehicule,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.stop_circle_outlined,
                        iconColor: Colors.grey,
                        title: 'Retirer la plaque',
                        subtitle: 'Retirer la plaque du véhicule.',
                        buttonText: 'Retirer plaque',
                        buttonColor: Colors.grey,
                        onTap: onRetirerPlaque,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.access_time,
                        iconColor: Colors.teal,
                        title: 'Plaque temporaire',
                        subtitle: 'Attribuer une plaque temporaire au véhicule.',
                        buttonText: 'Plaque temporaire',
                        buttonColor: Colors.teal,
                        onTap: onPlaqueTemporaire,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.campaign,
                        iconColor: Colors.red,
                        title: 'Avis de recherche',
                        subtitle: 'Émettre un avis de recherche pour ce véhicule.',
                        buttonText: 'Émettre un avis',
                        buttonColor: Colors.red,
                        onTap: onEmettreAvis,
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
