import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ui/app/solar_app.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_shell.dart';
import 'package:solar_ui/features/startup/presentation/splash_screen.dart';

void main() {
  late _MemoryThemeStore store;
  late ThemeController themeController;

  setUp(() {
    store = _MemoryThemeStore();
    themeController = ThemeController(store);
  });

  testWidgets('shows the local splash then opens the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      SolarApp(
        themeController: themeController,
        startupDuration: const Duration(milliseconds: 100),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Solar'), findsOneWidget);
    expect(find.text('Solar Service Management'), findsOneWidget);
    expect(find.text('Preparing your workspace'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 110));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(DashboardShell), findsOneWidget);
    expect(find.textContaining('Rahul'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
  });

  testWidgets('dashboard renders BRD modules at compact width', (
    WidgetTester tester,
  ) async {
    await _pumpDashboard(tester, themeController, const Size(390, 844));

    expect(find.text('Quick access'), findsOneWidget);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Sites & installations'), findsOneWidget);
    expect(find.text('Service requests'), findsOneWidget);
    expect(find.text('Complaints'), findsOneWidget);
    expect(find.text('Site visits'), findsOneWidget);
    expect(find.text('Technicians'), findsOneWidget);
    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Billing register'), findsOneWidget);
    expect(find.text('No live workspace data yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unimplemented action explains its placeholder status', (
    WidgetTester tester,
  ) async {
    await _pumpDashboard(tester, themeController, const Size(390, 844));

    await tester.ensureVisible(find.text('Billing register'));
    await tester.tap(find.text('Billing register'));
    await tester.pumpAndSettle();

    expect(find.text('Billing register is coming soon'), findsOneWidget);
    expect(find.textContaining('not a payment gateway'), findsOneWidget);
    expect(find.textContaining('No business operation'), findsOneWidget);
  });

  testWidgets('bottom navigation shows explicit coming-soon destinations', (
    WidgetTester tester,
  ) async {
    await _pumpDashboard(tester, themeController, const Size(390, 844));

    await tester.tap(find.text('Services').last);
    await tester.pump();

    expect(find.text('Services is coming soon'), findsOneWidget);
    expect(
      find.text('No API call or business operation is connected.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(find.text('Quick access'), findsOneWidget);
  });

  testWidgets('theme selector applies and persists all appearance modes', (
    WidgetTester tester,
  ) async {
    await _pumpDashboard(tester, themeController, const Size(900, 900));

    await tester.tap(find.byKey(const Key('theme-selector')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final dashboardContext = tester.element(find.byType(DashboardShell));
    expect(themeController.themeMode, ThemeMode.dark);
    expect(Theme.of(dashboardContext).brightness, Brightness.dark);
    expect(store.value, ThemeMode.dark.name);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('theme-selector')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(themeController.themeMode, ThemeMode.light);
    expect(store.value, ThemeMode.light.name);

    await tester.tap(find.byKey(const Key('theme-selector')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    expect(themeController.themeMode, ThemeMode.system);
    expect(store.value, ThemeMode.system.name);
  });

  testWidgets('dashboard renders without layout errors at browser width', (
    WidgetTester tester,
  ) async {
    await _pumpDashboard(tester, themeController, const Size(1180, 900));

    expect(
      find.text('Your solar service\nworkspace, in one place.'),
      findsOneWidget,
    );
    expect(find.text('My workspace'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('loads a persisted theme and falls back safely', () async {
    store.value = ThemeMode.light.name;
    await themeController.load();
    expect(themeController.themeMode, ThemeMode.light);

    final invalidStore = _MemoryThemeStore()..value = 'unsupported';
    final invalidController = ThemeController(invalidStore);
    await invalidController.load();
    expect(invalidController.themeMode, ThemeMode.system);
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  ThemeController themeController,
  Size size,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    SolarApp(themeController: themeController, startupDuration: Duration.zero),
  );
  await tester.pump();
  await tester.pumpAndSettle();
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
