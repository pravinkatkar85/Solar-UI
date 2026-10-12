import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';

class SignedInUser {
  const SignedInUser({
    required this.userId,
    required this.fullName,
    required this.roleName,
    required this.accessToken,
  });

  final String userId;
  final String fullName;
  final String roleName;
  final String accessToken;
}

class AuthResult {
  const AuthResult.success({this.user, this.message = ''}) : isSuccess = true;

  const AuthResult.failure(this.message) : isSuccess = false, user = null;

  final bool isSuccess;
  final String message;
  final SignedInUser? user;
}

abstract interface class AuthApi {
  Future<AuthResult> register({
    required String countryId,
    required String nationalNumber,
    required String fullName,
    required String pin,
  });

  Future<AuthResult> login({
    required String countryId,
    required String nationalNumber,
    required String pin,
  });

  void close();
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi({required this._baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final ApiBaseUrl _baseUrl;
  final http.Client _client;

  @override
  Future<AuthResult> register({
    required String countryId,
    required String nationalNumber,
    required String fullName,
    required String pin,
  }) {
    return _post('/api/auth/register', {
      'country_id': countryId,
      'national_number': nationalNumber,
      'full_name': fullName,
      'pin': pin,
    }, expectUser: false);
  }

  @override
  Future<AuthResult> login({
    required String countryId,
    required String nationalNumber,
    required String pin,
  }) {
    return _post('/api/auth/login', {
      'country_id': countryId,
      'national_number': nationalNumber,
      'pin': pin,
    }, expectUser: true);
  }

  Future<AuthResult> _post(
    String path,
    Map<String, String> body, {
    required bool expectUser,
  }) async {
    try {
      final response = await _client
          .post(
            _baseUrl.value.resolve('${_baseUrl.value.path}$path'),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body),
          )
          .timeout(HttpDropdownClient.defaultTimeout);
      return _read(response.body, expectUser: expectUser);
    } on TimeoutException {
      return const AuthResult.failure('The request timed out. Try again.');
    } on Object {
      return const AuthResult.failure('Sign-in could not be completed.');
    }
  }

  AuthResult _read(String body, {required bool expectUser}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return const AuthResult.failure('Sign-in could not be completed.');
    }
    if (decoded is! Map) {
      return const AuthResult.failure('Sign-in could not be completed.');
    }
    final status = decoded['status'];
    final message = decoded['message'];
    if (message is! String || message.isEmpty) {
      return const AuthResult.failure('Sign-in could not be completed.');
    }
    if (status != 'SUCCESS') {
      return AuthResult.failure(message);
    }
    if (!expectUser) {
      return AuthResult.success(message: message);
    }
    final data = decoded['data'];
    if (data is! Map) {
      return const AuthResult.failure('Sign-in could not be completed.');
    }
    final userId = data['user_id'];
    final fullName = data['full_name'];
    final roleName = data['role_name'];
    final accessToken = data['access_token'];
    if (userId is! String ||
        fullName is! String ||
        fullName.trim().isEmpty ||
        roleName is! String ||
        roleName.trim().isEmpty ||
        accessToken is! String ||
        accessToken.isEmpty) {
      return const AuthResult.failure('Sign-in could not be completed.');
    }
    return AuthResult.success(
      message: message,
      user: SignedInUser(
        userId: userId,
        fullName: fullName.trim(),
        roleName: roleName.trim(),
        accessToken: accessToken,
      ),
    );
  }

  @override
  void close() => _client.close();
}
