/// The API base URL was missing or is not a plain http(s) address.
class InvalidApiBaseUrlException implements Exception {
  const InvalidApiBaseUrlException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The dropdown request took longer than the allowed timeout.
class DropdownTimeoutException implements Exception {
  const DropdownTimeoutException([
    this.message = 'The request timed out. Try again.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// The device could not reach the API, or the response was not the JSON contract.
class DropdownTransportException implements Exception {
  const DropdownTransportException([
    this.message = 'The dropdown service could not be reached.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// The API returned its JSON error contract (`status`, `code`, `message`, `data`).
class DropdownApiException implements Exception {
  const DropdownApiException({required this.message, required this.code});

  final String message;
  final int code;

  @override
  String toString() => message;
}
