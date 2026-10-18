import 'package:flutter/material.dart';
import 'package:solar_ui/core/theme/app_layout.dart';
import 'package:solar_ui/core/widgets/solar_buttons.dart';
import 'package:solar_ui/core/widgets/solar_card.dart';
import 'package:solar_ui/core/widgets/solar_form_field.dart';
import 'package:solar_ui/features/auth/auth_api.dart';

/// Changes the PIN for the signed-in session. The bearer token comes from login.
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({
    required this.authApi,
    required this.accessToken,
    super.key,
  });

  final AuthApi authApi;
  final String accessToken;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  var _hideOld = true;
  var _hideNew = true;
  var _hideConfirm = true;
  var _submitting = false;
  var _message = '';
  var _messageIsError = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final oldPin = _oldController.text.trim();
    final newPin = _newController.text.trim();
    final confirmPin = _confirmController.text.trim();
    if (oldPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      _setMessage('Enter your current PIN, a new PIN, and the confirmation.');
      return;
    }
    if (!_isPin(oldPin) || !_isPin(newPin) || !_isPin(confirmPin)) {
      _setMessage('PIN must be 4 digits');
      return;
    }
    if (newPin != confirmPin) {
      _setMessage('PIN entries do not match');
      return;
    }
    if (widget.accessToken.trim().isEmpty) {
      _setMessage('Sign in again to change your PIN.');
      return;
    }

    setState(() {
      _submitting = true;
      _message = '';
    });
    final result = await widget.authApi.changePin(
      accessToken: widget.accessToken,
      oldPin: oldPin,
      newPin: newPin,
      confirmPin: confirmPin,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _messageIsError = !result.isSuccess;
      _message = result.message;
      if (result.isSuccess) {
        _oldController.clear();
        _newController.clear();
        _confirmController.clear();
      }
    });
  }

  void _setMessage(String message) {
    setState(() {
      _message = message;
      _messageIsError = true;
    });
  }

  bool _isPin(String value) => RegExp(r'^[0-9]{4}$').hasMatch(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change PIN')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
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
                      'Use your current PIN to choose a new 4-digit PIN.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _pinField(
                      keyName: 'change-old-pin',
                      visibilityKey: 'change-old-visibility',
                      label: 'Old PIN',
                      controller: _oldController,
                      hidden: _hideOld,
                      onToggle: () => setState(() => _hideOld = !_hideOld),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _pinField(
                      keyName: 'change-new-pin',
                      visibilityKey: 'change-new-visibility',
                      label: 'New PIN',
                      controller: _newController,
                      hidden: _hideNew,
                      onToggle: () => setState(() => _hideNew = !_hideNew),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _pinField(
                      keyName: 'change-confirm-pin',
                      visibilityKey: 'change-confirm-visibility',
                      label: 'Confirm PIN',
                      controller: _confirmController,
                      hidden: _hideConfirm,
                      onToggle: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                    ),
                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _message,
                        key: const Key('change-message'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _messageIsError
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    SolarPrimaryButton(
                      key: const Key('change-submit'),
                      label: 'Update PIN',
                      expand: true,
                      isLoading: _submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pinField({
    required String keyName,
    required String visibilityKey,
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return SolarTextField(
      key: Key(keyName),
      label: label,
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: hidden,
      maxLength: 4,
      enabled: !_submitting,
      suffixIcon: IconButton(
        key: Key(visibilityKey),
        tooltip: hidden ? 'Show PIN' : 'Hide PIN',
        onPressed: _submitting ? null : onToggle,
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    );
  }
}
