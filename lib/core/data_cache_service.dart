import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_template.dart';
import '../viewer/renderers/report_renderer.dart';

/// Service that manages data caching and refresh
class DataCacheService {
  static const String _cachePrefix = 'report_cache_';
  static const String _metadataPrefix = 'cache_metadata_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const int _maxCacheSize = 50; // Maximum number of cached reports

  static SharedPreferences? _prefs;

  /// Initializes the service
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves data to the cache
  static Future<void> cacheData(
    String cacheKey,
    List<dynamic> data, {
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    await init();

    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'duration':
            duration?.inMilliseconds ?? _defaultCacheDuration.inMilliseconds,
        'metadata': metadata ?? {},
      };

      final jsonString = jsonEncode(cacheData);
      await _prefs!.setString('$_cachePrefix$cacheKey', jsonString);

      await _updateCacheMetadata(cacheKey, cacheData);

      // Drop old cache entries if needed
      await _cleanupOldCache();
    } catch (e) {
      throw Exception('Error while saving to the cache: $e');
    }
  }

  /// Reads data from the cache
  static Future<CacheResult?> getCachedData(String cacheKey) async {
    await init();

    try {
      final jsonString = _prefs!.getString('$_cachePrefix$cacheKey');
      if (jsonString == null) return null;

      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final duration = cacheData['duration'] as int;
      final data = cacheData['data'] as List<dynamic>;
      final metadata = cacheData['metadata'] as Map<String, dynamic>? ?? {};

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > duration) {
        // Expired cache, remove it
        await removeCachedData(cacheKey);
        return null;
      }

      return CacheResult(
        data: data,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
        metadata: metadata,
        isExpired: false,
      );
    } catch (e) {
      // On error, remove the corrupted cache
      await removeCachedData(cacheKey);
      return null;
    }
  }

  /// Removes specific data from the cache
  static Future<void> removeCachedData(String cacheKey) async {
    await init();

    await _prefs!.remove('$_cachePrefix$cacheKey');
    await _prefs!.remove('$_metadataPrefix$cacheKey');
  }

  /// Clears the whole cache
  static Future<void> clearAllCache() async {
    await init();

    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_metadataPrefix)) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Returns information about the cache
  static Future<CacheInfo> getCacheInfo() async {
    await init();

    final keys = _prefs!.getKeys();
    int totalItems = 0;
    int totalSize = 0;
    final List<CacheItemInfo> items = [];

    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final cacheKey = key.substring(_cachePrefix.length);
        final jsonString = _prefs!.getString(key);

        if (jsonString != null) {
          try {
            final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
            final timestamp = cacheData['timestamp'] as int;
            final duration = cacheData['duration'] as int;
            final metadata =
                cacheData['metadata'] as Map<String, dynamic>? ?? {};

            totalItems++;
            totalSize += jsonString.length;

            final now = DateTime.now().millisecondsSinceEpoch;
            final isExpired = now - timestamp > duration;

            items.add(
              CacheItemInfo(
                key: cacheKey,
                timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
                size: jsonString.length,
                isExpired: isExpired,
                metadata: metadata,
              ),
            );
          } catch (e) {
            // Ignore corrupted cache
          }
        }
      }
    }

    return CacheInfo(
      totalItems: totalItems,
      totalSize: totalSize,
      items: items,
    );
  }

  /// Updates the cache metadata
  static Future<void> _updateCacheMetadata(
    String cacheKey,
    Map<String, dynamic> cacheData,
  ) async {
    final metadata = {
      'lastAccessed': DateTime.now().millisecondsSinceEpoch,
      'key': cacheKey,
      'timestamp': cacheData['timestamp'],
      'size': jsonEncode(cacheData).length,
    };

    await _prefs!.setString('$_metadataPrefix$cacheKey', jsonEncode(metadata));
  }

  /// Clears the old cache
  static Future<void> _cleanupOldCache() async {
    final cacheInfo = await getCacheInfo();

    if (cacheInfo.totalItems <= _maxCacheSize) return;

    // Sort by last access (oldest first)
    final sortedItems = List.from(cacheInfo.items);
    sortedItems.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

    final itemsToRemove = cacheInfo.totalItems - _maxCacheSize;
    for (int i = 0; i < itemsToRemove; i++) {
      await removeCachedData(sortedItems[i].key);
    }
  }
}

/// Cache result
class CacheResult {
  final List<dynamic> data;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final bool isExpired;

  CacheResult({
    required this.data,
    required this.timestamp,
    required this.metadata,
    required this.isExpired,
  });
}

/// Information about the cache
class CacheInfo {
  final int totalItems;
  final int totalSize;
  final List<CacheItemInfo> items;

  CacheInfo({
    required this.totalItems,
    required this.totalSize,
    required this.items,
  });
}

/// Information about a cache item
class CacheItemInfo {
  final String key;
  final DateTime timestamp;
  final int size;
  final bool isExpired;
  final Map<String, dynamic> metadata;
  late final DateTime lastAccessed;

  CacheItemInfo({
    required this.key,
    required this.timestamp,
    required this.size,
    required this.isExpired,
    required this.metadata,
  }) {
    lastAccessed = DateTime.now();
  }
}

/// Callback that refreshes the data
typedef DataRefreshCallback =
    Future<List<dynamic>> Function(
      ReportTemplate template,
      Map<String, dynamic>? parameters,
      List<ReportFilter>? filters,
    );

/// Service that refreshes data
class DataRefreshService {
  /// Refreshes data, using the cache
  static Future<RefreshResult> refreshData(
    ReportTemplate template, {
    Map<String, dynamic>? parameters,
    List<ReportFilter>? filters,
    Duration? cacheDuration,
    bool forceRefresh = false,
    DataRefreshCallback? refreshCallback,
  }) async {
    final cacheKey = _generateCacheKey(template, parameters, filters);

    try {
      // Unless forced, try the cache first
      if (!forceRefresh) {
        final cachedData = await DataCacheService.getCachedData(cacheKey);
        if (cachedData != null && !cachedData.isExpired) {
          return RefreshResult(
            data: cachedData.data,
            source: DataSource.cache,
            timestamp: cachedData.timestamp,
            metadata: cachedData.metadata,
          );
        }
      }

      if (refreshCallback != null) {
        final startTime = DateTime.now();
        final data = await refreshCallback(template, parameters, filters);
        final endTime = DateTime.now();

        // Salva in cache
        await DataCacheService.cacheData(
          cacheKey,
          data,
          duration: cacheDuration,
          metadata: {
            'template': template.name,
            'parameters': parameters,
            'filters': filters?.map((f) => f.field).toList(),
            'refreshTime': endTime.millisecondsSinceEpoch,
            'duration': endTime.difference(startTime).inMilliseconds,
          },
        );

        return RefreshResult(
          data: data,
          source: DataSource.remote,
          timestamp: endTime,
          metadata: {
            'refreshDuration': endTime.difference(startTime).inMilliseconds,
            'cacheKey': cacheKey,
          },
        );
      } else {
        throw Exception('No refresh callback provided');
      }
    } catch (e) {
      // On error, use the cache even when expired
      if (!forceRefresh) {
        final cachedData = await DataCacheService.getCachedData(cacheKey);
        if (cachedData != null) {
          return RefreshResult(
            data: cachedData.data,
            source: DataSource.cache,
            timestamp: cachedData.timestamp,
            metadata: {
              ...cachedData.metadata,
              'warning':
                  'Data from the expired cache, because the refresh failed',
              'error': e.toString(),
            },
          );
        }
      }

      throw Exception('Error while refreshing the data: $e');
    }
  }

  /// Generates a unique cache key
  static String _generateCacheKey(
    ReportTemplate template,
    Map<String, dynamic>? parameters,
    List<ReportFilter>? filters,
  ) {
    final buffer = StringBuffer();
    buffer.write(template.name);

    if (parameters != null && parameters.isNotEmpty) {
      buffer.write('_params_');
      final sortedKeys = parameters.keys.toList()..sort();
      for (final key in sortedKeys) {
        buffer.write('$key=${parameters[key]}');
      }
    }

    if (filters != null && filters.isNotEmpty) {
      buffer.write('_filters_');
      final activeFilters = filters.where((f) => f.enabled).toList();
      activeFilters.sort((a, b) => a.field.compareTo(b.field));
      for (final filter in activeFilters) {
        buffer.write('${filter.field}${filter.operator}${filter.value}');
      }
    }

    return buffer.toString().hashCode.toString();
  }
}

/// Refresh result
class RefreshResult {
  final List<dynamic> data;
  final DataSource source;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  RefreshResult({
    required this.data,
    required this.source,
    required this.timestamp,
    required this.metadata,
  });
}

/// Data source
enum DataSource { cache, remote }
