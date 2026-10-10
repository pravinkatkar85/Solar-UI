import 'package:flutter/foundation.dart';

/// Development-only identity used until authentication is implemented.
@immutable
class DemoUser {
  const DemoUser({
    required this.displayName,
    required this.role,
    required this.isDevelopmentOnly,
  });

  final String displayName;
  final String role;
  final bool isDevelopmentOnly;

  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    return words.map((word) => word[0].toUpperCase()).join();
  }
}

abstract final class DemoUsers {
  static const current = DemoUser(
    displayName: 'Rahul Sharma',
    role: 'Service Manager',
    isDevelopmentOnly: true,
  );
}
