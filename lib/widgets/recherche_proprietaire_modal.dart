import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class RechercheProprietaireModal extends StatefulWidget {
  const RechercheProprietaireModal({super.key});

  @override
  State<RechercheProprietaireModal> createState() => _RechercheProprietaireModalState();
}

class _RechercheProprietaireModalState extends State<RechercheProprietaireModal> {
  final _searchController = TextEditingController();
  String _selectedType = 'particulier'; // 'particulier' ou 'entreprise'
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final query = _searchController.text.trim();
      final url = _selectedType == 'particulier'
          ? '${ApiConfig.baseUrl}/particuliers?search=$query&limit=20'
          : '${ApiConfig.baseUrl}/entreprises?search=$query&limit=20';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _results = List<Map<String, dynamic>>.from(data['data'] ?? []);
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _results = [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.indigo,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rechercher un propriétaire',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Particulier ou Entreprise',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sélecteur de type
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'particulier',
                        label: Text('Particulier'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: 'entreprise',
                        label: Text('Entreprise'),
                        icon: Icon(Icons.business),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() {
                        _selectedType = selected.first;
                        _results = [];
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Champ de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher',
                hintText: _selectedType == 'particulier'
                    ? 'Nom, prénom, téléphone...'
                    : 'Désignation, RCCM, téléphone...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  _search();
                } else if (value.isEmpty) {
                  setState(() {
                    _results = [];
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Résultats
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final theme = Theme.of(context);

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche en cours...'),
          ],
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Saisissez au moins 2 caractères pour rechercher',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.withOpacity(0.1),
              child: Icon(
                _selectedType == 'particulier' ? Icons.person : Icons.business,
                color: Colors.indigo,
              ),
            ),
            title: Text(
              _selectedType == 'particulier'
                  ? '${item['nom'] ?? ''} ${item['prenom'] ?? ''}'
                  : item['designation'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (_selectedType == 'particulier') ...[
                  if (item['gsm'] != null)
                    Text('📱 ${item['gsm']}'),
                  if (item['adresse'] != null)
                    Text('📍 ${item['adresse']}'),
                ] else ...[
                  if (item['rccm'] != null)
                    Text('RCCM: ${item['rccm']}'),
                  if (item['telephone'] != null)
                    Text('📱 ${item['telephone']}'),
                ],
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'type': _selectedType,
                  'id': item['id'],
                  'data': item,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sélectionner'),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
