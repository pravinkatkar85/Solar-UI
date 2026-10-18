import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/auth/auth_api.dart';
import 'package:solar_ui/features/auth/presentation/login_screen.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_shell.dart';
import 'package:solar_ui/features/startup/presentation/splash_screen.dart';

void main() {
  late _MemoryThemeStore store;
  late ThemeController themeController;
  late _FakeAuthApi auth;

  setUp(() {
    store = _MemoryThemeStore();
    themeController = ThemeController(store);
    auth = _FakeAuthApi();
  });

  testWidgets('invalid PIN stays on sign-in and never opens the dashboard', (
    WidgetTester tester,
  ) async {
    await _showLogin(tester, auth, themeController);

    await tester.enterText(find.byKey(const Key('login-mobile')), '9876543210');
    await tester.enterText(find.byKey(const Key('login-pin')), '0000');
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(auth.loginCalls, 1);
    expect(find.text('The mobile number or PIN is incorrect'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(DashboardShell), findsNothing);
  });

  testWidgets('a successful login shows the API name after the splash', (
    WidgetTester tester,
  ) async {
    auth.loginResult = const AuthResult.success(
      user: SignedInUser(
        userId: '7',
        fullName: 'Asha Nair',
        roleName: 'End Customer',
        accessToken: 'test-token',
      ),
    );

    await _showLogin(tester, auth, themeController);
    await tester.enterText(find.byKey(const Key('login-mobile')), '9876543210');
    await tester.enterText(find.byKey(const Key('login-pin')), '1234');
    await _tapSubmit(tester);

    expect(auth.loginCalls, 1);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(DashboardShell), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardShell), findsOneWidget);
    expect(find.textContaining('Asha'), findsWidgets);
    expect(find.text('End Customer'), findsNothing);
    expect(find.textContaining('Rahul'), findsNothing);
  });

  testWidgets('creating an account returns to sign-in', (
    WidgetTester tester,
  ) async {
    await _showLogin(tester, auth, themeController);

    await tester.tap(find.byKey(const Key('login-mode')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('register-name')), 'Asha Nair');
    await tester.enterText(find.byKey(const Key('login-mobile')), '9876543210');
    await tester.enterText(find.byKey(const Key('login-pin')), '1234');
    await tester.enterText(
      find.byKey(const Key('register-confirm-pin')),
      '9999',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(auth.registerCalls, 0);
    expect(find.text('PIN entries do not match'), findsOneWidget);
    expect(find.byType(DashboardShell), findsNothing);

    await tester.enterText(
      find.byKey(const Key('register-confirm-pin')),
      '1234',
    );
    await _tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(auth.registerCalls, 1);
    expect(auth.loginCalls, 0);
    expect(
      find.text('Account created. Sign in with your mobile number and PIN.'),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byType(DashboardShell), findsNothing);
    expect(find.byType(SplashScreen), findsNothing);
  });
}

Future<void> _showLogin(
  WidgetTester tester,
  _FakeAuthApi auth,
  ThemeController themeController,
) async {
  await tester.binding.setSurfaceSize(const Size(500, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_app(auth, themeController));
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.byKey(const Key('login-submit'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
  await tester.pump();
}

Widget _app(_FakeAuthApi auth, ThemeController themeController) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: LoginScreen(
      authApi: auth,
      countries: _countries(),
      themeController: themeController,
      postLoginDelay: const Duration(milliseconds: 100),
    ),
  );
}

DropdownRepository _countries() {
  final transport = _ScriptedTransport()
    ..respond('COUNTRIES', options: const [_Option('1', 'India')]);
  return DropdownRepository(
    baseUrl: ApiBaseUrl.parse('http://localhost:3000'),
    transport: transport,
    cache: MemoryDropdownCacheStore(),
  );
}

class _FakeAuthApi implements AuthApi {
  AuthResult loginResult = const AuthResult.failure(
    'The mobile number or PIN is incorrect',
  );
  int loginCalls = 0;
  int registerCalls = 0;

  @override
  Future<AuthResult> login({
    required String countryId,
    required String nationalNumber,
    required String pin,
  }) async {
    loginCalls += 1;
    return loginResult;
  }

  @override
  Future<AuthResult> register({
    required String countryId,
    required String nationalNumber,
    required String fullName,
    required String pin,
  }) async {
    registerCalls += 1;
    return const AuthResult.success(message: 'Account created');
  }

  @override
  void close() {}

  @override
  Future<AuthResult> changePin({
    required String accessToken,
    required String oldPin,
    required String newPin,
    required String confirmPin,
  }) async {
    return const AuthResult.failure('PIN could not be updated.');
  }
}

class _MemoryThemeStore implements ThemePreferenceStore {
  String? value;

  @override
  Future<String?> readThemePreference() async => value;

  @override
  Future<void> writeThemePreference(String value) async {
    this.value = value;
  }
}

class _Option {
  const _Option(this.value, this.label);

  final String value;
  final String label;
}

class _ScriptedTransport implements DropdownTransport {
  final Map<String, DropdownHttpResponse> _responses = {};

  void respond(
    String dropdownCode, {
    String parentValue = '',
    required List<_Option> options,
  }) {
    _responses['$dropdownCode|$parentValue'] = DropdownHttpResponse(
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

  @override
  Future<DropdownHttpResponse> post({
    required Uri uri,
    required Map<String, Object?> jsonBody,
    required Duration timeout,
  }) async {
    final parent = jsonBody['parent_value'] ?? '';
    final response = _responses['${jsonBody['dropdown_code']}|$parent'];
    if (response == null) {
      throw StateError('No dropdown script');
    }
    return response;
  }
}
