import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../utils/responsive.dart';
import '../widgets/vehicule_creation_modal.dart';
import '../widgets/top_bar.dart';
import '../widgets/create_entreprise_modal.dart';
import '../widgets/create_particulier_modal.dart';
import '../widgets/conducteur_vehicule_modal.dart';

class CreateDossierScreen extends StatelessWidget {
  const CreateDossierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(context,
                    mobile: 16.0, tablet: 24.0, desktop: 32.0),
                vertical: Responsive.value(context,
                    mobile: 16.0, tablet: 20.0, desktop: 24.0),
              ),
              children: [
                const TopBar(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'CRÉER UN DOSSIER',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: Responsive.value(context,
                      mobile: 1, tablet: 2, desktop: 3),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  // Make tiles less tall
                  childAspectRatio: Responsive.value(context,
                      mobile: 1.9, tablet: 2.1, desktop: 2.3),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DossierTile(
                      icon: Icons.badge,
                      title: 'Conducteur et véhicule',
                      description:
                          'Créer un dossier pour un conducteur avec un véhicule.',
                      onTap: () => _showConducteurVehiculeModal(context),
                    ),
                    _DossierTile(
                      icon: Icons.directions_car,
                      title: 'Véhicules et plaques d\'immatriculations',
                      description:
                          'Créer un dossier pour un véhicule sans propriétaire.',
                      onTap: () => _showVehiculeCreationModal(context),
                    ),
                    _DossierTile(
                      icon: Icons.person,
                      title: 'Enregistrer un particulier',
                      description:
                          'Créer un dossier pour un particulier sans véhicule.',
                      onTap: () => _showParticulierCreationModal(context),
                    ),
                    _DossierTile(
                      icon: Icons.business,
                      title: 'Enregistrer une entreprise',
                      description: 'Créer un dossier pour une entreprise.',
                      onTap: () => _showEntrepriseCreationModal(context),
                    ),
                    _DossierTile(
                      icon: Icons.description,
                      title: 'Rapport de l\'accident',
                      description:
                          'Créer un dossier pour un rapport d\'accident.',
                      onTap: () {
                        NotificationService.info(
                          context,
                          'Fonctionnalité à implémenter',
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVehiculeCreationModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VehiculeCreationModal(),
    );
  }

  void _showEntrepriseCreationModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateEntrepriseModal(),
    );
  }

  void _showParticulierCreationModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateParticulierModal(),
    );
  }

  void _showConducteurVehiculeModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ConducteurVehiculeModal(),
    );
  }
}

class _DossierTile extends StatelessWidget {
  const _DossierTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: cs.onSurface, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style:
                          tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Text(
                description,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: cs.outline.withValues(alpha: 0.3)),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
