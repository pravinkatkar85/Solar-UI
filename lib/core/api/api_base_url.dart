import 'package:solar_ui/core/api/dropdown_exceptions.dart';

/// Address of the Solar API, supplied at build or run time.
///
/// There is no built-in server address. The same URL is not valid on every
/// platform, so pass one with `--dart-define=API_BASE_URL=...`:
///
/// * Android emulator: `http://10.0.2.2:3000`
/// * Flutter web on this computer: `http://localhost:3000`
/// * Physical device: `http://<this-computer-lan-address>:3000`
///
/// The API process must be listening on an interface that device can reach.
/// A browser also needs the API to allow that web origin. This app does not
/// send database credentials.
class ApiBaseUrl {
  const ApiBaseUrl._(this.value);

  static const environmentKey = 'API_BASE_URL';

  /// Base address without a trailing slash, for example `http://localhost:3000`.
  final Uri value;

  /// Reads [environmentKey]. An empty value means the define was not passed.
  factory ApiBaseUrl.fromEnvironment() {
    const raw = String.fromEnvironment(environmentKey);
    return ApiBaseUrl.parse(raw);
  }

  factory ApiBaseUrl.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const InvalidApiBaseUrlException(
        'API_BASE_URL is not set. Pass --dart-define=API_BASE_URL=... '
        'Use http://10.0.2.2:3000 on the Android emulator, '
        'http://localhost:3000 for Flutter web, or the computer LAN address '
        'from a physical device.',
      );
    }

    final parsed = Uri.tryParse(trimmed);
    final scheme = parsed?.scheme.toLowerCase();
    final hasSupportedScheme = scheme == 'http' || scheme == 'https';
    if (parsed == null ||
        !parsed.hasAuthority ||
        !hasSupportedScheme ||
        parsed.host.isEmpty) {
      throw const InvalidApiBaseUrlException(
        'API_BASE_URL must be an http or https address without a username or password.',
      );
    }
    if (parsed.userInfo.isNotEmpty) {
      throw const InvalidApiBaseUrlException(
        'API_BASE_URL must be an http or https address without a username or password.',
      );
    }

    final path = parsed.path.endsWith('/')
        ? parsed.path.substring(0, parsed.path.length - 1)
        : parsed.path;
    return ApiBaseUrl._(parsed.replace(path: path));
  }

  /// `POST` target for the dropdown endpoint.
  Uri get dropdownEndpoint => value.resolve('${value.path}/api/dropdowns');
}
