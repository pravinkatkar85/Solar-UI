import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_colors.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/solar_buttons.dart';
import 'package:solar_ui/core/widgets/solar_form_field.dart';
import 'package:solar_ui/features/auth/session_controller.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';
import 'package:solar_ui/features/catalogue/presentation/catalogue_artwork.dart';

enum CatalogueSort { featured, name, priceLow, priceHigh }

/// First page of a filtered or unfiltered catalogue. View all opens the rest.
const int cataloguePreviewCount = 8;

/// Published catalogue. Enquiry submission needs the signed-in bearer token.
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({
    required this.catalogueApi,
    this.accessToken,
    this.onRequestSignIn,
    this.embedded = false,
    this.mediaBaseUrl,
    this.showAll = false,
    this.initialCategory,
    this.initialSort = CatalogueSort.featured,
    super.key,
  });

  final CatalogueApi catalogueApi;
  final String? accessToken;
  final Future<void> Function()? onRequestSignIn;
  final bool embedded;
  final String? mediaBaseUrl;
  final bool showAll;
  final String? initialCategory;
  final CatalogueSort initialSort;

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late Future<CatalogueResult> _products;
  late String? _category;
  late CatalogueSort _sort;
  late bool _showAll;

  @override
  void initState() {
    super.initState();
    _products = widget.catalogueApi.listProducts();
    _category = widget.initialCategory;
    _sort = widget.initialSort;
    _showAll = widget.showAll;
  }

  void _reload() {
    setState(() {
      _products = widget.catalogueApi.listProducts();
    });
  }

  List<String> _categoryNames(List<CatalogueProduct> products) {
    final names =
        products
            .map((product) => product.categoryName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return names;
  }

  List<CatalogueProduct> _arrange(List<CatalogueProduct> products) {
    final category = _category;
    final filtered = category == null || category.isEmpty
        ? products
        : products
              .where((product) => product.categoryName == category)
              .toList();
    final sorted = [...filtered];
    switch (_sort) {
      case CatalogueSort.name:
        sorted.sort(
          (a, b) => a.productName.toLowerCase().compareTo(
            b.productName.toLowerCase(),
          ),
        );
      case CatalogueSort.priceLow:
        sorted.sort((a, b) => _amount(a).compareTo(_amount(b)));
      case CatalogueSort.priceHigh:
        sorted.sort((a, b) => _amount(b).compareTo(_amount(a)));
      case CatalogueSort.featured:
        sorted.sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          if (order != 0) return order;
          return a.productName.toLowerCase().compareTo(
            b.productName.toLowerCase(),
          );
        });
    }
    return sorted;
  }

  double _amount(CatalogueProduct product) {
    return double.tryParse(product.listPrice) ?? 0;
  }

  void _openRemaining() {
    if (!widget.embedded) {
      setState(() => _showAll = true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CatalogueScreen(
          catalogueApi: widget.catalogueApi,
          accessToken: widget.accessToken,
          mediaBaseUrl: widget.mediaBaseUrl,
          onRequestSignIn: widget.onRequestSignIn,
          initialCategory: _category,
          initialSort: _sort,
          showAll: true,
        ),
      ),
    );
  }

  void _openProduct(CatalogueProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductDetailScreen(
          catalogueApi: widget.catalogueApi,
          productId: product.productId,
          accessToken: widget.accessToken,
          mediaBaseUrl: widget.mediaBaseUrl,
          onRequestSignIn: widget.onRequestSignIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<CatalogueResult>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.embedded
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                )
              : const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data;
        if (result == null || !result.isSuccess) {
          return _MessagePane(
            message: result?.message ?? 'Products could not be loaded.',
            onRetry: _reload,
            shrink: widget.embedded,
          );
        }
        final products = result.products ?? const <CatalogueProduct>[];
        if (products.isEmpty) {
          return _MessagePane(
            message: 'No published products yet.',
            shrink: widget.embedded,
          );
        }
        return _CatalogueCollection(
          products: _arrange(products),
          categories: _categoryNames(products),
          category: _category,
          sort: _sort,
          onCategory: (value) => setState(() => _category = value),
          onSort: (value) => setState(() => _sort = value),
          embedded: widget.embedded,
          mediaBaseUrl: widget.mediaBaseUrl,
          showAll: _showAll,
          onViewAll: _openRemaining,
          onOpen: _openProduct,
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: body,
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    required this.catalogueApi,
    required this.productId,
    this.accessToken,
    this.mediaBaseUrl,
    this.onRequestSignIn,
    super.key,
  });

  final CatalogueApi catalogueApi;
  final String productId;
  final String? accessToken;
  final String? mediaBaseUrl;
  final Future<void> Function()? onRequestSignIn;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<CatalogueResult> _detail;
  final _messageController = TextEditingController();
  final _windowController = TextEditingController();
  var _submitting = false;
  var _notice = '';
  var _noticeIsError = false;
  var _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _detail = widget.catalogueApi.productDetail(widget.productId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _windowController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final token = _bearer(context);
    if (token.isEmpty) {
      _setNotice('Sign in to send an enquiry.');
      return;
    }
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _setNotice('Enter a requirement of 2000 characters or fewer');
      return;
    }
    setState(() {
      _submitting = true;
      _notice = '';
    });
    final result = await widget.catalogueApi.createEnquiry(
      accessToken: token,
      productId: widget.productId,
      messageText: message,
      preferredContactWindow: _windowController.text,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _noticeIsError = !result.isSuccess;
      _notice = result.isSuccess
          ? 'Enquiry ${result.enquiryNo} submitted'
          : result.message;
      if (result.isSuccess) {
        _messageController.clear();
        _windowController.clear();
      }
    });
  }

  String _bearer(BuildContext context) {
    final explicit = widget.accessToken?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    return SessionScope.maybeOf(context)?.accessToken?.trim() ?? '';
  }

  void _setNotice(String message) {
    setState(() {
      _notice = message;
      _noticeIsError = true;
    });
  }

  void _openPhoto(List<String> urls) {
    if (urls.isEmpty) return;
    final index = _photoIndex.clamp(0, urls.length - 1);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _ProductPhotoViewer(
          urls: urls,
          initialIndex: index,
          mediaBaseUrl: widget.mediaBaseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Product'),
      ),
      body: FutureBuilder<CatalogueResult>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snapshot.data?.product;
          if (snapshot.data == null ||
              !snapshot.data!.isSuccess ||
              product == null) {
            return _MessagePane(
              message:
                  snapshot.data?.message ?? 'This product is not available',
            );
          }
          final signedIn = _bearer(context).isNotEmpty;
          final theme = Theme.of(context);
          final photos = _productPhotoUrls(product);
          final photoIndex = photos.isEmpty
              ? 0
              : _photoIndex.clamp(0, photos.length - 1);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductPhotoStage(
                  photos: photos,
                  index: photoIndex,
                  mediaBaseUrl: widget.mediaBaseUrl,
                  onSelect: (index) => setState(() => _photoIndex = index),
                  onOpen: photos.isEmpty ? null : () => _openPhoto(photos),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (product.categoryName.isNotEmpty)
                            Text(
                              product.categoryName.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.solarOrangeDark,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            product.productName,
                            style: theme.textTheme.headlineMedium,
                          ),
                          if (product.listPrice.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              formatCataloguePrice(
                                product.currencyCode,
                                product.listPrice,
                              ),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? AppColors.solarOrangeDarkTheme
                                    : AppColors.deepNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (product.specs.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Specification',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final entry in product.specs.entries)
                              _SpecRow(
                                label: catalogueSpecParts(
                                  entry.key,
                                  entry.value,
                                ).$1,
                                value: catalogueSpecParts(
                                  entry.key,
                                  entry.value,
                                ).$2,
                              ),
                          ],
                          if (product.longDescription.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              product.longDescription,
                              key: const Key('product-description'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                          if (product.media.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Media',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            for (final item in product.media)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Text(
                                  item.caption.isEmpty
                                      ? item.mediaType
                                      : '${item.mediaType}: ${item.caption}',
                                ),
                              ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          if (!signedIn) ...[
                            const Text(
                              'Sign in to send an enquiry.',
                              key: Key('enquiry-signin'),
                            ),
                            if (widget.onRequestSignIn != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              SolarPrimaryButton(
                                key: const Key('enquiry-sign-in'),
                                label: 'Send enquiry',
                                expand: true,
                                onPressed: () {
                                  widget.onRequestSignIn?.call();
                                },
                              ),
                            ],
                          ] else ...[
                            SolarTextField(
                              key: const Key('enquiry-message'),
                              label: 'Requirement',
                              controller: _messageController,
                              enabled: !_submitting,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SolarTextField(
                              key: const Key('enquiry-window'),
                              label: 'Preferred contact window',
                              controller: _windowController,
                              enabled: !_submitting,
                            ),
                            if (_notice.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _notice,
                                key: const Key('enquiry-notice'),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: _noticeIsError
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                    ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            SolarPrimaryButton(
                              key: const Key('enquiry-submit'),
                              label: 'Send enquiry',
                              expand: true,
                              isLoading: _submitting,
                              onPressed: _submit,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CatalogueCollection extends StatelessWidget {
  const _CatalogueCollection({
    required this.products,
    required this.categories,
    required this.category,
    required this.sort,
    required this.onCategory,
    required this.onSort,
    required this.embedded,
    required this.mediaBaseUrl,
    required this.showAll,
    required this.onViewAll,
    required this.onOpen,
  });

  final List<CatalogueProduct> products;
  final List<String> categories;
  final String? category;
  final CatalogueSort sort;
  final ValueChanged<String?> onCategory;
  final ValueChanged<CatalogueSort> onSort;
  final bool embedded;
  final String? mediaBaseUrl;
  final bool showAll;
  final VoidCallback onViewAll;
  final ValueChanged<CatalogueProduct> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 760
            ? 3
            : 2;
        final visible = showAll || products.length <= cataloguePreviewCount
            ? products
            : products.take(cataloguePreviewCount).toList();
        final hiddenCount = products.length - visible.length;
        return CustomScrollView(
          key: const Key('catalogue-list'),
          shrinkWrap: embedded,
          physics: embedded ? const NeverScrollableScrollPhysics() : null,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  embedded ? 0 : AppSpacing.lg,
                  embedded ? 0 : AppSpacing.md,
                  embedded ? 0 : AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _CatalogueControls(
                  categories: categories,
                  category: category,
                  sort: sort,
                  onCategory: onCategory,
                  onSort: onSort,
                  summary: hiddenCount > 0
                      ? 'Showing ${visible.length} of ${products.length}'
                      : null,
                  showViewAll: hiddenCount > 0,
                  onViewAll: onViewAll,
                ),
              ),
            ),
            if (products.isEmpty)
              const SliverToBoxAdapter(
                child: _MessagePane(
                  message: 'No products match this filter.',
                  shrink: true,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  embedded ? 0 : AppSpacing.lg,
                  0,
                  embedded ? 0 : AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: width < 520 ? 0.72 : 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return CatalogueProductCard(
                      product: visible[index],
                      mediaBaseUrl: mediaBaseUrl,
                      onTap: () => onOpen(visible[index]),
                    );
                  }, childCount: visible.length),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CatalogueControls extends StatelessWidget {
  const _CatalogueControls({
    required this.categories,
    required this.category,
    required this.sort,
    required this.onCategory,
    required this.onSort,
    required this.summary,
    required this.showViewAll,
    required this.onViewAll,
  });

  final List<String> categories;
  final String? category;
  final CatalogueSort sort;
  final ValueChanged<String?> onCategory;
  final ValueChanged<CatalogueSort> onSort;
  final String? summary;
  final bool showViewAll;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtering = category != null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Solar systems', style: theme.textTheme.headlineSmall),
              if (summary != null)
                Text(summary!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        _ToolIcon(
          itemKey: const Key('catalogue-category'),
          tooltip: filtering ? category! : 'Categories',
          icon: Icons.tune_rounded,
          active: filtering,
          onPressed: () => _openFilter(context),
        ),
        _ToolIcon(
          itemKey: const Key('catalogue-sort'),
          tooltip: 'Sort · ${_sortLabel(sort)}',
          icon: Icons.swap_vert_rounded,
          active: sort != CatalogueSort.featured,
          onPressed: () => _openSort(context),
        ),
        if (showViewAll)
          TextButton(
            key: const Key('catalogue-view-all'),
            onPressed: onViewAll,
            child: const Text('View all'),
          ),
      ],
    );
  }

  Future<void> _openFilter(BuildContext context) {
    return _openOptions(
      context,
      title: 'Categories',
      options: [
        _Option(
          label: 'All',
          selected: category == null,
          onTap: () => onCategory(null),
        ),
        for (final name in categories)
          _Option(
            label: name,
            selected: category == name,
            onTap: () => onCategory(name),
          ),
      ],
    );
  }

  Future<void> _openSort(BuildContext context) {
    return _openOptions(
      context,
      title: 'Sort',
      options: [
        for (final option in CatalogueSort.values)
          _Option(
            label: _sortLabel(option),
            selected: sort == option,
            onTap: () => onSort(option),
          ),
      ],
    );
  }

  Future<void> _openOptions(
    BuildContext context, {
    required String title,
    required List<_Option> options,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final option in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.label),
                    trailing: option.selected
                        ? Icon(
                            Icons.check_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      option.onTap();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Option {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.itemKey,
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final Key itemKey;
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: itemKey,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: active ? scheme.primary : scheme.surface,
        foregroundColor: active ? scheme.onPrimary : scheme.onSurface,
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      icon: Icon(icon),
    );
  }
}

String _sortLabel(CatalogueSort sort) {
  return switch (sort) {
    CatalogueSort.featured => 'Featured',
    CatalogueSort.name => 'Name',
    CatalogueSort.priceLow => 'Price · low',
    CatalogueSort.priceHigh => 'Price · high',
  };
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.message,
    this.onRetry,
    this.shrink = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            key: const Key('catalogue-message'),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            SolarSecondaryButton(label: 'Try again', onPressed: onRetry),
          ],
        ],
      ),
    );
    if (shrink) return content;
    return Center(child: content);
  }
}

List<String> _productPhotoUrls(CatalogueProduct product) {
  final urls = <String>[];
  void add(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || urls.contains(trimmed)) return;
    urls.add(trimmed);
  }

  add(product.thumbnailUrl);
  for (final item in product.media) {
    if (item.mediaType.toUpperCase() == 'PHOTO' || item.mediaType.isEmpty) {
      add(item.fileUrl);
    }
  }
  return urls;
}

class _ProductPhotoStage extends StatelessWidget {
  const _ProductPhotoStage({
    required this.photos,
    required this.index,
    required this.mediaBaseUrl,
    required this.onSelect,
    required this.onOpen,
  });

  final List<String> photos;
  final int index;
  final String? mediaBaseUrl;
  final ValueChanged<int> onSelect;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = photos.isEmpty ? '' : photos[index];
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = (constraints.maxWidth * 0.75).clamp(240.0, 460.0);
              return SizedBox(
                height: height,
                child: InkWell(
                  key: const Key('product-photo'),
                  onTap: onOpen,
                  child: CatalogueArtwork(
                    imageUrl: selected,
                    mediaBaseUrl: mediaBaseUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          if (photos.length > 1)
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                itemCount: photos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, photoIndex) {
                  final selectedPhoto = photoIndex == index;
                  return InkWell(
                    key: Key('product-photo-$photoIndex'),
                    onTap: () => onSelect(photoIndex),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedPhoto
                              ? AppColors.solarOrange
                              : theme.colorScheme.outlineVariant,
                          width: selectedPhoto ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.small),
                      ),
                      child: SizedBox(
                        width: 72,
                        child: CatalogueArtwork(
                          imageUrl: photos[photoIndex],
                          mediaBaseUrl: mediaBaseUrl,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (onOpen != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('product-photo-open'),
                onPressed: onOpen,
                child: const Text('View image'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductPhotoViewer extends StatefulWidget {
  const _ProductPhotoViewer({
    required this.urls,
    required this.initialIndex,
    required this.mediaBaseUrl,
  });

  final List<String> urls;
  final int initialIndex;
  final String? mediaBaseUrl;

  @override
  State<_ProductPhotoViewer> createState() => _ProductPhotoViewerState();
}

class _ProductPhotoViewerState extends State<_ProductPhotoViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late var _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_index + 1} of ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.urls.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: CatalogueArtwork(
                    imageUrl: widget.urls[index],
                    mediaBaseUrl: widget.mediaBaseUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
