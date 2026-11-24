import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class ShiftCandidate {
  const ShiftCandidate({
    required this.name,
    required this.isOwner,
    this.staffMember,
  });

  final String name;
  final bool isOwner;
  final StaffSetup? staffMember;
}

/// Dialog asking the owner who is on the shift when opening the front desk:
/// "Who is working the shift?"
/// Allows selecting the owner or any registered staff member.
class ShiftSelectionDialog extends StatefulWidget {
  const ShiftSelectionDialog({
    super.key,
    required this.ownerName,
    required this.staff,
  });

  final String ownerName;
  final List<StaffSetup> staff;

  @override
  State<ShiftSelectionDialog> createState() => _ShiftSelectionDialogState();
}

class _ShiftSelectionDialogState extends State<ShiftSelectionDialog> {
  late ShiftCandidate _selected;

  @override
  void initState() {
    super.initState();
    _selected = ShiftCandidate(
      name: widget.ownerName.isEmpty ? 'Owner' : widget.ownerName,
      isOwner: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.schedule_outlined,
                      size: 20,
                      color: Color(0xFF1B6B50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Who is working the shift?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authInk,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select who is starting this front desk shift.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.authMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Owner option
              _candidateTile(
                candidate: ShiftCandidate(
                  name: widget.ownerName.isEmpty ? 'Owner' : widget.ownerName,
                  isOwner: true,
                ),
                subtitle: 'Owner',
                icon: Icons.star_outline,
              ),

              const SizedBox(height: 8),

              // Staff options
              for (final member in widget.staff) ...[
                _candidateTile(
                  candidate: ShiftCandidate(
                    name: member.name,
                    isOwner: false,
                    staffMember: member,
                  ),
                  subtitle: 'Staff',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('confirm-shift-candidate'),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B50),
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Start shift',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _candidateTile({
    required ShiftCandidate candidate,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selected.isOwner == candidate.isOwner &&
        (candidate.isOwner ||
            _selected.staffMember?.pin == candidate.staffMember?.pin);

    return InkWell(
      onTap: () => setState(() => _selected = candidate),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7F4) : AppColors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4A9B79) : AppColors.authBorder,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isSelected
                  ? const Color(0xFFD6EDE0)
                  : const Color(0xFFF1F3F2),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF1B6B50) : AppColors.authMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authInk,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.authMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF1B6B50) : AppColors.authMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
