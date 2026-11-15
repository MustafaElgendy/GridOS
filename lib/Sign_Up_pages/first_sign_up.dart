import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/workspace_page.dart';
import 'package:grid_os/Sign_Up_pages/auth_shared_widgets.dart';
import 'package:grid_os/Sign_Up_pages/sign_up_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class FirstSignUpPage extends StatefulWidget {
  const FirstSignUpPage({super.key, this.submitSignup});

  final SignUpSubmitter? submitSignup;

  @override
  State<FirstSignUpPage> createState() => _FirstSignUpPageState();
}

class _FirstSignUpPageState extends State<FirstSignUpPage> {
  static final _uppercasePattern = RegExp('[A-Z]');
  static final _lowercasePattern = RegExp('[a-z]');
  static final _numberPattern = RegExp('[0-9]');
  static final _symbolPattern = RegExp(r'[^A-Za-z0-9]');

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => WorkspacePage(
          setup: StartupSetup(ownerName: '', workspaceName: ''),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          submitSignup: widget.submitSignup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Start free', style: AppTextStyles.authHeading),
            const SizedBox(height: 4),
            const Text(
              'Run your whole workspace from one place. No card needed.',
              style: AppTextStyles.authDescription,
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: validateEmailAddress,
              decoration: AppInputStyles.authentication(
                hintText: 'you@example.com',
              ),
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Password'),
            const SizedBox(height: 5),
            TextFormField(
              key: const ValueKey('signup-password'),
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              autocorrect: false,
              validator: _validatePassword,
              onFieldSubmitted: (_) => _submit(),
              decoration: AppInputStyles.authentication(
                suffixIcon: TextButton(
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  style: AppButtonStyles.authToggle,
                  child: Text(_isPasswordVisible ? 'Hide' : 'Show'),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Use 8+ characters with uppercase, lowercase, a number, and a symbol.',
              style: AppTextStyles.authHelper,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('create-account'),
              onPressed: _submit,
              child: const Text('Create account'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Authentication is waiting for the backend API.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authHelper,
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: AppTextStyles.authSmallText,
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    style: AppButtonStyles.authInline,
                    child: const Text('Log in', style: AppTextStyles.authLink),
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
