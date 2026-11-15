import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/preview_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/Sign_Up_pages/sign_up_models.dart';
import 'package:grid_os/theme/app_theme.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.setup,
    this.email = '',
    this.password = '',
    this.submitSignup,
  });

  final StartupSetup setup;
  final String email;
  final String password;
  final SignUpSubmitter? submitSignup;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<int> _workspaceRevision = ValueNotifier(0);
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _workspaceRevision.dispose();
    super.dispose();
  }

  void _notifyWorkspaceSummary() {
    _workspaceRevision.value++;
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phone.isEmpty) return 'Enter your phone number.';
    if (phone.length < 7 || phone.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  Future<void> _continue() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    final submitSignup = widget.submitSignup;
    if (submitSignup != null) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      final result = await submitSignup(
        SignUpRequest(
          email: widget.email,
          password: widget.password,
          fullName: widget.setup.ownerName.trim(),
          workspaceName: widget.setup.workspaceName.trim(),
        ),
      );
      if (!mounted) return;

      if (result != SignUpSubmissionResult.created) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = switch (result) {
            SignUpSubmissionResult.emailAlreadyRegistered =>
              'An account already exists for this email.',
            SignUpSubmissionResult.serviceUnavailable =>
              'Unable to reach the authentication service. Try again.',
            SignUpSubmissionResult.created => null,
          };
        });
        return;
      }
    }

    if (!mounted) return;
    if (submitSignup != null) {
      setState(() => _isSubmitting = false);
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SpacesPage(setup: widget.setup)),
    );
  }

  void _finishLater() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SetupDashboardPage(setup: widget.setup),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final setup = widget.setup;
    final country = setup.country;
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            SetupProgressAppBar(
              workspaceName: setup.workspaceName,
              title: 'Your workspace',
              step: 1,
              onFinishLater: _finishLater,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  return SingleChildScrollView(
                    key: const PageStorageKey<String>('workspace-setup'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 28 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1050),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _pageHeading(),
                                        _workspaceForm(setup, country),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _workspaceRevision,
                                        builder: (context, _, _) =>
                                            _summary(setup),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _pageHeading(),
                              const SizedBox(height: 4),
                              _workspaceForm(setup, country),
                              const SizedBox(height: 20),
                              ValueListenableBuilder<int>(
                                valueListenable: _workspaceRevision,
                                builder: (context, _, _) => _summary(setup),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageHeading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 1 OF 5',
            style: TextStyle(
              color: AppColors.authGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Your workspace', style: AppTextStyles.authHeading),
          const SizedBox(height: 4),
          Text(
            'About 3 minutes. We filled in common answers, so only change what’s different.',
            style: AppTextStyles.authDescription,
          ),
        ],
      ),
    );
  }

  Widget _workspaceForm(StartupSetup setup, SetupCountry country) {
    final compactFields = MediaQuery.sizeOf(context).width < 600;
    return Form(
      key: _formKey,
      child: _SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SetupSection(
              title: 'Workspace name',
              child: TextFormField(
                key: const ValueKey('signup-workspace-name'),
                initialValue: setup.workspaceName,
                textCapitalization: TextCapitalization.words,
                validator: _required,
                onChanged: (value) {
                  setup.workspaceName = value;
                  _notifyWorkspaceSummary();
                },
                decoration: setupInputDecoration(
                  hintText: 'e.g. Ramla Workspace',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 13),
              child: Text(
                'Staff see it on every screen. Customers see it on receipts.',
                style: AppTextStyles.authHelper.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
            if (compactFields) ...[
              _ownerField(setup),
              SetupSection(
                title: 'Phone number',
                child: _phoneFields(setup, country),
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ownerField(setup)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SetupSection(
                      title: 'Phone number',
                      child: _phoneFields(setup, country),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'You, the owner. Not the workspace.',
                      style: AppTextStyles.authHelper.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only our team sees this, so we can contact you.',
                      style: AppTextStyles.authHelper.copyWith(
                        color: AppColors.authInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Where is it?', style: AppTextStyles.authFieldLabel),
            ),
            SetupSection(
              title: 'Country',
              child: DropdownButtonFormField<SetupCountry>(
                key: ValueKey('workspace-country-${country.name}'),
                initialValue: country,
                isExpanded: true,
                decoration: setupInputDecoration(),
                items: [
                  for (final option in setupCountries)
                    DropdownMenuItem(
                      value: option,
                      child: Text('${option.flag}  ${option.name}'),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    setup.country = value;
                    setup.city = null;
                    setup.cityChoice = null;
                  });
                },
              ),
            ),
            if (compactFields) ...[
              SetupSection(title: 'City', child: _cityField(setup, country)),
              SetupSection(
                title: 'Area (optional)',
                child: TextFormField(
                  key: const ValueKey('setup-area'),
                  initialValue: setup.area,
                  onChanged: (value) {
                    setup.area = value;
                    _notifyWorkspaceSummary();
                  },
                  decoration: setupInputDecoration(hintText: 'e.g. Dokki'),
                ),
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SetupSection(
                      title: 'City',
                      child: _cityField(setup, country),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SetupSection(
                      title: 'Area (optional)',
                      child: TextFormField(
                        key: const ValueKey('setup-area'),
                        initialValue: setup.area,
                        onChanged: (value) {
                          setup.area = value;
                          _notifyWorkspaceSummary();
                        },
                        decoration: setupInputDecoration(
                          hintText: 'e.g. Dokki',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (setup.cityChoice == 'Other')
              SetupSection(
                title: 'City name',
                child: TextFormField(
                  key: ValueKey('setup-city-other-${country.name}'),
                  initialValue: setup.city == 'Other' ? '' : setup.city,
                  onChanged: (value) {
                    setup.city = value;
                    _notifyWorkspaceSummary();
                  },
                  validator: _required,
                  decoration: setupInputDecoration(hintText: 'Enter your city'),
                ),
              ),
            SetupSection(
              title: 'Opening hours',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HoursOption(
                    label: 'Open 24 hours',
                    selected: setup.hoursMode == SetupHoursMode.twentyFourHours,
                    onChanged: () => setState(
                      () => setup.hoursMode = SetupHoursMode.twentyFourHours,
                    ),
                  ),
                  _HoursOption(
                    label: 'Every day, same hours',
                    selected: setup.hoursMode == SetupHoursMode.sameEveryDay,
                    onChanged: () => setState(
                      () => setup.hoursMode = SetupHoursMode.sameEveryDay,
                    ),
                  ),
                  if (setup.hoursMode == SetupHoursMode.sameEveryDay) ...[
                    const SizedBox(height: 10),
                    _hoursRow(
                      setup.opensAt,
                      setup.closesAt,
                      onOpen: (time) => setState(() => setup.opensAt = time),
                      onClose: (time) => setState(() => setup.closesAt = time),
                    ),
                  ],
                  _HoursOption(
                    label: 'Set hours for each day',
                    selected: setup.hoursMode == SetupHoursMode.perDay,
                    onChanged: () =>
                        setState(() => setup.hoursMode = SetupHoursMode.perDay),
                  ),
                  if (setup.hoursMode == SetupHoursMode.perDay) ...[
                    const SizedBox(height: 10),
                    for (final day in setup.schedule)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            SizedBox(width: 42, child: Text(day.day)),
                            Switch(
                              value: day.isOpen,
                              onChanged: (value) =>
                                  setState(() => day.isOpen = value),
                            ),
                            if (day.isOpen)
                              Expanded(
                                child: _hoursRow(
                                  day.opensAt,
                                  day.closesAt,
                                  onOpen: (time) =>
                                      setState(() => day.opensAt = time),
                                  onClose: (time) =>
                                      setState(() => day.closesAt = time),
                                ),
                              )
                            else
                              const Expanded(child: Text('Closed')),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                key: const ValueKey('signup-setup-feedback'),
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('workspace-continue'),
                onPressed: _isSubmitting ? null : _continue,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ownerField(StartupSetup setup) {
    return SetupSection(
      title: 'Your name',
      child: TextFormField(
        key: const ValueKey('signup-full-name'),
        initialValue: setup.ownerName,
        textCapitalization: TextCapitalization.words,
        validator: _required,
        onChanged: (value) => setup.ownerName = value,
        decoration: setupInputDecoration(hintText: 'e.g. Karim Hassan'),
      ),
    );
  }

  Widget _phoneFields(StartupSetup setup, SetupCountry country) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: DropdownButtonFormField<SetupCountry>(
            key: ValueKey('phone-code-${country.name}'),
            initialValue: country,
            isExpanded: true,
            decoration: setupInputDecoration(),
            selectedItemBuilder: (context) => [
              for (final option in setupCountries)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(option.flag),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          option.phoneCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            items: [
              for (final option in setupCountries)
                DropdownMenuItem(
                  value: option,
                  child: Text(
                    '${option.flag} ${option.phoneCode}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                setup.country = value;
                setup.city = null;
                setup.cityChoice = null;
              });
            },
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextFormField(
            key: const ValueKey('setup-phone'),
            initialValue: setup.phone,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            onChanged: (value) {
              setup.phone = value;
              _notifyWorkspaceSummary();
            },
            decoration: setupInputDecoration(
              hintText: country.name == 'Egypt'
                  ? '0xxxxxxxxxx'
                  : 'Phone number',
            ),
          ),
        ),
      ],
    );
  }

  Widget _cityField(StartupSetup setup, SetupCountry country) {
    return DropdownButtonFormField<String>(
      key: ValueKey('workspace-city-${country.name}-${setup.cityChoice}'),
      initialValue: country.cities.contains(setup.cityChoice)
          ? setup.cityChoice
          : null,
      isExpanded: true,
      decoration: setupInputDecoration(hintText: 'Choose a city'),
      validator: (value) => _required(value),
      items: [
        for (final city in country.cities)
          DropdownMenuItem(value: city, child: Text(city)),
      ],
      onChanged: (value) => setState(() {
        setup.cityChoice = value;
        setup.city = value == 'Other' ? '' : value;
      }),
    );
  }

  Widget _summary(StartupSetup setup) {
    final location = [
      setup.city,
      if (setup.area.trim().isNotEmpty) setup.area.trim(),
      setup.country.name,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
    final phone = setup.phone.isEmpty
        ? 'Not added yet\nOnly our team sees it'
        : '${setup.country.phoneCode} ${setup.phone}';
    final hours = switch (setup.hoursMode) {
      SetupHoursMode.twentyFourHours => 'Open 24 hours',
      SetupHoursMode.sameEveryDay =>
        'Every day · ${_formatTime(setup.opensAt)} – ${_formatTime(setup.closesAt)}',
      SetupHoursMode.perDay => 'Custom hours',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Your setup so far', style: AppTextStyles.authFieldLabel),
        const SizedBox(height: 3),
        const Text('Updates as you choose', style: AppTextStyles.authHelper),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.authGreen),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.homePaleGreen,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadii.control - 1),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: AppColors.authGreen,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STEP 1 INFO',
                            style: TextStyle(
                              color: AppColors.authMuted,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            'Workspace',
                            style: TextStyle(
                              color: AppColors.authInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Filling in now',
                      style: TextStyle(
                        color: AppColors.authGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _SummaryRow(
                label: 'Name',
                value: setup.workspaceName.isEmpty
                    ? 'Not added yet'
                    : setup.workspaceName,
              ),
              _SummaryRow(
                label: 'Location',
                value: location.isEmpty ? 'Not added yet' : location,
              ),
              _SummaryRow(label: 'Phone', value: phone),
              _SummaryRow(label: 'Hours', value: hours, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.authGreen, size: 15),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Opening hours decide which times staff can book rooms for you. You can change them any time, for example in Ramadan.',
                style: TextStyle(
                  color: AppColors.authGreen,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hoursRow(
    String opensAt,
    String closesAt, {
    required ValueChanged<String> onOpen,
    required ValueChanged<String> onClose,
  }) {
    final isOvernight = _minutes(closesAt) <= _minutes(opensAt);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 4,
      children: [
        _timeButton('Opens', opensAt, onOpen),
        const Text('to'),
        _timeButton('Closes', closesAt, onClose),
        if (isOvernight)
          const Text(
            'next day',
            style: TextStyle(color: AppColors.authMuted, fontSize: 11),
          ),
      ],
    );
  }

  Widget _timeButton(
    String label,
    String value,
    ValueChanged<String> onSelected,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final time = await pickSetupTime(context, value);
        if (time != null) onSelected(time);
      },
      child: Text('$label ${_formatTime(value)}'),
    );
  }

  int _minutes(String time) {
    final parts = time.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: child,
    );
  }
}

class _HoursOption extends StatelessWidget {
  const _HoursOption({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => onChanged(),
              ),
              Expanded(child: Text(label, style: AppTextStyles.authSmallText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.authBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(label, style: AppTextStyles.authHelper),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.authInk,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
