import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/preview_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key, required this.setup});

  final StartupSetup setup;

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String? _error;
  bool _skipped = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _addStaff() {
    final name = _nameController.text.trim();
    final pin = _pinController.text;
    if (name.isEmpty) {
      setState(() => _error = 'Enter a staff name.');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Enter a 4-digit PIN.');
      return;
    }
    if (widget.setup.staffPins.contains(pin)) {
      setState(() => _error = 'That PIN is already in use.');
      return;
    }
    setState(() {
      widget.setup.staffPins.add(pin);
      widget.setup.staff.add(StaffSetup(name: name, pin: pin));
      _nameController.clear();
      _pinController.clear();
      _error = null;
      _skipped = false;
    });
  }

  void _openPreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PreviewPage(setup: widget.setup)),
    );
  }

  void _removeStaff(StaffSetup member) {
    setState(() {
      widget.setup.staff.remove(member);
      widget.setup.staffPins.remove(member.pin);
      _error = null;
    });
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }

  Widget _memberCard({
    required String name,
    required String subtitle,
    required bool isOwner,
    StaffSetup? member,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.homePaleGreen,
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: AppColors.authGreen,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
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
                Text(subtitle, style: AppTextStyles.authHelper),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.authBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'You',
                style: TextStyle(color: AppColors.authInk, fontSize: 9),
              ),
            )
          else
            IconButton(
              key: ValueKey('delete-staff-${member!.pin}'),
              tooltip: 'Delete $name',
              visualDensity: VisualDensity.compact,
              onPressed: () => _removeStaff(member),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _staffField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.authHelper),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: label == 'Name'
              ? TextCapitalization.words
              : TextCapitalization.none,
          decoration: setupInputDecoration(hintText: hintText).copyWith(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addStaffForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nameField = _staffField(
          label: 'Name',
          hintText: 'e.g. Mona',
          controller: _nameController,
        );
        final pinField = _staffField(
          label: '4-digit PIN',
          hintText: '••••',
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
        );
        final addButton = OutlinedButton(
          onPressed: _addStaff,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 40),
          ),
          child: const Text('Add'),
        );

        if (constraints.maxWidth >= 360) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 3, child: nameField),
              const SizedBox(width: 8),
              Expanded(flex: 1, child: pinField),
              const SizedBox(width: 8),
              addButton,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            nameField,
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: pinField),
                const SizedBox(width: 8),
                addButton,
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasStaff = widget.setup.staff.isNotEmpty;
    final continueLabel = hasStaff || _skipped ? 'Save' : 'Skip for now';
    return SetupPageFrame(
      step: 5,
      workspaceName: widget.setup.workspaceName,
      title: 'Your staff',
      description:
          'Who works the front desk. You can skip this and add them later.',
      onBack: () => Navigator.of(context).pop(),
      onFinishLater: _openPreview,
      onContinue: hasStaff || _skipped
          ? _openPreview
          : () => setState(() => _skipped = true),
      continueLabel: continueLabel,
      panelChild: false,
      summary: SetupProgressSummary(
        setup: widget.setup,
        activeStep: 5,
        onEditStep: (step) =>
            returnToSetupStep(context, currentStep: 5, targetStep: step),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SetupPanel(
            backgroundColor: AppColors.white,
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _memberCard(
                  name: widget.setup.ownerName,
                  subtitle: 'Owner · runs the desk when needed',
                  isOwner: true,
                ),
                for (final member in widget.setup.staff)
                  _memberCard(
                    name: member.name,
                    subtitle: 'Staff member · PIN set',
                    isOwner: false,
                    member: member,
                  ),
                const SizedBox(height: 7),
                const Text(
                  'Add the people who work the front desk',
                  style: AppTextStyles.authFieldLabel,
                ),
                const SizedBox(height: 8),
                _addStaffForm(),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                const Text(
                  'You tell each person their PIN yourself. It’s never shown on the front-desk screen.',
                  style: AppTextStyles.authHelper,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
