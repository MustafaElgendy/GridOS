import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class DashboardStaffPage extends StatelessWidget {
  const DashboardStaffPage({
    super.key,
    required this.setup,
    required this.onSetOwnerPin,
    required this.onAddStaff,
    required this.onRemoveStaff,
  });

  final StartupSetup setup;
  final VoidCallback onSetOwnerPin;
  final VoidCallback onAddStaff;
  final ValueChanged<StaffSetup> onRemoveStaff;

  @override
  Widget build(BuildContext context) {
    final ownerName = setup.ownerName.trim().isEmpty
        ? 'Owner'
        : setup.ownerName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Staff', style: AppTextStyles.authHeading),
            ),
            FilledButton.icon(
              onPressed: onAddStaff,
              icon: const Icon(Icons.person_add_alt_1, size: 17),
              label: const Text('Add staff'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage who can open the front desk and start a shift.',
          style: AppTextStyles.authDescription,
        ),
        const SizedBox(height: 18),
        _DashboardStaffCard(
          initials: _initials(ownerName),
          title: '$ownerName · Owner',
          subtitle: 'Runs the front desk until you add staff',
          trailing: OutlinedButton(
            onPressed: onSetOwnerPin,
            child: Text(
              setup.ownerPin == null ? 'Set owner PIN' : 'Change owner PIN',
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (setup.staff.isEmpty)
          const _NoStaffCard()
        else
          for (final member in setup.staff) ...[
            _DashboardStaffCard(
              initials: _initials(member.name),
              title: member.name,
              subtitle: 'Staff PIN set',
              trailing: IconButton(
                tooltip: 'Remove ${member.name}',
                onPressed: () => onRemoveStaff(member),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  String _initials(String name) {
    final names = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = names.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? 'O' : initials;
  }
}

class _DashboardStaffCard extends StatelessWidget {
  const _DashboardStaffCard({
    required this.initials,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String initials;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.homePaleGreen,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.authGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.authFieldLabel),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.authHelper),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _NoStaffCard extends StatelessWidget {
  const _NoStaffCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.authMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No staff added yet. Add a team member when you are ready.',
              style: AppTextStyles.authDescription,
            ),
          ),
        ],
      ),
    );
  }
}
