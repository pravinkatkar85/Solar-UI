import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_colors.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';

/// Turns the address stored on the product into a loadable image address.
///
/// The database stores a site path such as `/media/catalogue/TEST-CAT-01.jpg`
/// or an absolute http(s) URL. The API base comes from the running client.
String? resolveCatalogueMediaUrl(String stored, String? mediaBaseUrl) {
  final value = stored.trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme == 'http' || uri.scheme == 'https') return value;
    return null;
  }
  if (value.startsWith('/') &&
      mediaBaseUrl != null &&
      mediaBaseUrl.isNotEmpty) {
    final base = mediaBaseUrl.endsWith('/')
        ? mediaBaseUrl.substring(0, mediaBaseUrl.length - 1)
        : mediaBaseUrl;
    return '$base$value';
  }
  if (value.startsWith('assets/')) return value;
  return null;
}

/// Loads the image address returned for a product.
class CatalogueArtwork extends StatelessWidget {
  const CatalogueArtwork({
    required this.imageUrl,
    this.mediaBaseUrl,
    this.borderRadius,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final String? mediaBaseUrl;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCatalogueMediaUrl(imageUrl, mediaBaseUrl);
    final Widget image;
    if (resolved == null) {
      image = const _ArtworkFallback();
    } else if (resolved.startsWith('assets/')) {
      image = Image.asset(
        resolved,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _ArtworkFallback(),
      );
    } else {
      image = Image.network(
        resolved,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => const _ArtworkFallback(),
      );
    }

    final radius = borderRadius;
    if (radius == null) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepNavy, Color(0xFF3A2A22)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.solar_power_rounded,
          color: AppColors.solarOrange,
          size: 42,
        ),
      ),
    );
  }
}

class CatalogueProductCard extends StatelessWidget {
  const CatalogueProductCard({
    required this.product,
    required this.onTap,
    this.mediaBaseUrl,
    super.key,
  });

  final CatalogueProduct product;
  final VoidCallback onTap;
  final String? mediaBaseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(AppRadii.medium));
    final priceColor = theme.brightness == Brightness.dark
        ? AppColors.solarOrangeDarkTheme
        : AppColors.deepNavy;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('product-${product.productId}'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CatalogueArtwork(
                  imageUrl: product.thumbnailUrl,
                  mediaBaseUrl: mediaBaseUrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName.isNotEmpty)
                      Text(
                        product.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.solarOrangeDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      product.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatCataloguePrice(
                        product.currencyCode,
                        product.listPrice,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: priceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatCataloguePrice(String currency, String amount) {
  final value = num.tryParse(amount.trim());
  if (value == null) {
    return [currency, amount].where((part) => part.isNotEmpty).join(' ');
  }
  final negative = value < 0;
  final absolute = value.abs();
  final fixed = absolute == absolute.roundToDouble()
      ? absolute.toStringAsFixed(0)
      : absolute.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % 3 == 0) grouped.write(',');
    grouped.write(digits[index]);
  }
  final fraction = parts.length == 2 ? '.${parts[1]}' : '';
  final prefix = negative ? '-' : '';
  final code = currency.trim();
  return code.isEmpty
      ? '$prefix$grouped$fraction'
      : '$code $prefix$grouped$fraction';
}

(String, String) catalogueSpecParts(String key, String value) {
  switch (key) {
    case 'brand':
      return ('Brand', value);
    case 'wattage_wp':
      return ('Output', '$value Wp');
    case 'capacity_kw':
      return ('Capacity', '$value kW');
    case 'capacity_ah':
      return ('Capacity', '$value Ah');
    case 'capacity_kwh':
      return ('Storage', '$value kWh');
    case 'voltage_v':
      return ('Voltage', '$value V');
    case 'phase':
      return ('Supply', value == 'single' ? 'Single phase' : 'Three phase');
    case 'material':
      return ('Material', value);
    case 'visits':
      return ('Visits', value);
    default:
      final title = key.replaceAll('_', ' ');
      return (title, value);
  }
}
