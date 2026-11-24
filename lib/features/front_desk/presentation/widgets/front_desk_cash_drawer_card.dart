import 'package:flutter/material.dart';

import 'package:grid_os/theme/app_theme.dart';

class FrontDeskCashDrawerCard extends StatelessWidget {
  const FrontDeskCashDrawerCard({
    super.key,
    required this.staffName,
    required this.onAddExpense,
    required this.onAddCash,
  });

  final String staffName;
  final VoidCallback onAddExpense;
  final VoidCallback onAddCash;

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
          Row(
            children: [
              const Text(
                'Cash drawer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authInk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$staffName · this shift',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.authMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.arrow_upward, size: 14),
                  label: const Text('Add expense', style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.authBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddCash,
                  icon: const Icon(Icons.arrow_downward, size: 14),
                  label: const Text('Add cash', style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.authBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Paid something from the drawer, or put money in that isn’t a payment? Add it here. Payments are counted automatically.',
            style: TextStyle(fontSize: 9, color: AppColors.authMuted, height: 1.3),
          ),
        ],
      ),
    );
  }
}
