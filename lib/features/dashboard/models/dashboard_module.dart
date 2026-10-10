import 'package:flutter/material.dart';

@immutable
class DashboardModule {
  const DashboardModule({
    required this.title,
    required this.icon,
    required this.placeholderDescription,
  });

  final String title;
  final IconData icon;
  final String placeholderDescription;
}

abstract final class DashboardModules {
  static const items = [
    DashboardModule(
      title: 'Customers',
      icon: Icons.people_alt_outlined,
      placeholderDescription:
          'Customer profiles and onboarding will be added in a later phase.',
    ),
    DashboardModule(
      title: 'Sites & installations',
      icon: Icons.solar_power_outlined,
      placeholderDescription: 'Solar sites, equipment and installation tracking are not connected yet.',
    ),
    DashboardModule(
      title: 'Service requests',
      icon: Icons.build_circle_outlined,
      placeholderDescription:
          'Service booking and request allocation will be implemented later.',
    ),
    DashboardModule(
      title: 'Complaints',
      icon: Icons.support_agent_outlined,
      placeholderDescription:
          'Complaint ticket creation and lifecycle tracking are coming soon.',
    ),
    DashboardModule(
      title: 'Site visits',
      icon: Icons.location_on_outlined,
      placeholderDescription: 'Visit scheduling, assignment and offline charge records are coming soon.',
    ),
    DashboardModule(
      title: 'Technicians',
      icon: Icons.engineering_outlined,
      placeholderDescription:
          'Technician workspace and assignments are not implemented yet.',
    ),
    DashboardModule(
      title: 'Catalogue',
      icon: Icons.grid_view_rounded,
      placeholderDescription:
          'Product catalogue management and enquiries will be added later.',
    ),
    DashboardModule(
      title: 'Billing register',
      icon: Icons.receipt_long_outlined,
      placeholderDescription: 'This will be an admin-maintained offline billing and payment register, not a payment gateway.',
    ),
  ];
}
