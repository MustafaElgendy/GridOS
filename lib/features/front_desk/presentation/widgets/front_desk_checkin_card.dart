import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskCheckinCard extends StatelessWidget {
  const FrontDeskCheckinCard({
    super.key,
    required this.setup,
    required this.onSearchChanged,
    required this.onNewCustomer,
    required this.currency,
  });

  final StartupSetup setup;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNewCustomer;
  final String currency;

  String _pricingSummary() {
    final sharedPrice = setup.prices[SetupSpaceType.sharedArea];
    if (sharedPrice != null) {
      if (sharedPrice.walkInMode == WalkInPriceMode.byHours &&
          sharedPrice.walkInSteps.isNotEmpty) {
        final step = sharedPrice.walkInSteps.first;
        final stepHours = step.untilHours.trim().isEmpty ? '3' : step.untilHours.trim();
        final stepPrice = step.price.trim().isEmpty ? '100' : step.price.trim();
        final morePrice = sharedPrice.moreHoursPrice.trim().isEmpty
            ? '150'
            : sharedPrice.moreHoursPrice.trim();
        return 'Pricing today: up to $stepHours h - $stepPrice $currency · over $stepHours h - $morePrice $currency. Returning customers and plans are detected automatically.';
      } else if (sharedPrice.walkInMode == WalkInPriceMode.perHour &&
          sharedPrice.hourlyPrice.trim().isNotEmpty) {
        return 'Pricing today: ${sharedPrice.hourlyPrice.trim()} $currency per hour. Returning customers and plans are detected automatically.';
      } else if (sharedPrice.walkInMode == WalkInPriceMode.dayPrice &&
          sharedPrice.dayPrice.trim().isNotEmpty) {
        return 'Pricing today: ${sharedPrice.dayPrice.trim()} $currency for day pass. Returning customers and plans are detected automatically.';
      }
    }
    return 'Pricing today: standard walk-in rates apply. Returning customers and plans are detected automatically.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.authBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Check in now',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.authInk,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 17,
                        color: AppColors.authMuted,
                      ),
                      hintText: 'Search by phone number or name',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.authMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        borderSide:
                            const BorderSide(color: AppColors.authBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        borderSide:
                            const BorderSide(color: AppColors.authBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                        borderSide:
                            const BorderSide(color: AppColors.authGreen),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                key: const ValueKey('checkin-new-customer'),
                onPressed: onNewCustomer,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Check in',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.authGreen,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _pricingSummary(),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.authMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
