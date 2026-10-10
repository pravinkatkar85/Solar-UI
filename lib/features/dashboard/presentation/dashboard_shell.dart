import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/theme_selector.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final destinations = [
      DashboardHome(user: widget.user, themeController: widget.themeController),
      const _ComingSoonDestination(
        icon: Icons.people_alt_outlined,
        title: 'Customers',
        description:
            'Customer profiles and onboarding will be implemented after the '
            'approved database and API contracts are available.',
      ),
      const _ComingSoonDestination(
        icon: Icons.home_repair_service_outlined,
        title: 'Services',
        description:
            'Service requests, complaints, visits and assignments will be '
            'introduced in later feature phases.',
      ),
      _ComingSoonDestination(
        icon: Icons.more_horiz_rounded,
        title: 'More',
        description: 'Profile, preferences and additional tools are not implemented yet.',
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
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
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

class _ComingSoonDestination extends StatelessWidget {
  const _ComingSoonDestination({
    required this.icon,
    required this.title,
    required this.description,
    this.themeController,
  });

  final IconData icon;
  final String title;
  final String description;
  final ThemeController? themeController;

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
              if (themeController != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SolarThemeSelector(controller: themeController!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
