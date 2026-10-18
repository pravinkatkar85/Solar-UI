import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';

class CatalogueProduct {
  const CatalogueProduct({
    required this.productId,
    required this.productName,
    required this.listPrice,
    required this.currencyCode,
    this.categoryName = '',
    this.shortDescription = '',
    this.longDescription = '',
    this.thumbnailUrl = '',
    this.media = const [],
    this.specs = const {},
    this.sortOrder = 0,
  });

  final String productId;
  final String productName;
  final String listPrice;
  final String currencyCode;
  final String categoryName;
  final String shortDescription;
  final String longDescription;
  final String thumbnailUrl;
  final List<CatalogueMedia> media;
  final Map<String, String> specs;
  final int sortOrder;

  factory CatalogueProduct.fromJson(Map<dynamic, dynamic> json) {
    final media = json['media'];
    return CatalogueProduct(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      listPrice: json['list_price']?.toString() ?? '',
      currencyCode: json['currency_code']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      longDescription: json['long_description']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      specs: _readSpecs(json['specs_json']),
      sortOrder: _readSortOrder(json['sort_order']),
      media: media is List
          ? media
                .whereType<Map>()
                .map(
                  (item) => CatalogueMedia(
                    mediaType: item['media_type']?.toString() ?? '',
                    fileUrl: item['file_url']?.toString() ?? '',
                    caption: item['caption']?.toString() ?? '',
                  ),
                )
                .toList()
          : const [],
    );
  }
}

Map<String, String> _readSpecs(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.key.toString().isNotEmpty && entry.value != null)
        entry.key.toString(): entry.value.toString(),
  };
}

int _readSortOrder(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

class CatalogueMedia {
  const CatalogueMedia({
    required this.mediaType,
    required this.fileUrl,
    required this.caption,
  });

  final String mediaType;
  final String fileUrl;
  final String caption;
}

class CatalogueEnquiry {
  const CatalogueEnquiry({
    required this.enquiryNo,
    required this.productName,
    required this.statusName,
    required this.messageText,
    this.productId = '',
    this.productEnquiryId = '',
    this.statusCode = '',
    this.agentName = '',
    this.agentMobile = '',
    this.preferredContactWindow = '',
    this.createdOn = '',
  });

  final String enquiryNo;
  final String productId;
  final String productEnquiryId;
  final String productName;
  final String statusName;
  final String statusCode;
  final String agentName;
  final String agentMobile;
  final String messageText;
  final String preferredContactWindow;
  final String createdOn;

  factory CatalogueEnquiry.fromJson(Map<dynamic, dynamic> json) {
    return CatalogueEnquiry(
      enquiryNo: json['enquiry_no']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productEnquiryId: json['product_enquiry_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      statusName: json['status_name']?.toString() ?? '',
      statusCode: json['status_code']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? '',
      agentMobile: json['agent_mobile']?.toString() ?? '',
      messageText: json['message_text']?.toString() ?? '',
      preferredContactWindow:
          json['preferred_contact_window']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
    );
  }
}

class CatalogueResult {
  const CatalogueResult.success({
    this.products,
    this.product,
    this.enquiries,
    this.message = '',
  }) : isSuccess = true,
       enquiryNo = '';

  const CatalogueResult.enquiry(this.enquiryNo, {this.message = ''})
    : isSuccess = true,
      products = null,
      product = null,
      enquiries = null;

  const CatalogueResult.failure(this.message)
    : isSuccess = false,
      products = null,
      product = null,
      enquiries = null,
      enquiryNo = '';

  final bool isSuccess;
  final String message;
  final List<CatalogueProduct>? products;
  final CatalogueProduct? product;
  final List<CatalogueEnquiry>? enquiries;
  final String enquiryNo;
}

abstract interface class CatalogueApi {
  Future<CatalogueResult> listProducts();

  Future<CatalogueResult> productDetail(String productId);

  Future<CatalogueResult> createEnquiry({
    required String accessToken,
    required String productId,
    required String messageText,
    String? preferredContactWindow,
  });

  Future<CatalogueResult> listEnquiries({required String accessToken});

  Future<CatalogueResult> updateEnquiry({
    required String accessToken,
    required String productEnquiryId,
    required String action,
    String? note,
  });

  void close();

  /// API origin used to load image paths stored on the product.
  String? get mediaBaseUrl;
}

class HttpCatalogueApi implements CatalogueApi {
  HttpCatalogueApi({required this._baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final ApiBaseUrl _baseUrl;
  final http.Client _client;

  @override
  String? get mediaBaseUrl {
    final base = _baseUrl.value;
    final text = base.toString();
    return text.endsWith('/') ? text.substring(0, text.length - 1) : text;
  }

  @override
  Future<CatalogueResult> listProducts() {
    return _post('/api/catalogue/products', const {});
  }

  @override
  Future<CatalogueResult> productDetail(String productId) {
    return _post('/api/catalogue/products', {'product_id': productId});
  }

  @override
  Future<CatalogueResult> createEnquiry({
    required String accessToken,
    required String productId,
    required String messageText,
    String? preferredContactWindow,
  }) async {
    if (accessToken.trim().isEmpty) {
      return const CatalogueResult.failure('Sign in to send an enquiry.');
    }
    final body = <String, String>{
      'product_id': productId,
      'message_text': messageText,
    };
    final window = preferredContactWindow?.trim() ?? '';
    if (window.isNotEmpty) body['preferred_contact_window'] = window;
    return _post(
      '/api/catalogue/enquiries',
      body,
      accessToken: accessToken,
      kind: _CatalogueCall.enquiry,
    );
  }

  @override
  Future<CatalogueResult> listEnquiries({required String accessToken}) {
    if (accessToken.trim().isEmpty) {
      return Future.value(
        const CatalogueResult.failure('Sign in to view your enquiries.'),
      );
    }
    return _post(
      '/api/catalogue/enquiries/list',
      const {},
      accessToken: accessToken,
      kind: _CatalogueCall.enquiries,
    );
  }

  @override
  Future<CatalogueResult> updateEnquiry({
    required String accessToken,
    required String productEnquiryId,
    required String action,
    String? note,
  }) {
    if (accessToken.trim().isEmpty) {
      return Future.value(
        const CatalogueResult.failure('Sign in to update an enquiry.'),
      );
    }
    final body = <String, String>{
      'product_enquiry_id': productEnquiryId,
      'action': action,
    };
    final trimmed = note?.trim() ?? '';
    if (trimmed.isNotEmpty) body['note'] = trimmed;
    return _post(
      '/api/catalogue/enquiries/action',
      body,
      accessToken: accessToken,
      kind: _CatalogueCall.action,
    );
  }

  Future<CatalogueResult> _post(
    String path,
    Map<String, String> body, {
    String? accessToken,
    _CatalogueCall kind = _CatalogueCall.products,
  }) async {
    try {
      final headers = <String, String>{
        'accept': 'application/json',
        'content-type': 'application/json; charset=utf-8',
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['authorization'] = 'Bearer $accessToken';
      }
      final response = await _client
          .post(
            _baseUrl.value.resolve('${_baseUrl.value.path}$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(HttpDropdownClient.defaultTimeout);
      return _read(response.body, kind: kind);
    } on TimeoutException {
      return const CatalogueResult.failure('The request timed out. Try again.');
    } on Object {
      return CatalogueResult.failure(_fallback(kind));
    }
  }

  CatalogueResult _read(String body, {required _CatalogueCall kind}) {
    final fallback = _fallback(kind);
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return CatalogueResult.failure(fallback);
    }
    if (decoded is! Map) return CatalogueResult.failure(fallback);
    final message = decoded['message'];
    if (message is! String || message.isEmpty) {
      return CatalogueResult.failure(fallback);
    }
    if (decoded['status'] != 'SUCCESS') {
      return CatalogueResult.failure(message);
    }
    final data = decoded['data'];
    if (data is! Map) return CatalogueResult.failure(fallback);
    if (kind == _CatalogueCall.enquiry) {
      final enquiryNo = data['enquiry_no'];
      if (enquiryNo is! String || enquiryNo.isEmpty) {
        return CatalogueResult.failure(fallback);
      }
      return CatalogueResult.enquiry(enquiryNo, message: message);
    }
    if (kind == _CatalogueCall.action) {
      return CatalogueResult.success(message: message);
    }
    if (kind == _CatalogueCall.enquiries) {
      final enquiries = data['enquiries'];
      if (enquiries is! List) return CatalogueResult.failure(fallback);
      return CatalogueResult.success(
        enquiries: enquiries
            .whereType<Map>()
            .map(CatalogueEnquiry.fromJson)
            .where((item) => item.enquiryNo.isNotEmpty)
            .toList(),
        message: message,
      );
    }
    if (data['product_id'] != null) {
      return CatalogueResult.success(
        product: CatalogueProduct.fromJson(data),
        message: message,
      );
    }
    final products = data['products'];
    if (products is! List) return CatalogueResult.failure(fallback);
    return CatalogueResult.success(
      products: products
          .whereType<Map>()
          .map(CatalogueProduct.fromJson)
          .where((product) => product.productId.isNotEmpty)
          .toList(),
      message: message,
    );
  }

  @override
  void close() => _client.close();
}

enum _CatalogueCall { products, enquiry, enquiries, action }

String _fallback(_CatalogueCall kind) {
  return switch (kind) {
    _CatalogueCall.enquiry => 'Enquiry could not be submitted.',
    _CatalogueCall.enquiries => 'Enquiries could not be loaded.',
    _CatalogueCall.action => 'Enquiry could not be updated.',
    _CatalogueCall.products => 'Products could not be loaded.',
  };
}
