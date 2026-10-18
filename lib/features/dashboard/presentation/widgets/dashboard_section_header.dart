import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    required this.title,
    this.description = '',
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
