import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskShiftsCard extends StatelessWidget {
  const FrontDeskShiftsCard({
    super.key,
    required this.setup,
    required this.ownerName,
    required this.ownerOnShift,
    required this.workingStaffPins,
    required this.onStartShift,
    required this.onEndShift,
  });

  final StartupSetup setup;
  final String ownerName;
  final bool ownerOnShift;
  final Set<String> workingStaffPins;
  final Future<void> Function({required String? pin, required bool isOwner})
      onStartShift;
  final Future<void> Function({required String? pin, required bool isOwner})
      onEndShift;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.authBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Who’s working?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.authInk,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'The owner is always listed first.',
            style: TextStyle(fontSize: 10, color: AppColors.authMuted),
          ),
          const SizedBox(height: 8),
          _workerRow(
            name: '$ownerName · Owner',
            pin: null,
            isOwner: true,
            isWorking: ownerOnShift,
          ),
          for (final member in setup.staff)
            _workerRow(
              name: member.name,
              pin: member.pin,
              isOwner: false,
              isWorking: workingStaffPins.contains(member.pin),
            ),
        ],
      ),
    );
  }

  Widget _workerRow({
    required String name,
    required String? pin,
    required bool isOwner,
    required bool isWorking,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.authBorder)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isWorking
                ? AppColors.homePaleGreen
                : AppColors.authBackground,
            child: Icon(
              isOwner ? Icons.star_outline : Icons.person_outline,
              size: 15,
              color: AppColors.authGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.authInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isWorking ? 'On shift' : 'Not started',
                  style: const TextStyle(fontSize: 9, color: AppColors.authMuted),
                ),
              ],
            ),
          ),
          if (isWorking)
            OutlinedButton(
              onPressed: () => onEndShift(pin: pin, isOwner: isOwner),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
              child: const Text('End shift', style: TextStyle(fontSize: 10)),
            )
          else if (!isOwner || setup.staff.isNotEmpty)
            OutlinedButton(
              key: ValueKey(isOwner ? 'start-shift-owner' : 'start-shift-$pin'),
              onPressed: () => onStartShift(pin: pin, isOwner: isOwner),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
              child: const Text('Start shift', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }
}
