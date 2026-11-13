import 'package:flutter/material.dart';
import 'package:grid_os/theme/app_theme.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AuthBrand(),
                        const SizedBox(height: 22),
                        AuthCard(child: form),
                        const SizedBox(height: 18),
                        const AuthSupportPrompt(),
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
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.authCard),
        boxShadow: AppShadows.authCard,
      ),
      child: child,
    );
  }
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _BrandTile(),
              _BrandTile(),
              _BrandTile(),
              _BrandTile(),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'GridOS',
          style: AppTextStyles.authBrand,
        ),
      ],
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authGreen,
        borderRadius: BorderRadius.circular(AppRadii.brandTile),
      ),
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: AppButtonStyles.authGoogle,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoogleMark(),
          SizedBox(width: 9),
          Flexible(
            child: Text(
              'Continue with Google',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.googleButton,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.googleBorder),
      ),
      child: const Text(
        'G',
        style: AppTextStyles.googleMark,
      ),
    );
  }
}

class AuthEmailDivider extends StatelessWidget {
  const AuthEmailDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.authBorder, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or with your email',
            style: AppTextStyles.authDivider,
          ),
        ),
        Expanded(child: Divider(color: AppColors.authBorder, height: 1)),
      ],
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.authFieldLabel,
    );
  }
}

class AuthSupportPrompt extends StatelessWidget {
  const AuthSupportPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Icon(
          Icons.chat_bubble_outline_rounded,
          color: AppColors.authGreen,
          size: 14,
        ),
        Text(
          'Questions? Talk to us on WhatsApp',
          style: AppTextStyles.authSupport,
        ),
      ],
    );
  }
}

String? validateEmailAddress(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
