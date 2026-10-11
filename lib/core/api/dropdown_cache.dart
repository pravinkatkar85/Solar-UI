import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_ui/core/api/dropdown_models.dart';

/// Stores successful dropdown results until `cache_ttl_seconds` elapses.
///
/// Empty option lists are cached for that same TTL and are then refreshed.
/// A TTL of zero is not stored. A broken cache entry is removed and treated
/// as a miss. Error responses are never written here.
abstract interface class DropdownCacheStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

class MemoryDropdownCacheStore implements DropdownCacheStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class SharedPreferencesDropdownCacheStore implements DropdownCacheStore {
  @override
  Future<String?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}

class DropdownResultCache {
  DropdownResultCache({required this._store, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DropdownCacheStore _store;
  final DateTime Function() _clock;

  static String cacheKey(String dropdownCode, String? parentValue) {
    final parent = parentValue?.trim() ?? '';
    return 'dropdown_cache.${dropdownCode.trim()}|$parent';
  }

  Future<DropdownList?> read({
    required String dropdownCode,
    String? parentValue,
  }) async {
    final key = cacheKey(dropdownCode, parentValue);
    final stored = await _store.read(key);
    if (stored == null) return null;

    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) {
        await _store.remove(key);
        return null;
      }
      final json = Map<String, dynamic>.from(decoded);
      final expiresAtMs = json['expires_at_ms'];
      final storedParent = json['parent_value'];
      final data = json['data'];
      final parent = _normalizedParent(parentValue);
      if (expiresAtMs is! int || storedParent != parent || data is! Map) {
        await _store.remove(key);
        return null;
      }
      if (expiresAtMs <= _clock().millisecondsSinceEpoch) {
        await _store.remove(key);
        return null;
      }
      final list = DropdownList.fromData(Map<String, dynamic>.from(data));
      if (list.dropdownCode != dropdownCode.trim()) {
        await _store.remove(key);
        return null;
      }
      return list;
    } on Object {
      await _store.remove(key);
      return null;
    }
  }

  Future<void> write({required DropdownList list, String? parentValue}) async {
    if (list.cacheTtlSeconds <= 0) return;

    final key = cacheKey(list.dropdownCode, parentValue);
    final expiresAt = _clock().add(Duration(seconds: list.cacheTtlSeconds));
    await _store.write(
      key,
      jsonEncode({
        'expires_at_ms': expiresAt.millisecondsSinceEpoch,
        'parent_value': _normalizedParent(parentValue),
        'data': list.toJson(),
      }),
    );
  }

  String _normalizedParent(String? parentValue) {
    final parent = parentValue?.trim() ?? '';
    return parent.isEmpty ? '' : parent;
  }
}
