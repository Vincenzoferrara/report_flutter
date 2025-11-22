import 'package:flutter/material.dart';

/// Modello per annotazione temporanea (solo sessione)
class SessionAnnotation {
  final String id;
  final int? pageIndex;
  final String? elementId;
  final Offset? position;
  final String content;
  final String author;
  final DateTime createdAt;
  final AnnotationType type;

  SessionAnnotation({
    required this.id,
    this.pageIndex,
    this.elementId,
    this.position,
    required this.content,
    required this.author,
    required this.createdAt,
    this.type = AnnotationType.note,
  });

  SessionAnnotation copyWith({
    String? id,
    int? pageIndex,
    String? elementId,
    Offset? position,
    String? content,
    String? author,
    DateTime? createdAt,
    AnnotationType? type,
  }) {
    return SessionAnnotation(
      id: id ?? this.id,
      pageIndex: pageIndex ?? this.pageIndex,
      elementId: elementId ?? this.elementId,
      position: position ?? this.position,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}

/// Tipi di annotazioni
enum AnnotationType {
  note,
  highlight,
  comment,
  question,
  issue,
}

/// Servizio per gestione annotazioni temporanee (solo sessione)
class SessionAnnotationService {
  static final Map<String, List<SessionAnnotation>> _sessionAnnotations = {};

  /// Aggiunge un'annotazione temporanea
  static void addAnnotation(String reportId, SessionAnnotation annotation) {
    final annotations = _sessionAnnotations[reportId] ?? [];
    annotations.removeWhere((a) => a.id == annotation.id);
    annotations.add(annotation);
    _sessionAnnotations[reportId] = annotations;
  }

  /// Ottieni tutte le annotazioni temporanee per un report
  static List<SessionAnnotation> getAnnotations(String reportId) {
    return _sessionAnnotations[reportId] ?? [];
  }

  /// Ottieni annotazioni per una pagina specifica
  static List<SessionAnnotation> getAnnotationsForPage(
    String reportId,
    int pageIndex,
  ) {
    final allAnnotations = getAnnotations(reportId);
    return allAnnotations
        .where((a) => a.pageIndex == pageIndex)
        .toList();
  }

  /// Ottieni annotazioni per un elemento specifico
  static List<SessionAnnotation> getAnnotationsForElement(
    String reportId,
    String elementId,
  ) {
    final allAnnotations = getAnnotations(reportId);
    return allAnnotations
        .where((a) => a.elementId == elementId)
        .toList();
  }

  /// Elimina un'annotazione temporanea
  static void deleteAnnotation(String reportId, String annotationId) {
    final annotations = _sessionAnnotations[reportId] ?? [];
    annotations.removeWhere((a) => a.id == annotationId);
    _sessionAnnotations[reportId] = annotations;
  }

  /// Elimina tutte le annotazioni temporanee per un report
  static void clearAnnotations(String reportId) {
    _sessionAnnotations.remove(reportId);
  }

  /// Pulisci tutte le annotazioni (fine sessione)
  static void clearAllAnnotations() {
    _sessionAnnotations.clear();
  }

  /// Genera ID univoco per annotazione
  static String generateId() {
    return 'annotation_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Conta annotazioni per un report
  static int getAnnotationCount(String reportId) {
    return _sessionAnnotations[reportId]?.length ?? 0;
  }
}

/// Widget per gestione annotazioni temporanee
class SessionAnnotationOverlay extends StatefulWidget {
  final String reportId;
  final int pageIndex;
  final List<SessionAnnotation> annotations;
  final bool enabled;
  final Function(SessionAnnotation)? onAnnotationAdded;
  final Function(SessionAnnotation)? onAnnotationUpdated;
  final Function(String)? onAnnotationDeleted;

  const SessionAnnotationOverlay({
    super.key,
    required this.reportId,
    required this.pageIndex,
    required this.annotations,
    this.enabled = true,
    this.onAnnotationAdded,
    this.onAnnotationUpdated,
    this.onAnnotationDeleted,
  });

  @override
  State<SessionAnnotationOverlay> createState() => _SessionAnnotationOverlayState();
}

class _SessionAnnotationOverlayState extends State<SessionAnnotationOverlay> {
  final List<SessionAnnotation> _localAnnotations = [];
  SessionAnnotation? _selectedAnnotation;
  bool _isAddingAnnotation = false;
  Offset? _pendingPosition;

  @override
  void initState() {
    super.initState();
    _localAnnotations.addAll(widget.annotations);
  }

  @override
  void didUpdateWidget(SessionAnnotationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.annotations != widget.annotations) {
      setState(() {
        _localAnnotations.clear();
        _localAnnotations.addAll(widget.annotations);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Indicatori annotazioni esistenti
        ..._localAnnotations.map((annotation) => _buildAnnotationMarker(annotation)),
        
        // Area per aggiungere nuove annotazioni
        if (_isAddingAnnotation)
          _buildAddAnnotationOverlay(),
      ],
    );
  }

  Widget _buildAnnotationMarker(SessionAnnotation annotation) {
    if (annotation.position == null) return const SizedBox.shrink();

    return Positioned(
      left: annotation.position!.dx,
      top: annotation.position!.dy,
      child: GestureDetector(
        onTap: () => _showAnnotationDialog(annotation),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _getAnnotationColor(annotation.type),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getAnnotationIcon(annotation.type),
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAddAnnotationOverlay() {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _pendingPosition = details.localPosition;
        });
        _showAddAnnotationDialog();
      },
      child: Container(
        color: Colors.transparent,
        child: CustomPaint(
          painter: _AddAnnotationPainter(),
        ),
      ),
    );
  }

  void _showAnnotationDialog(SessionAnnotation annotation) {
    showDialog(
      context: context,
      builder: (context) => _SessionAnnotationDialog(
        annotation: annotation,
        onSave: (updatedAnnotation) {
          SessionAnnotationService.addAnnotation(widget.reportId, updatedAnnotation);
          setState(() {
            final index = _localAnnotations.indexWhere((a) => a.id == updatedAnnotation.id);
            if (index >= 0) {
              _localAnnotations[index] = updatedAnnotation;
            }
          });
          widget.onAnnotationUpdated?.call(updatedAnnotation);
        },
        onDelete: () {
          SessionAnnotationService.deleteAnnotation(widget.reportId, annotation.id);
          setState(() {
            _localAnnotations.removeWhere((a) => a.id == annotation.id);
          });
          widget.onAnnotationDeleted?.call(annotation.id);
        },
      ),
    );
  }

  void _showAddAnnotationDialog() {
    if (_pendingPosition == null) return;

    showDialog(
      context: context,
      builder: (context) => _SessionAnnotationDialog(
        isNew: true,
        initialPosition: _pendingPosition!,
        onSave: (newAnnotation) {
          SessionAnnotationService.addAnnotation(widget.reportId, newAnnotation);
          setState(() {
            _localAnnotations.add(newAnnotation);
            _isAddingAnnotation = false;
            _pendingPosition = null;
          });
          widget.onAnnotationAdded?.call(newAnnotation);
        },
        onCancel: () {
          setState(() {
            _isAddingAnnotation = false;
            _pendingPosition = null;
          });
        },
      ),
    );
  }

  Color _getAnnotationColor(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return Colors.blue;
      case AnnotationType.highlight:
        return Colors.yellow;
      case AnnotationType.comment:
        return Colors.green;
      case AnnotationType.question:
        return Colors.orange;
      case AnnotationType.issue:
        return Colors.red;
    }
  }

  IconData _getAnnotationIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return Icons.note;
      case AnnotationType.highlight:
        return Icons.highlight;
      case AnnotationType.comment:
        return Icons.comment;
      case AnnotationType.question:
        return Icons.help;
      case AnnotationType.issue:
        return Icons.error;
    }
  }
}

/// Dialog per gestione annotazioni temporanee
class _SessionAnnotationDialog extends StatefulWidget {
  final SessionAnnotation? annotation;
  final bool isNew;
  final Offset? initialPosition;
  final Function(SessionAnnotation)? onSave;
  final Function()? onDelete;
  final Function()? onCancel;

  const _SessionAnnotationDialog({
    this.annotation,
    this.isNew = false,
    this.initialPosition,
    this.onSave,
    this.onDelete,
    this.onCancel,
  });

  @override
  State<_SessionAnnotationDialog> createState() => _SessionAnnotationDialogState();
}

class _SessionAnnotationDialogState extends State<_SessionAnnotationDialog> {
  late TextEditingController _contentController;
  late TextEditingController _authorController;
  late AnnotationType _selectedType;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.annotation?.content ?? '',
    );
    _authorController = TextEditingController(
      text: widget.annotation?.author ?? 'Utente',
    );
    _selectedType = widget.annotation?.type ?? AnnotationType.note;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Nuova Annotazione (Temporanea)' : 'Modifica Annotazione'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nota temporaneità
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questa annotazione è temporanea e sarà persa alla chiusura',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tipo annotazione
            DropdownButtonFormField<AnnotationType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: AnnotationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getAnnotationIcon(type), size: 20),
                      const SizedBox(width: 8),
                      Text(_getAnnotationLabel(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Contenuto
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Contenuto',
                border: OutlineInputBorder(),
                hintText: 'Inserisci qui la tua annotazione...',
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 16),
            
            // Autore
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Autore',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!widget.isNew)
          TextButton(
            onPressed: widget.onDelete,
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _saveAnnotation,
          child: Text(widget.isNew ? 'Aggiungi' : 'Salva'),
        ),
      ],
    );
  }

  void _saveAnnotation() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il contenuto non può essere vuoto')),
      );
      return;
    }

    final annotation = SessionAnnotation(
      id: widget.annotation?.id ?? SessionAnnotationService.generateId(),
      pageIndex: widget.annotation?.pageIndex,
      elementId: widget.annotation?.elementId,
      position: widget.initialPosition ?? widget.annotation?.position,
      content: _contentController.text.trim(),
      author: _authorController.text.trim(),
      createdAt: widget.annotation?.createdAt ?? DateTime.now(),
      type: _selectedType,
    );

    widget.onSave?.call(annotation);
    Navigator.of(context).pop();
  }

  IconData _getAnnotationIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return Icons.note;
      case AnnotationType.highlight:
        return Icons.highlight;
      case AnnotationType.comment:
        return Icons.comment;
      case AnnotationType.question:
        return Icons.help;
      case AnnotationType.issue:
        return Icons.error;
    }
  }

  String _getAnnotationLabel(AnnotationType type) {
    switch (type) {
      case AnnotationType.note:
        return 'Nota';
      case AnnotationType.highlight:
        return 'Evidenziazione';
      case AnnotationType.comment:
        return 'Commento';
      case AnnotationType.question:
        return 'Domanda';
      case AnnotationType.issue:
        return 'Problema';
    }
  }
}

/// Painter per overlay aggiunta annotazioni
class _AddAnnotationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}