import 'package:flutter/material.dart';

abstract final class AuthColors {
  static const pageBackground = Color(0xFFF6F7F3);
  static const cardBorder = Color(0xFFE6E9E4);
  static const ink = Color(0xFF202722);
  static const muted = Color(0xFF737B75);
  static const green = Color(0xFF117562);
  static const error = Color(0xFFB3261E);
}

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
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
        color: Colors.white,
        border: Border.all(color: AuthColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D2017),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
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
          style: TextStyle(
            color: AuthColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
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
        color: AuthColors.green,
        borderRadius: BorderRadius.circular(1.5),
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
      style: OutlinedButton.styleFrom(
        foregroundColor: AuthColors.ink,
        side: const BorderSide(color: AuthColors.cardBorder),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
              style: TextStyle(fontWeight: FontWeight.w600),
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
        border: Border.all(color: const Color(0xFFB8BDB9)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF6D746F),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
        Expanded(child: Divider(color: AuthColors.cardBorder, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or with your email',
            style: TextStyle(color: AuthColors.muted, fontSize: 11),
          ),
        ),
        Expanded(child: Divider(color: AuthColors.cardBorder, height: 1)),
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
      style: const TextStyle(
        color: AuthColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
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
          color: AuthColors.green,
          size: 14,
        ),
        Text(
          'Questions? Talk to us on WhatsApp',
          style: TextStyle(
            color: AuthColors.green,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

InputDecoration authInputDecoration({String? hintText, Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF9AA19B), fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    isDense: true,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.green, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AuthColors.error, width: 1.4),
    ),
  );
}

String? validateEmailAddress(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address.';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
  return null;
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
