import 'package:solar_ui/core/api/dropdown_exceptions.dart';

/// One option from `POST /api/dropdowns`.
class DropdownOption {
  const DropdownOption({required this.value, required this.label});

  /// Stored id, as text. For reference data this is `ref_data_id`.
  final String value;

  /// Text shown to the user.
  final String label;

  factory DropdownOption.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    final label = json['label'];
    if (value is! String ||
        label is! String ||
        value.isEmpty ||
        label.isEmpty) {
      throw const DropdownTransportException(
        'The server response could not be read.',
      );
    }
    return DropdownOption(value: value, label: label);
  }

  Map<String, String> toJson() => {'value': value, 'label': label};
}

/// A successful dropdown payload from the API.
class DropdownList {
  const DropdownList({
    required this.dropdownCode,
    required this.cacheTtlSeconds,
    required this.options,
  });

  final String dropdownCode;
  final int cacheTtlSeconds;
  final List<DropdownOption> options;

  bool get isEmpty => options.isEmpty;

  factory DropdownList.fromData(Map<String, dynamic> json) {
    final dropdownCode = json['dropdown_code'];
    final cacheTtlSeconds = json['cache_ttl_seconds'];
    final options = json['options'];
    if (dropdownCode is! String ||
        dropdownCode.isEmpty ||
        cacheTtlSeconds is! int ||
        cacheTtlSeconds < 0 ||
        options is! List) {
      throw const DropdownTransportException(
        'The server response could not be read.',
      );
    }

    return DropdownList(
      dropdownCode: dropdownCode,
      cacheTtlSeconds: cacheTtlSeconds,
      options: [for (final option in options) _optionFromJson(option)],
    );
  }

  static DropdownOption _optionFromJson(Object? option) {
    if (option is Map<String, dynamic>) {
      return DropdownOption.fromJson(option);
    }
    if (option is Map) {
      return DropdownOption.fromJson(Map<String, dynamic>.from(option));
    }
    throw const DropdownTransportException(
      'The server response could not be read.',
    );
  }

  Map<String, Object> toJson() => {
    'dropdown_code': dropdownCode,
    'cache_ttl_seconds': cacheTtlSeconds,
    'options': [for (final option in options) option.toJson()],
  };
}
