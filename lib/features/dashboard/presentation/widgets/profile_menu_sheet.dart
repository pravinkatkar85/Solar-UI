import 'package:flutter/material.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_colors.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/features/dashboard/presentation/widgets/coming_soon_sheet.dart';

/// Account actions opened from the home profile icon.
Future<void> showProfileMenu(
  BuildContext context, {
  required DemoUser user,
  required VoidCallback? onChangePin,
  required Future<void> Function()? onSignIn,
  required VoidCallback? onViewEnquiries,
  required VoidCallback? onOpenAddress,
  required Future<void> Function()? onSignOut,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Account',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (sheetContext, animation, secondaryAnimation) {
      final signedIn = onSignOut != null;
      final width = MediaQuery.sizeOf(sheetContext).width;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Theme.of(sheetContext).colorScheme.surface,
          child: SizedBox(
            width: width < 480 ? width * 0.86 : 380,
            height: double.infinity,
            child: SafeArea(
              child: signedIn
                  ? _SignedInMenu(
                      user: user,
                      hostContext: context,
                      sheetContext: sheetContext,
                      onChangePin: onChangePin,
                      onSignIn: onSignIn,
                      onViewEnquiries: onViewEnquiries,
                      onOpenAddress: onOpenAddress,
                      onSignOut: onSignOut,
                    )
                  : _GuestMenu(
                      user: user,
                      sheetContext: sheetContext,
                      onSignIn: onSignIn,
                    ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: slide, child: child);
    },
  );
}

class _GuestMenu extends StatelessWidget {
  const _GuestMenu({
    required this.user,
    required this.sheetContext,
    required this.onSignIn,
  });

  final DemoUser user;
  final BuildContext sheetContext;
  final Future<void> Function()? onSignIn;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Identity(user: user, subtitle: 'Sign in to manage your account'),
        const SizedBox(height: AppSpacing.lg),
        _ActionRow(
          itemKey: const Key('profile-sign-in'),
          icon: Icons.login_rounded,
          label: 'Sign in',
          onTap: () {
            final signIn = onSignIn;
            if (signIn == null) return;
            Navigator.of(sheetContext).pop();
            signIn();
          },
        ),
      ],
    );
  }
}

class _SignedInMenu extends StatelessWidget {
  const _SignedInMenu({
    required this.user,
    required this.hostContext,
    required this.sheetContext,
    required this.onChangePin,
    required this.onSignIn,
    required this.onViewEnquiries,
    required this.onOpenAddress,
    required this.onSignOut,
  });

  final DemoUser user;
  final BuildContext hostContext;
  final BuildContext sheetContext;
  final VoidCallback? onChangePin;
  final Future<void> Function()? onSignIn;
  final VoidCallback? onViewEnquiries;
  final VoidCallback? onOpenAddress;
  final Future<void> Function()? onSignOut;

  void _choose(VoidCallback? action) {
    if (action == null) return;
    Navigator.of(sheetContext).pop();
    action();
  }

  void _later(String title, String description) {
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showComingSoonSheet(hostContext, title: title, description: description);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Identity(user: user),
        const SizedBox(height: AppSpacing.lg),
        const _MenuHeading('Account'),
        _ActionRow(
          itemKey: const Key('profile-my-account'),
          icon: Icons.badge_outlined,
          label: 'My Account',
          onTap: () => _later(
            'My Account is coming soon',
            'Your registered name, mobile number and role will appear '
                'here once the account profile is connected.',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          itemKey: const Key('profile-change-pin'),
          icon: Icons.pin_outlined,
          label: 'Change PIN',
          onTap: () => _choose(() {
            final changePin = onChangePin;
            if (changePin != null) {
              changePin();
              return;
            }
            final signIn = onSignIn;
            if (signIn != null) {
              signIn();
            }
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          itemKey: const Key('profile-enquiries'),
          icon: Icons.forum_outlined,
          label: 'View enquiries',
          onTap: () => _choose(onViewEnquiries),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          itemKey: const Key('profile-current-product'),
          icon: Icons.solar_power_outlined,
          label: 'Current product',
          onTap: () => _later(
            'Current product is coming soon',
            'The product installed at your site will appear here once '
                'site and equipment records are connected.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _MenuHeading('Service'),
        _ActionRow(
          itemKey: const Key('profile-service-info'),
          icon: Icons.info_outline_rounded,
          label: 'Service information',
          onTap: () => _later(
            'Service information is coming soon',
            'Coverage, visit rules and the active service plan will '
                'appear here once service records are connected.',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          itemKey: const Key('profile-service-history'),
          icon: Icons.history_rounded,
          label: 'Service history',
          onTap: () => _later(
            'Service history is coming soon',
            'Completed visits and service updates will appear here once '
                'service history is connected.',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          itemKey: const Key('profile-due-dates'),
          icon: Icons.event_outlined,
          label: 'Next due dates',
          onTap: () => _later(
            'Due dates are coming soon',
            'Upcoming service dates will appear here once those '
                'schedules are connected.',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionRow(
          itemKey: const Key('profile-service-request'),
          icon: Icons.home_repair_service_outlined,
          label: 'Raise service request',
          onTap: () => _later(
            'Service requests are coming soon',
            'You will be able to raise a service request here once that '
                'contract is approved. No request has been created.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _MenuHeading('Place'),
        _ActionRow(
          itemKey: const Key('profile-address'),
          icon: Icons.location_on_outlined,
          label: 'View / update address',
          onTap: () => _choose(onOpenAddress),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ActionRow(
          itemKey: const Key('profile-sign-out'),
          icon: Icons.logout_rounded,
          label: 'Sign out',
          emphasized: true,
          onTap: () {
            final signOut = onSignOut;
            if (signOut == null) return;
            Navigator.of(sheetContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              signOut();
            });
          },
        ),
      ],
    );
  }
}

class _MenuHeading extends StatelessWidget {
  const _MenuHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: AppColors.solarOrangeDark, letterSpacing: 0.4),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user, this.subtitle});

  final DemoUser user;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.solarOrangeSoft,
          foregroundColor: AppColors.deepNavy,
          child: Text(
            user.initials,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName, style: theme.textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.itemKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: emphasized ? scheme.surfaceContainerHighest : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: itemKey,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.solarOrange),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
