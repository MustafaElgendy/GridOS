import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';

import 'workspace_page_utils.dart';

enum _BookingFilter { all, oneTime, longTerm }

class _BookingDateRange {
  const _BookingDateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  DateTime get endInclusive => endExclusive.subtract(const Duration(days: 1));

  bool includes(Booking booking) {
    if (booking.weekdays.isEmpty) {
      return !booking.startsAt.isBefore(start) &&
          booking.startsAt.isBefore(endExclusive);
    }

    final bookingStart = DateTime(
      booking.startsAt.year,
      booking.startsAt.month,
      booking.startsAt.day,
    );
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    final firstDay = rangeStart.isAfter(bookingStart)
        ? rangeStart
        : bookingStart;
    for (var offset = 0; offset < 7; offset++) {
      final day = DateTime(
        firstDay.year,
        firstDay.month,
        firstDay.day + offset,
      );
      if (!day.isBefore(rangeEnd)) return false;
      if (booking.until != null &&
          day.isAfter(
            DateTime(
              booking.until!.year,
              booking.until!.month,
              booking.until!.day,
            ),
          )) {
        return false;
      }
      if (booking.weekdays.contains(day.weekday)) return true;
    }
    return false;
  }

  static _BookingDateRange forPreset(String preset, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return switch (preset) {
      'Tomorrow' => _BookingDateRange(
        start: tomorrow,
        endExclusive: tomorrow.add(const Duration(days: 1)),
      ),
      'Next 7 days' => _BookingDateRange(
        start: today,
        endExclusive: today.add(const Duration(days: 7)),
      ),
      'This month' => _BookingDateRange(
        start: DateTime(today.year, today.month),
        endExclusive: DateTime(today.year, today.month + 1),
      ),
      'Next month' => _BookingDateRange(
        start: DateTime(today.year, today.month + 1),
        endExclusive: DateTime(today.year, today.month + 2),
      ),
      'Last 7 days' => _BookingDateRange(
        start: today.subtract(const Duration(days: 6)),
        endExclusive: tomorrow,
      ),
      _ => _BookingDateRange(start: today, endExclusive: tomorrow),
    };
  }
}

class _SelectedBookingDateRange {
  const _SelectedBookingDateRange({required this.label, required this.range});

  final String label;
  final _BookingDateRange range;
}

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
  String _datePreset = 'Today';
  late _BookingDateRange _dateRange = _BookingDateRange.forPreset(
    _datePreset,
    DateTime.now(),
  );

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
    amount: booking.amount,
    paidAmount: booking.paidAmount,
    weekdays: booking.weekdays,
    until: booking.until,
  );

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  Future<void> _openDateFilter() async {
    final selection = await showDialog<_SelectedBookingDateRange>(
      context: context,
      builder: (context) => _BookingDateFilterDialog(
        initialLabel: _datePreset,
        initialRange: _dateRange,
      ),
    );
    if (selection == null) return;
    setState(() {
      _datePreset = selection.label;
      _dateRange = selection.range;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookings = widget.repository.bookings.where((booking) {
      if (!_dateRange.includes(booking)) return false;
      if (_filter == _BookingFilter.oneTime) {
        return booking.kind == BookingKind.oneTime;
      }
      if (_filter == _BookingFilter.longTerm) {
        return booking.kind == BookingKind.longTerm;
      }
      return true;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final bookingsBySpace = <SetupSpaceType?, Map<String, List<Booking>>>{};
    for (final booking in bookings) {
      final type = booking.spaceType;
      final name = booking.spaceName ?? type?.label ?? 'Other space';
      (bookingsBySpace[type] ??= <String, List<Booking>>{})
          .putIfAbsent(name, () => [])
          .add(booking);
    }
    final categories = <({String name, Map<String, List<Booking>> spaces})>[];
    for (final type in SetupSpaceType.values) {
      final spaces = bookingsBySpace[type];
      if (spaces != null) {
        categories.add((name: _bookingCategoryName(type), spaces: spaces));
      }
    }
    final otherSpaces = bookingsBySpace[null];
    if (otherSpaces != null) {
      categories.add((name: 'Other spaces', spaces: otherSpaces));
    }
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
          spacing: 8,
          runSpacing: 7,
          children: [
            OutlinedButton(
              key: const ValueKey('workspace-booking-date-filter'),
              onPressed: _openDateFilter,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15),
                  const SizedBox(width: 7),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dates',
                        style: TextStyle(fontSize: 9, height: 1),
                      ),
                      Text(
                        '${_datePreset == 'Custom dates' ? 'Custom' : _datePreset}  '
                        '${_bookingRangeLabel(_dateRange)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.keyboard_arrow_down, size: 15),
                ],
              ),
            ),
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
          for (final category in categories) ...[
            const SizedBox(height: 8),
            _BookingCategoryPanel(
              name: category.name,
              spaces: category.spaces,
              customerFor: widget.repository.customerById,
              currency: widget.setup.country.currency,
              onEdit: _editBooking,
              onCancel: _cancelBooking,
            ),
          ],
      ],
    );
  }
}

class _BookingDateFilterDialog extends StatefulWidget {
  const _BookingDateFilterDialog({
    required this.initialLabel,
    required this.initialRange,
  });

  final String initialLabel;
  final _BookingDateRange initialRange;

  @override
  State<_BookingDateFilterDialog> createState() =>
      _BookingDateFilterDialogState();
}

class _BookingDateFilterDialogState extends State<_BookingDateFilterDialog> {
  static const _presets = [
    'Today',
    'Tomorrow',
    'Next 7 days',
    'This month',
    'Next month',
    'Last 7 days',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late String _selectedLabel = widget.initialLabel;
  late DateTime _start = widget.initialRange.start;
  late DateTime _end = widget.initialRange.endInclusive;
  late int _visibleYear = _start.year;

  _BookingDateRange get _range => _BookingDateRange(
    start: DateTime(_start.year, _start.month, _start.day),
    endExclusive: DateTime(_end.year, _end.month, _end.day + 1),
  );

  void _selectPreset(String preset) {
    final range = _BookingDateRange.forPreset(preset, DateTime.now());
    setState(() {
      _selectedLabel = preset;
      _start = range.start;
      _end = range.endInclusive;
      _visibleYear = _start.year;
    });
  }

  void _selectMonth(int month) {
    final start = DateTime(_visibleYear, month);
    final endExclusive = DateTime(_visibleYear, month + 1);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    setState(() {
      _start = start;
      _end = endExclusive.subtract(const Duration(days: 1));
      _selectedLabel = start == currentMonth
          ? 'This month'
          : start == nextMonth
          ? 'Next month'
          : 'Custom dates';
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedLabel = 'Custom dates';
      if (isStart) {
        _start = selected;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = selected;
        if (_start.isAfter(_end)) _start = _end;
      }
      _visibleYear = selected.year;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _SelectedBookingDateRange(label: _selectedLabel, range: _range),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthPicker = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pick months',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              key: const ValueKey('workspace-booking-date-previous-year'),
              tooltip: 'Previous year',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _visibleYear--),
              icon: const Icon(Icons.chevron_left, size: 18),
            ),
            Text(
              '$_visibleYear',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              key: const ValueKey('workspace-booking-date-next-year'),
              tooltip: 'Next year',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _visibleYear++),
              icon: const Icon(Icons.chevron_right, size: 18),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 2.1,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var month = 1; month <= 12; month++)
              OutlinedButton(
                key: ValueKey('workspace-booking-date-month-$month'),
                onPressed: () => _selectMonth(month),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor:
                      _start.year == _visibleYear && _start.month == month
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(_months[month - 1]),
              ),
          ],
        ),
      ],
    );

    final customDates = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 18),
        const Text(
          'Or your own dates',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              key: const ValueKey('workspace-booking-date-from'),
              onPressed: () => _pickDate(isStart: true),
              child: Text('From  ${formatWorkspaceDate(_start)}'),
            ),
            OutlinedButton(
              key: const ValueKey('workspace-booking-date-to'),
              onPressed: () => _pickDate(isStart: false),
              child: Text('To  ${formatWorkspaceDate(_end)}'),
            ),
            FilledButton(
              key: const ValueKey('workspace-booking-date-apply'),
              onPressed: _apply,
              child: const Text('Show'),
            ),
          ],
        ),
      ],
    );

    return AlertDialog(
      title: const Text('Dates'),
      content: SizedBox(
        width: 610,
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final preset in _presets)
                          ChoiceChip(
                            key: ValueKey(
                              'workspace-booking-date-preset-$preset',
                            ),
                            label: Text(preset),
                            selected: _selectedLabel == preset,
                            onSelected: (_) => _selectPreset(preset),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    monthPicker,
                    customDates,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 145,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final preset in _presets)
                          _BookingDatePresetTile(
                            preset: preset,
                            selected: _selectedLabel == preset,
                            range: _BookingDateRange.forPreset(
                              preset,
                              DateTime.now(),
                            ),
                            onPressed: () => _selectPreset(preset),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(children: [monthPicker, customDates])),
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _BookingDatePresetTile extends StatelessWidget {
  const _BookingDatePresetTile({
    required this.preset,
    required this.selected,
    required this.range,
    required this.onPressed,
  });

  final String preset;
  final bool selected;
  final _BookingDateRange range;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('workspace-booking-date-preset-$preset'),
      dense: true,
      visualDensity: VisualDensity.compact,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(preset, style: const TextStyle(fontSize: 12)),
      subtitle: Text(
        _bookingRangeLabel(range),
        style: const TextStyle(fontSize: 10),
      ),
      onTap: onPressed,
    );
  }
}

String _bookingRangeLabel(_BookingDateRange range) {
  final start = range.start;
  final end = range.endInclusive;
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return '${_bookingMonthName(start.month)} ${start.day}';
  }
  if (start.year == end.year && start.month == end.month) {
    return '${_bookingMonthName(start.month)} ${start.day}–${end.day}';
  }
  return '${formatWorkspaceDate(start)}–${formatWorkspaceDate(end)}';
}

String _bookingMonthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

class _BookingCategoryPanel extends StatelessWidget {
  const _BookingCategoryPanel({
    required this.name,
    required this.spaces,
    required this.customerFor,
    required this.currency,
    required this.onEdit,
    required this.onCancel,
  });

  final String name;
  final Map<String, List<Booking>> spaces;
  final Customer? Function(String id) customerFor;
  final String currency;
  final ValueChanged<Booking> onEdit;
  final ValueChanged<Booking> onCancel;

  @override
  Widget build(BuildContext context) {
    final bookingCount = spaces.values.fold<int>(
      0,
      (total, bookings) => total + bookings.length,
    );
    return DashboardPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
            child: Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$bookingCount booking${bookingCount == 1 ? '' : 's'} · '
                  '${spaces.length} space${spaces.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final entry in spaces.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${entry.value.length} booking${entry.value.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            for (var index = 0; index < entry.value.length; index++) ...[
              _BookingRow(
                booking: entry.value[index],
                customer: customerFor(entry.value[index].customerId),
                currency: currency,
                onEdit: () => onEdit(entry.value[index]),
                onCancel: () => onCancel(entry.value[index]),
              ),
              if (index < entry.value.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
            if (entry.key != spaces.keys.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({
    required this.booking,
    required this.customer,
    required this.currency,
    required this.onEdit,
    required this.onCancel,
  });

  final Booking booking;
  final Customer? customer;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final status = _bookingStatus(booking, DateTime.now());
    final owing = (booking.amount - booking.paidAmount).clamp(
      0.0,
      double.infinity,
    );
    final time = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatWorkspaceDate(booking.startsAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          '${formatWorkspaceTime(booking.startsAt)} – '
          '${formatWorkspaceTime(booking.endsAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
    final customerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          customer?.name ?? 'Customer',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (customer?.phone?.isNotEmpty == true)
          Text(customer!.phone!, style: Theme.of(context).textTheme.bodySmall),
        if (booking.notes?.isNotEmpty == true)
          Text(booking.notes!, style: Theme.of(context).textTheme.bodySmall),
        if (booking.kind == BookingKind.longTerm) ...[
          Text(
            'Repeats ${booking.weekdays.map(_weekdayLabel).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (booking.until != null)
            Text(
              'Until ${formatWorkspaceDate(booking.until!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ],
    );
    final statusBadge = _BookingStatusBadge(status: status);
    final payment = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Paid ${formatWorkspaceAmount(booking.paidAmount, currency)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Owes ${formatWorkspaceAmount(owing, currency)}',
          style: TextStyle(
            color: owing > 0 ? Colors.deepOrange.shade800 : null,
            fontSize: 11,
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit booking',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        if (booking.status != BookingStatus.cancelled &&
            booking.status != BookingStatus.completed)
          IconButton(
            tooltip: 'Cancel booking',
            onPressed: onCancel,
            icon: const Icon(Icons.close),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                time,
                const SizedBox(height: 5),
                customerInfo,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [statusBadge, payment],
                ),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              SizedBox(width: 130, child: time),
              Expanded(child: customerInfo),
              statusBadge,
              const SizedBox(width: 14),
              SizedBox(width: 145, child: payment),
              actions,
            ],
          ),
        );
      },
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'In use now' => Colors.green,
      'Coming up' => Colors.blue,
      'Cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color.shade800,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _weekdayLabel(int day) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];

String _bookingCategoryName(SetupSpaceType type) => switch (type) {
  SetupSpaceType.sharedArea => 'Shared areas',
  SetupSpaceType.virtualOffice => 'Virtual offices',
  SetupSpaceType.other => 'Other spaces',
  _ => type.label,
};

String _bookingStatus(Booking booking, DateTime now) {
  if (booking.status == BookingStatus.cancelled) return 'Cancelled';
  if (booking.status == BookingStatus.completed) return 'Done';

  final start = _nextBookingOccurrence(booking, now);
  if (start == null) return 'Done';
  final end = start.add(booking.endsAt.difference(booking.startsAt));
  if (now.isBefore(start)) return 'Coming up';
  if (now.isBefore(end)) return 'In use now';
  return 'Done';
}

DateTime? _nextBookingOccurrence(Booking booking, DateTime now) {
  if (booking.weekdays.isEmpty) return booking.startsAt;

  final firstDay = DateTime(
    booking.startsAt.year,
    booking.startsAt.month,
    booking.startsAt.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  final startDay = today.isAfter(firstDay) ? today : firstDay;
  for (var offset = 0; offset <= 370; offset++) {
    final day = DateTime(startDay.year, startDay.month, startDay.day + offset);
    if (booking.until != null &&
        day.isAfter(
          DateTime(
            booking.until!.year,
            booking.until!.month,
            booking.until!.day,
          ),
        )) {
      return null;
    }
    if (!booking.weekdays.contains(day.weekday)) continue;
    final occurrence = DateTime(
      day.year,
      day.month,
      day.day,
      booking.startsAt.hour,
      booking.startsAt.minute,
    );
    final end = occurrence.add(booking.endsAt.difference(booking.startsAt));
    if (!end.isBefore(now)) return occurrence;
  }
  return null;
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
  late final _amount = TextEditingController(
    text: (widget.booking?.amount ?? 0).toString(),
  );
  late final _paidAmount = TextEditingController(
    text: (widget.booking?.paidAmount ?? 0).toString(),
  );
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
    _amount.dispose();
    _paidAmount.dispose();
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
    setState(() => _fieldError = null);
    final amount = double.parse(_amount.text.trim());
    final paidAmount = double.parse(_paidAmount.text.trim());
    if (paidAmount > amount) {
      setState(() => _fieldError = 'Paid amount cannot exceed the total.');
      return;
    }
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
        amount: amount,
        paidAmount: paidAmount,
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
                TextFormField(
                  key: const ValueKey('workspace-booking-amount'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: workspaceInputDecoration(
                    'Total price (${widget.setup.country.currency})',
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('workspace-booking-paid-amount'),
                  controller: _paidAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: workspaceInputDecoration(
                    'Amount paid (${widget.setup.country.currency})',
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 10),
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

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount < 0) {
      return 'Enter a valid non-negative amount';
    }
    return null;
  }
}
