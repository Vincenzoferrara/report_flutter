import 'package:flutter/material.dart';
import '../models/report_element.dart';

/// Service that loads images based on conditions
class ConditionalImageLoader {
  /// Loads an image based on the configured conditions
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
        return _loadConditionalImage(
          data,
          element,
          width: width,
          height: height,
          fit: fit,
        );
      case 'field':
        return _loadFieldImage(
          data,
          element,
          width: width,
          height: height,
          fit: fit,
        );
      case 'asset':
        return _loadAssetImage(element, width: width, height: height, fit: fit);
      case 'url':
        return _loadUrlImage(element, width: width, height: height, fit: fit);
      default:
        return _loadDefaultImage(width: width, height: height);
    }
  }

  /// Loads an image based on logical conditions
  static Widget _loadConditionalImage(
    Map<String, dynamic> data,
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );

    // Evaluate the rules in order
    for (final rule in conditionalImages) {
      if (_evaluateCondition(data, rule)) {
        final imageField = rule['imageField'] as String?;
        if (imageField != null && imageField.isNotEmpty) {
          return _loadFieldImageByName(
            data,
            imageField,
            width: width,
            height: height,
            fit: fit,
          );
        }
      }
    }

    // No condition met, use the fallback
    final fallbackAsset = element.properties['fallbackAsset'] as String?;
    if (fallbackAsset != null && fallbackAsset.isNotEmpty) {
      return Image.asset(
        fallbackAsset,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _loadErrorImage(width, height),
      );
    }

    return _loadDefaultImage(width: width, height: height);
  }

  /// Loads an image from a data field
  static Widget _loadFieldImage(
    Map<String, dynamic> data,
    ReportElement element, {
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final fieldName = element.properties['fieldName'] as String?;
    if (fieldName != null && fieldName.isNotEmpty) {
      return _loadFieldImageByName(
        data,
        fieldName,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return _loadDefaultImage(width: width, height: height);
  }

  /// Loads an image from a specific data field
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

    if (imageValue is String && _isUrl(imageValue)) {
      return Image.network(
        imageValue,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _loadErrorImage(width, height),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadLoadingImage(width, height, loadingProgress);
        },
      );
    }

    if (imageValue is String && imageValue.startsWith('assets/')) {
      return Image.asset(
        imageValue,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _loadErrorImage(width, height),
      );
    }

    // Relative path: try it as an asset
    if (imageValue is String) {
      return Image.asset(
        'assets/$imageValue',
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _loadErrorImage(width, height),
      );
    }

    // In-memory image (e.g. from the camera)
    if (imageValue is Image) {
      return imageValue;
    }

    return _loadDefaultImage(width: width, height: height);
  }

  /// Loads an image from the assets
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
        errorBuilder: (context, error, stackTrace) =>
            _loadErrorImage(width, height),
      );
    }
    return _loadDefaultImage(width: width, height: height);
  }

  /// Loads an image from a URL
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
        errorBuilder: (context, error, stackTrace) =>
            _loadErrorImage(width, height),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _loadLoadingImage(width, height, loadingProgress);
        },
      );
    }
    return _loadDefaultImage(width: width, height: height);
  }

  /// Default image
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

  /// Error image
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

  /// Loading image
  static Widget _loadLoadingImage(
    double? width,
    double? height,
    ImageChunkEvent loadingProgress,
  ) {
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
              ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
              : null,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }

  /// Evaluates a condition for conditional images
  static bool _evaluateCondition(
    Map<String, dynamic> data,
    Map<String, dynamic> rule,
  ) {
    final condition = rule['condition'] as String?;
    if (condition == null || condition.isEmpty) return false;

    try {
      String evalCondition = condition;

      // Find every {field} reference
      final fieldRegex = RegExp(r'\{([^}]+)\}');
      final matches = fieldRegex.allMatches(condition);

      for (final match in matches) {
        final fieldName = match.group(1)!;
        final value = _getNestedValue(data, fieldName);
        final valueStr = value?.toString() ?? 'null';

        // Handle quoted strings
        if (value is String) {
          evalCondition = evalCondition.replaceAll(
            '{$fieldName}',
            '"$valueStr"',
          );
        } else {
          evalCondition = evalCondition.replaceAll('{$fieldName}', valueStr);
        }
      }

      return _evaluateSimpleCondition(evalCondition);
    } catch (e) {
      return false;
    }
  }

  /// Simplified condition evaluation
  static bool _evaluateSimpleCondition(String condition) {
    try {
      // Remove extra spaces
      condition = condition.trim();

      if (condition.contains('==')) {
        final parts = condition.split('==');
        if (parts.length == 2) {
          final left = parts[0].trim().replaceAll('"', '');
          final right = parts[1].trim().replaceAll('"', '');
          return left == right;
        }
      }

      if (condition.contains('!=')) {
        final parts = condition.split('!=');
        if (parts.length == 2) {
          final left = parts[0].trim().replaceAll('"', '');
          final right = parts[1].trim().replaceAll('"', '');
          return left != right;
        }
      }

      // Numeric conditions
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

  /// Reads a nested value from a map using dot notation
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

  /// Whether a string is a URL
  static bool _isUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Adds a conditional image rule
  static void addConditionalRule(
    ReportElement element,
    Map<String, dynamic> rule,
  ) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );
    conditionalImages.add(rule);
    element.properties['conditionalImages'] = conditionalImages;
  }

  /// Removes a conditional image rule
  static void removeConditionalRule(ReportElement element, int index) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );
    if (index >= 0 && index < conditionalImages.length) {
      conditionalImages.removeAt(index);
      element.properties['conditionalImages'] = conditionalImages;
    }
  }

  /// Updates a conditional image rule
  static void updateConditionalRule(
    ReportElement element,
    int index,
    Map<String, dynamic> rule,
  ) {
    final conditionalImages = List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );
    if (index >= 0 && index < conditionalImages.length) {
      conditionalImages[index] = rule;
      element.properties['conditionalImages'] = conditionalImages;
    }
  }

  /// Whether an element supports conditional images
  static bool supportsConditionalImages(ReportElement element) {
    return element.type == ReportElementType.image;
  }

  /// Returns the conditional image rules of an element
  static List<Map<String, dynamic>> getConditionalRules(ReportElement element) {
    return List<Map<String, dynamic>>.from(
      element.properties['conditionalImages'] ?? [],
    );
  }
}
