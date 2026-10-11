import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/company_logo.dart';
import 'package:solar_ui/core/widgets/solar_feedback.dart';
import 'package:solar_ui/core/widgets/theme_selector.dart';
import 'package:solar_ui/features/dashboard/models/dashboard_module.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/coming_soon_sheet.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/dashboard_hero.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/empty_workspace_card.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/quick_action_card.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({
    required this.user,
    required this.themeController,
    this.now,
    super.key,
  });

  final DemoUser user;
  final ThemeController themeController;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final currentDate = now ?? DateTime.now();

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
                    currentDate: currentDate,
                    themeController: themeController,
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
                  const SizedBox(height: AppSpacing.xl),
                  const DashboardSectionHeader(
                    title: 'Quick access',
                    description: 'BRD-aligned modules prepared for future implementation.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _QuickActionGrid(),
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
    required this.currentDate,
    required this.themeController,
  });

  final DemoUser user;
  final DateTime currentDate;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              onPressed: () => showComingSoonSheet(
                context,
                title: 'Notifications are coming soon',
                description:
                    'The documented notification inbox will be connected in '
                    'a later feature phase. No unread count is being simulated.',
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _greeting(currentDate.hour),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          user.firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(user.role, style: Theme.of(context).textTheme.bodyMedium),
            const SolarStatusIndicator(
              label: 'Demo mode',
              tone: SolarStatusTone.info,
            ),
            Text(
              _formattedDate(currentDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}';
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

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
              onTap: () => showComingSoonSheet(
                context,
                title: '${module.title} is coming soon',
                description: module.placeholderDescription,
              ),
            );
          },
        );
      },
    );
  }
}
