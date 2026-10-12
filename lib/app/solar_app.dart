import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/api/api_base_url.dart';
import 'package:solar_ui/core/api/dropdown_cache.dart';
import 'package:solar_ui/core/api/dropdown_client.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/branding/company_profile.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/theme/app_theme.dart';
import 'package:solar_ui/features/auth/auth_api.dart';
import 'package:solar_ui/features/auth/presentation/login_screen.dart';

/// Root application configuration.
///
/// Sign-in is the gate. After a valid PIN, the existing splash runs and then
/// opens the existing dashboard.
class SolarApp extends StatelessWidget {
  const SolarApp({
    required this.themeController,
    this.startupDuration = const Duration(seconds: 6),
    super.key,
  });

  final ThemeController themeController;
  final Duration startupDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: CompanyProfile.productName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 240),
          home: _LoginHost(
            themeController: themeController,
            postLoginDelay: startupDuration,
          ),
        );
      },
    );
  }
}

class _LoginHost extends StatefulWidget {
  const _LoginHost({
    required this.themeController,
    required this.postLoginDelay,
  });

  final ThemeController themeController;
  final Duration postLoginDelay;

  @override
  State<_LoginHost> createState() => _LoginHostState();
}

class _LoginHostState extends State<_LoginHost> {
  HttpDropdownClient? _dropdownClient;
  HttpAuthApi? _authApi;
  DropdownRepository? _countries;
  String? _setupError;

  @override
  void initState() {
    super.initState();
    try {
      final baseUrl = ApiBaseUrl.fromEnvironment();
      final dropdownClient = HttpDropdownClient();
      _dropdownClient = dropdownClient;
      _authApi = HttpAuthApi(baseUrl: baseUrl);
      _countries = DropdownRepository(
        baseUrl: baseUrl,
        transport: dropdownClient,
        cache: SharedPreferencesDropdownCacheStore(),
      );
    } on InvalidApiBaseUrlException catch (error) {
      _setupError = error.message;
    }
  }

  @override
  void dispose() {
    _authApi?.close();
    _dropdownClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _setupError;
    if (message != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return LoginScreen(
      authApi: _authApi!,
      countries: _countries!,
      themeController: widget.themeController,
      postLoginDelay: widget.postLoginDelay,
    );
  }
}
