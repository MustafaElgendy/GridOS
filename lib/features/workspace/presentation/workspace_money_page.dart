import 'package:flutter/material.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';

import 'workspace_page_utils.dart';

enum _MoneyView { summary, income, expenses }

class WorkspaceMoneyPage extends StatefulWidget {
  const WorkspaceMoneyPage({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.currency,
  });

  final WorkspaceRepository repository;
  final VoidCallback onChanged;
  final String currency;

  @override
  State<WorkspaceMoneyPage> createState() => _WorkspaceMoneyPageState();
}

class _WorkspaceMoneyPageState extends State<WorkspaceMoneyPage> {
  _MoneyView _view = _MoneyView.summary;
  String _period = 'This month';

  DateTime? get _fromDate {
    final now = DateTime.now();
    switch (_period) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This week':
        return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case 'This month':
        return DateTime(now.year, now.month);
      case 'This year':
        return DateTime(now.year);
      default:
        return null;
    }
  }

  Future<void> _addEntry(MoneyEntryKind kind) async {
    final draft = await showDialog<_MoneyEntryDraft>(
      context: context,
      builder: (context) =>
          _MoneyEntryDialog(kind: kind, currency: widget.currency),
    );
    if (draft == null) return;
    widget.repository.createMoneyEntry(
      MoneyEntry(
        id: newWorkspaceId('money'),
        kind: kind,
        amount: draft.amount,
        occurredAt: draft.occurredAt,
        currency: widget.currency,
        description: draft.description,
        paymentMethod: draft.paymentMethod,
      ),
    );
    _changed();
  }

  DateTime _nextDueDate(DateTime dueAt, BillFrequency frequency) {
    if (frequency == BillFrequency.weekly) {
      return dueAt.add(const Duration(days: 7));
    }
    final monthOffset = frequency == BillFrequency.yearly ? 12 : 1;
    final targetMonth = DateTime(dueAt.year, dueAt.month + monthOffset, 1);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      dueAt.day > lastDay ? lastDay : dueAt.day,
      dueAt.hour,
      dueAt.minute,
    );
  }

  Future<void> _addBill() async {
    final draft = await showDialog<_BillDraft>(
      context: context,
      builder: (context) => _BillDialog(currency: widget.currency),
    );
    if (draft == null) return;
    widget.repository.createBill(
      Bill(
        id: newWorkspaceId('bill'),
        amount: draft.amount,
        currency: widget.currency,
        description: draft.description,
        issuedAt: DateTime.now(),
        dueAt: draft.dueAt,
        frequency: draft.frequency,
      ),
    );
    _changed();
  }

  Future<void> _markBillPaid(Bill bill) async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Mark ${bill.description} paid'),
        children: [
          for (final option in ['Cash', 'Card', 'Transfer'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option),
              child: Text(option),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (method == null) return;
    final paidAt = DateTime.now();
    widget.repository.updateBill(
      Bill(
        id: bill.id,
        amount: bill.amount,
        currency: bill.currency,
        description: bill.description,
        issuedAt: bill.issuedAt,
        dueAt: bill.dueAt,
        customerId: bill.customerId,
        paidAt: paidAt,
        frequency: bill.frequency,
      ),
    );
    widget.repository.createMoneyEntry(
      MoneyEntry(
        id: newWorkspaceId('money'),
        kind: MoneyEntryKind.expense,
        amount: bill.amount,
        occurredAt: paidAt,
        currency: bill.currency,
        description: bill.description,
        billId: bill.id,
        paymentMethod: method,
      ),
    );
    if (bill.frequency != BillFrequency.oneTime) {
      widget.repository.createBill(
        Bill(
          id: newWorkspaceId('bill'),
          amount: bill.amount,
          currency: bill.currency,
          description: bill.description,
          issuedAt: paidAt,
          dueAt: _nextDueDate(bill.dueAt, bill.frequency),
          frequency: bill.frequency,
        ),
      );
    }
    _changed();
  }

  Future<void> _deleteEntry(MoneyEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete money entry?'),
        content: const Text('This removes the entry from your totals.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.repository.deleteMoneyEntry(entry.id);
      _changed();
    }
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final totals =
        widget.repository.moneyTotals(from: _fromDate)[widget.currency] ??
        MoneyTotals(income: 0, expenses: 0, currency: widget.currency);
    final entries = widget.repository.moneyEntries.where((entry) {
      if (entry.currency != widget.currency) return false;
      if (_fromDate != null && entry.occurredAt.isBefore(_fromDate!)) {
        return false;
      }
      if (_view == _MoneyView.income && entry.kind != MoneyEntryKind.income) {
        return false;
      }
      if (_view == _MoneyView.expenses &&
          entry.kind != MoneyEntryKind.expense) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final bills = _view == _MoneyView.expenses
        ? (widget.repository.bills
              .where((bill) => bill.currency == widget.currency)
              .toList()
            ..sort((a, b) => a.dueAt.compareTo(b.dueAt)))
        : <Bill>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Money',
          'Track money in, spending, bills and shift payments.',
          trailing: PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (value) => setState(() => _period = value),
            itemBuilder: (context) => [
              for (final option in [
                'Today',
                'This week',
                'This month',
                'This year',
                'All time',
              ])
                PopupMenuItem(value: option, child: Text(option)),
            ],
            child: Chip(
              avatar: const Icon(Icons.date_range, size: 17),
              label: Text(_period),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final view in _MoneyView.values)
              ChoiceChip(
                label: Text(switch (view) {
                  _MoneyView.summary => 'Summary',
                  _MoneyView.income => 'Money in',
                  _MoneyView.expenses => 'Money out',
                }),
                selected: _view == view,
                onSelected: (_) => setState(() => _view = view),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_view == _MoneyView.summary) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 540
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MoneySummaryCard(
                    width: width,
                    label: 'Money in',
                    amount: totals.income,
                    currency: widget.currency,
                    icon: Icons.south_west,
                  ),
                  _MoneySummaryCard(
                    width: width,
                    label: 'Money out',
                    amount: totals.expenses,
                    currency: widget.currency,
                    icon: Icons.north_east,
                  ),
                  _MoneySummaryCard(
                    width: width,
                    label: 'Net',
                    amount: totals.net,
                    currency: widget.currency,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              );
            },
          ),
          if (widget.repository.shifts.isNotEmpty) ...[
            const SizedBox(height: 12),
            DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Recent shifts',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  for (final shift in widget.repository.shifts.reversed.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shift.personName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${formatWorkspaceDate(shift.startedAt)} · ${formatWorkspaceTime(shift.startedAt)}'
                                  '${shift.endedAt == null ? ' · On shift' : '–${formatWorkspaceTime(shift.endedAt!)}'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (shift.expectedCash != null)
                            Text(
                              'Counted ${formatWorkspaceAmount(shift.closingCash ?? 0, widget.currency)}\nExpected ${formatWorkspaceAmount(shift.expectedCash!, widget.currency)}',
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addEntry(MoneyEntryKind.income),
                  icon: const Icon(Icons.add),
                  label: const Text('Add money in'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addEntry(MoneyEntryKind.expense),
                  icon: const Icon(Icons.remove),
                  label: const Text('Add spending'),
                ),
              ),
            ],
          ),
        ] else if (_view == _MoneyView.income)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _addEntry(MoneyEntryKind.income),
              icon: const Icon(Icons.add),
              label: const Text('Add money in'),
            ),
          )
        else
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _addEntry(MoneyEntryKind.expense),
                icon: const Icon(Icons.add),
                label: const Text('Add spending'),
              ),
              OutlinedButton.icon(
                onPressed: _addBill,
                icon: const Icon(Icons.event_repeat),
                label: const Text('Add bill'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        if (_view == _MoneyView.expenses && bills.isNotEmpty) ...[
          const Text('Bills', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final bill in bills)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: DashboardPanel(
                child: Row(
                  children: [
                    Icon(
                      bill.isPaid
                          ? Icons.check_circle_outline
                          : Icons.event_note_outlined,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${formatWorkspaceAmount(bill.amount, bill.currency)} · Due ${formatWorkspaceDate(bill.dueAt)} · ${bill.frequency.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (!bill.isPaid)
                      TextButton(
                        onPressed: () => _markBillPaid(bill),
                        child: const Text('Mark paid'),
                      )
                    else
                      const Chip(label: Text('Paid')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (entries.isEmpty && bills.isEmpty)
          DashboardEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: _view == _MoneyView.expenses
                ? 'No spending yet'
                : 'No money recorded yet',
            description: _view == _MoneyView.expenses
                ? 'Add a one-time expense or set up a recurring bill.'
                : 'Money from visits, sales and expenses will appear here.',
            actionLabel: _view == _MoneyView.expenses
                ? 'Add spending'
                : 'Add money in',
            onPressed: () => _addEntry(
              _view == _MoneyView.expenses
                  ? MoneyEntryKind.expense
                  : MoneyEntryKind.income,
            ),
          )
        else
          for (final entry in entries) ...[
            const SizedBox(height: 7),
            DashboardPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    entry.kind == MoneyEntryKind.income
                        ? Icons.south_west
                        : Icons.north_east,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.description ??
                              (entry.kind == MoneyEntryKind.income
                                  ? 'Money in'
                                  : 'Expense'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            formatWorkspaceDate(entry.occurredAt),
                            entry.paymentMethod,
                          ].whereType<String>().join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatWorkspaceAmount(entry.amount, entry.currency),
                    style: TextStyle(
                      color: entry.kind == MoneyEntryKind.income
                          ? Colors.green.shade800
                          : Colors.deepOrange.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete entry',
                    onPressed: () => _deleteEntry(entry),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _MoneySummaryCard extends StatelessWidget {
  const _MoneySummaryCard({
    required this.width,
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
  });

  final double width;
  final String label;
  final double amount;
  final String currency;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 7),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            formatWorkspaceAmount(amount, currency),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _MoneyEntryDraft {
  const _MoneyEntryDraft({
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.occurredAt,
  });

  final double amount;
  final String description;
  final String paymentMethod;
  final DateTime occurredAt;
}

class _MoneyEntryDialog extends StatefulWidget {
  const _MoneyEntryDialog({required this.kind, required this.currency});

  final MoneyEntryKind kind;
  final String currency;

  @override
  State<_MoneyEntryDialog> createState() => _MoneyEntryDialogState();
}

class _MoneyEntryDialogState extends State<_MoneyEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String _paymentMethod = 'Cash';

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _MoneyEntryDraft(
        amount: double.parse(_amount.text.trim()),
        description: _description.text.trim(),
        paymentMethod: _paymentMethod,
        occurredAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.kind == MoneyEntryKind.income;
    return AlertDialog(
      title: Text(isIncome ? 'Add money in' : 'Add spending'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('workspace-money-description'),
                controller: _description,
                autofocus: true,
                decoration: workspaceInputDecoration('What is it for?'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Add a description'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('workspace-money-amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: workspaceInputDecoration(
                  'Amount (${widget.currency})',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || !amount.isFinite || amount <= 0
                      ? 'Enter an amount greater than zero'
                      : null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _paymentMethod,
                decoration: workspaceInputDecoration('Payment method'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? 'Cash'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _BillDraft {
  const _BillDraft({
    required this.amount,
    required this.description,
    required this.dueAt,
    required this.frequency,
  });

  final double amount;
  final String description;
  final DateTime dueAt;
  final BillFrequency frequency;
}

class _BillDialog extends StatefulWidget {
  const _BillDialog({required this.currency});

  final String currency;

  @override
  State<_BillDialog> createState() => _BillDialogState();
}

class _BillDialogState extends State<_BillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  DateTime _dueAt = DateTime.now();
  BillFrequency _frequency = BillFrequency.monthly;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null && mounted) setState(() => _dueAt = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _BillDraft(
        amount: double.parse(_amount.text.trim()),
        description: _description.text.trim(),
        dueAt: _dueAt,
        frequency: _frequency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add bill'),
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _description,
              autofocus: true,
              decoration: workspaceInputDecoration('Bill or supplier'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: workspaceInputDecoration(
                'Amount (${widget.currency})',
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Enter an amount greater than zero'
                    : null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<BillFrequency>(
              isExpanded: true,
              initialValue: _frequency,
              decoration: workspaceInputDecoration('Repeats'),
              items: [
                for (final frequency in BillFrequency.values)
                  DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.name),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _frequency = value ?? BillFrequency.oneTime),
            ),
            TextButton(
              onPressed: _pickDate,
              child: Text('Due ${formatWorkspaceDate(_dueAt)}'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save bill')),
    ],
  );
}
