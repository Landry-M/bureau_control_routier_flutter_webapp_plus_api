import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlerts();
    });
  }

  void _loadAlerts() {
    final authProvider = context.read<AuthProvider>();
    final alertProvider = context.read<AlertProvider>();
    alertProvider.loadAlerts(authProvider.username);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return dateStr;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          if (alertProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (alertProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    alertProvider.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadAlerts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (alertProvider.totalAlerts == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, 
                    size: 64, 
                    color: Colors.green[300]
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune alerte active',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tout est en ordre !',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => alertProvider.refresh(
              context.read<AuthProvider>().username
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec compteur total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined, 
                          size: 24, 
                          color: Colors.white
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${alertProvider.totalAlerts} alerte(s) active(s)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Avis de recherche actifs
                  if (alertProvider.avisRechercheActifs.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Avis de recherche actifs',
                      alertProvider.avisRechercheActifs.length,
                      Icons.search,
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.avisRechercheActifs.map((avis) => 
                      _buildAvisRechercheCard(context, avis)
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 2. Assurances expirées
                  if (alertProvider.assurancesExpirees.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Assurances expirées',
                      alertProvider.assurancesExpirees.length,
                      Icons.shield_outlined,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.assurancesExpirees.map((assurance) => 
                      _buildAssuranceCard(context, assurance)
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Permis temporaires expirés
                  if (alertProvider.permisTemporairesExpires.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Permis temporaires expirés',
                      alertProvider.permisTemporairesExpires.length,
                      Icons.card_membership_outlined,
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.permisTemporairesExpires.map((permis) => 
                      _buildPermisTemporaireCard(context, permis)
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 4. Plaques expirées
                  if (alertProvider.plaquesExpirees.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Plaques d\'immatriculation expirées',
                      alertProvider.plaquesExpirees.length,
                      Icons.directions_car_outlined,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.plaquesExpirees.map((plaque) => 
                      _buildPlaqueCard(context, plaque)
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 5. Permis de conduire expirés
                  if (alertProvider.permisConduireExpires.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Permis de conduire expirés',
                      alertProvider.permisConduireExpires.length,
                      Icons.badge_outlined,
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    ...alertProvider.permisConduireExpires.map((permis) => 
                      _buildPermisConduireCard(context, permis)
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisRechercheCard(BuildContext context, Map<String, dynamic> avis) {
    final theme = Theme.of(context);
    final cibleDetails = avis['cible_details'];
    final isVehicule = avis['cible_type'] == 'vehicule_plaque';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVehicule ? Icons.directions_car_outlined : Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVehicule 
                        ? 'Véhicule: ${cibleDetails?['plaque'] ?? 'N/A'}'
                        : 'Particulier: ${cibleDetails?['nom'] ?? 'N/A'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (isVehicule && cibleDetails != null)
                      Text(
                        '${cibleDetails['marque']} ${cibleDetails['modele'] ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    if (!isVehicule && cibleDetails != null)
                      Text(
                        'Tél: ${cibleDetails['gsm'] ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                avis['niveau'] ?? 'Moyen',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            avis['motif'] ?? 'Aucun motif spécifié',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Émis le: ${_formatDate(avis['created_at'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssuranceCard(BuildContext context, Map<String, dynamic> assurance) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assurance['plaque'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${assurance['marque']} ${assurance['modele'] ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${assurance['societe_assurance'] ?? 'N/A'} - ${assurance['nume_assurance'] ?? 'N/A'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Expirée le: ${_formatDate(assurance['date_expire_assurance'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermisTemporaireCard(BuildContext context, Map<String, dynamic> permis) {
    final theme = Theme.of(context);
    final isVehicule = permis['cible_type'] == 'vehicule_plaque';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVehicule ? Icons.directions_car_outlined : Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permis['numero'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      permis['cible_nom'] ?? 'N/A',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            permis['motif'] ?? 'N/A',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Expiré le: ${_formatDate(permis['date_fin'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaqueCard(BuildContext context, Map<String, dynamic> plaque) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plaque['plaque'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${plaque['marque']} ${plaque['modele'] ?? ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${plaque['couleur'] ?? 'N/A'} • ${plaque['annee'] ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Expirée le: ${_formatDate(plaque['plaque_expire_le'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermisConduireCard(BuildContext context, Map<String, dynamic> permis) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permis['nom'] ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tél: ${permis['gsm'] ?? 'N/A'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (permis['adresse'] != null && permis['adresse'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              permis['adresse'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Expiré le: ${_formatDate(permis['permis_date_expiration'])}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
