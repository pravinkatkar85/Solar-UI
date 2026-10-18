import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/features/auth/auth_api.dart';
import 'package:solar_ui/features/auth/presentation/login_screen.dart';
import 'package:solar_ui/features/auth/session_controller.dart';
import 'package:solar_ui/features/catalogue/catalogue_api.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_shell.dart';
import 'package:solar_ui/features/startup/presentation/splash_screen.dart';

/// Splash while the saved session is read, then the home dashboard.
class AppLaunch extends StatefulWidget {
  const AppLaunch({
    required this.session,
    required this.authApi,
    required this.catalogueApi,
    required this.countries,
    required this.themeController,
    this.launchDuration = const Duration(milliseconds: 700),
    this.postLoginDelay = const Duration(seconds: 6),
    super.key,
  });

  final SessionController session;
  final AuthApi authApi;
  final CatalogueApi catalogueApi;
  final DropdownRepository countries;
  final ThemeController themeController;
  final Duration launchDuration;
  final Duration postLoginDelay;

  @override
  State<AppLaunch> createState() => _AppLaunchState();
}

class _AppLaunchState extends State<AppLaunch> {
  @override
  void initState() {
    super.initState();
    widget.session.load();
  }

  Future<void> _signIn(BuildContext navigatorContext) async {
    final user = await Navigator.of(navigatorContext).push<SignedInUser>(
      MaterialPageRoute<SignedInUser>(
        builder: (context) => LoginScreen(
          authApi: widget.authApi,
          countries: widget.countries,
          themeController: widget.themeController,
          postLoginDelay: widget.postLoginDelay,
          onSignedIn: (signedIn) => Navigator.of(context).pop(signedIn),
        ),
      ),
    );
    if (user == null) return;
    await widget.session.signIn(user);
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(
      startupDuration: widget.launchDuration,
      destinationBuilder: (context) => ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          if (!widget.session.loaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final signedIn = widget.session.isSignedIn;
          return DashboardShell(
            user: signedIn
                ? DemoUser.signedIn(
                    displayName: widget.session.displayName,
                    role: widget.session.roleName,
                  )
                : const DemoUser(
                    displayName: 'Guest',
                    role: 'Visitor',
                    isDevelopmentOnly: false,
                  ),
            themeController: widget.themeController,
            authApi: widget.authApi,
            catalogueApi: widget.catalogueApi,
            accessToken: signedIn ? widget.session.accessToken : null,
            onSignIn: signedIn ? null : () => _signIn(context),
            onSignOut: signedIn ? widget.session.signOut : null,
          );
        },
      ),
    );
  }
}
