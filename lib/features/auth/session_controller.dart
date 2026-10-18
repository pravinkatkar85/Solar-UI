import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_ui/features/auth/auth_api.dart';

class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.displayName,
    required this.roleName,
  });

  final String accessToken;
  final String displayName;
  final String roleName;
}

abstract interface class SessionStore {
  Future<StoredSession?> read();

  Future<void> write(StoredSession session);

  Future<void> clear();
}

class SharedPreferencesSessionStore implements SessionStore {
  static const tokenKey = 'session_access_token';
  static const nameKey = 'session_display_name';
  static const roleKey = 'session_role_name';

  @override
  Future<StoredSession?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(tokenKey);
    final name = preferences.getString(nameKey);
    final role = preferences.getString(roleKey);
    if (token == null || token.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    return StoredSession(
      accessToken: token,
      displayName: name,
      roleName: role ?? '',
    );
  }

  @override
  Future<void> write(StoredSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(tokenKey, session.accessToken);
    await preferences.setString(nameKey, session.displayName);
    await preferences.setString(roleKey, session.roleName);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(tokenKey);
    await preferences.remove(nameKey);
    await preferences.remove(roleKey);
  }
}

/// True when the token is missing, not a JWT, or its exp claim is in the past.
/// This does not verify the signature. The API still verifies the bearer token.
bool sessionTokenExpired(String token, {DateTime? now}) {
  final parts = token.split('.');
  if (parts.length != 3 || parts.any((part) => part.isEmpty)) return true;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return true;
    final exp = payload['exp'];
    if (exp is! num) return true;
    final clock = now ?? DateTime.now();
    return exp * 1000 <= clock.millisecondsSinceEpoch;
  } on FormatException {
    return true;
  }
}

class SessionController extends ChangeNotifier {
  SessionController(this._store);

  final SessionStore _store;
  var loaded = false;
  String? accessToken;
  String displayName = 'Guest';
  String roleName = 'Visitor';

  bool get isSignedIn {
    final token = accessToken;
    return token != null && token.isNotEmpty && !sessionTokenExpired(token);
  }

  Future<void> load() async {
    final saved = await _store.read();
    if (saved != null && !sessionTokenExpired(saved.accessToken)) {
      accessToken = saved.accessToken;
      displayName = saved.displayName;
      roleName = saved.roleName;
    } else {
      accessToken = null;
      displayName = 'Guest';
      roleName = 'Visitor';
      if (saved != null) await _store.clear();
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> signIn(SignedInUser user) async {
    accessToken = user.accessToken;
    displayName = user.fullName;
    roleName = user.roleName;
    await _store.write(
      StoredSession(
        accessToken: user.accessToken,
        displayName: user.fullName,
        roleName: user.roleName,
      ),
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    accessToken = null;
    displayName = 'Guest';
    roleName = 'Visitor';
    notifyListeners();
    await _store.clear();
  }
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    required SessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static SessionController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
  }
}
