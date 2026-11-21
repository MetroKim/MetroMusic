import 'package:breezze_design_system/breezze_design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_session.dart';
import '../../widgets/bz_brand_icons.dart';

/// Auth screen — login + register in one premium glass card, wired to
/// the real backend session controller.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _registerMode = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(authSessionProvider.notifier);
    if (_registerMode) {
      await controller.register(
        _email.text.trim(),
        _password.text,
        displayName: _displayName.text.trim().isEmpty
            ? null
            : _displayName.text.trim(),
      );
    } else {
      await controller.login(_email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authSessionProvider);
    final busy = auth is AuthSigningIn;
    final error = auth is AuthError ? auth.code : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BzRibbonLogo(width: 120, color: theme.bzText1),
                  const SizedBox(height: 12),
                  Text(
                    _registerMode ? 'Create your account' : 'Welcome back',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Free. Every platform. One line.',
                    style: TextStyle(fontSize: BzType.body, color: theme.bzText2),
                  ),
                  const SizedBox(height: 32),
                  BzGlassContainer(
                    radius: BzRadius.card,
                    blur: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_registerMode) ...[
                            _field(
                              controller: _displayName,
                              hint: 'Display name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _field(
                            controller: _email,
                            hint: 'Email',
                            icon: Icons.mail_outline,
                            keyboard: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _password,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),
                          const SizedBox(height: 20),
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorText(error),
                                style: TextStyle(
                                    fontSize: BzType.footnote,
                                    color: theme.bzError),
                              ),
                            ),
                          _SubmitButton(
                            label: _registerMode ? 'Sign up' : 'Log in',
                            busy: busy,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _registerMode = !_registerMode),
                    child: Text(
                      _registerMode
                          ? 'Have an account? Log in'
                          : 'New here? Create an account',
                      style: TextStyle(color: theme.bzText2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _errorText(String code) {
    switch (code) {
      case 'EMAIL_TAKEN':
        return 'That email is already registered.';
      case 'INVALID_CREDENTIALS':
        return 'Wrong email or password.';
      case 'NETWORK_ERROR':
        return 'Cannot reach Breezze. Check your connection.';
      default:
        return 'Something went wrong. Try again.';
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.bzSurface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BzRadius.input),
          borderSide: BorderSide(color: theme.bzSeparator),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: busy ? null : onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.bzText1,
          borderRadius: BorderRadius.circular(BzRadius.button),
        ),
        child: Center(
          child: busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.bzBackground,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: BzType.subheadline,
                    fontWeight: FontWeight.w600,
                    color: theme.bzBackground,
                  ),
                ),
        ),
      ),
    );
  }
}
