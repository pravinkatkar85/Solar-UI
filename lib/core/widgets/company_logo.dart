import 'package:flutter/material.dart';
import 'package:solar_ui/core/branding/company_profile.dart';
import 'package:solar_ui/core/theme/app_layout.dart';

/// Official wordmark. The source JPEG has a solid brand-blue field, so it is
/// placed on that same color and never stretched beyond its natural ratio.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({this.height = 56, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: CompanyProfile.legalName,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CompanyProfile.logoBackground,
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ExcludeSemantics(
            child: Image.asset(
              CompanyProfile.logoAsset,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(
                  height: height,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CompanyProfile.legalName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
