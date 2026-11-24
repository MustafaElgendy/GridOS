import 'package:flutter/material.dart';

import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskCheckoutPanel extends StatefulWidget {
  const FrontDeskCheckoutPanel({
    super.key,
    required this.selectedVisit,
    required this.customer,
    required this.currency,
    required this.onCompleteCheckout,
    required this.onCancelSelection,
  });

  final Visit? selectedVisit;
  final Customer? customer;
  final String currency;
  final void Function(Visit visit, String paymentMethod) onCompleteCheckout;
  final VoidCallback onCancelSelection;

  @override
  State<FrontDeskCheckoutPanel> createState() => _FrontDeskCheckoutPanelState();
}

class _FrontDeskCheckoutPanelState extends State<FrontDeskCheckoutPanel> {
  String _selectedMethod = 'Cash';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authInk,
                ),
              ),
              if (widget.selectedVisit != null)
                TextButton(
                  onPressed: widget.onCancelSelection,
                  child: const Text('Clear', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.selectedVisit == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(
                    Icons.output_rounded,
                    size: 32,
                    color: AppColors.authMuted,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No one selected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap Check out on someone in the list, or find them by name.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.authMuted),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(AppRadii.control),
                border: Border.all(color: const Color(0xFFE0EAE3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customer?.name ?? 'Walk-in customer',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(widget.selectedVisit!.spaceName?.isEmpty ?? true) ? 'General Space' : widget.selectedVisit!.spaceName} · Checked in at ${_formatTime(widget.selectedVisit!.checkedInAt)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.authMuted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total to pay',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${widget.selectedVisit!.amount.toStringAsFixed(0)} ${widget.currency}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.authGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Payment method',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final method in ['Cash', 'Card', 'Transfer', 'Pay later'])
                  ChoiceChip(
                    label: Text(method, style: const TextStyle(fontSize: 10)),
                    selected: _selectedMethod == method,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedMethod = method);
                    },
                    selectedColor: AppColors.homePaleGreen,
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      side: BorderSide(
                        color: _selectedMethod == method
                            ? AppColors.authGreen
                            : AppColors.authBorder,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => widget.onCompleteCheckout(
                widget.selectedVisit!,
                _selectedMethod,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.authGreen,
                minimumSize: const Size(double.infinity, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
              child: const Text(
                'Complete check out',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
