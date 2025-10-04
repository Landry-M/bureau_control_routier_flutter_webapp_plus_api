import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/responsive.dart';
import '../widgets/top_bar.dart';
import '../services/vehicule_service.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.query = '', this.type = 'general'});

  final String query; // from query params
  final String type;  // 'general' | 'plate'

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _vehiculeService = VehiculeService();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _all = [];

  // pagination (client-side)
  int _page = 1;
  final int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.query.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      // For now, both general and plate search hit the same local vehicule search
      final items = await _vehiculeService.searchLocal(widget.query);
      setState(() {
        _all = items;
        _page = 1;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _pageItems {
    final start = (_page - 1) * _perPage;
    final end = start + _perPage;
    if (start >= _all.length) return [];
    return _all.sublist(start, end > _all.length ? _all.length : end);
  }

  int get _totalPages => (_all.length / _perPage).ceil().clamp(1, 1000000);

  void _showDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final entries = item.entries.toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              controller: controller,
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 160, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value?.toString() ?? '')),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
                vertical: Responsive.value(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
              ),
              children: [
                const TopBar(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text('Résultats de recherche', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (!_loading)
                      Text('${_all.length} résultat(s)', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_error != null)
                  Center(child: Text(_error!, style: tt.bodyMedium?.copyWith(color: cs.error)))
                else if (_all.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(children: [
                        const Icon(Icons.inbox),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Aucun résultat pour "${widget.query}".', style: tt.bodyMedium)),
                      ]),
                    ),
                  )
                else ...[
                  Card(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _pageItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = _pageItems[i];
                        final plaque = (item['plaque'] ?? item['plate'] ?? '').toString();
                        final marque = (item['marque'] ?? '').toString();
                        final modele = (item['modele'] ?? '').toString();
                        final couleur = (item['couleur'] ?? '').toString();
                        return ListTile(
                          leading: const Icon(Icons.directions_car),
                          title: Text(plaque.isNotEmpty ? plaque : 'Plaque inconnue'),
                          subtitle: Text([
                            if (marque.isNotEmpty) marque,
                            if (modele.isNotEmpty) modele,
                            if (couleur.isNotEmpty) couleur,
                          ].join(' · ')),
                          onTap: () {
                            if (plaque.isNotEmpty) {
                              context.push('/vehicule/${Uri.encodeComponent(plaque)}');
                            } else {
                              _showDetails(item);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_totalPages > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 1 ? () => setState(() => _page--) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('$_page / $_totalPages'),
                        IconButton(
                          onPressed: _page < _totalPages ? () => setState(() => _page++) : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
