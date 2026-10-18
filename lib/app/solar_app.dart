import 'package:flutter/material.dart';
import 'package:solar_ui/app/app_launch.dart';
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
import 'package:solar_ui/features/auth/session_controller.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';

/// Root application configuration.
///
/// Launch checks the saved session, then opens the home dashboard as a guest
/// or as the signed-in user. Sign-in is available from that dashboard.
class SolarApp extends StatefulWidget {
  const SolarApp({
    required this.themeController,
    this.startupDuration = const Duration(seconds: 6),
    super.key,
  });

  final ThemeController themeController;
  final Duration startupDuration;

  @override
  State<SolarApp> createState() => _SolarAppState();
}

class _SolarAppState extends State<SolarApp> {
  HttpAuthApi? _authApi;
  HttpCatalogueApi? _catalogueApi;
  HttpDropdownClient? _dropdownClient;
  DropdownRepository? _countries;
  ApiBaseUrl? _baseUrl;
  String? _setupError;
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    _session = SessionController(SharedPreferencesSessionStore());
    final dropdownClient = HttpDropdownClient();
    _dropdownClient = dropdownClient;
    try {
      final baseUrl = ApiBaseUrl.fromEnvironment();
      _baseUrl = baseUrl;
      _authApi = HttpAuthApi(baseUrl: baseUrl);
      _catalogueApi = HttpCatalogueApi(baseUrl: baseUrl);
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
    _catalogueApi?.close();
    _dropdownClient?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupError = _setupError;
    final authApi = _authApi;
    final catalogueApi = _catalogueApi;
    final countries = _countries;
    final baseUrl = _baseUrl;
    return AnimatedBuilder(
      animation: widget.themeController,
      builder: (context, _) {
        return MaterialApp(
          title: CompanyProfile.productName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: widget.themeController.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 240),
          builder: (context, child) => SessionScope(
            controller: _session,
            child: child ?? const SizedBox.shrink(),
          ),
          home:
              setupError != null ||
                  authApi == null ||
                  catalogueApi == null ||
                  countries == null ||
                  baseUrl == null
              ? _SetupMessage(
                  message: setupError ?? 'Sign-in could not be started.',
                )
              : _LoginHost(
                  authApi: authApi,
                  catalogueApi: catalogueApi,
                  countries: countries,
                  themeController: widget.themeController,
                  postLoginDelay: widget.startupDuration,
                  session: _session,
                ),
        );
      },
    );
  }
}

class _SetupMessage extends StatelessWidget {
  const _SetupMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _LoginHost extends StatefulWidget {
  const _LoginHost({
    required this.authApi,
    required this.catalogueApi,
    required this.countries,
    required this.themeController,
    required this.postLoginDelay,
    required this.session,
  });

  final HttpAuthApi authApi;
  final HttpCatalogueApi catalogueApi;
  final DropdownRepository countries;
  final ThemeController themeController;
  final Duration postLoginDelay;
  final SessionController session;

  @override
  State<_LoginHost> createState() => _LoginHostState();
}

class _LoginHostState extends State<_LoginHost> {
  @override
  Widget build(BuildContext context) {
    return AppLaunch(
      session: widget.session,
      authApi: widget.authApi,
      catalogueApi: widget.catalogueApi,
      countries: widget.countries,
      themeController: widget.themeController,
      postLoginDelay: widget.postLoginDelay,
    );
  }
}
