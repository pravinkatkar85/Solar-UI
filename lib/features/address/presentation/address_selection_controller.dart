import 'package:flutter/foundation.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_models.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/features/address/address_dropdowns.dart';

/// One address field while its options are loading, ready, empty, or failed.
class AddressFieldState {
  AddressFieldState(this.level);

  final AddressDropdownLevel level;
  DropdownOption? selected;
  List<DropdownOption> options = const [];
  bool loading = false;
  String? errorMessage;
}

/// Loads the address cascade through [DropdownRepository].
///
/// Country loads first. A child loads only after its parent option is
/// selected, using that option's `value` as `parent_value`. Changing a
/// parent clears every field below it.
class AddressSelectionController extends ChangeNotifier {
  AddressSelectionController({required this._repository})
    : fields = [
        for (final level in AddressDropdowns.levels) AddressFieldState(level),
      ];

  final DropdownRepository _repository;
  final List<AddressFieldState> fields;
  final List<int> _tokens = List<int>.filled(AddressDropdowns.levels.length, 0);
  var _disposed = false;

  Future<void> loadInitial() => _fetch(0);

  /// Selects an option already present in this field and loads the next one.
  Future<void> select(int index, String value) async {
    final field = fields[index];
    DropdownOption? option;
    for (final candidate in field.options) {
      if (candidate.value == value) {
        option = candidate;
        break;
      }
    }
    if (option == null || field.selected?.value == value) return;

    field.selected = option;
    _clearAfter(index);
    _notify();
    if (index + 1 < fields.length) {
      await _fetch(index + 1);
    }
  }

  Future<void> retry(int index) => _fetch(index);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _clearAfter(int index) {
    for (var i = index + 1; i < fields.length; i++) {
      _tokens[i]++;
      final field = fields[i];
      field.selected = null;
      field.options = const [];
      field.loading = false;
      field.errorMessage = null;
    }
  }

  Future<void> _fetch(int index) async {
    final parent = index == 0 ? null : fields[index - 1].selected?.value;
    if (index > 0 && parent == null) return;

    final token = ++_tokens[index];
    final field = fields[index];
    field
      ..loading = true
      ..errorMessage = null
      ..options = const []
      ..selected = null;
    _notify();

    try {
      final list = await _repository.load(
        dropdownCode: field.level.dropdownCode,
        parentValue: parent,
      );
      if (_disposed || token != _tokens[index]) return;
      field
        ..loading = false
        ..errorMessage = null
        ..options = list.options
        ..selected = null;
      _notify();
    } on DropdownTimeoutException catch (error) {
      _fail(index, token, error.message);
    } on DropdownApiException catch (error) {
      _fail(index, token, error.message);
    } on DropdownTransportException catch (error) {
      _fail(index, token, error.message);
    } on Object {
      _fail(index, token, const DropdownTransportException().message);
    }
  }

  void _fail(int index, int token, String message) {
    if (_disposed || token != _tokens[index]) return;
    final field = fields[index];
    field
      ..loading = false
      ..errorMessage = message
      ..options = const []
      ..selected = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
