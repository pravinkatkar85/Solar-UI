/// Address dropdowns configured in `solar_app.ref_dropdown_config`.
///
/// The chain and parent columns are the seeded metadata:
/// `COUNTRIES` (no parent) → `STATES` (`country_id`) → `DISTRICTS`
/// (`state_id`) → `CITIES` (`district_id`) → `PINCODES` (`city_id`).
///
/// A child request sends the selected parent option `value` as
/// `parent_value`. That value is the id text already returned by
/// `POST /api/dropdowns` (`country_id`, `state_id`, `district_id`, or
/// `city_id`). No identity is assumed.
class AddressDropdownLevel {
  const AddressDropdownLevel({
    required this.dropdownCode,
    required this.label,
    required this.parentDropdownCode,
  });

  /// `ref_dropdown_config.dropdown_code`.
  final String dropdownCode;

  /// Short field label for the form.
  final String label;

  /// `ref_dropdown_config.parent_dropdown_code`. Null for the first level.
  final String? parentDropdownCode;
}

abstract final class AddressDropdowns {
  static const country = AddressDropdownLevel(
    dropdownCode: 'COUNTRIES',
    label: 'Country',
    parentDropdownCode: null,
  );

  static const state = AddressDropdownLevel(
    dropdownCode: 'STATES',
    label: 'State',
    parentDropdownCode: 'COUNTRIES',
  );

  static const district = AddressDropdownLevel(
    dropdownCode: 'DISTRICTS',
    label: 'District',
    parentDropdownCode: 'STATES',
  );

  static const city = AddressDropdownLevel(
    dropdownCode: 'CITIES',
    label: 'City',
    parentDropdownCode: 'DISTRICTS',
  );

  static const pincode = AddressDropdownLevel(
    dropdownCode: 'PINCODES',
    label: 'Pincode',
    parentDropdownCode: 'CITIES',
  );

  static const levels = <AddressDropdownLevel>[
    country,
    state,
    district,
    city,
    pincode,
  ];
}
