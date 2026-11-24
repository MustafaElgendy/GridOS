import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

/// Dialog to ask if this device is used as the front desk by staff.
class FrontDeskChoiceDialog extends StatefulWidget {
  const FrontDeskChoiceDialog({super.key});

  @override
  State<FrontDeskChoiceDialog> createState() => _FrontDeskChoiceDialogState();
}

class _FrontDeskChoiceDialogState extends State<FrontDeskChoiceDialog> {
  bool _isFrontDesk = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Will staff use this computer?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _choiceCard(
            key: const ValueKey('frontdesk-choice-yes'),
            selected: _isFrontDesk,
            title: 'Yes, it’s the front desk',
            description:
                'Staff start their shifts here with their PIN. Your side gets a lock.',
            onTap: () => setState(() => _isFrontDesk = true),
          ),
          const SizedBox(height: 8),
          _choiceCard(
            key: const ValueKey('frontdesk-choice-no'),
            selected: !_isFrontDesk,
            title: 'No, it’s just mine',
            description:
                'Staff use another computer. On the front desk computer, log in and tap Open the front desk.',
            onTap: () => setState(() => _isFrontDesk = false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-frontdesk-choice'),
          onPressed: () => Navigator.pop(context, _isFrontDesk),
          child: const Text('Open the front desk'),
        ),
      ],
    );
  }

  Widget _choiceCard({
    required Key key,
    required bool selected,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F7F4) : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.authGreen : AppColors.authBorder,
          ),
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.authGreen : AppColors.authMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(description, style: AppTextStyles.authHelper),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for owner PIN creation or verification.
class OwnerPinDialog extends StatefulWidget {
  const OwnerPinDialog({
    super.key,
    this.title = 'Set your owner PIN',
    this.actionLabel = 'Save PIN',
    this.verifyMode = false,
    this.expectedPin,
  });

  final String title;
  final String actionLabel;
  final bool verifyMode;
  final String? expectedPin;

  @override
  State<OwnerPinDialog> createState() => _OwnerPinDialogState();
}

class _OwnerPinDialogState extends State<OwnerPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text;
    if (widget.verifyMode) {
      if (pin.length != 6) {
        setState(() => _error = 'Enter your 6-digit owner PIN.');
        return;
      }
      if (widget.expectedPin != null && pin != widget.expectedPin) {
        setState(() => _error = 'That PIN does not match.');
        return;
      }
      Navigator.pop(context, pin);
      return;
    }

    if (pin.length != 6) {
      setState(() => _error = 'Enter a 6-digit PIN.');
      return;
    }
    if (_isWeakPin(pin)) {
      setState(
        () => _error = 'Choose a less predictable PIN, not a simple sequence.',
      );
      return;
    }
    if (pin != _confirmController.text) {
      setState(() => _error = 'The PINs do not match.');
      return;
    }
    Navigator.pop(context, pin);
  }

  bool _isWeakPin(String pin) {
    if (pin.split('').every((digit) => digit == pin[0])) return true;
    final values = pin.codeUnits;
    final ascending = values.asMap().entries.every(
      (entry) => entry.key == 0 || entry.value == values[entry.key - 1] + 1,
    );
    final descending = values.asMap().entries.every(
      (entry) => entry.key == 0 || entry.value == values[entry.key - 1] - 1,
    );
    return ascending ||
        descending ||
        const {'121212', '123123', '112233'}.contains(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.verifyMode
                ? 'Enter your 6-digit owner PIN to return to Owner view.'
                : 'Your 6-digit PIN protects your side and lets you start a shift.',
            style: AppTextStyles.authDescription,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('owner-pin-entry'),
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: setupInputDecoration(hintText: '6-digit owner PIN')
                .copyWith(counterText: ''),
            onSubmitted: (_) => _submit(),
          ),
          if (!widget.verifyMode) ...[
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('owner-pin-confirm'),
              controller: _confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: setupInputDecoration(hintText: 'Confirm owner PIN')
                  .copyWith(counterText: ''),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 7),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('save-owner-pin'),
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

/// Dialog for staff or owner to enter shift PIN.
class ShiftPinDialog extends StatefulWidget {
  const ShiftPinDialog({
    super.key,
    required this.person,
    required this.digits,
    this.action = 'Start shift',
  });

  final String person;
  final int digits;
  final String action;

  @override
  State<ShiftPinDialog> createState() => _ShiftPinDialogState();
}

class _ShiftPinDialogState extends State<ShiftPinDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} · ${widget.person}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your PIN to continue.',
            style: AppTextStyles.authDescription,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('shift-pin-entry'),
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: widget.digits,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: setupInputDecoration(
              hintText: '${widget.digits}-digit PIN',
            ).copyWith(counterText: ''),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('submit-shift-pin'),
          onPressed: _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }

  void _submit() {
    if (_controller.text.length != widget.digits) {
      setState(() => _error = 'Enter a ${widget.digits}-digit PIN.');
      return;
    }
    Navigator.pop(context, _controller.text);
  }
}

/// Dialog for counting cash drawer money (opening or closing shift).
class CashCountDialog extends StatefulWidget {
  const CashCountDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.expectedCash,
  });

  final String title;
  final String actionLabel;
  final double? expectedCash;

  @override
  State<CashCountDialog> createState() => _CashCountDialogState();
}

class _CashCountDialogState extends State<CashCountDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || !amount.isFinite || amount < 0) {
      setState(() => _error = 'Enter a valid cash amount.');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.expectedCash != null) ...[
          Text(
            'Expected cash: ${widget.expectedCash!.toStringAsFixed(2)}',
            style: AppTextStyles.authDescription,
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          key: const ValueKey('cash-count-entry'),
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: setupInputDecoration(hintText: 'Counted amount'),
          onSubmitted: (_) => _save(),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('save-cash-count'),
        onPressed: _save,
        child: Text(widget.actionLabel),
      ),
    ],
  );
}

/// Dialog for adding a staff member.
class AddStaffDialog extends StatefulWidget {
  const AddStaffDialog({super.key, required this.existingPins});

  final Set<String> existingPins;

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _add() {
    final name = _nameController.text.trim();
    final pin = _pinController.text;
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Enter a 4-digit PIN.');
      return;
    }
    if (widget.existingPins.contains(pin)) {
      setState(() => _error = 'That PIN is already in use.');
      return;
    }
    Navigator.pop(context, StaffSetup(name: name, pin: pin));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add staff'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('new-staff-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: setupInputDecoration(hintText: 'Name'),
          ),
          const SizedBox(height: 9),
          TextField(
            key: const ValueKey('new-staff-pin'),
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: setupInputDecoration(
              hintText: '4-digit PIN',
            ).copyWith(counterText: ''),
            onSubmitted: (_) => _add(),
          ),
          if (_error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('save-new-staff'),
          onPressed: _add,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
