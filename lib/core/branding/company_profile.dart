import 'package:solar_ui/core/theme/app_colors.dart';

/// Approved company identity for the mobile experience.
///
/// These values belong in deployment configuration once that mechanism exists.
/// Do not add contact numbers, websites, or taglines that were not supplied.
abstract final class CompanyProfile {
  static const legalName = 'POURNIMA ENERGY AND INFRA LLP';
  static const productName = 'Solar Service Management';
  static const logoAsset = 'assets/branding/pournima_wordmark.jpeg';
  static const logoBackground = AppColors.brandBlue;

  static const addressLines = [
    'Block No 302, Third Floor,',
    'Shubhdin Pride,',
    'Opposite Irrigation Office, Bombay Restaurant Chowk,',
    'Satara - 415002',
  ];

  static const gstin = '27ABHFP7712L1ZS';
}
