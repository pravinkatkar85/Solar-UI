import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/company_logo.dart';
import 'package:solar_ui/core/widgets/theme_selector.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';
import 'package:solar_ui/features/catalogue/presentation/catalogue_screen.dart';
import 'package:solar_ui/features/dashboard/models/dashboard_module.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/coming_soon_sheet.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/dashboard_hero.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/empty_workspace_card.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/profile_menu_sheet.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/quick_action_card.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({
    required this.user,
    required this.themeController,
    this.catalogueApi,
    this.accessToken,
    this.onSignIn,
    this.onOpenCatalogue,
    this.onChangePin,
    this.onViewEnquiries,
    this.onOpenAddress,
    this.onSignOut,
    super.key,
  });

  final DemoUser user;
  final ThemeController themeController;
  final CatalogueApi? catalogueApi;
  final String? accessToken;
  final Future<void> Function()? onSignIn;
  final VoidCallback? onOpenCatalogue;
  final VoidCallback? onChangePin;
  final VoidCallback? onViewEnquiries;
  final VoidCallback? onOpenAddress;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth < AppSizes.compactBreakpoint
            ? AppSpacing.md
            : AppSpacing.xl;

        return SingleChildScrollView(
          key: const PageStorageKey('dashboard-home-scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.md,
            horizontalPadding,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(
                    user: user,
                    themeController: themeController,
                    onChangePin: onChangePin,
                    onViewEnquiries: onViewEnquiries,
                    onSignIn: onSignIn,
                    onOpenAddress: onOpenAddress,
                    onSignOut: onSignOut,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DashboardHero(
                    user: user,
                    onOpenWorkspace: () => showComingSoonSheet(
                      context,
                      title: 'Service workspace is coming soon',
                      description:
                          'The workspace will be connected after service '
                          'request, visit and assignment contracts are approved.',
                    ),
                  ),
                  if (catalogueApi != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    CatalogueScreen(
                      catalogueApi: catalogueApi!,
                      accessToken: accessToken,
                      onRequestSignIn: onSignIn,
                      mediaBaseUrl: catalogueApi!.mediaBaseUrl,
                      embedded: true,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const DashboardSectionHeader(
                    title: 'Quick access',
                    description: 'BRD-aligned modules prepared for future implementation.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuickActionGrid(onOpenCatalogue: onOpenCatalogue),
                  const SizedBox(height: AppSpacing.xl),
                  const DashboardSectionHeader(
                    title: 'My workspace',
                    description:
                        'Live operational information will appear here later.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const EmptyWorkspaceCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.user,
    required this.themeController,
    required this.onChangePin,
    required this.onViewEnquiries,
    required this.onSignIn,
    required this.onOpenAddress,
    required this.onSignOut,
  });

  final DemoUser user;
  final ThemeController themeController;
  final VoidCallback? onChangePin;
  final VoidCallback? onViewEnquiries;
  final Future<void> Function()? onSignIn;
  final VoidCallback? onOpenAddress;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconStyle = IconButton.styleFrom(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      side: BorderSide(color: colorScheme.outlineVariant),
    );

    return Row(
      children: [
        const Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CompanyLogo(height: 28),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SolarThemeSelector(controller: themeController, showLabel: false),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          tooltip: 'Notifications — not implemented yet',
          style: iconStyle,
          onPressed: () => showComingSoonSheet(
            context,
            title: 'Notifications are coming soon',
            description:
                'The documented notification inbox will be connected in '
                'a later feature phase. No unread count is being simulated.',
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton(
          key: const Key('profile-menu'),
          tooltip: 'Account',
          style: iconStyle,
          onPressed: () => showProfileMenu(
            context,
            user: user,
            onChangePin: onChangePin,
            onViewEnquiries: onViewEnquiries,
            onSignIn: onSignIn,
            onOpenAddress: onOpenAddress,
            onSignOut: onSignOut,
          ),
          icon: const Icon(Icons.person_outline_rounded),
        ),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({this.onOpenCatalogue});

  final VoidCallback? onOpenCatalogue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= 960 => 4,
          >= 620 => 3,
          _ => 2,
        };
        final aspectRatio = columns == 2 ? 0.98 : 1.08;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: DashboardModules.items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final module = DashboardModules.items[index];
            return QuickActionCard(
              module: module,
              onTap: () {
                if (module.title == 'Catalogue' && onOpenCatalogue != null) {
                  onOpenCatalogue!();
                  return;
                }
                showComingSoonSheet(
                  context,
                  title: '${module.title} is coming soon',
                  description: module.placeholderDescription,
                );
              },
            );
          },
        );
      },
    );
  }
}
