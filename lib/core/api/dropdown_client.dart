import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solar_ui/core/api/dropdown_exceptions.dart';

class DropdownHttpResponse {
  const DropdownHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// Sends the dropdown POST. Tests can substitute their own implementation.
abstract interface class DropdownTransport {
  Future<DropdownHttpResponse> post({
    required Uri uri,
    required Map<String, Object?> jsonBody,
    required Duration timeout,
  });
}

class HttpDropdownClient implements DropdownTransport {
  HttpDropdownClient({http.Client? client}) : _client = client ?? http.Client();

  static const defaultTimeout = Duration(seconds: 15);

  final http.Client _client;

  @override
  Future<DropdownHttpResponse> post({
    required Uri uri,
    required Map<String, Object?> jsonBody,
    required Duration timeout,
  }) async {
    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(jsonBody),
          )
          .timeout(timeout);
      return DropdownHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
    } on TimeoutException {
      throw const DropdownTimeoutException();
    } on DropdownTimeoutException {
      rethrow;
    } on Object {
      throw const DropdownTransportException();
    }
  }

  void close() => _client.close();
}
