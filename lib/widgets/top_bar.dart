import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../utils/responsive.dart';
import '../widgets/create_agent_modal.dart';
import '../services/notification_service.dart';
import '../services/vehicule_service.dart';
import '../widgets/vehicule_creation_modal.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final _generalSearchCtrl = TextEditingController();
  final _plateSearchCtrl = TextEditingController();

  void _showCreateAgentModal(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateAgentModal(),
    );

    if (result != null) {
      NotificationService.success(
        context,
        'Agent ${result['nom']} créé avec succès !',
      );
    }
  }

  void _onGeneralSearch() {
    final q = _generalSearchCtrl.text.trim();
    if (q.isEmpty) return;
    context.push('/search?q=${Uri.encodeComponent(q)}&type=general');
  }

  Future<void> _onPlateSearch() async {
    final q = _plateSearchCtrl.text.trim();
    if (q.isEmpty) return;
    try {
      final service = VehiculeService();
      final username = context.read<AuthProvider>().username;
      final results = await service.searchLocal(q, username: username);
      if (!mounted) return;
      if (results.isEmpty) {
        // Open creation modal with prefilled plaque
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => VehiculeCreationModal(initialPlaque: q),
        );
      } else {
        // Navigate to paginated results screen for plate
        context.push('/search?q=${Uri.encodeComponent(q)}&type=plate');
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(context, 'Erreur de recherche: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final username = context.watch<AuthProvider>().username;
    final isMobile = Responsive.isMobile(context);

    Widget logo() => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(6),
          child: Image.asset('lib/assets/images/logo.png', fit: BoxFit.contain),
        );

    Widget accueil() => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/dashboard'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Accueil', style: tt.titleMedium),
          ),
        );

    Widget generalSearch() => TextField(
          controller: _generalSearchCtrl,
          onSubmitted: (_) => _onGeneralSearch(),
          decoration: InputDecoration(
            hintText: 'Veuillez saisir votre recherche',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Rechercher',
              icon: const Icon(Icons.search),
              onPressed: _onGeneralSearch,
            ),
          ),
        );

    Widget plateSearch() => TextField(
          controller: _plateSearchCtrl,
          onSubmitted: (_) => _onPlateSearch(),
          decoration: InputDecoration(
            hintText: 'Rechercher par plaque',
            prefixIcon: const Icon(Icons.directions_car),
            suffixIcon: IconButton(
              tooltip: 'Rechercher la plaque',
              icon: const Icon(Icons.search),
              onPressed: _onPlateSearch,
            ),
          ),
        );

    Widget profileMenu() => PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (value) {
            switch (value) {
              case 'profile':
                NotificationService.info(
                  context,
                  'Mon profil (à implémenter)',
                );
                break;
              case 'manage_agents':
                context.push('/users');
                break;
              case 'create_agent':
                _showCreateAgentModal(context);
                break;
              case 'logout':
                context.read<AuthProvider>().logout();
                context.go('/login');
                break;
            }
          },
          itemBuilder: (context) {
            final isSuper = context.read<AuthProvider>().role == 'superadmin';
            final items = <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Mon profil'),
              ),
            ];
            if (isSuper) {
              items.add(const PopupMenuDivider());
              items.addAll(const [
                PopupMenuItem<String>(
                  value: 'manage_agents',
                  child: Text('Gestion des agents'),
                ),
                PopupMenuItem<String>(
                  value: 'create_agent',
                  child: Text('Créer un agent'),
                ),
              ]);
            }
            items.add(const PopupMenuDivider());
            items.add(const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16),
                  SizedBox(width: 8),
                  Text('Se déconnecter'),
                ],
              ),
            ));
            return items;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(username, style: tt.bodyMedium),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        );

    final alertsButton = Consumer<AlertProvider>(
      builder: (context, alertProvider, child) {
        final alertCount = alertProvider.totalAlerts;
        return Badge(
          label: Text('$alertCount'),
          isLabelVisible: alertCount > 0,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          child: IconButton(
            tooltip: 'Alertes',
            icon: const Icon(Icons.notifications_outlined),
            color: cs.onSurface,
            onPressed: () => context.push('/alerts'),
          ),
        );
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [logo()]),
          const SizedBox(height: 8),
          generalSearch(),
          const SizedBox(height: 8),
          plateSearch(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              alertsButton,
              profileMenu(),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        logo(),
        const SizedBox(width: 12),
        accueil(),
        const SizedBox(width: 16),
        // Two inline searches on larger screens
        Expanded(child: generalSearch()),
        const SizedBox(width: 12),
        Expanded(child: plateSearch()),
        const SizedBox(width: 16),
        alertsButton,
        const SizedBox(width: 8),
        profileMenu(),
      ],
    );
  }

  @override
  void dispose() {
    _generalSearchCtrl.dispose();
    _plateSearchCtrl.dispose();
    super.dispose();
  }
}
