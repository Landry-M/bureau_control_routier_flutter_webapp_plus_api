import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/responsive.dart';
import '../widgets/top_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Text('SOS'),
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

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String)>[
      (Icons.assignment, "Rapport des activités"),
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
                onTap: () {
                  if (a.$2 == "Rapport des activités") {
                    context.push('/activity-report');
                  } else if (a.$2 == "Créer un dossier") {
                    context.push('/create-dossier');
                  } else if (a.$2 == "Consulter tous les dossiers") {
                    context.push('/all-records');
                  } else if (a.$2 == "Rapports d'accidents") {
                    context.push('/accidents');
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
