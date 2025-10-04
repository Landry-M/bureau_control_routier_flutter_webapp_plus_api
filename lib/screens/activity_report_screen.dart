import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/log_service.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  final _searchController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _filteredActivities = [];
  bool _isLoading = false;
  String _error = '';

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;

  // Filtres
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final apiClient =
          ApiClient(baseUrl: 'http://localhost/api/routes/index.php');
      final logService = LogService(apiClient);

      final result = await logService.getLogs(
        limit: 1000, // Charger plus pour permettre le filtrage local
        offset: 0,
      );

      if (result['success'] == true) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_activities);

    // Filtre par nom d'agent
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((activity) {
        final username = activity['username']?.toString().toLowerCase() ?? '';
        return username.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filtre par date
    if (_dateFrom != null || _dateTo != null) {
      filtered = filtered.where((activity) {
        final createdAt = activity['created_at'];
        if (createdAt == null) return false;

        try {
          final activityDate = DateTime.parse(createdAt);

          if (_dateFrom != null && activityDate.isBefore(_dateFrom!)) {
            return false;
          }

          if (_dateTo != null &&
              activityDate.isAfter(_dateTo!.add(const Duration(days: 1)))) {
            return false;
          }

          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Tri par date décroissante
    filtered.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    setState(() {
      _filteredActivities = filtered;
      _totalItems = filtered.length;
      _currentPage = 1; // Reset à la première page
    });
  }

  List<Map<String, dynamic>> _getPaginatedData() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredActivities.length) return [];

    return _filteredActivities.sublist(
      startIndex,
      endIndex > _filteredActivities.length
          ? _filteredActivities.length
          : endIndex,
    );
  }

  int get _totalPages => (_totalItems / _itemsPerPage).ceil();

  Future<void> _selectDate(
      TextEditingController controller, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = picked;
          _dateFromController.text = _formatDate(picked);
        } else {
          _dateTo = picked;
          _dateToController.text = _formatDate(picked);
        }
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _dateFrom = null;
      _dateTo = null;
      _searchController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _applyFilters();
    });
  }

  Widget _buildFiltersSection() {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Ligne des filtres
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Recherche par nom
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Rechercher par nom d\'agent',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),

                // Date de début
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _dateFromController,
                    decoration: const InputDecoration(
                      labelText: 'Date de début',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_dateFromController, true),
                  ),
                ),

                // Date de fin
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _dateToController,
                    decoration: const InputDecoration(
                      labelText: 'Date de fin',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_dateToController, false),
                  ),
                ),

                // Bouton effacer filtres
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer filtres'),
                ),

                // Bouton actualiser
                ElevatedButton.icon(
                  onPressed: _loadActivities,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final theme = Theme.of(context);
    final paginatedData = _getPaginatedData();

    if (paginatedData.isEmpty && !_isLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune activité trouvée',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez de modifier vos filtres ou actualisez les données',
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
          // En-tête du tableau
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Rapport d\'activités',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredActivities.length} résultat(s)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Tableau
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date/Heure')),
                DataColumn(label: Text('Agent')),
                DataColumn(label: Text('Action')),
                DataColumn(label: Text('Détails')),
                DataColumn(label: Text('Adresse IP')),
              ],
              rows: paginatedData.map((activity) {
                final createdAt = activity['created_at'];
                final formattedDate = createdAt != null
                    ? _formatDateTime(DateTime.parse(createdAt))
                    : 'N/A';

                // Handle both 'details' and 'details_operation' field names
                var details = activity['details'];
                if (details == null && activity['details_operation'] != null) {
                  // Parse JSON string if it's details_operation
                  try {
                    details = json.decode(activity['details_operation']);
                  } catch (e) {
                    details = activity['details_operation'];
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
                    DataCell(Text(formattedDate)),
                    DataCell(Text(activity['username'] ?? 'N/A')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getActionColor(activity['action']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity['action'] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          detailsText,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    DataCell(Text(activity['ip_address'] ?? 'N/A')),
                  ],
                );
              }).toList(),
            ),
          ),

          // Pagination
          if (_totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Color _getActionColor(String? action) {
    if (action == null) return Colors.grey;

    if (action.toLowerCase().contains('connexion')) {
      if (action.toLowerCase().contains('échouée')) {
        return Colors.red;
      }
      return Colors.green;
    }

    if (action.toLowerCase().contains('mot de passe')) {
      return Colors.orange;
    }

    if (action.toLowerCase().contains('création')) {
      return Colors.blue;
    }

    return Colors.purple;
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bouton précédent
          IconButton(
            onPressed:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
          ),

          // Numéros de pages
          ...List.generate(
            _totalPages > 5 ? 5 : _totalPages,
            (index) {
              int pageNumber;
              if (_totalPages <= 5) {
                pageNumber = index + 1;
              } else {
                // Logique pour afficher 5 pages autour de la page courante
                int start = _currentPage - 2;
                if (start < 1) start = 1;
                if (start + 4 >= _totalPages) start = _totalPages - 4;
                pageNumber = start + index;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _currentPage == pageNumber
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pageNumber.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: () =>
                            setState(() => _currentPage = pageNumber),
                        child: Text(pageNumber.toString()),
                      ),
              );
            },
          ),

          // Bouton suivant
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport d\'activités'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
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
                        'Erreur',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadActivities,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildFiltersSection(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildDataTable(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
