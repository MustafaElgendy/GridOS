import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/auth_shared_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

enum LoginAuthenticationResult {
  authenticated,
  invalidCredentials,
  serviceUnavailable,
}

typedef LoginAuthenticator = Future<LoginAuthenticationResult> Function(
  String email,
  String password,
);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authenticate});

  final LoginAuthenticator? authenticate;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _maxFailedAttempts = 5;
  static const _lockoutDuration = Duration(minutes: 5);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Timer? _lockoutTimer;
  Duration _remainingLockout = Duration.zero;
  String? _feedbackMessage;
  _FeedbackType _feedbackType = _FeedbackType.information;
  int _failedAttempts = 0;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  bool get _isLockedOut => _remainingLockout > Duration.zero;

  String get _formattedLockout {
    final seconds = _remainingLockout.inSeconds;
    final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsPart = (seconds % 60).toString().padLeft(2, '0');
    return '$minutesPart:$secondsPart';
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    return null;
  }

  void _showApiPending(String message) {
    setState(() {
      _feedbackMessage = message;
      _feedbackType = _FeedbackType.information;
    });
  }

  Future<void> _submit() async {
    if (_isLockedOut || _isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authenticate = widget.authenticate;
    if (authenticate == null) {
      _showApiPending('Authentication is waiting for the API.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    final result = await authenticate(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      switch (result) {
        case LoginAuthenticationResult.authenticated:
          _failedAttempts = 0;
          _feedbackMessage = 'Login successful.';
          _feedbackType = _FeedbackType.success;
        case LoginAuthenticationResult.invalidCredentials:
          _failedAttempts++;
          _feedbackType = _FeedbackType.error;
          if (_failedAttempts >= _maxFailedAttempts) {
            _remainingLockout = _lockoutDuration;
            _feedbackMessage =
                'Too many attempts. Try again in $_formattedLockout.';
          } else {
            _feedbackMessage =
                'That password isn’t right. Try again, or tap Forgot password.';
          }
        case LoginAuthenticationResult.serviceUnavailable:
          _feedbackMessage =
              'Unable to reach the authentication service. Try again.';
          _feedbackType = _FeedbackType.error;
      }
    });

    if (_isLockedOut) _startLockoutTimer();
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingLockout <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() {
          _remainingLockout = Duration.zero;
          _failedAttempts = 0;
          _feedbackMessage = null;
        });
      } else {
        setState(() {
          _remainingLockout -= const Duration(seconds: 1);
        });
      }
    });
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
              'Welcome back',
              style: AppTextStyles.authHeading,
            ),
            const SizedBox(height: 4),
            const Text(
              'Log in with the email you signed up with.',
              style: AppTextStyles.authDescription,
            ),
            const SizedBox(height: 16),
            AuthGoogleButton(
              key: const ValueKey('login-google'),
              onPressed: () =>
                  _showApiPending('Google sign-in is waiting for the API.'),
            ),
            const SizedBox(height: 14),
            const AuthEmailDivider(),
            const SizedBox(height: 14),
            const AuthFieldLabel('Email'),
            const SizedBox(height: 5),
            TextFormField(
              key: const ValueKey('login-email'),
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
              key: const ValueKey('login-password'),
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
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
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 7),
              Text(
                _feedbackMessage!,
                key: const ValueKey('login-feedback'),
                style: AppTextStyles.authHelper.copyWith(
                  color: switch (_feedbackType) {
                    _FeedbackType.error => AppColors.error,
                    _FeedbackType.information => AppColors.authMuted,
                    _FeedbackType.success => AppColors.authGreen,
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _showApiPending('Password reset is waiting for the API.'),
                style: AppButtonStyles.authInline,
                child: const Text(
                  'Forgot password?',
                  style: AppTextStyles.authLink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('login-submit'),
              onPressed: _isLockedOut || _isSubmitting ? null : _submit,
              style: AppButtonStyles.authPrimaryDisabled,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      _isLockedOut
                          ? 'Try again in $_formattedLockout'
                          : 'Log in',
                    ),
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
                    'New to GridOS? ',
                    style: AppTextStyles.authSmallText,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/sign-up'),
                    style: AppButtonStyles.authInline,
                    child: const Text(
                      'Start free',
                      style: AppTextStyles.authLink,
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

enum _FeedbackType { error, information, success }
