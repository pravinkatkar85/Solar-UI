import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';

class EmptyWorkspaceCard extends StatelessWidget {
  const EmptyWorkspaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SolarCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.inbox_outlined,
              color: colorScheme.onSecondaryContainer,
              size: AppSizes.iconLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No live workspace data yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Requests, visits and assignments will appear here after '
                  'their approved API contracts are implemented.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Development preview',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
