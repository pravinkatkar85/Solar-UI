import 'dart:convert';

import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_models.dart';

/// Loads dropdown options from `POST /api/dropdowns` and caches successes.
///
/// The request body is only `dropdown_code` and, when a parent selection
/// exists, `parent_value`. No authentication header is added. The response
/// body is the database contract itself: `status`, `code`, `message`, `data`.
class DropdownRepository {
  DropdownRepository({
    required this._baseUrl,
    required this._transport,
    required DropdownCacheStore cache,
    DateTime Function()? clock,
    this.timeout = HttpDropdownClient.defaultTimeout,
  }) : _cache = DropdownResultCache(store: cache, clock: clock);

  static const defaultTimeout = HttpDropdownClient.defaultTimeout;

  final ApiBaseUrl _baseUrl;
  final DropdownTransport _transport;
  final DropdownResultCache _cache;
  final Duration timeout;

  Future<DropdownList> load({
    required String dropdownCode,
    String? parentValue,
  }) async {
    final code = dropdownCode.trim();
    final parent = _parentOrNull(parentValue);
    final cached = await _cache.read(dropdownCode: code, parentValue: parent);
    if (cached != null) return cached;

    final body = <String, Object?>{'dropdown_code': code};
    if (parent != null) body['parent_value'] = parent;

    final response = await _transport.post(
      uri: _baseUrl.dropdownEndpoint,
      jsonBody: body,
      timeout: timeout,
    );
    final list = _readResponse(response);
    await _cache.write(list: list, parentValue: parent);
    return list;
  }

  DropdownList _readResponse(DropdownHttpResponse response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const DropdownTransportException(
        'The server response could not be read.',
      );
    }
    if (decoded is! Map) {
      throw const DropdownTransportException(
        'The server response could not be read.',
      );
    }

    final json = Map<String, dynamic>.from(decoded);
    final status = json['status'];
    final code = json['code'];
    final message = json['message'];
    if (status is! String ||
        code is! int ||
        message is! String ||
        !json.containsKey('data')) {
      throw const DropdownTransportException(
        'The server response could not be read.',
      );
    }

    if (status == 'SUCCESS' && code == 200) {
      final data = json['data'];
      if (data is! Map) {
        throw const DropdownTransportException(
          'The server response could not be read.',
        );
      }
      return DropdownList.fromData(Map<String, dynamic>.from(data));
    }

    if (status == 'ERROR') {
      throw DropdownApiException(message: message, code: code);
    }
    throw const DropdownTransportException(
      'The server response could not be read.',
    );
  }

  String? _parentOrNull(String? parentValue) {
    final parent = parentValue?.trim() ?? '';
    return parent.isEmpty ? null : parent;
  }
}
