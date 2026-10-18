import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ui/app/app_launch.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/auth/auth_api.dart';
import 'package:solar_ui/features/auth/presentation/login_screen.dart';
import 'package:solar_ui/features/auth/session_controller.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_shell.dart';

void main() {
  test('expired and unreadable tokens are treated as signed out', () {
    final now = DateTime.utc(2026, 10, 18, 12);
    final future =
        now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final past =
        now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000;

    expect(sessionTokenExpired(_jwt(future), now: now), isFalse);
    expect(sessionTokenExpired(_jwt(past), now: now), isTrue);
    expect(sessionTokenExpired('missing', now: now), isTrue);
  });

  testWidgets('guest launch opens the dashboard with products and Sign In', (
    WidgetTester tester,
  ) async {
    final catalogue = _FakeCatalogueApi();
    final harness = _Harness(catalogue: catalogue);

    await harness.pump(tester);
    await harness.finishSplash(tester);

    expect(find.byType(DashboardShell), findsOneWidget);
    expect(find.textContaining('Guest'), findsWidgets);
    expect(find.byKey(const Key('sign-in')), findsNothing);
    await tester.tap(find.byKey(const Key('profile-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-sign-in')), findsOneWidget);
    expect(find.text('My Account'), findsNothing);
    expect(find.text('Rooftop 3kW'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('a valid saved session opens the dashboard without a PIN', (
    WidgetTester tester,
  ) async {
    final harness = _Harness(catalogue: _FakeCatalogueApi());
    final exp =
        DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch ~/
        1000;
    harness.store.saved = StoredSession(
      accessToken: _jwt(exp),
      displayName: 'Asha Nair',
      roleName: 'End Customer',
    );

    await harness.pump(tester);
    await harness.finishSplash(tester);

    expect(find.textContaining('Asha'), findsWidgets);
    expect(find.text('End Customer'), findsNothing);
    expect(find.byKey(const Key('sign-in')), findsNothing);
    expect(find.byKey(const Key('login-pin')), findsNothing);

    await tester.tap(find.byKey(const Key('profile-menu')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-sign-out')));
    await tester.tap(find.byKey(const Key('profile-sign-out')));
    await tester.pumpAndSettle();

    expect(harness.session.accessToken, isNull);
    expect(harness.store.saved, isNull);
    expect(find.textContaining('Guest'), findsWidgets);
    expect(find.textContaining('Asha'), findsNothing);
    await tester.tap(find.byKey(const Key('profile-menu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-sign-in')), findsOneWidget);
    expect(find.text('Change PIN'), findsNothing);
  });

  testWidgets('an expired saved session opens the guest dashboard', (
    WidgetTester tester,
  ) async {
    final harness = _Harness(catalogue: _FakeCatalogueApi());
    final exp =
        DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch ~/
        1000;
    harness.store.saved = StoredSession(
      accessToken: _jwt(exp),
      displayName: 'Asha Nair',
      roleName: 'End Customer',
    );

    await harness.pump(tester);
    await harness.finishSplash(tester);

    expect(find.textContaining('Guest'), findsWidgets);
    expect(find.byKey(const Key('sign-in')), findsNothing);
    expect(find.textContaining('Asha'), findsNothing);
    expect(harness.store.saved, isNull);
  });

  testWidgets('a missing session opens the guest dashboard', (
    WidgetTester tester,
  ) async {
    final harness = _Harness(catalogue: _FakeCatalogueApi());

    await harness.pump(tester);
    await harness.finishSplash(tester);

    expect(harness.session.accessToken, isNull);
    expect(find.byKey(const Key('sign-in')), findsNothing);
    expect(find.text('Rooftop 3kW'), findsOneWidget);
  });

  testWidgets('published product details open without signing in', (
    WidgetTester tester,
  ) async {
    final catalogue = _FakeCatalogueApi();
    final harness = _Harness(catalogue: catalogue);

    await harness.pump(tester);
    await harness.finishSplash(tester);
    await tester.ensureVisible(find.byKey(const Key('product-3')));
    await tester.tap(find.byKey(const Key('product-3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-description')), findsOneWidget);
    expect(find.text('PHOTO: Roof view'), findsOneWidget);
    expect(catalogue.detailCalls, ['3']);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('a guest enquiry opens sign-in and returns to the product', (
    WidgetTester tester,
  ) async {
    final catalogue = _FakeCatalogueApi();
    final harness = _Harness(catalogue: catalogue);
    final exp =
        DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch ~/
        1000;
    harness.auth.loginResult = AuthResult.success(
      user: SignedInUser(
        userId: '7',
        fullName: 'Asha Nair',
        roleName: 'End Customer',
        accessToken: _jwt(exp),
      ),
    );

    await harness.pump(tester);
    await harness.finishSplash(tester);
    await tester.ensureVisible(find.byKey(const Key('product-3')));
    await tester.tap(find.byKey(const Key('product-3')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('enquiry-sign-in')));
    await tester.tap(find.byKey(const Key('enquiry-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byKey(const Key('browse-catalogue')), findsNothing);

    await tester.enterText(find.byKey(const Key('login-mobile')), '9876543210');
    await tester.enterText(find.byKey(const Key('login-pin')), '1234');
    final submit = find.byKey(const Key('login-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byKey(const Key('enquiry-message')), findsOneWidget);
    expect(find.byKey(const Key('product-description')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('enquiry-message')),
      'Need a rooftop quote',
    );
    await tester.ensureVisible(find.byKey(const Key('enquiry-submit')));
    await tester.tap(find.byKey(const Key('enquiry-submit')));
    await tester.pumpAndSettle();

    expect(
      catalogue.enquiryCalls.single['accessToken'],
      harness.auth.loginResult.user!.accessToken,
    );
    expect(catalogue.enquiryCalls.single['productId'], '3');
    expect(catalogue.enquiryCalls.single.containsKey('userId'), isFalse);
  });
}

String _jwt(int expSeconds) {
  String encode(Object value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return '${encode({'alg': 'none'})}.${encode({'exp': expSeconds})}.sig';
}

class _Harness {
  _Harness({required this.catalogue})
    : store = _MemorySessionStore(),
      auth = _FakeAuthApi() {
    session = SessionController(store);
    themeController = ThemeController(_MemoryThemeStore());
  }

  final _FakeCatalogueApi catalogue;
  final _MemorySessionStore store;
  final _FakeAuthApi auth;
  late final SessionController session;
  late final ThemeController themeController;

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => SessionScope(
          controller: session,
          child: child ?? const SizedBox.shrink(),
        ),
        home: AppLaunch(
          session: session,
          authApi: auth,
          catalogueApi: catalogue,
          countries: _countries(),
          themeController: themeController,
          launchDuration: const Duration(milliseconds: 100),
          postLoginDelay: const Duration(milliseconds: 100),
        ),
      ),
    );
  }

  Future<void> finishSplash(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
  }
}

class _MemorySessionStore implements SessionStore {
  StoredSession? saved;

  @override
  Future<void> clear() async {
    saved = null;
  }

  @override
  Future<StoredSession?> read() async => saved;

  @override
  Future<void> write(StoredSession session) async {
    saved = session;
  }
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

  @override
  Future<AuthResult> changePin({
    required String accessToken,
    required String oldPin,
    required String newPin,
    required String confirmPin,
  }) async {
    return const AuthResult.failure('PIN could not be updated.');
  }

  @override
  void close() {}

  @override
  Future<AuthResult> login({
    required String countryId,
    required String nationalNumber,
    required String pin,
  }) async {
    return loginResult;
  }

  @override
  Future<AuthResult> register({
    required String countryId,
    required String nationalNumber,
    required String fullName,
    required String pin,
  }) async {
    return const AuthResult.success(message: 'Account created');
  }
}

class _FakeCatalogueApi implements CatalogueApi {
  final List<String> detailCalls = [];
  final List<Map<String, String>> enquiryCalls = [];

  @override
  void close() {}

  @override
  String? get mediaBaseUrl => null;

  @override
  Future<CatalogueResult> createEnquiry({
    required String accessToken,
    required String productId,
    required String messageText,
    String? preferredContactWindow,
  }) async {
    enquiryCalls.add({
      'accessToken': accessToken,
      'productId': productId,
      'messageText': messageText,
    });
    return const CatalogueResult.enquiry('ENQ-00000015');
  }

  @override
  Future<CatalogueResult> listEnquiries({required String accessToken}) async {
    return const CatalogueResult.success(enquiries: []);
  }

  @override
  Future<CatalogueResult> updateEnquiry({
    required String accessToken,
    required String productEnquiryId,
    required String action,
    String? note,
  }) async {
    return const CatalogueResult.success(message: 'Enquiry updated');
  }

  @override
  Future<CatalogueResult> listProducts() async {
    return const CatalogueResult.success(
      products: [
        CatalogueProduct(
          productId: '3',
          productName: 'Rooftop 3kW',
          listPrice: '45000.00',
          currencyCode: 'INR',
          shortDescription: 'Published system',
        ),
      ],
    );
  }

  @override
  Future<CatalogueResult> productDetail(String productId) async {
    detailCalls.add(productId);
    return const CatalogueResult.success(
      product: CatalogueProduct(
        productId: '3',
        productName: 'Rooftop 3kW',
        listPrice: '45000.00',
        currencyCode: 'INR',
        longDescription: 'Grid-tied system',
        media: [
          CatalogueMedia(
            mediaType: 'PHOTO',
            fileUrl: 'assets/branding/pournima_wordmark.jpeg',
            caption: 'Roof view',
          ),
        ],
      ),
    );
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
    return response ??
        const DropdownHttpResponse(statusCode: 500, body: '{"status":"ERROR"}');
  }
}
