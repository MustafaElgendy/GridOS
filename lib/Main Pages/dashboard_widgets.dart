import 'package:flutter/material.dart';
import 'package:grid_os/theme/app_theme.dart';

BoxDecoration dashboardCardDecoration() => BoxDecoration(
  color: AppColors.white,
  border: Border.all(color: AppColors.authBorder),
  borderRadius: BorderRadius.circular(AppRadii.control),
);

class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: dashboardCardDecoration(),
      child: child,
    );
  }
}

class DashboardPageHeader extends StatelessWidget {
  const DashboardPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleKey,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Key? titleKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: titleKey,
                style: const TextStyle(
                  color: AppColors.authInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.authHelper),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(24),
      decoration: dashboardCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.homePaleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.authGreen),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.authFieldLabel,
          ),
          const SizedBox(height: 5),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.authDescription,
          ),
          const SizedBox(height: 15),
          FilledButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
