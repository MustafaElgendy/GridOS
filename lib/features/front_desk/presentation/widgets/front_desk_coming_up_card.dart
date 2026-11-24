import 'package:flutter/material.dart';

import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskComingUpCard extends StatelessWidget {
  const FrontDeskComingUpCard({
    super.key,
    required this.bookings,
    required this.repository,
    required this.currency,
    required this.onCheckInBooking,
  });

  final List<Booking> bookings;
  final WorkspaceRepository repository;
  final String currency;
  final ValueChanged<Booking> onCheckInBooking;

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
            'Coming up',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.authInk,
            ),
          ),
          const SizedBox(height: 10),
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'No upcoming bookings for today.',
                style: TextStyle(color: AppColors.authMuted, fontSize: 11),
              ),
            )
          else
            for (final booking in bookings) ...[
              _bookingRow(booking),
              const Divider(height: 12, color: AppColors.authBorder),
            ],
        ],
      ),
    );
  }

  Widget _bookingRow(Booking booking) {
    final start = booking.startsAt;
    final end = booking.endsAt;
    final timeStr =
        '${start.hour % 12 == 0 ? 12 : start.hour % 12}:${start.minute.toString().padLeft(2, '0')} ${start.hour >= 12 ? 'PM' : 'AM'} - ${end.hour % 12 == 0 ? 12 : end.hour % 12}:${end.minute.toString().padLeft(2, '0')} ${end.hour >= 12 ? 'PM' : 'AM'} Today';

    final customer = repository.customerById(booking.customerId);
    final customerName = customer?.name ?? 'Customer';
    final space = (booking.spaceName?.isEmpty ?? true)
        ? (booking.spaceType?.label ?? 'Space')
        : booking.spaceName!;
    final isPaid = booking.amount > 0 && booking.paidAmount >= booking.amount;

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            timeStr,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.authInk,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$space · $customerName',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authInk,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Booking · ${booking.amount.toStringAsFixed(0)} $currency',
                style: const TextStyle(fontSize: 10, color: AppColors.authMuted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isPaid
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            isPaid ? 'Paid' : 'Not paid',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isPaid
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE65100),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => onCheckInBooking(booking),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(60, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            side: const BorderSide(color: AppColors.authGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
          ),
          child: const Text(
            'Check in',
            style: TextStyle(fontSize: 10, color: AppColors.authGreen),
          ),
        ),
      ],
    );
  }
}
