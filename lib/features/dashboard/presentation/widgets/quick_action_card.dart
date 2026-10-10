import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';
import 'package:solar_ui/features/dashboard/models/dashboard_module.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({required this.module, required this.onTap, super.key});

  final DashboardModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SolarCard(
      onTap: onTap,
      semanticLabel: '${module.title}, coming soon',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            alignment: Alignment.center,
            child: Icon(
              module.icon,
              size: AppSizes.iconMedium,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          Text(
            module.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Coming soon',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colorScheme.primary),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: AppSizes.iconSmall,
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
