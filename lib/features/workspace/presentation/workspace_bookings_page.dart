import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';

import 'workspace_page_utils.dart';

enum _BookingFilter { all, oneTime, longTerm }

class WorkspaceBookingsPage extends StatefulWidget {
  const WorkspaceBookingsPage({
    super.key,
    required this.repository,
    required this.setup,
    required this.onChanged,
    required this.onOpenFrontDesk,
  });

  final WorkspaceRepository repository;
  final StartupSetup setup;
  final VoidCallback onChanged;
  final VoidCallback onOpenFrontDesk;

  @override
  State<WorkspaceBookingsPage> createState() => _WorkspaceBookingsPageState();
}

class _WorkspaceBookingsPageState extends State<WorkspaceBookingsPage> {
  _BookingFilter _filter = _BookingFilter.all;

  Future<void> _addBooking() async {
    final booking = await showDialog<Booking>(
      context: context,
      builder: (context) => _BookingFormDialog(
        repository: widget.repository,
        setup: widget.setup,
      ),
    );
    if (booking == null) return;
    widget.repository.createBooking(booking);
    _changed();
  }

  Future<void> _editBooking(Booking booking) async {
    final updated = await showDialog<Booking>(
      context: context,
      builder: (context) => _BookingFormDialog(
        repository: widget.repository,
        setup: widget.setup,
        booking: booking,
      ),
    );
    if (updated == null) return;
    widget.repository.updateBooking(updated);
    _changed();
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This booking will no longer appear as scheduled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    widget.repository.updateBooking(
      _copyBooking(booking, status: BookingStatus.cancelled),
    );
    _changed();
  }

  Booking _copyBooking(Booking booking, {BookingStatus? status}) => Booking(
    id: booking.id,
    customerId: booking.customerId,
    kind: booking.kind,
    startsAt: booking.startsAt,
    endsAt: booking.endsAt,
    status: status ?? booking.status,
    spaceType: booking.spaceType,
    spaceName: booking.spaceName,
    notes: booking.notes,
    weekdays: booking.weekdays,
    until: booking.until,
  );

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = widget.repository.bookings.where((booking) {
      if (_filter == _BookingFilter.oneTime) {
        return booking.kind == BookingKind.oneTime;
      }
      if (_filter == _BookingFilter.longTerm) {
        return booking.kind == BookingKind.longTerm;
      }
      return true;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Bookings',
          'See and manage bookings for your spaces.',
          trailing: FilledButton.icon(
            onPressed: _addBooking,
            icon: const Icon(Icons.add, size: 17),
            label: const Text('New booking'),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          children: [
            for (final filter in _BookingFilter.values)
              ChoiceChip(
                label: Text(switch (filter) {
                  _BookingFilter.all => 'All',
                  _BookingFilter.oneTime => 'One-time',
                  _BookingFilter.longTerm => 'Long-term',
                }),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          DashboardEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No bookings yet',
            description: 'When staff book on Today, it shows up here.',
            actionLabel: 'Open the front desk',
            onPressed: widget.onOpenFrontDesk,
          )
        else
          for (final booking in bookings) ...[
            const SizedBox(height: 8),
            _BookingCard(
              booking: booking,
              customer: widget.repository.customerById(booking.customerId),
              onEdit: () => _editBooking(booking),
              onCancel: () => _cancelBooking(booking),
            ),
          ],
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.customer,
    required this.onEdit,
    required this.onCancel,
  });

  final Booking booking;
  final Customer? customer;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final days = booking.weekdays.map(_weekdayLabel).join(', ');
    final isCancelled = booking.status == BookingStatus.cancelled;
    return DashboardPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_available_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer?.name ?? 'Customer',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    booking.spaceName ?? booking.spaceType?.label ?? 'Space',
                    formatWorkspaceDate(booking.startsAt),
                    '${formatWorkspaceTime(booking.startsAt)}–${formatWorkspaceTime(booking.endsAt)}',
                    if (booking.kind == BookingKind.longTerm && days.isNotEmpty)
                      'Repeats $days',
                    if (booking.until != null)
                      'Until ${formatWorkspaceDate(booking.until!)}',
                    if (isCancelled) 'Cancelled',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (booking.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(booking.notes!),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit booking',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          if (!isCancelled)
            IconButton(
              tooltip: 'Cancel booking',
              onPressed: onCancel,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  String _weekdayLabel(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}

class _BookingFormDialog extends StatefulWidget {
  const _BookingFormDialog({
    required this.repository,
    required this.setup,
    this.booking,
  });

  final WorkspaceRepository repository;
  final StartupSetup setup;
  final Booking? booking;

  @override
  State<_BookingFormDialog> createState() => _BookingFormDialogState();
}

class _BookingFormDialogState extends State<_BookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _customer = TextEditingController(
    text: widget.booking == null
        ? ''
        : widget.repository.customerById(widget.booking!.customerId)?.name,
  );
  late final _phone = TextEditingController(
    text: widget.booking == null
        ? ''
        : widget.repository.customerById(widget.booking!.customerId)?.phone,
  );
  late final _notes = TextEditingController(text: widget.booking?.notes);
  late BookingKind _kind = widget.booking?.kind ?? BookingKind.oneTime;
  late DateTime _startsAt = widget.booking?.startsAt ?? DateTime.now();
  late DateTime _endsAt =
      widget.booking?.endsAt ?? DateTime.now().add(const Duration(hours: 1));
  late DateTime? _until = widget.booking?.until;
  late Set<int> _weekdays = {...?widget.booking?.weekdays};
  late SetupSpaceType? _spaceType = widget.booking?.spaceType;
  late String? _spaceName = widget.booking?.spaceName;
  String? _fieldError;

  List<WorkspaceSpaceOption> get _spaceOptions =>
      workspaceSpaceOptions(widget.setup);

  @override
  void initState() {
    super.initState();
    if (_spaceType == null && _spaceOptions.isNotEmpty) {
      _spaceType = _spaceOptions.first.type;
      _spaceName = _spaceOptions.first.name;
    }
    if (_kind == BookingKind.longTerm && _weekdays.isEmpty) {
      _weekdays = {_startsAt.weekday};
    }
  }

  @override
  void dispose() {
    _customer.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool end}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: end ? (_until ?? _startsAt) : _startsAt,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected == null || !mounted) return;
    if (end) {
      setState(() => _until = selected);
      return;
    }
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day,
      _startsAt.hour,
      _startsAt.minute,
    );
    setState(() {
      final duration = _endsAt.difference(_startsAt);
      _startsAt = start;
      _endsAt = start.add(
        duration.isNegative || duration == Duration.zero
            ? const Duration(hours: 1)
            : duration,
      );
    });
  }

  Future<void> _pickTime({required bool end}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(end ? _endsAt : _startsAt),
    );
    if (selected == null || !mounted) return;
    final old = end ? _endsAt : _startsAt;
    final value = DateTime(
      old.year,
      old.month,
      old.day,
      selected.hour,
      selected.minute,
    );
    setState(() {
      if (end) {
        _endsAt = value;
      } else {
        final duration = _endsAt.difference(_startsAt);
        _startsAt = value;
        if (!duration.isNegative && duration > Duration.zero) {
          _endsAt = value.add(duration);
        }
      }
    });
  }

  String _spaceValue(WorkspaceSpaceOption option) =>
      '${option.type.name}|${option.name}';

  WorkspaceSpaceOption? get _selectedSpace {
    for (final option in _spaceOptions) {
      if (option.type == _spaceType && option.name == _spaceName) return option;
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_endsAt.isBefore(_startsAt) || _endsAt.isAtSameMomentAs(_startsAt)) {
      setState(() => _fieldError = 'End time must be after start time.');
      return;
    }
    if (_kind == BookingKind.longTerm && _weekdays.isEmpty) {
      setState(() => _fieldError = 'Choose at least one day.');
      return;
    }
    final customerName = _customer.text.trim();
    final customerPhone = _phone.text.trim();
    Customer? customer;
    for (final existing in widget.repository.customers) {
      final sameName =
          existing.name.toLowerCase() == customerName.toLowerCase();
      final samePhone =
          customerPhone.isNotEmpty && existing.phone == customerPhone;
      if (sameName || samePhone) {
        customer = existing;
        break;
      }
    }
    customer ??= widget.repository.createCustomer(
      Customer(
        id: newWorkspaceId('customer'),
        name: customerName,
        phone: customerPhone.isEmpty ? null : customerPhone,
        createdAt: DateTime.now(),
      ),
    );
    final old = widget.booking;
    Navigator.pop(
      context,
      Booking(
        id: old?.id ?? newWorkspaceId('booking'),
        customerId: customer.id,
        kind: _kind,
        startsAt: _startsAt,
        endsAt: _endsAt,
        status: old?.status ?? BookingStatus.confirmed,
        spaceType: _spaceType,
        spaceName: _spaceName,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        weekdays: _kind == BookingKind.longTerm ? _weekdays : const {},
        until: _kind == BookingKind.longTerm ? _until : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSpace = _selectedSpace;
    return AlertDialog(
      title: Text(widget.booking == null ? 'New booking' : 'Edit booking'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('workspace-booking-customer'),
                  controller: _customer,
                  autofocus: true,
                  decoration: workspaceInputDecoration('Customer name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a customer name'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: workspaceInputDecoration('Phone (optional)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<BookingKind>(
                  isExpanded: true,
                  initialValue: _kind,
                  decoration: workspaceInputDecoration('Booking type'),
                  items: const [
                    DropdownMenuItem(
                      value: BookingKind.oneTime,
                      child: Text('One-time'),
                    ),
                    DropdownMenuItem(
                      value: BookingKind.longTerm,
                      child: Text('Long-term / recurring'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _kind = value;
                      if (value == BookingKind.longTerm && _weekdays.isEmpty) {
                        _weekdays = {_startsAt.weekday};
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (_spaceOptions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: selectedSpace == null
                        ? null
                        : _spaceValue(selectedSpace),
                    decoration: workspaceInputDecoration('Space'),
                    items: [
                      for (final option in _spaceOptions)
                        DropdownMenuItem(
                          value: _spaceValue(option),
                          child: Text('${option.type.label} · ${option.name}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      final option = _spaceOptions.firstWhere(
                        (item) => _spaceValue(item) == value,
                      );
                      setState(() {
                        _spaceType = option.type;
                        _spaceName = option.name;
                      });
                    },
                  ),
                if (_spaceOptions.isNotEmpty) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _pickDate(end: false),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(formatWorkspaceDate(_startsAt)),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickTime(end: false),
                        child: Text(formatWorkspaceTime(_startsAt)),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Ends')),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickTime(end: true),
                        child: Text(formatWorkspaceTime(_endsAt)),
                      ),
                    ),
                  ],
                ),
                if (_kind == BookingKind.longTerm) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Repeats on'),
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (var day = 1; day <= 7; day++)
                        FilterChip(
                          label: Text(_weekdayLabel(day)),
                          selected: _weekdays.contains(day),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _weekdays.add(day);
                            } else {
                              _weekdays.remove(day);
                            }
                          }),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _pickDate(end: true),
                    child: Text(
                      _until == null
                          ? 'No end date'
                          : 'Until ${formatWorkspaceDate(_until!)}',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: workspaceInputDecoration('Notes (optional)'),
                ),
                if (_fieldError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _fieldError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save booking')),
      ],
    );
  }

  String _weekdayLabel(int day) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
}
