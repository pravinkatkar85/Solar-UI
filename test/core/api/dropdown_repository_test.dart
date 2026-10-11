import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';

void main() {
  const baseUrl = 'http://10.0.2.2:3000';

  group('ApiBaseUrl', () {
    test('rejects a missing API base URL', () {
      expect(
        ApiBaseUrl.fromEnvironment,
        throwsA(isA<InvalidApiBaseUrlException>()),
      );
      expect(
        () => ApiBaseUrl.parse(''),
        throwsA(
          isA<InvalidApiBaseUrlException>().having(
            (error) => error.message,
            'message',
            contains('API_BASE_URL is not set'),
          ),
        ),
      );
    });

    test(
      'rejects an invalid API base URL without keeping embedded secrets',
      () {
        expect(
          () => ApiBaseUrl.parse('http://user:secret@localhost:3000'),
          throwsA(
            isA<InvalidApiBaseUrlException>().having(
              (error) => error.message,
              'message',
              isNot(contains('secret')),
            ),
          ),
        );
        expect(
          () => ApiBaseUrl.parse('ftp://localhost:3000'),
          throwsA(isA<InvalidApiBaseUrlException>()),
        );
      },
    );
  });

  group('DropdownRepository', () {
    late MemoryDropdownCacheStore cache;
    late _FakeTransport transport;
    late DropdownRepository repository;
    var now = DateTime.utc(2026, 10, 11);

    setUp(() {
      cache = MemoryDropdownCacheStore();
      transport = _FakeTransport();
      now = DateTime.utc(2026, 10, 11);
      repository = DropdownRepository(
        baseUrl: ApiBaseUrl.parse(baseUrl),
        transport: transport,
        cache: cache,
        clock: () => now,
      );
    });

    test('parses a successful dropdown response', () async {
      transport.response = _jsonResponse(
        statusCode: 200,
        status: 'SUCCESS',
        code: 200,
        message: 'Dropdown options loaded',
        data: {
          'dropdown_code': 'COUNTRIES',
          'cache_ttl_seconds': 3600,
          'options': [
            {'value': '1', 'label': 'India'},
          ],
        },
      );

      final list = await repository.load(dropdownCode: ' COUNTRIES ');

      expect(list.dropdownCode, 'COUNTRIES');
      expect(list.cacheTtlSeconds, 3600);
      expect(list.options.single.value, '1');
      expect(list.options.single.label, 'India');
      expect(transport.requests.single.uri.path, '/api/dropdowns');
      expect(transport.requests.single.jsonBody, {
        'dropdown_code': 'COUNTRIES',
      });
      expect(repository.timeout, const Duration(seconds: 15));
    });

    test('returns an empty option list', () async {
      transport.response = _jsonResponse(
        statusCode: 200,
        status: 'SUCCESS',
        code: 200,
        message: 'No dropdown options found',
        data: {
          'dropdown_code': 'AMC_PLANS',
          'cache_ttl_seconds': 60,
          'options': [],
        },
      );

      final list = await repository.load(dropdownCode: 'AMC_PLANS');

      expect(list.isEmpty, isTrue);
      expect(list.options, isEmpty);
    });

    test('surfaces an API error message and does not cache it', () async {
      transport.response = _jsonResponse(
        statusCode: 404,
        status: 'ERROR',
        code: 404,
        message: 'Dropdown was not found',
        data: null,
      );

      await expectLater(
        repository.load(dropdownCode: 'NOT_A_REAL_DROPDOWN'),
        throwsA(
          isA<DropdownApiException>()
              .having((error) => error.code, 'code', 404)
              .having(
                (error) => error.message,
                'message',
                'Dropdown was not found',
              ),
        ),
      );
      expect(cache.values, isEmpty);

      await expectLater(
        repository.load(dropdownCode: 'NOT_A_REAL_DROPDOWN'),
        throwsA(isA<DropdownApiException>()),
      );
      expect(transport.requests, hasLength(2));
    });

    test(
      'uses a safe message when the HTTP body is not the JSON contract',
      () async {
        transport.response = const DropdownHttpResponse(
          statusCode: 500,
          body: '<html>secret database host</html>',
        );

        await expectLater(
          repository.load(dropdownCode: 'COUNTRIES'),
          throwsA(
            isA<DropdownTransportException>().having(
              (error) => error.message,
              'message',
              isNot(contains('secret')),
            ),
          ),
        );
      },
    );

    test('rejects invalid JSON', () async {
      transport.response = const DropdownHttpResponse(
        statusCode: 200,
        body: '{"status":',
      );

      await expectLater(
        repository.load(dropdownCode: 'COUNTRIES'),
        throwsA(isA<DropdownTransportException>()),
      );
    });

    test('returns a cached success before the TTL expires', () async {
      transport.response = _countriesResponse();

      final first = await repository.load(dropdownCode: 'COUNTRIES');
      final second = await repository.load(dropdownCode: 'COUNTRIES');

      expect(second.options.single.label, first.options.single.label);
      expect(transport.requests, hasLength(1));
    });

    test('refreshes a cached success after the TTL expires', () async {
      transport.response = _countriesResponse(ttlSeconds: 60);

      await repository.load(dropdownCode: 'COUNTRIES');
      now = now.add(const Duration(seconds: 61));
      await repository.load(dropdownCode: 'COUNTRIES');

      expect(transport.requests, hasLength(2));
    });

    test('does not keep an empty result after its TTL', () async {
      transport.response = _jsonResponse(
        statusCode: 200,
        status: 'SUCCESS',
        code: 200,
        message: 'No dropdown options found',
        data: {
          'dropdown_code': 'AMC_PLANS',
          'cache_ttl_seconds': 30,
          'options': [],
        },
      );

      final cached = await repository.load(dropdownCode: 'AMC_PLANS');
      expect(cached.isEmpty, isTrue);
      await repository.load(dropdownCode: 'AMC_PLANS');
      expect(transport.requests, hasLength(1));

      now = now.add(const Duration(seconds: 31));
      await repository.load(dropdownCode: 'AMC_PLANS');
      expect(transport.requests, hasLength(2));
    });

    test('keeps separate cache entries for different parent values', () async {
      transport.response = _jsonResponse(
        statusCode: 200,
        status: 'SUCCESS',
        code: 200,
        message: 'Dropdown options loaded',
        data: {
          'dropdown_code': 'STATES',
          'cache_ttl_seconds': 3600,
          'options': [
            {'value': '27', 'label': 'Maharashtra'},
          ],
        },
      );

      await repository.load(dropdownCode: 'STATES', parentValue: '1');
      await repository.load(dropdownCode: 'STATES', parentValue: '2');
      await repository.load(dropdownCode: 'STATES', parentValue: '1');
      await repository.load(dropdownCode: 'STATES', parentValue: '2');

      expect(transport.requests, hasLength(2));
      expect(transport.requests[0].jsonBody['parent_value'], '1');
      expect(transport.requests[1].jsonBody['parent_value'], '2');
    });

    test('ignores a malformed cache entry and loads from the API', () async {
      transport.response = _countriesResponse();
      await cache.write(
        DropdownResultCache.cacheKey('COUNTRIES', null),
        '{not json',
      );

      final list = await repository.load(dropdownCode: 'COUNTRIES');

      expect(list.options, isNotEmpty);
      expect(transport.requests, hasLength(1));
    });
  });

  test('times out when the request exceeds the configured limit', () async {
    expect(HttpDropdownClient.defaultTimeout, const Duration(seconds: 15));
    expect(DropdownRepository.defaultTimeout, const Duration(seconds: 15));

    final pending = Completer<http.StreamedResponse>();
    addTearDown(() {
      if (!pending.isCompleted) {
        pending.complete(http.StreamedResponse(const Stream.empty(), 200));
      }
    });

    await expectLater(
      HttpDropdownClient(client: _PendingClient(pending)).post(
        uri: Uri.parse('http://127.0.0.1:3000/api/dropdowns'),
        jsonBody: const {'dropdown_code': 'COUNTRIES'},
        timeout: const Duration(milliseconds: 20),
      ),
      throwsA(isA<DropdownTimeoutException>()),
    );
  });
}

DropdownHttpResponse _countriesResponse({int ttlSeconds = 3600}) {
  return _jsonResponse(
    statusCode: 200,
    status: 'SUCCESS',
    code: 200,
    message: 'Dropdown options loaded',
    data: {
      'dropdown_code': 'COUNTRIES',
      'cache_ttl_seconds': ttlSeconds,
      'options': [
        {'value': '1', 'label': 'India'},
      ],
    },
  );
}

DropdownHttpResponse _jsonResponse({
  required int statusCode,
  required String status,
  required int code,
  required String message,
  required Object? data,
}) {
  return DropdownHttpResponse(
    statusCode: statusCode,
    body:
        '{"status":"$status","code":$code,"message":"$message","data":${data == null ? 'null' : _encodeData(data)}}',
  );
}

String _encodeData(Object data) {
  if (data is Map<String, Object?> && data['options'] is List) {
    final options = data['options']! as List;
    final encodedOptions = options
        .map((option) {
          final values = option as Map;
          return '{"value":"${values['value']}","label":"${values['label']}"}';
        })
        .join(',');
    return '{"dropdown_code":"${data['dropdown_code']}","cache_ttl_seconds":${data['cache_ttl_seconds']},"options":[$encodedOptions]}';
  }
  return 'null';
}

class _FakeTransport implements DropdownTransport {
  final List<_RecordedRequest> requests = [];
  DropdownHttpResponse response = const DropdownHttpResponse(
    statusCode: 500,
    body: '',
  );

  @override
  Future<DropdownHttpResponse> post({
    required Uri uri,
    required Map<String, Object?> jsonBody,
    required Duration timeout,
  }) async {
    requests.add(_RecordedRequest(uri, jsonBody, timeout));
    return response;
  }
}

class _RecordedRequest {
  const _RecordedRequest(this.uri, this.jsonBody, this.timeout);

  final Uri uri;
  final Map<String, Object?> jsonBody;
  final Duration timeout;
}

class _PendingClient extends http.BaseClient {
  _PendingClient(this._pending);

  final Completer<http.StreamedResponse> _pending;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _pending.future;
}
