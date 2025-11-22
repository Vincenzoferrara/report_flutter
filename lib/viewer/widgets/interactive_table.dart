import 'package:flutter/material.dart';
import '../../core/data_extractor.dart';

/// Tabella interattiva con ordinamento, selezione e drill-down
class InteractiveTable extends StatefulWidget {
  final List columns;
  final List<dynamic> tableData;
  final Map<String, dynamic> headerStyle;
  final Map<String, dynamic> cellStyle;
  final double borderWidth;
  final Color borderColor;
  final double scale;
  final bool enableSorting;
  final bool enableSelection;
  final bool enableDrillDown;
  final Function(dynamic)? onRowClick;

  const InteractiveTable({
    super.key,
    required this.columns,
    required this.tableData,
    required this.headerStyle,
    required this.cellStyle,
    required this.borderWidth,
    required this.borderColor,
    required this.scale,
    required this.enableSorting,
    required this.enableSelection,
    required this.enableDrillDown,
    this.onRowClick,
  });

  @override
  State<InteractiveTable> createState() => _InteractiveTableState();
}

class _InteractiveTableState extends State<InteractiveTable> {
  List<dynamic> _sortedData = [];
  String? _sortColumn;
  bool _sortAscending = true;
  Set<int> _selectedRows = <int>{};

  @override
  void initState() {
    super.initState();
    _sortedData = List.from(widget.tableData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con controlli
        if (widget.enableSelection || widget.enableSorting)
          _buildTableHeader(),
        
        // Tabella
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  _parseColor(widget.headerStyle['backgroundColor'] ?? '#EEEEEE'),
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primaryContainer;
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.grey.shade50;
                    }
                    return null;
                  },
                ),
                border: TableBorder.all(
                  color: widget.borderColor,
                  width: widget.borderWidth,
                ),
                columnSpacing: 4 * widget.scale,
                horizontalMargin: 2 * widget.scale,
                headingTextStyle: TextStyle(
                  fontSize: (widget.headerStyle['fontSize'] as num?)?.toDouble() ?? 10 * widget.scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                dataTextStyle: TextStyle(
                  fontSize: (widget.cellStyle['fontSize'] as num?)?.toDouble() ?? 9 * widget.scale,
                  color: Colors.black87,
                ),
                showCheckboxColumn: widget.enableSelection,
                onSelectAll: widget.enableSelection ? _selectAll : null,
                columns: _buildColumns(),
                rows: _buildRows(),
              ),
            ),
          ),
        ),
        
        // Footer con informazioni
        if (widget.enableSelection)
          _buildTableFooter(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.enableSelection) ...[
            Text(
              '${_selectedRows.length} selezionati',
              style: TextStyle(
                fontSize: 10 * widget.scale,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedRows.isNotEmpty)
              TextButton(
                onPressed: _clearSelection,
                child: Text(
                  'Cancella',
                  style: TextStyle(fontSize: 10 * widget.scale),
                ),
              ),
          ],
          const Spacer(),
          if (widget.enableSorting && _sortColumn != null) ...[
            Icon(
              Icons.sort,
              size: 12 * widget.scale,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Ordinato per $_sortColumn',
              style: TextStyle(
                fontSize: 10 * widget.scale,
                color: Colors.grey.shade600,
              ),
            ),
            IconButton(
              onPressed: _clearSorting,
              icon: Icon(
                Icons.clear,
                size: 12 * widget.scale,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: widget.borderColor,
            width: widget.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_sortedData.length} righe totali',
            style: TextStyle(
              fontSize: 10 * widget.scale,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          if (_selectedRows.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _exportSelected,
              icon: Icon(Icons.download, size: 12 * widget.scale),
              label: Text(
                'Esporta selezionati',
                style: TextStyle(fontSize: 10 * widget.scale),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return widget.columns.map<DataColumn>((column) {
      final columnDef = column as Map<String, dynamic>;
      final field = columnDef['field'] as String;
      final title = columnDef['title'] as String? ?? field;
      
      return DataColumn(
        label: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: (widget.headerStyle['fontSize'] as num?)?.toDouble() ?? 10 * widget.scale,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.enableSorting) ...[
              SizedBox(width: 4 * widget.scale),
              _buildSortIcon(field),
            ],
          ],
        ),
        onSort: widget.enableSorting ? (columnIndex, ascending) {
          _sortData(field, ascending);
        } : null,
        tooltip: widget.enableSorting ? 'Clicca per ordinare' : null,
      );
    }).toList();
  }

  Widget _buildSortIcon(String field) {
    if (_sortColumn != field) {
      return Icon(
        Icons.unfold_more,
        size: 12 * widget.scale,
        color: Colors.grey.shade400,
      );
    }
    
    return Icon(
      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 12 * widget.scale,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  List<DataRow> _buildRows() {
    return _sortedData.asMap().entries.map<DataRow>((entry) {
      final index = entry.key;
      final rowData = entry.value;
      final isSelected = _selectedRows.contains(index);
      
      return DataRow(
        selected: isSelected,
        onSelectChanged: widget.enableSelection ? (selected) {
          _toggleRowSelection(index, selected ?? false);
        } : null,
        cells: widget.columns.map<DataCell>((column) {
          final columnDef = column as Map<String, dynamic>;
          final field = columnDef['field'] as String;
          final value = DataExtractor.getValue(rowData, field) ?? '';
          
          return DataCell(
            SizedBox(
              width: (columnDef['width'] as num?)?.toDouble() ?? 80 * widget.scale,
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: (widget.cellStyle['fontSize'] as num?)?.toDouble() ?? 9 * widget.scale,
                  decoration: widget.enableDrillDown && _isClickableField(field)
                      ? TextDecoration.underline
                      : null,
                  color: widget.enableDrillDown && _isClickableField(field)
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: widget.enableDrillDown && _isClickableField(field)
                ? () => widget.onRowClick?.call(rowData)
                : null,
          );
        }).toList(),
        onLongPress: widget.enableDrillDown
            ? () => widget.onRowClick?.call(rowData)
            : null,
      );
    }).toList();
  }

  bool _isClickableField(String field) {
    // Logica per determinare se un campo è cliccabile per drill-down
    // Es. campi ID, codici, link, etc.
    final clickableFields = ['id', 'code', 'codice', 'link', 'url'];
    return clickableFields.any((clickable) => 
        field.toLowerCase().contains(clickable));
  }

  void _sortData(String field, bool ascending) {
    setState(() {
      _sortColumn = field;
      _sortAscending = ascending;
      
      _sortedData.sort((a, b) {
        final aValue = DataExtractor.getValue(a, field);
        final bValue = DataExtractor.getValue(b, field);
        
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return ascending ? -1 : 1;
        if (bValue == null) return ascending ? 1 : -1;
        
        final comparison = aValue.toString().compareTo(bValue.toString());
        return ascending ? comparison : -comparison;
      });
    });
  }

  void _clearSorting() {
    setState(() {
      _sortColumn = null;
      _sortedData = List.from(widget.tableData);
    });
  }

  void _toggleRowSelection(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedRows.add(index);
      } else {
        _selectedRows.remove(index);
      }
    });
  }

  void _selectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedRows = Set.from(Iterable.generate(_sortedData.length));
      } else {
        _selectedRows.clear();
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedRows.clear();
    });
  }

  void _exportSelected() {
    final selectedData = _selectedRows.map((index) => _sortedData[index]).toList();
    
    // TODO: Implementare esportazione dati selezionati
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Esportazione di ${selectedData.length} record in sviluppo'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}