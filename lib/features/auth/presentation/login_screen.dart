import 'dart:async';

import 'package:flutter/material.dart';
import 'package:solar_ui/app/theme_controller.dart';
import 'package:solar_ui/core/api/dropdown_exceptions.dart';
import 'package:solar_ui/core/api/dropdown_models.dart';
import 'package:solar_ui/core/api/dropdown_repository.dart';
import 'package:solar_ui/core/demo/demo_user.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/solar_buttons.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';
import 'package:solar_ui/core/widgets/solar_feedback.dart';
import 'package:solar_ui/core/widgets/solar_form_field.dart';
import 'package:solar_ui/features/auth/auth_api.dart';
import 'package:solar_ui/features/dashboard/presentation/dashboard_shell.dart';
import 'package:solar_ui/features/startup/presentation/splash_screen.dart';

/// Mobile number and PIN gate. The dashboard opens only after a successful login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authApi,
    required this.countries,
    required this.themeController,
    this.postLoginDelay = const Duration(seconds: 6),
    super.key,
  });

  final AuthApi authApi;
  final DropdownRepository countries;
  final ThemeController themeController;
  final Duration postLoginDelay;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  List<DropdownOption> _countries = const [];
  String? _countryId;
  var _loadingCountries = true;
  var _countryError = '';
  var _creatingAccount = false;
  var _submitting = false;
  var _message = '';
  var _messageIsError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCountries());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
      _countryError = '';
    });
    try {
      final list = await widget.countries.load(dropdownCode: 'COUNTRIES');
      if (!mounted) return;
      setState(() {
        _countries = list.options;
        _loadingCountries = false;
        if (list.options.length == 1) {
          _countryId = list.options.single.value;
        }
      });
    } on DropdownTimeoutException catch (error) {
      _showCountryError(error.message);
    } on DropdownApiException catch (error) {
      _showCountryError(error.message);
    } on DropdownTransportException catch (error) {
      _showCountryError(error.message);
    } on Object {
      _showCountryError('The dropdown service could not be reached.');
    }
  }

  void _showCountryError(String message) {
    if (!mounted) return;
    setState(() {
      _loadingCountries = false;
      _countryError = message;
    });
  }

  Future<void> _submit() async {
    final countryId = _countryId;
    final mobile = _mobileController.text.trim();
    final pin = _pinController.text.trim();
    if (countryId == null) {
      _setMessage('Choose a country', isError: true);
      return;
    }
    if (mobile.isEmpty) {
      _setMessage('Enter a valid mobile number', isError: true);
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      _setMessage('PIN must be 4 digits', isError: true);
      return;
    }
    if (_creatingAccount && pin != _confirmPinController.text.trim()) {
      _setMessage('PIN entries do not match', isError: true);
      return;
    }
    if (_creatingAccount && _nameController.text.trim().isEmpty) {
      _setMessage('Enter your name', isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _message = '';
    });

    final result = _creatingAccount
        ? await widget.authApi.register(
            countryId: countryId,
            nationalNumber: mobile,
            fullName: _nameController.text.trim(),
            pin: pin,
          )
        : await widget.authApi.login(
            countryId: countryId,
            nationalNumber: mobile,
            pin: pin,
          );
    if (!mounted) return;

    final user = result.user;
    if (!_creatingAccount && result.isSuccess && user != null) {
      _openDashboard(user);
      return;
    }

    setState(() {
      _submitting = false;
      _messageIsError = !result.isSuccess;
      _message = result.isSuccess
          ? 'Account created. Sign in with your mobile number and PIN.'
          : result.message;
      if (result.isSuccess) {
        _creatingAccount = false;
        _pinController.clear();
        _confirmPinController.clear();
      }
    });
  }

  void _openDashboard(SignedInUser user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => SplashScreen(
          startupDuration: widget.postLoginDelay,
          destinationBuilder: (context) => DashboardShell(
            user: DemoUser.signedIn(
              displayName: user.fullName,
              role: user.roleName,
            ),
            themeController: widget.themeController,
          ),
        ),
      ),
    );
  }

  void _setMessage(String message, {required bool isError}) {
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth < AppSizes.compactBreakpoint
                ? AppSpacing.md
                : AppSpacing.xl;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.lg,
                horizontal,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SolarCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _creatingAccount ? 'Create account' : 'Sign in',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _creatingAccount
                              ? 'Register a mobile number and a 4-digit PIN.'
                              : 'Use your registered mobile number and PIN.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_loadingCountries)
                          const SolarLoadingIndicator(
                            label: 'Loading countries',
                            compact: true,
                          )
                        else if (_countryError.isNotEmpty) ...[
                          Text(
                            _countryError,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SolarSecondaryButton(
                              label: 'Try again',
                              onPressed: _loadCountries,
                            ),
                          ),
                        ] else ...[
                          _countryField(),
                          const SizedBox(height: AppSpacing.md),
                          if (_creatingAccount) ...[
                            SolarTextField(
                              key: const Key('register-name'),
                              label: 'Full name',
                              controller: _nameController,
                              enabled: !_submitting,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          SolarTextField(
                            key: const Key('login-mobile'),
                            label: 'Mobile number',
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            enabled: !_submitting,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SolarTextField(
                            key: const Key('login-pin'),
                            label: 'PIN',
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            helperText: '4 digits',
                            enabled: !_submitting,
                          ),
                          if (_creatingAccount) ...[
                            const SizedBox(height: AppSpacing.md),
                            SolarTextField(
                              key: const Key('register-confirm-pin'),
                              label: 'Confirm PIN',
                              controller: _confirmPinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 4,
                              enabled: !_submitting,
                            ),
                          ],
                          if (_message.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _message,
                              key: const Key('login-message'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _messageIsError
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          SolarPrimaryButton(
                            key: const Key('login-submit'),
                            label: _creatingAccount
                                ? 'Create account'
                                : 'Sign in',
                            expand: true,
                            isLoading: _submitting,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SolarSecondaryButton(
                            key: const Key('login-mode'),
                            label: _creatingAccount
                                ? 'Back to sign in'
                                : 'Create an account',
                            expand: true,
                            onPressed: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _creatingAccount = !_creatingAccount;
                                      _message = '';
                                      _pinController.clear();
                                      _confirmPinController.clear();
                                    });
                                  },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _countryField() {
    return DropdownButtonFormField<String>(
      key: const Key('login-country'),
      initialValue: _countryId,
      decoration: const InputDecoration(labelText: 'Country'),
      items: [
        for (final country in _countries)
          DropdownMenuItem(value: country.value, child: Text(country.label)),
      ],
      onChanged: _submitting
          ? null
          : (value) => setState(() => _countryId = value),
    );
  }
}
