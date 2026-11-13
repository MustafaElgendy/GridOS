import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/auth_shared_widgets.dart';
import 'package:grid_os/Sign_Up_pages/sign_up_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class AlmostTherePage extends StatefulWidget {
  const AlmostTherePage({
    super.key,
    required this.email,
    required this.password,
    this.submitSignup,
  });

  final String email;
  final String password;
  final SignUpSubmitter? submitSignup;

  @override
  State<AlmostTherePage> createState() => _AlmostTherePageState();
}

class _AlmostTherePageState extends State<AlmostTherePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _workspaceController = TextEditingController();

  String? _feedbackMessage;
  _FeedbackType _feedbackType = _FeedbackType.information;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) {
      return;
    }

    final submitSignup = widget.submitSignup;
    if (submitSignup == null) {
      setState(() {
        _feedbackMessage = 'Account setup is waiting for the API.';
        _feedbackType = _FeedbackType.information;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
    });

    final result = await submitSignup(
      SignUpRequest(
        email: widget.email,
        password: widget.password,
        fullName: _nameController.text.trim(),
        workspaceName: _workspaceController.text.trim(),
      ),
    );
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      switch (result) {
        case SignUpSubmissionResult.created:
          _feedbackMessage = 'Your account is ready.';
          _feedbackType = _FeedbackType.success;
        case SignUpSubmissionResult.emailAlreadyRegistered:
          _feedbackMessage = 'An account already exists for this email.';
          _feedbackType = _FeedbackType.error;
        case SignUpSubmissionResult.serviceUnavailable:
          _feedbackMessage =
              'Unable to reach the authentication service. Try again.';
          _feedbackType = _FeedbackType.error;
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
              'Almost there',
              style: AppTextStyles.authHeading,
            ),
            const SizedBox(height: 4),
            const Text(
              'Two things, then we set up your workspace together.',
              style: AppTextStyles.authDescription,
            ),
            const SizedBox(height: 18),
            const AuthFieldLabel('Your name'),
            const SizedBox(height: 5),
            TextFormField(
              key: const ValueKey('signup-full-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: _validateRequired,
              decoration: AppInputStyles.authentication(
                hintText: 'Your name',
              ),
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Workspace name'),
            const SizedBox(height: 5),
            TextFormField(
              key: const ValueKey('signup-workspace-name'),
              controller: _workspaceController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              validator: _validateRequired,
              onFieldSubmitted: (_) => _submit(),
              decoration: AppInputStyles.authentication(
                hintText: 'Your workspace',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('start-setup'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Start setup'),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _feedbackMessage!,
                key: const ValueKey('signup-setup-feedback'),
                textAlign: TextAlign.center,
                style: AppTextStyles.authHelper.copyWith(
                  color: switch (_feedbackType) {
                    _FeedbackType.information => AppColors.authMuted,
                    _FeedbackType.error => AppColors.error,
                    _FeedbackType.success => AppColors.authGreen,
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _FeedbackType { information, error, success }