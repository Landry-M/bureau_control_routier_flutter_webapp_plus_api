import 'dart:convert';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/log_service.dart';
import '../utils/responsive.dart';
import '../widgets/top_bar.dart';

class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _displayedLogs = [];

  // Filtres
  final _searchController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedAction;

  // Scroll infini
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 20;
  int _currentOffset = 0;
  bool _hasMoreData = true;

  // Actions disponibles pour le filtre
  final List<String> _availableActions = [
    'Connexion réussie',
    'Connexion échouée',
    'Déconnexion',
    'Création agent',
    'Modification agent',
    'Suppression agent',
    'Création particulier',
    'Création entreprise',
    'Création véhicule',
    'Création contravention',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLogs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentOffset = 0;
        _hasMoreData = true;
        _displayedLogs.clear();
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final client = ApiClient(baseUrl: ApiConfig.baseUrl);
      final logService = LogService(client);

      final result = await logService.getLogs(
        limit: _itemsPerPage,
        offset: _currentOffset,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        dateFrom: _dateFrom?.toIso8601String(),
        dateTo: _dateTo?.toIso8601String(),
        action: _selectedAction,
      );

      if (result['success'] == true) {
        final logs = List<Map<String, dynamic>>.from(result['data'] ?? []);
        setState(() {
          if (refresh || _currentOffset == 0) {
            _displayedLogs = logs;
          } else {
            _displayedLogs.addAll(logs);
          }
          _currentOffset += logs.length;
          _hasMoreData = logs.length == _itemsPerPage;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Erreur lors du chargement des logs';
          _loading = false;
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() {
        _error = errorMessage;
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_loadingMore || !_hasMoreData) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final client = ApiClient(baseUrl: ApiConfig.baseUrl);
      final logService = LogService(client);

      final result = await logService.getLogs(
        limit: _itemsPerPage,
        offset: _currentOffset,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        dateFrom: _dateFrom?.toIso8601String(),
        dateTo: _dateTo?.toIso8601String(),
        action: _selectedAction,
      );

      if (result['success'] == true) {
        final logs = List<Map<String, dynamic>>.from(result['data'] ?? []);
        setState(() {
          _displayedLogs.addAll(logs);
          _currentOffset += logs.length;
          _hasMoreData = logs.length == _itemsPerPage;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  void _applyFilters() {
    // Recharger les données avec les nouveaux filtres
    _loadLogs(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _dateFrom = null;
      _dateTo = null;
      _selectedAction = null;
    });
    _applyFilters();
  }

  Future<void> _selectDate(bool isFromDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.white,
                ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        if (isFromDate) {
          _dateFrom = date;
          _dateFromController.text = _formatDate(date);
        } else {
          _dateTo = date;
          _dateToController.text = _formatDate(date);
        }
        _applyFilters();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getActionColor(String? action) {
    if (action == null) return Colors.grey;

    final actionLower = action.toLowerCase();
    if (actionLower.contains('connexion')) {
      if (actionLower.contains('échouée')) return Colors.red;
      return Colors.green;
    }
    if (actionLower.contains('création')) return Colors.blue;
    if (actionLower.contains('modification')) return Colors.orange;
    if (actionLower.contains('suppression')) return Colors.red;
    if (actionLower.contains('déconnexion')) return Colors.grey;

    return Colors.purple;
  }

  Widget _buildFiltersCard() {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Filtres de recherche',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Effacer tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Recherche par agent

                // Filtre par action
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: InputDecoration(
                      labelText: 'Type d\'action',
                      prefixIcon: const Icon(Icons.settings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Toutes les actions'),
                      ),
                      ..._availableActions
                          .map((action) => DropdownMenuItem<String>(
                                value: action,
                                child: Text(action),
                              )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),

                // Date de début
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _dateFromController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date de début',
                      hintText: 'Sélectionner...',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () => _selectDate(true),
                  ),
                ),

                // Date de fin
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _dateToController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date de fin',
                      hintText: 'Sélectionner...',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () => _selectDate(false),
                  ),
                ),

                // Bouton actualiser
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _loadLogs,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final theme = Theme.of(context);

    if (_displayedLogs.isEmpty && !_loading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune activité trouvée',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez de modifier vos filtres de recherche',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec barre de recherche
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.table_chart, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Journal des activités',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                // Barre de recherche en en-tête du tableau
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Rechercher dans les activités',
                          hintText: 'Agent, action, détails...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed:
                          _loading ? null : () => _loadLogs(refresh: true),
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tableau avec scroll infini
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainer,
              ),
              columns: const [
                DataColumn(
                  label: Text('Date/Heure',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Agent',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Action',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Détails',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text('Adresse IP',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: [
                ..._displayedLogs.map((log) {
                  final createdAt = log['created_at'];
                  final formattedDate = createdAt != null
                      ? _formatDateTime(DateTime.parse(createdAt))
                      : 'N/A';

                  // Gestion des détails
                  var details = log['details'];
                  if (details == null && log['details_operation'] != null) {
                    try {
                      details = json.decode(log['details_operation']);
                    } catch (e) {
                      details = log['details_operation'];
                    }
                  }

                  String detailsText = 'N/A';
                  if (details != null && details is Map) {
                    detailsText = details.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(', ');
                  } else if (details != null) {
                    detailsText = details.toString();
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          formattedDate,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            log['username'] ?? 'N/A',
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getActionColor(log['action']),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            log['action'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            detailsText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          log['ip_address'] ?? 'N/A',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  );
                }),
                // Indicateur de chargement pour le scroll infini
                if (_loadingMore)
                  DataRow(
                    cells: [
                      const DataCell(SizedBox()),
                      const DataCell(SizedBox()),
                      DataCell(
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Chargement...',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const DataCell(SizedBox()),
                      const DataCell(SizedBox()),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.value(context,
                        mobile: 16.0, tablet: 24.0, desktop: 32.0),
                    vertical: Responsive.value(context,
                        mobile: 12.0, tablet: 16.0, desktop: 20.0),
                  ),
                  child: const TopBar(),
                ),

                // Titre de la page avec flèche retour
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                        tooltip: 'Retour',
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.assessment,
                        size: 28,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rapport d\'activités',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contenu principal
                Expanded(
                  child: _loading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Chargement des activités...'),
                            ],
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Erreur de chargement',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: theme.textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadLogs,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  _buildFiltersCard(),
                                  const SizedBox(height: 16),
                                  _buildDataTable(),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
