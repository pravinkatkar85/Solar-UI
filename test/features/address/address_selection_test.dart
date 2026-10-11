import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/address/presentation/address_selection_controller.dart';
import 'package:solar_ui/features/address/presentation/address_selection_screen.dart';

void main() {
  group('AddressSelectionController', () {
    late _ScriptedTransport transport;
    late AddressSelectionController controller;

    setUp(() {
      transport = _ScriptedTransport();
      controller = AddressSelectionController(
        repository: _repository(transport),
      );
    });

    tearDown(() => controller.dispose());

    test('loads countries first and children only after each parent', () async {
      transport.respond('COUNTRIES', options: const [_Option('10', 'India')]);
      transport.respond(
        'STATES',
        parentValue: '10',
        options: const [_Option('20', 'Maharashtra')],
      );
      transport.respond(
        'DISTRICTS',
        parentValue: '20',
        options: const [_Option('30', 'Pune')],
      );
      transport.respond(
        'CITIES',
        parentValue: '30',
        options: const [_Option('40', 'Pune City')],
      );
      transport.respond(
        'PINCODES',
        parentValue: '40',
        options: const [_Option('50', '411001')],
      );

      await controller.loadInitial();

      expect(transport.requests, [
        {'dropdown_code': 'COUNTRIES'},
      ]);
      expect(controller.fields[1].options, isEmpty);
      expect(controller.fields[1].loading, isFalse);

      await controller.select(0, '10');
      expect(transport.requests.last, {
        'dropdown_code': 'STATES',
        'parent_value': '10',
      });
      expect(
        transport.requests.where(
          (body) => body['dropdown_code'] == 'DISTRICTS',
        ),
        isEmpty,
      );

      await controller.select(1, '20');
      await controller.select(2, '30');
      await controller.select(3, '40');

      expect(transport.requests.map((body) => body['dropdown_code']), [
        'COUNTRIES',
        'STATES',
        'DISTRICTS',
        'CITIES',
        'PINCODES',
      ]);
      expect(transport.requests[2]['parent_value'], '20');
      expect(transport.requests[3]['parent_value'], '30');
      expect(transport.requests[4]['parent_value'], '40');
      expect(controller.fields[4].selected, isNull);
      expect(controller.fields[4].options.single.label, '411001');
    });

    test(
      'changing a parent clears every dependent selection and options',
      () async {
        transport.respond(
          'COUNTRIES',
          options: const [_Option('10', 'India'), _Option('11', 'Nepal')],
        );
        transport.respond(
          'STATES',
          parentValue: '10',
          options: const [_Option('20', 'Maharashtra')],
        );
        transport.respond(
          'STATES',
          parentValue: '11',
          options: const [_Option('21', 'Bagmati')],
        );
        transport.respond(
          'DISTRICTS',
          parentValue: '20',
          options: const [_Option('30', 'Pune')],
        );

        await controller.loadInitial();
        await controller.select(0, '10');
        await controller.select(1, '20');
        expect(controller.fields[2].options.single.label, 'Pune');

        await controller.select(0, '11');

        expect(controller.fields[0].selected?.label, 'Nepal');
        expect(controller.fields[1].selected, isNull);
        expect(controller.fields[1].options.single.label, 'Bagmati');
        expect(controller.fields[2].selected, isNull);
        expect(controller.fields[2].options, isEmpty);
        expect(controller.fields[2].loading, isFalse);
        expect(controller.fields[3].options, isEmpty);
        expect(controller.fields[4].options, isEmpty);
        expect(
          transport.requests.where(
            (body) =>
                body['dropdown_code'] == 'DISTRICTS' &&
                body['parent_value'] == '21',
          ),
          isEmpty,
        );
      },
    );

    test('ignores a stale child response after the parent changes', () async {
      transport.respond(
        'COUNTRIES',
        options: const [_Option('10', 'India'), _Option('11', 'Nepal')],
      );
      final firstStates = Completer<DropdownHttpResponse>();
      final secondStates = Completer<DropdownHttpResponse>();
      transport.handle('STATES', '10', () => firstStates.future);
      transport.handle('STATES', '11', () => secondStates.future);

      await controller.loadInitial();
      final firstSelection = controller.select(0, '10');
      await Future<void>.delayed(Duration.zero);
      final secondSelection = controller.select(0, '11');
      firstStates.complete(
        _success('STATES', const [_Option('20', 'Maharashtra')]),
      );
      secondStates.complete(
        _success('STATES', const [_Option('21', 'Bagmati')]),
      );
      await Future.wait([firstSelection, secondSelection]);

      expect(controller.fields[0].selected?.value, '11');
      expect(controller.fields[1].options.single.label, 'Bagmati');
      expect(controller.fields[2].options, isEmpty);
    });

    test('shows an API error and retries the same dropdown', () async {
      transport.handle(
        'COUNTRIES',
        '',
        () async => throw const DropdownTimeoutException(
          'The request timed out. Try again.',
        ),
      );

      await controller.loadInitial();
      expect(controller.fields[0].loading, isFalse);
      expect(controller.fields[0].options, isEmpty);
      expect(
        controller.fields[0].errorMessage,
        'The request timed out. Try again.',
      );

      transport.respond('COUNTRIES', options: const [_Option('10', 'India')]);
      await controller.retry(0);

      expect(controller.fields[0].errorMessage, isNull);
      expect(controller.fields[0].options.single.label, 'India');
      expect(
        transport.requests.where(
          (body) => body['dropdown_code'] == 'COUNTRIES',
        ),
        hasLength(2),
      );
    });

    test('keeps an empty success as an empty list', () async {
      transport.respond('COUNTRIES', options: const [_Option('10', 'India')]);
      transport.respond('STATES', parentValue: '10', options: const []);

      await controller.loadInitial();
      await controller.select(0, '10');

      expect(controller.fields[1].loading, isFalse);
      expect(controller.fields[1].errorMessage, isNull);
      expect(controller.fields[1].options, isEmpty);
      expect(controller.fields[2].options, isEmpty);
    });
  });

  group('AddressSelectionScreen', () {
    testWidgets('shows loading, then countries, with children waiting', (
      tester,
    ) async {
      final transport = _ScriptedTransport();
      final countries = Completer<DropdownHttpResponse>();
      transport.handle('COUNTRIES', '', () => countries.future);

      await tester.pumpWidget(_app(_repository(transport)));
      expect(find.text('Loading country'), findsOneWidget);
      expect(find.text('Select state first.'), findsOneWidget);
      expect(find.text('Select district first.'), findsOneWidget);

      countries.complete(_success('COUNTRIES', const [_Option('10', 'India')]));
      await tester.pump();

      expect(find.text('Loading country'), findsNothing);
      expect(find.text('India'), findsNothing);
      await tester.tap(find.byKey(const Key('address-dropdown-COUNTRIES')));
      await tester.pumpAndSettle();
      expect(find.text('India'), findsOneWidget);

      final dropdowns = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdowns.first.onChanged, isNotNull);
      expect(dropdowns.elementAt(1).onChanged, isNull);
      expect(dropdowns.last.onChanged, isNull);
    });

    testWidgets('shows an error and loads after retry', (tester) async {
      final transport = _ScriptedTransport();
      var attempts = 0;
      transport.handle('COUNTRIES', '', () async {
        attempts++;
        if (attempts == 1) {
          return _error(message: 'Dropdown options could not be loaded');
        }
        return _success('COUNTRIES', const [_Option('10', 'India')]);
      });

      await tester.pumpWidget(_app(_repository(transport)));
      await tester.pump();

      expect(find.text('Dropdown options could not be loaded'), findsOneWidget);
      await tester.tap(find.byKey(const Key('address-retry-COUNTRIES')));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('address-dropdown-COUNTRIES')));
      await tester.pumpAndSettle();
      expect(find.text('India'), findsOneWidget);
      expect(find.text('Dropdown options could not be loaded'), findsNothing);
    });

    testWidgets(
      'shows an empty child list and clears it when the parent changes',
      (tester) async {
        final transport = _ScriptedTransport();
        transport.respond(
          'COUNTRIES',
          options: const [_Option('10', 'India'), _Option('11', 'Nepal')],
        );
        transport.respond(
          'STATES',
          parentValue: '10',
          options: const [_Option('20', 'Maharashtra')],
        );
        transport.respond('STATES', parentValue: '11', options: const []);

        await tester.pumpWidget(_app(_repository(transport)));
        await tester.pump();
        await _choose(tester, 'COUNTRIES', 'India');

        await tester.tap(find.byKey(const Key('address-dropdown-STATES')));
        await tester.pumpAndSettle();
        expect(find.text('Maharashtra'), findsOneWidget);
        Navigator.of(tester.element(find.byType(AddressSelectionScreen))).pop();
        await tester.pumpAndSettle();

        expect(find.text('Select district first.'), findsOneWidget);

        await _choose(tester, 'COUNTRIES', 'Nepal');

        expect(find.text('Maharashtra'), findsNothing);
        expect(find.text('No options are available.'), findsOneWidget);
        expect(find.text('Select district first.'), findsOneWidget);
      },
    );
  });
}

Future<void> _choose(WidgetTester tester, String code, String label) async {
  await tester.tap(find.byKey(Key('address-dropdown-$code')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pump();
  await tester.pump();
}

Widget _app(DropdownRepository repository) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: AddressSelectionScreen(repository: repository)),
  );
}

DropdownRepository _repository(_ScriptedTransport transport) {
  return DropdownRepository(
    baseUrl: ApiBaseUrl.parse('http://localhost:3000'),
    transport: transport,
    cache: MemoryDropdownCacheStore(),
  );
}

class _Option {
  const _Option(this.value, this.label);

  final String value;
  final String label;
}

class _ScriptedTransport implements DropdownTransport {
  final List<Map<String, Object?>> requests = [];
  final Map<String, Future<DropdownHttpResponse> Function()> _handlers = {};

  void respond(
    String dropdownCode, {
    String parentValue = '',
    required List<_Option> options,
  }) {
    handle(
      dropdownCode,
      parentValue,
      () async => _success(dropdownCode, options),
    );
  }

  void handle(
    String dropdownCode,
    String parentValue,
    Future<DropdownHttpResponse> Function() response,
  ) {
    _handlers['$dropdownCode|$parentValue'] = response;
  }

  @override
  Future<DropdownHttpResponse> post({
    required Uri uri,
    required Map<String, Object?> jsonBody,
    required Duration timeout,
  }) async {
    requests.add(Map<String, Object?>.from(jsonBody));
    final parent = jsonBody['parent_value'] ?? '';
    final key = '${jsonBody['dropdown_code']}|$parent';
    final handler = _handlers[key];
    if (handler == null) {
      throw StateError('No dropdown script for $key');
    }
    return handler();
  }
}

DropdownHttpResponse _success(String dropdownCode, List<_Option> options) {
  return DropdownHttpResponse(
    statusCode: 200,
    body: jsonEncode({
      'status': 'SUCCESS',
      'code': 200,
      'message': 'Dropdown options loaded',
      'data': {
        'dropdown_code': dropdownCode,
        'cache_ttl_seconds': 3600,
        'options': [
          for (final option in options)
            {'value': option.value, 'label': option.label},
        ],
      },
    }),
  );
}

DropdownHttpResponse _error({required String message}) {
  return DropdownHttpResponse(
    statusCode: 500,
    body: jsonEncode({
      'status': 'ERROR',
      'code': 500,
      'message': message,
      'data': null,
    }),
  );
}
