import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/auth_shared_widgets.dart';

class FirstSignUpPage extends StatefulWidget {
  const FirstSignUpPage({super.key});

  @override
  State<FirstSignUpPage> createState() => _FirstSignUpPageState();
}

class _FirstSignUpPageState extends State<FirstSignUpPage> {
  static final _uppercasePattern = RegExp('[A-Z]');
  static final _lowercasePattern = RegExp('[a-z]');
  static final _numberPattern = RegExp('[0-9]');
  static final _symbolPattern = RegExp(r'[^A-Za-z0-9]');

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Use at least 8 characters.';
    if (!_uppercasePattern.hasMatch(password) ||
        !_lowercasePattern.hasMatch(password) ||
        !_numberPattern.hasMatch(password) ||
        !_symbolPattern.hasMatch(password)) {
      return 'Include uppercase, lowercase, a number, and a symbol.';
    }
    return null;
  }

  void _showApiPendingMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Authentication will be available when the API is connected.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _showApiPendingMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Start free',
              style: TextStyle(
                color: AuthColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Run your whole workspace from one place. No card needed.',
              style: TextStyle(
                color: AuthColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            AuthGoogleButton(
              key: const ValueKey('google-sign-in'),
              onPressed: _showApiPendingMessage,
            ),
            const SizedBox(height: 14),
            const AuthEmailDivider(),
            const SizedBox(height: 14),
            const AuthFieldLabel('Email'),
            const SizedBox(height: 5),
            TextFormField(
              key: const ValueKey('signup-email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: validateEmailAddress,
              decoration: authInputDecoration(hintText: 'you@example.com'),
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Password'),
            const SizedBox(height: 5),
            TextFormField(
              key: const ValueKey('signup-password'),
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              validator: _validatePassword,
              onFieldSubmitted: (_) => _submit(),
              decoration: authInputDecoration(
                suffixIcon: TextButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AuthColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(_isPasswordVisible ? 'Hide' : 'Show'),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Use 8+ characters with uppercase, lowercase, a number, and a symbol.',
              style: TextStyle(
                color: AuthColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('create-account'),
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AuthColors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Create account'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Authentication is waiting for the backend API.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AuthColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AuthColors.muted, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AuthColors.green,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
