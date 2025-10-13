import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../utils/responsive.dart';
import '../widgets/top_bar.dart';
import '../widgets/sos_modal.dart';
import '../config/api_config.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    // Charger les alertes au premier affichage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlerts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les alertes à chaque fois que les dépendances changent
    // (notamment lors du retour via pop)
    // Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlerts();
    });
  }

  void _loadAlerts() {
    final username = context.read<AuthProvider>().username;
    context.read<AlertProvider>().loadAlerts(username);
  }

  void _showSosModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SosModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSosModal(context),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(context,
                    mobile: 12.0, tablet: 16.0, desktop: 16.0),
                vertical: Responsive.value(context,
                    mobile: 8.0, tablet: 12.0, desktop: 12.0),
              ),
              children: [
                const TopBar(),
                const SizedBox(height: 12),
                _PoliceBanner(tt: tt, cs: cs),
                const SizedBox(height: 16),
                _QuickActionsRow(cs: cs, tt: tt),
                const SizedBox(height: 16),
                // _MainCardsRow(cs: cs, tt: tt),
                const SizedBox(height: 16),
                // _CameraRow(cs: cs, tt: tt),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fonction pour ouvrir le PDF du code de la route dans un nouvel onglet
Future<void> _openCodeDelaRoute(BuildContext context) async {
  try {
    // Construire l'URL du PDF
    final pdfUrl =
        '${ApiConfig.baseUrl.replaceAll('/api/routes/index.php', '')}/api/assets/code_de_la_route.pdf';

    final uri = Uri.parse(pdfUrl);

    // Ouvrir dans un nouvel onglet/fenêtre
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication, // Ouvre dans le navigateur/visionneuse PDF
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le fichier PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final isSuperAdmin = role == 'superadmin';
    
    final actions = <(IconData, String)>[
      // Rapport des activités uniquement pour les superadmins
      if (isSuperAdmin) (Icons.assignment, "Rapport des activités"),
      (Icons.add, "Créer un dossier"),
      (Icons.folder_open, "Consulter tous les dossiers"),
      (Icons.car_crash, "Rapports d'accidents"),
      (Icons.menu_book, "Code de la route"),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final a in actions) ...[
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
              ),
              child: InkWell(
                onTap: () async {
                  if (a.$2 == "Rapport des activités") {
                    context.push('/activity-report');
                  } else if (a.$2 == "Créer un dossier") {
                    context.push('/create-dossier');
                  } else if (a.$2 == "Consulter tous les dossiers") {
                    context.push('/all-records');
                  } else if (a.$2 == "Rapports d'accidents") {
                    context.push('/accidents');
                  } else if (a.$2 == "Code de la route") {
                    await _openCodeDelaRoute(context);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(a.$1, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(a.$2,
                          style:
                              tt.bodyMedium?.copyWith(color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _PoliceBanner extends StatelessWidget {
  const _PoliceBanner({required this.tt, required this.cs});
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'BUREAU DE CONTRÔLE ROUTIER',
        style: tt.titleLarge?.copyWith(color: cs.onPrimary),
      ),
    );
  }
}

// Classes supprimées car non utilisées dans cette version
