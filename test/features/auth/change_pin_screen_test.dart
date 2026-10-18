import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/auth/auth_api.dart';
import 'package:solar_ui/features/auth/presentation/change_pin_screen.dart';

void main() {
  testWidgets('requires all PIN fields before calling the API', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthApi();
    await _show(tester, auth);

    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pump();

    expect(auth.calls, isEmpty);
    expect(
      find.text('Enter your current PIN, a new PIN, and the confirmation.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects a PIN that is not 4 digits', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthApi();
    await _show(tester, auth);
    await tester.enterText(find.byKey(const Key('change-old-pin')), '1357');
    await tester.enterText(find.byKey(const Key('change-new-pin')), '12');
    await tester.enterText(find.byKey(const Key('change-confirm-pin')), '12');
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pump();

    expect(auth.calls, isEmpty);
    expect(find.text('PIN must be 4 digits'), findsOneWidget);
  });

  testWidgets('rejects a confirmation mismatch before calling the API', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthApi();
    await _show(tester, auth);
    await _enterPins(tester, confirm: '2469');
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pump();

    expect(auth.calls, isEmpty);
    expect(find.text('PIN entries do not match'), findsOneWidget);
  });

  testWidgets('shows a loading state and ignores a second tap', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthApi()..gate = Completer<AuthResult>();
    await _show(tester, auth);
    await _enterPins(tester);
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pump();
    expect(auth.calls, hasLength(1));

    auth.gate!.complete(const AuthResult.success(message: 'PIN updated'));
    await tester.pumpAndSettle();
    expect(find.text('PIN updated'), findsOneWidget);
  });

  testWidgets('shows success and clears the PIN fields', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthApi();
    await _show(tester, auth);
    await _enterPins(tester);
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pumpAndSettle();

    expect(auth.calls, [
      {
        'accessToken': 'session-token',
        'oldPin': '1357',
        'newPin': '2468',
        'confirmPin': '2468',
      },
    ]);
    expect(find.text('PIN updated'), findsOneWidget);
    expect(_fieldText(tester, 'change-old-pin'), isEmpty);
    expect(_fieldText(tester, 'change-new-pin'), isEmpty);
    expect(_fieldText(tester, 'change-confirm-pin'), isEmpty);
  });

  testWidgets('shows an API error and keeps the form', (
    WidgetTester tester,
  ) async {
    final auth = _FakeAuthApi()
      ..result = const AuthResult.failure('The current PIN is incorrect');
    await _show(tester, auth);
    await _enterPins(tester);
    await tester.tap(find.byKey(const Key('change-submit')));
    await tester.pumpAndSettle();

    expect(find.text('The current PIN is incorrect'), findsOneWidget);
    expect(_fieldText(tester, 'change-old-pin'), '1357');
  });
}

String _fieldText(WidgetTester tester, String key) {
  final field = tester.widget<TextField>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
  );
  return field.controller?.text ?? '';
}

Future<void> _show(WidgetTester tester, _FakeAuthApi auth) async {
  await tester.binding.setSurfaceSize(const Size(500, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: ChangePinScreen(authApi: auth, accessToken: 'session-token'),
    ),
  );
}

Future<void> _enterPins(WidgetTester tester, {String confirm = '2468'}) async {
  await tester.enterText(find.byKey(const Key('change-old-pin')), '1357');
  await tester.enterText(find.byKey(const Key('change-new-pin')), '2468');
  await tester.enterText(find.byKey(const Key('change-confirm-pin')), confirm);
}

class _FakeAuthApi implements AuthApi {
  AuthResult result = const AuthResult.success(message: 'PIN updated');
  Completer<AuthResult>? gate;
  final List<Map<String, String>> calls = [];

  @override
  Future<AuthResult> changePin({
    required String accessToken,
    required String oldPin,
    required String newPin,
    required String confirmPin,
  }) {
    calls.add({
      'accessToken': accessToken,
      'oldPin': oldPin,
      'newPin': newPin,
      'confirmPin': confirmPin,
    });
    return gate?.future ?? Future<AuthResult>.value(result);
  }

  @override
  Future<AuthResult> login({
    required String countryId,
    required String nationalNumber,
    required String pin,
  }) async {
    return const AuthResult.failure('Not used');
  }

  @override
  Future<AuthResult> register({
    required String countryId,
    required String nationalNumber,
    required String fullName,
    required String pin,
  }) async {
    return const AuthResult.failure('Not used');
  }

  @override
  void close() {}
}
