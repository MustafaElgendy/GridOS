import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grid_os/theme/app_theme.dart';

/// Modal dialog matching the Owner view unlock dialog design:
/// - Teal lock badge icon
/// - Title "Owner view"
/// - Subtitle "[StaffName]'s shift stays open."
/// - Prompt "[OwnerName], type your 6-digit owner PIN"
/// - 6-digit secure PIN container with dots
/// - Helper text: "Staff can't open this. It locks itself after 3 minutes without use and goes back to the front desk."
/// - Actions: Cancel and Unlock
class OwnerUnlockDialog extends StatefulWidget {
  const OwnerUnlockDialog({
    super.key,
    required this.ownerName,
    required this.staffName,
    this.expectedPin,
  });

  final String ownerName;
  final String staffName;
  final String? expectedPin;

  @override
  State<OwnerUnlockDialog> createState() => _OwnerUnlockDialogState();
}

class _OwnerUnlockDialogState extends State<OwnerUnlockDialog> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    if (_error != null) {
      setState(() => _error = null);
    } else {
      setState(() {});
    }
  }

  void _unlock() {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'Enter your 6-digit owner PIN.');
      return;
    }
    if (widget.expectedPin != null && pin != widget.expectedPin) {
      setState(() => _error = 'That PIN does not match.');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final enteredPin = _pinController.text;
    final staffClean = widget.staffName.contains(' · ')
        ? widget.staffName.split(' · ').first
        : widget.staffName;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Teal lock badge + Title & Subtitle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icons.lock_outline,
                      size: 20,
                      color: Color(0xFF1B6B50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Owner view',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.authInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$staffClean’s shift stays open.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.authMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prompt Label
              Text(
                '${widget.ownerName}, type your 6-digit owner PIN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authInk,
                ),
              ),
              const SizedBox(height: 10),

              // PIN Input Container
              GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _error != null
                          ? AppColors.error
                          : const Color(0xFF4A9B79),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Visual dots display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final hasDigit = index < enteredPin.length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasDigit
                                    ? AppColors.authInk
                                    : const Color(0xFFC4C9C6),
                              ),
                            ),
                          );
                        }),
                      ),
                      // Transparent TextField to accept user input
                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          key: const ValueKey('owner-pin-entry'),
                          controller: _pinController,
                          focusNode: _focusNode,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSubmitted: (_) => _unlock(),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Security helper caption
              const Text(
                'Staff can’t open this. It locks itself after 3 minutes without use and goes back to the front desk.',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.authMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),

              // Actions: Cancel and Unlock
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.authInk,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('unlock-owner-view'),
                    onPressed: _unlock,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B50),
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Unlock',
                      key: ValueKey('save-owner-pin'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
}
