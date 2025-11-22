import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_template.dart';
import '../viewer/renderers/report_renderer.dart';

/// Servizio per gestione cache e refresh dati
class DataCacheService {
  static const String _cachePrefix = 'report_cache_';
  static const String _metadataPrefix = 'cache_metadata_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  static const int _maxCacheSize = 50; // Massimo numero di report in cache

  static SharedPreferences? _prefs;

  /// Inizializza il servizio
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Salva dati in cache
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
        'duration': duration?.inMilliseconds ?? _defaultCacheDuration.inMilliseconds,
        'metadata': metadata ?? {},
      };

      final jsonString = jsonEncode(cacheData);
      await _prefs!.setString('$_cachePrefix$cacheKey', jsonString);
      
      // Aggiorna metadati della cache
      await _updateCacheMetadata(cacheKey, cacheData);
      
      // Pulisci cache vecchia se necessario
      await _cleanupOldCache();
    } catch (e) {
      throw Exception('Errore durante il salvataggio in cache: $e');
    }
  }

  /// Recupera dati dalla cache
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

      // Verifica se la cache è ancora valida
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > duration) {
        // Cache scaduta, rimuovila
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
      // Se c'è un errore, rimuovi la cache corrotta
      await removeCachedData(cacheKey);
      return null;
    }
  }

  /// Rimuovi dati specifici dalla cache
  static Future<void> removeCachedData(String cacheKey) async {
    await init();
    
    await _prefs!.remove('$_cachePrefix$cacheKey');
    await _prefs!.remove('$_metadataPrefix$cacheKey');
  }

  /// Svuota tutta la cache
  static Future<void> clearAllCache() async {
    await init();
    
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_metadataPrefix)) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Ottiene informazioni sulla cache
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
            final metadata = cacheData['metadata'] as Map<String, dynamic>? ?? {};
            
            totalItems++;
            totalSize += jsonString.length;
            
            final now = DateTime.now().millisecondsSinceEpoch;
            final isExpired = now - timestamp > duration;
            
            items.add(CacheItemInfo(
              key: cacheKey,
              timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
              size: jsonString.length,
              isExpired: isExpired,
              metadata: metadata,
            ));
          } catch (e) {
            // Ignora cache corrotta
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

  /// Aggiorna metadati della cache
  static Future<void> _updateCacheMetadata(String cacheKey, Map<String, dynamic> cacheData) async {
    final metadata = {
      'lastAccessed': DateTime.now().millisecondsSinceEpoch,
      'key': cacheKey,
      'timestamp': cacheData['timestamp'],
      'size': jsonEncode(cacheData).length,
    };

    await _prefs!.setString('$_metadataPrefix$cacheKey', jsonEncode(metadata));
  }

  /// Pulisce cache vecchia
  static Future<void> _cleanupOldCache() async {
    final cacheInfo = await getCacheInfo();
    
    if (cacheInfo.totalItems <= _maxCacheSize) return;

    // Ordina per ultimo accesso (più vecchi prima)
    final sortedItems = List.from(cacheInfo.items);
    sortedItems.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

    // Rimuovi gli elementi più vecchi fino a raggiungere il limite
    final itemsToRemove = cacheInfo.totalItems - _maxCacheSize;
    for (int i = 0; i < itemsToRemove; i++) {
      await removeCachedData(sortedItems[i].key);
    }
  }
}

/// Risultato della cache
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

/// Informazioni sulla cache
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

/// Informazioni su un item della cache
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

/// Funzione di callback per refresh dati
typedef DataRefreshCallback = Future<List<dynamic>> Function(
  ReportTemplate template,
  Map<String, dynamic>? parameters,
  List<ReportFilter>? filters,
);

/// Servizio per refresh dati
class DataRefreshService {

  /// Esegue refresh dati con gestione cache
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
      // Se non è forzato, prova a ottenere dalla cache
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

      // Esegui refresh dati
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
        throw Exception('Nessuna callback di refresh fornita');
      }
    } catch (e) {
      // In caso di errore, prova a usare cache anche se scaduta
      if (!forceRefresh) {
        final cachedData = await DataCacheService.getCachedData(cacheKey);
        if (cachedData != null) {
          return RefreshResult(
            data: cachedData.data,
            source: DataSource.cache,
            timestamp: cachedData.timestamp,
            metadata: {
              ...cachedData.metadata,
              'warning': 'Dati dalla cache scaduta a causa di errore refresh',
              'error': e.toString(),
            },
          );
        }
      }
      
      throw Exception('Errore durante refresh dati: $e');
    }
  }

  /// Genera chiave cache univoca
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

/// Risultato del refresh
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

/// Sorgente dati
enum DataSource {
  cache,
  remote,
}