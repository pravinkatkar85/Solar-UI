import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/features/address/presentation/address_selection_screen.dart';
import 'package:solar_ui/features/company/presentation/company_about_screen.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_home.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    required this.user,
    required this.themeController,
    super.key,
  });

  final DemoUser user;
  final ThemeController themeController;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  HttpDropdownClient? _dropdownClient;
  DropdownRepository? _addressRepository;
  String? _addressSetupMessage;

  @override
  void dispose() {
    _dropdownClient?.close();
    super.dispose();
  }

  void _openAddress() {
    if (_addressRepository != null || _addressSetupMessage != null) return;
    try {
      final client = HttpDropdownClient();
      _dropdownClient = client;
      _addressRepository = DropdownRepository(
        baseUrl: ApiBaseUrl.fromEnvironment(),
        transport: client,
        cache: SharedPreferencesDropdownCacheStore(),
      );
    } on InvalidApiBaseUrlException catch (error) {
      _addressSetupMessage = error.message;
    }
  }

  Widget _customersPage() {
    final message = _addressSetupMessage;
    if (message != null) {
      return _AddressSetupNotice(message: message);
    }
    final repository = _addressRepository;
    if (repository == null) return const SizedBox.shrink();
    return AddressSelectionScreen(repository: repository);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final destinations = [
      DashboardHome(user: widget.user, themeController: widget.themeController),
      _customersPage(),
      const _ComingSoonDestination(
        icon: Icons.home_repair_service_outlined,
        title: 'Services',
        description:
            'Service requests, complaints, visits and assignments will be '
            'introduced in later feature phases.',
      ),
      CompanyAboutScreen(
        user: widget.user,
        themeController: widget.themeController,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _selectedIndex, children: destinations),
        ),
        bottomNavigationBar: _DashboardNavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            if (_selectedIndex == index) return;
            if (index == 1) _openAddress();
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }
}

class _DashboardNavigationBar extends StatelessWidget {
  const _DashboardNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: NavigationBar(
              height: 72,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Customers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_repair_service_outlined),
                  selectedIcon: Icon(Icons.home_repair_service_rounded),
                  label: 'Services',
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  selectedIcon: Icon(Icons.more_rounded),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressSetupNotice extends StatelessWidget {
  const _AddressSetupNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Address selection is unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonDestination extends StatelessWidget {
  const _ComingSoonDestination({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 42,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '$title is coming soon',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No API call or business operation is connected.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
