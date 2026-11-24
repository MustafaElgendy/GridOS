import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/theme/app_theme.dart';

enum FrontDeskTab { today, bookings, customers }

class FrontDeskHeader extends StatelessWidget {
  const FrontDeskHeader({
    super.key,
    required this.setup,
    required this.selectedTab,
    required this.onTabSelected,
    required this.currentStaffName,
    required this.isOwner,
    required this.onSwitchToOwner,
    required this.onEndShift,
    required this.onToggleArabic,
    required this.isArabic,
  });

  final StartupSetup setup;
  final FrontDeskTab selectedTab;
  final ValueChanged<FrontDeskTab> onTabSelected;
  final String currentStaffName;
  final bool isOwner;
  final VoidCallback onSwitchToOwner;
  final VoidCallback onEndShift;
  final VoidCallback onToggleArabic;
  final bool isArabic;

  String get _workspaceInitial {
    final name = setup.workspaceName.trim();
    return name.isEmpty ? 'G' : name[0].toUpperCase();
  }

  String _dateLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} · $hour:$minute $period';
  }

  String get _ownerName =>
      setup.ownerName.trim().isEmpty ? 'Owner' : setup.ownerName.trim();

  String get _staffDisplayName {
    if (currentStaffName.contains(' · ')) {
      return currentStaffName.split(' · ').first;
    }
    return currentStaffName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.authBorder)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Group: Brand, Badge, Navigation tabs
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mobile navigation drawer button (if drawer is available in parent)
                        Builder(
                          builder: (ctx) {
                            final hasDrawer =
                                Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
                            if (!hasDrawer) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: IconButton(
                                key: const ValueKey('dashboard-drawer-menu'),
                                tooltip: 'Open navigation',
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                                icon: const Icon(Icons.menu, size: 20),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            );
                          },
                        ),

                        // Workspace Logo & Name
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.authGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _workspaceInitial,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          setup.workspaceName.isEmpty
                              ? 'GridOS'
                              : setup.workspaceName,
                          style: const TextStyle(
                            color: AppColors.authInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Staff view badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.homePaleGreen,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: const Text(
                            'Staff view',
                            style: TextStyle(
                              color: AppColors.authGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Navigation Tabs
                        _tabButton(
                          FrontDeskTab.today,
                          'Today',
                          const ValueKey('frontdesk-tab-today'),
                        ),
                        const SizedBox(width: 4),
                        _tabButton(
                          FrontDeskTab.bookings,
                          'Bookings',
                          const ValueKey('frontdesk-tab-bookings'),
                        ),
                        const SizedBox(width: 4),
                        _tabButton(
                          FrontDeskTab.customers,
                          'Customers',
                          const ValueKey('frontdesk-tab-customers'),
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // Right Group: Pushed to the Far-right (Date, Language, Lock, Staff Dropdown)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _dateLabel(),
                          style: const TextStyle(
                            color: AppColors.authMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Arabic toggle button
                        OutlinedButton(
                          onPressed: onToggleArabic,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: const BorderSide(color: AppColors.authBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'English' : 'العربية',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.authInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Quick Owner View icon button
                        IconButton(
                          key: const ValueKey('switch-to-owner'),
                          tooltip: 'Switch to Owner view',
                          onPressed: onSwitchToOwner,
                          icon: const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.authGreen,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 6),

                        // Staff dropdown menu on Far-Right
                        _staffDropdownMenu(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabButton(FrontDeskTab tab, String label, Key key) {
    final selected = selectedTab == tab;
    return InkWell(
      key: key,
      onTap: () => onTabSelected(tab),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8ECE9) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.authInk : AppColors.authMuted,
          ),
        ),
      ),
    );
  }

  Widget _staffDropdownMenu(BuildContext context) {
    final initial = _staffDisplayName.trim().isEmpty
        ? 'S'
        : _staffDisplayName.trim()[0].toUpperCase();

    return PopupMenuButton<String>(
      key: const ValueKey('front-desk-staff-menu'),
      tooltip: 'Staff menu',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'owner') {
          onSwitchToOwner();
        } else if (value == 'end_shift') {
          onEndShift();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const ValueKey('frontdesk-close-shift'),
          value: 'end_shift',
          child: const Row(
            children: [
              Icon(Icons.exit_to_app_rounded, size: 16, color: AppColors.authInk),
              SizedBox(width: 10),
              Text(
                'Close my shift',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.authInk,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'owner',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.authInk),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner view',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_ownerName only · needs the owner PIN',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.authMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.authBorder),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFE8ECE9),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.authInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _staffDisplayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authInk,
                  ),
                ),
                const Text(
                  'Shift since 9:00 AM',
                  style: TextStyle(fontSize: 8.5, color: AppColors.authMuted),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 15,
              color: AppColors.authMuted,
            ),
          ],
        ),
      ),
    );
  }
}
