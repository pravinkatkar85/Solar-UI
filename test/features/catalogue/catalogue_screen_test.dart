import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';
import 'package:solar_ui/features/catalogue/presentation/catalogue_screen.dart';
import 'package:solar_ui/features/catalogue/presentation/enquiry_list_screen.dart';

void main() {
  testWidgets('shows only the published products returned by the API', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi();
    await tester.pumpWidget(_app(CatalogueScreen(catalogueApi: api)));
    await tester.pumpAndSettle();

    expect(find.text('Rooftop 3kW'), findsOneWidget);
    expect(find.text('Draft panel'), findsNothing);
    expect(api.detailCalls, isEmpty);
    expect(api.enquiryCalls, isEmpty);
  });

  testWidgets('shows eight products until view all', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi()..manyProducts = true;
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(CatalogueScreen(catalogueApi: api)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-8')), findsOneWidget);
    expect(find.byKey(const Key('product-9')), findsNothing);
    expect(find.text('Showing 8 of 12'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('catalogue-view-all')));
    await tester.tap(find.byKey(const Key('catalogue-view-all')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('product-12')),
      400,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.byKey(const Key('product-12')), findsOneWidget);
    expect(find.byKey(const Key('catalogue-view-all')), findsNothing);
  });

  testWidgets('lists the signed-in user enquiries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        EnquiryListScreen(
          catalogueApi: _FakeCatalogueApi(),
          accessToken: 'token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ENQ-00000015'), findsOneWidget);
    expect(find.text('Rooftop 3kW'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Need a rooftop quote'), findsOneWidget);
    expect(find.textContaining('Engineer: Not assigned yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('enquiry-menu-ENQ-00000015')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('enquiry-cancel-ENQ-00000015')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('enquiry-followup-ENQ-00000015')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('enquiry-contact-ENQ-00000015')),
      findsOneWidget,
    );
  });

  testWidgets('opens the product photo so the whole image can be viewed', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi();
    await tester.pumpWidget(
      _app(ProductDetailScreen(catalogueApi: api, productId: '3')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-photo')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('product-photo-open')));
    await tester.tap(find.byKey(const Key('product-photo-open')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('shows product description and media', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi();
    await tester.pumpWidget(_app(CatalogueScreen(catalogueApi: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-3')));
    await tester.pumpAndSettle();

    expect(find.text('Grid-tied system'), findsOneWidget);
    expect(find.text('PHOTO: Roof view'), findsOneWidget);
    expect(api.detailCalls, ['3']);
  });

  testWidgets('shows an unavailable product message', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi()..detailMissing = true;
    await tester.pumpWidget(
      _app(
        ProductDetailScreen(
          catalogueApi: api,
          productId: '4',
          accessToken: 'token',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This product is not available'), findsOneWidget);
    expect(api.enquiryCalls, isEmpty);
  });

  testWidgets('submits an enquiry for a signed-in user', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi();
    await tester.pumpWidget(
      _app(
        ProductDetailScreen(
          catalogueApi: api,
          productId: '3',
          accessToken: 'session-token',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('enquiry-message')),
      'Need a rooftop quote',
    );
    final submit = find.byKey(const Key('enquiry-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(api.enquiryCalls, [
      {
        'accessToken': 'session-token',
        'productId': '3',
        'messageText': 'Need a rooftop quote',
      },
    ]);
    expect(find.text('Enquiry ENQ-00000015 submitted'), findsOneWidget);
  });

  testWidgets('does not submit an enquiry before sign-in', (
    WidgetTester tester,
  ) async {
    final api = _FakeCatalogueApi();
    await tester.pumpWidget(
      _app(ProductDetailScreen(catalogueApi: api, productId: '3')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to send an enquiry.'), findsOneWidget);
    expect(find.byKey(const Key('enquiry-submit')), findsNothing);
    expect(api.enquiryCalls, isEmpty);
  });
}

Widget _app(Widget home) {
  return MaterialApp(theme: AppTheme.lightTheme, home: home);
}

class _FakeCatalogueApi implements CatalogueApi {
  var detailMissing = false;
  var manyProducts = false;
  final List<String> detailCalls = [];
  final List<Map<String, String>> enquiryCalls = [];

  @override
  Future<CatalogueResult> listProducts() async {
    if (manyProducts) {
      return CatalogueResult.success(
        products: [
          for (var index = 1; index <= 12; index++)
            CatalogueProduct(
              productId: '$index',
              productName: 'Product ${index.toString().padLeft(2, '0')}',
              listPrice: '${index * 1000}',
              currencyCode: 'INR',
              sortOrder: index,
            ),
        ],
      );
    }
    return const CatalogueResult.success(
      products: [
        CatalogueProduct(
          productId: '3',
          productName: 'Rooftop 3kW',
          listPrice: '45000.00',
          currencyCode: 'INR',
          shortDescription: 'Published system',
        ),
      ],
    );
  }

  @override
  Future<CatalogueResult> productDetail(String productId) async {
    detailCalls.add(productId);
    if (detailMissing) {
      return const CatalogueResult.failure('This product is not available');
    }
    return const CatalogueResult.success(
      product: CatalogueProduct(
        productId: '3',
        productName: 'Rooftop 3kW',
        listPrice: '45000.00',
        currencyCode: 'INR',
        longDescription: 'Grid-tied system',
        media: [
          CatalogueMedia(
            mediaType: 'PHOTO',
            fileUrl: 'assets/branding/pournima_wordmark.jpeg',
            caption: 'Roof view',
          ),
        ],
      ),
    );
  }

  @override
  Future<CatalogueResult> createEnquiry({
    required String accessToken,
    required String productId,
    required String messageText,
    String? preferredContactWindow,
  }) async {
    enquiryCalls.add({
      'accessToken': accessToken,
      'productId': productId,
      'messageText': messageText,
    });
    return const CatalogueResult.enquiry(
      'ENQ-00000015',
      message: 'Enquiry submitted',
    );
  }

  @override
  Future<CatalogueResult> listEnquiries({required String accessToken}) async {
    return const CatalogueResult.success(
      enquiries: [
        CatalogueEnquiry(
          enquiryNo: 'ENQ-00000015',
          productEnquiryId: '15',
          productName: 'Rooftop 3kW',
          statusName: 'Open',
          statusCode: 'ENQ_OPEN',
          messageText: 'Need a rooftop quote',
          createdOn: '2026-10-18T12:00:00Z',
        ),
      ],
    );
  }

  @override
  Future<CatalogueResult> updateEnquiry({
    required String accessToken,
    required String productEnquiryId,
    required String action,
    String? note,
  }) async {
    return const CatalogueResult.success(message: 'Enquiry cancelled');
  }

  @override
  void close() {}

  @override
  String? get mediaBaseUrl => null;
}
