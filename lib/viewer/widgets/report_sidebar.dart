import 'package:flutter/material.dart';
import '../renderers/report_renderer.dart';
import '../../models/report_template.dart';
import '../../schema/data_schema.dart';

/// Widget per la barra laterale del visualizzatore report
class ReportSidebar extends StatefulWidget {
  final ReportTemplate template;
  final List<dynamic> data;
  final DataSchema? schema;
  final ReportViewerOptions options;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageSelected;
  final ValueChanged<List<ReportFilter>>? onFiltersChanged;
  final ValueChanged<Map<String, dynamic>>? onParametersChanged;

  const ReportSidebar({
    super.key,
    required this.template,
    required this.data,
    this.schema,
    required this.options,
    required this.currentPage,
    required this.totalPages,
    this.onPageSelected,
    this.onFiltersChanged,
    this.onParametersChanged,
  });

  @override
  State<ReportSidebar> createState() => _ReportSidebarState();
}

class _ReportSidebarState extends State<ReportSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReportFilter> _filters = [];
  Map<String, dynamic> _parameters = {};
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filters = List.from(widget.options.filters);
    _parameters = Map.from(widget.options.parameters);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.options.showSidebar) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _isExpanded ? 280 : 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header con toggle
          _buildHeader(),
          
          // Contenuto tabs
          if (_isExpanded) ...[
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (_isExpanded) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pannello Report',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.filter_list), text: 'Filtri'),
        Tab(icon: Icon(Icons.tune), text: 'Parametri'),
        Tab(icon: Icon(Icons.view_carousel), text: 'Pagine'),
      ],
      labelStyle: const TextStyle(fontSize: 10),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      indicatorSize: TabBarIndicatorSize.tab,
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFiltersTab(),
        _buildParametersTab(),
        _buildPagesTab(),
      ],
    );
  }

  Widget _buildFiltersTab() {
    if (!widget.options.enableFilters) {
      return const Center(
        child: Text('Filtri non abilitati'),
      );
    }

    return Column(
      children: [
        // Header filtri
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 16),
              const SizedBox(width: 8),
              Text(
                'Filtri Dati',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (_filters.isNotEmpty)
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Cancella'),
                ),
            ],
          ),
        ),
        
        // Lista filtri
        Expanded(
          child: _filters.isEmpty
              ? _buildEmptyFilters()
              : ListView.builder(
                  itemCount: _filters.length,
                  itemBuilder: (context, index) => _buildFilterItem(_filters[index], index),
                ),
        ),
        
        // Aggiungi filtro
        Container(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addFilter,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Aggiungi Filtro'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFilters() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun filtro configurato',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi filtri per filtrare i dati del report',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(ReportFilter filter, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    filter.field,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: filter.enabled,
                  onChanged: (value) {
                    _updateFilter(index, filter.copyWith(enabled: value));
                  },
                ),
                IconButton(
                  onPressed: () => _removeFilter(index),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getOperatorLabel(filter.operator),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filter.value.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersTab() {
    if (!widget.options.enableParameters) {
      return const Center(
        child: Text('Parametri non abilitati'),
      );
    }

    return Column(
      children: [
        // Header parametri
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 16),
              const SizedBox(width: 8),
              Text(
                'Parametri Report',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
        
        // Lista parametri
        Expanded(
          child: _parameters.isEmpty
              ? _buildEmptyParameters()
              : ListView.builder(
                  itemCount: _parameters.length,
                  itemBuilder: (context, index) {
                    final entry = _parameters.entries.elementAt(index);
                    return _buildParameterItem(entry.key, entry.value);
                  },
                ),
        ),
        
        // Aggiungi parametro
        Container(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _addParameter,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Aggiungi Parametro'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyParameters() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tune,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun parametro configurato',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggiungi parametri per personalizzare il report',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParameterItem(String key, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(key),
        subtitle: Text(value.toString()),
        trailing: IconButton(
          onPressed: () => _removeParameter(key),
          icon: const Icon(Icons.delete_outline, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => _editParameter(key, value),
      ),
    );
  }

  Widget _buildPagesTab() {
    return Column(
      children: [
        // Header pagine
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.view_carousel, size: 16),
              const SizedBox(width: 8),
              Text(
                'Miniature Pagine',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '${widget.currentPage + 1} / ${widget.totalPages}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        
        // Griglia miniature
        Expanded(
          child: widget.totalPages == 0
              ? _buildEmptyPages()
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: widget.totalPages,
                  itemBuilder: (context, index) => _buildPageThumbnail(index),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyPages() {
    return const Center(
      child: Text('Nessuna pagina disponibile'),
    );
  }

  Widget _buildPageThumbnail(int pageIndex) {
    final isSelected = pageIndex == widget.currentPage;
    
    return GestureDetector(
      onTap: () => widget.onPageSelected?.call(pageIndex),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.white,
        ),
        child: Column(
          children: [
            // Miniatura placeholder
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  size: 24,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            
            // Numero pagina
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Text(
                'Pagina ${pageIndex + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOperatorLabel(String operator) {
    switch (operator) {
      case 'equals':
        return 'Uguale';
      case 'contains':
        return 'Contiene';
      case 'greater':
        return 'Maggiore';
      case 'less':
        return 'Minore';
      case 'between':
        return 'Tra';
      default:
        return operator;
    }
  }

  void _addFilter() {
    // TODO: Implementare dialog per aggiungere filtro
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Filtro'),
        content: const Text('Funzionalità da implementare'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _updateFilter(int index, ReportFilter filter) {
    setState(() {
      _filters[index] = filter;
    });
    widget.onFiltersChanged?.call(_filters);
  }

  void _removeFilter(int index) {
    setState(() {
      _filters.removeAt(index);
    });
    widget.onFiltersChanged?.call(_filters);
  }

  void _clearAllFilters() {
    setState(() {
      _filters.clear();
    });
    widget.onFiltersChanged?.call(_filters);
  }

  void _addParameter() {
    // TODO: Implementare dialog per aggiungere parametro
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Parametro'),
        content: const Text('Funzionalità da implementare'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _editParameter(String key, dynamic value) {
    // TODO: Implementare dialog per modificare parametro
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifica $key'),
        content: Text('Valore attuale: $value'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  void _removeParameter(String key) {
    setState(() {
      _parameters.remove(key);
    });
    widget.onParametersChanged?.call(_parameters);
  }
}