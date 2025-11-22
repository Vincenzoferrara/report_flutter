import 'package:flutter/material.dart';
import '../models/report_element.dart';
import '../schema/data_schema.dart';

/// Servizio per caricare immagini basate su condizioni
class ConditionalImageLoader {
  /// Carica un'immagine basata sulle condizioni configurate
  static Widget loadImage(
    Map<String, dynamic> data, 
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final source = element.properties['source'] as String?;
    
    switch (source) {
      case 'conditional':
        return _loadConditionalImage(data, element, width: width, height: height, fit: fit);
      case 'field':
        return _loadFieldImage(data, element, width: width, height: height, fit: fit);
      case 'asset':
        return _loadAssetImage(element, width: width, height: height, fit: fit);
      case 'url':
        return _loadUrlImage(element, width: width, height: height, fit: fit);
      default:
        return _loadDefaultImage(width: width, height: height);
    }
  }

  /// Carica un'immagine basata su condizioni logiche
  static Widget _loadConditionalImage(
    Map<String, dynamic> data,
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? []
    );
    
    // Valuta ogni regola in ordine
    for (final rule in conditionalImages) {
      if (_evaluateCondition(data, rule)) {
        final imageField = rule['imageField'] as String?;
        if (imageField != null && imageField.isNotEmpty) {
          return _loadFieldImageByName(data, imageField, width: width, height: height, fit: fit);
        }
      }
    }
    
    // Nessuna condizione soddisfatta, usa fallback
    final fallbackAsset = element.properties['fallbackAsset'] as String?;
    if (fallbackAsset != null && fallbackAsset.isNotEmpty) {
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _loadErrorImage(width, height),
      );
    }
    
    return _loadDefaultImage(width: width, height: height);
  }

  /// Carica un'immagine da un campo dati
  static Widget _loadFieldImage(
    Map<String, dynamic> data,
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final fieldName = element.properties['fieldName'] as String?;
    if (fieldName != null && fieldName.isNotEmpty) {
      return _loadFieldImageByName(data, fieldName, width: width, height: height, fit: fit);
    }
    return _loadDefaultImage(width: width, height: height);
  }

  /// Carica un'immagine da un campo dati specifico
  static Widget _loadFieldImageByName(
    Map<String, dynamic> data,
    String fieldName, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final imageValue = _getNestedValue(data, fieldName);
    
    if (imageValue == null) {
      return _loadDefaultImage(width: width, height: height);
    }
    
    // Se è un URL, carica da rete
    if (imageValue is String && _isUrl(imageValue)) {
      return Image.network(
        imageValue,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _loadErrorImage(width, height),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadLoadingImage(width, height, loadingProgress);
        },
      );
    }
    
    // Se è un path di asset, carica da asset
    if (imageValue is String && imageValue.startsWith('assets/')) {
      return Image.asset(
        imageValue,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _loadErrorImage(width, height),
      );
    }
    
    // Se è un path relativo, prova come asset
    if (imageValue is String) {
      return Image.asset(
        'assets/$imageValue',
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _loadErrorImage(width, height),
      );
    }
    
    // Se è un'immagine in memoria (es. da camera)
    if (imageValue is Image) {
      return imageValue;
    }
    
    return _loadDefaultImage(width: width, height: height);
  }

  /// Carica un'immagine dagli asset
  static Widget _loadAssetImage(
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final assetPath = element.properties['assetPath'] as String?;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _loadErrorImage(width, height),
      );
    }
    return _loadDefaultImage(width: width, height: height);
  }

  /// Carica un'immagine da URL
  static Widget _loadUrlImage(
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final url = element.properties['url'] as String?;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _loadErrorImage(width, height),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadLoadingImage(width, height, loadingProgress);
        },
      );
    }
    return _loadDefaultImage(width: width, height: height);
  }

  /// Immagine di default
  static Widget _loadDefaultImage({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey[400],
        size: (width ?? 50) * 0.6,
      ),
    );
  }

  /// Immagine di errore
  static Widget _loadErrorImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.broken_image,
        color: Colors.red[400],
        size: (width ?? 50) * 0.6,
      ),
    );
  }

  /// Immagine di caricamento
  static Widget _loadLoadingImage(double? width, double? height, ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }

  /// Valuta una condizione per le immagini condizionali
  static bool _evaluateCondition(Map<String, dynamic> data, Map<String, dynamic> rule) {
    final condition = rule['condition'] as String?;
    if (condition == null || condition.isEmpty) return false;
    
    try {
      // Sostituisci i campi dati nella condizione
      String evalCondition = condition;
      
      // Trova tutti i riferimenti a campi {campo}
      final fieldRegex = RegExp(r'\{([^}]+)\}');
      final matches = fieldRegex.allMatches(condition);
      
      for (final match in matches) {
        final fieldName = match.group(1)!;
        final value = _getNestedValue(data, fieldName);
        final valueStr = value?.toString() ?? 'null';
        
        // Gestisci stringhe con virgolette
        if (value is String) {
          evalCondition = evalCondition.replaceAll('{$fieldName}', '"$valueStr"');
        } else {
          evalCondition = evalCondition.replaceAll('{$fieldName}', valueStr);
        }
      }
      
      // Valutazione semplificata delle condizioni
      return _evaluateSimpleCondition(evalCondition);
    } catch (e) {
      return false;
    }
  }

  /// Valutazione semplificata di condizioni
  static bool _evaluateSimpleCondition(String condition) {
    try {
      // Rimuovi spazi extra
      condition = condition.trim();
      
      // Condizioni di uguaglianza
      if (condition.contains('==')) {
        final parts = condition.split('==');
        if (parts.length == 2) {
          final left = parts[0].trim().replaceAll('"', '');
          final right = parts[1].trim().replaceAll('"', '');
          return left == right;
        }
      }
      
      // Condizioni di disuguaglianza
      if (condition.contains('!=')) {
        final parts = condition.split('!=');
        if (parts.length == 2) {
          final left = parts[0].trim().replaceAll('"', '');
          final right = parts[1].trim().replaceAll('"', '');
          return left != right;
        }
      }
      
      // Condizioni numeriche
      if (condition.contains('>')) {
        final parts = condition.split('>');
        if (parts.length == 2) {
          final left = num.tryParse(parts[0].trim());
          final right = num.tryParse(parts[1].trim());
          return left != null && right != null && left > right;
        }
      }
      
      if (condition.contains('<')) {
        final parts = condition.split('<');
        if (parts.length == 2) {
          final left = num.tryParse(parts[0].trim());
          final right = num.tryParse(parts[1].trim());
          return left != null && right != null && left < right;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene un valore annidato da una mappa usando notazione dot
  static dynamic _getNestedValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    
    final parts = path.split('.');
    dynamic current = data;
    
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    
    return current;
  }

  /// Verifica se una stringa è un URL
  static bool _isUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Aggiunge una regola di immagine condizionale
  static void addConditionalRule(ReportElement element, Map<String, dynamic> rule) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? []
    );
    conditionalImages.add(rule);
    element.properties['conditionalImages'] = conditionalImages;
  }

  /// Rimuove una regola di immagine condizionale
  static void removeConditionalRule(ReportElement element, int index) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? []
    );
    if (index >= 0 && index < conditionalImages.length) {
      conditionalImages.removeAt(index);
      element.properties['conditionalImages'] = conditionalImages;
    }
  }

  /// Aggiorna una regola di immagine condizionale
  static void updateConditionalRule(ReportElement element, int index, Map<String, dynamic> rule) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? []
    );
    if (index >= 0 && index < conditionalImages.length) {
      conditionalImages[index] = rule;
      element.properties['conditionalImages'] = conditionalImages;
    }
  }

  /// Verifica se un elemento supporta immagini condizionali
  static bool supportsConditionalImages(ReportElement element) {
    return element.type == ReportElementType.image;
  }

  /// Ottiene le regole di immagine condizionale da un elemento
  static List<Map<String, dynamic>> getConditionalRules(ReportElement element) {
    return List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? []
    );
  }
}