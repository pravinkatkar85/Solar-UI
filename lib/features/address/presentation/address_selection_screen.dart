import 'dart:async';

import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/solar_buttons.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';
import 'package:solar_ui/core/widgets/solar_feedback.dart';
import 'package:solar_ui/features/address/presentation/address_selection_controller.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';

/// Country, state, district, city and pincode dropdowns.
///
/// This screen only selects an address. It does not save it.
class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({required this.repository, super.key});

  final DropdownRepository repository;

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  late final AddressSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AddressSelectionController(repository: widget.repository);
    unawaited(_controller.loadInitial());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < AppSizes.compactBreakpoint
                ? AppSpacing.md
                : AppSpacing.xl;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SolarCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Address',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Select the country, then the state, district, city and pincode.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (
                          var index = 0;
                          index < _controller.fields.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: AppSpacing.md),
                          _AddressDropdown(
                            controller: _controller,
                            index: index,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AddressDropdown extends StatelessWidget {
  const _AddressDropdown({required this.controller, required this.index});

  final AddressSelectionController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final field = controller.fields[index];
    final waitingForParent =
        index > 0 && controller.fields[index - 1].selected == null;
    final canChoose =
        !waitingForParent &&
        !field.loading &&
        field.errorMessage == null &&
        field.options.isNotEmpty;
    final selectedValue = field.selected?.value;
    final value = field.options.any((option) => option.value == selectedValue)
        ? selectedValue
        : null;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: field.level.label,
            helperText: _helper(waitingForParent),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: Key('address-dropdown-${field.level.dropdownCode}'),
              isExpanded: true,
              value: value,
              hint: Text('Select ${field.level.label.toLowerCase()}'),
              disabledHint: Text('Select ${field.level.label.toLowerCase()}'),
              items: [
                for (final option in field.options)
                  DropdownMenuItem<String>(
                    value: option.value,
                    child: Text(option.label),
                  ),
              ],
              onChanged: canChoose
                  ? (selected) {
                      if (selected != null) {
                        unawaited(controller.select(index, selected));
                      }
                    }
                  : null,
            ),
          ),
        ),
        if (field.loading) ...[
          const SizedBox(height: AppSpacing.sm),
          SolarLoadingIndicator(
            label: 'Loading ${field.level.label.toLowerCase()}',
            compact: true,
          ),
        ],
        if (field.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            field.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colorScheme.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: SolarSecondaryButton(
              key: Key('address-retry-${field.level.dropdownCode}'),
              label: 'Try again',
              onPressed: () => unawaited(controller.retry(index)),
            ),
          ),
        ],
      ],
    );
  }

  String? _helper(bool waitingForParent) {
    final field = controller.fields[index];
    if (waitingForParent) {
      final parent = controller.fields[index - 1].level.label.toLowerCase();
      return 'Select $parent first.';
    }
    if (field.loading || field.errorMessage != null) return null;
    if (field.options.isEmpty) return 'No options are available.';
    return null;
  }
}
