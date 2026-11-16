import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';

import 'workspace_page_utils.dart';

class WorkspaceTodayOperations extends StatefulWidget {
  const WorkspaceTodayOperations({
    super.key,
    required this.repository,
    required this.setup,
    required this.currency,
    required this.onChanged,
    required this.onOpenBookings,
  });

  final WorkspaceRepository repository;
  final StartupSetup setup;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onOpenBookings;

  @override
  State<WorkspaceTodayOperations> createState() =>
      _WorkspaceTodayOperationsState();
}

class _WorkspaceTodayOperationsState extends State<WorkspaceTodayOperations> {
  Future<void> _checkIn() async {
    final draft = await showDialog<_CheckInDraft>(
      context: context,
      builder: (context) => _CheckInDialog(
        repository: widget.repository,
        setup: widget.setup,
        currency: widget.currency,
      ),
    );
    if (draft == null) return;
    Customer? customer;
    for (final item in widget.repository.customers) {
      if (item.name.toLowerCase() == draft.customerName.toLowerCase() ||
          (draft.phone.isNotEmpty && item.phone == draft.phone)) {
        customer = item;
        break;
      }
    }
    customer ??= widget.repository.createCustomer(
      Customer(
        id: newWorkspaceId('customer'),
        name: draft.customerName,
        phone: draft.phone.isEmpty ? null : draft.phone,
        createdAt: DateTime.now(),
      ),
    );

    final now = DateTime.now();
    final visitId = newWorkspaceId('visit');
    widget.repository.createVisit(
      Visit(
        id: visitId,
        customerId: customer.id,
        checkedInAt: now,
        spaceType: draft.spaceType,
        spaceName: draft.spaceName,
        amount: draft.amount,
        paymentMethod: draft.paymentMethod,
        isPaid: draft.amount == 0 || draft.paymentMethod != 'Pay later',
      ),
    );
    for (final response in draft.responses.entries) {
      widget.repository.createQuestionResponse(
        CustomerQuestionResponse(
          id: newWorkspaceId('answer'),
          questionId: response.key,
          answer: response.value,
          answeredAt: now,
          customerId: customer.id,
          visitId: visitId,
        ),
      );
    }
    if (draft.amount > 0 && draft.paymentMethod != 'Pay later') {
      widget.repository.createMoneyEntry(
        MoneyEntry(
          id: newWorkspaceId('money'),
          kind: MoneyEntryKind.income,
          amount: draft.amount,
          occurredAt: now,
          currency: widget.currency,
          description: 'Visit · ${draft.customerName}',
          customerId: customer.id,
          paymentMethod: draft.paymentMethod,
        ),
      );
    } else if (draft.amount > 0) {
      widget.repository.updateCustomer(
        _copyCustomer(customer, balance: customer.balance + draft.amount),
      );
    }
    _changed();
  }

  Future<void> _checkOut(Visit visit) async {
    final answers = await _collectQuestionAnswers(
      context,
      widget.repository.questions
          .where(
            (question) => question.timing == CustomerQuestionTiming.checkOut,
          )
          .toList(),
    );
    if (answers == null || !mounted) return;
    var method = visit.paymentMethod;
    var collectPayment = false;
    if (!visit.isPaid && visit.amount > 0) {
      method = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(
            'Collect ${formatWorkspaceAmount(visit.amount, widget.currency)}?',
          ),
          children: [
            for (final option in ['Cash', 'Card', 'Transfer'])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, option),
                child: Text(option),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Pay later'),
              child: const Text('Leave as balance'),
            ),
          ],
        ),
      );
      if (method == null) return;
      collectPayment = method != 'Pay later';
    } else {
      collectPayment = false;
    }
    final now = DateTime.now();
    widget.repository.updateVisit(
      Visit(
        id: visit.id,
        customerId: visit.customerId,
        checkedInAt: visit.checkedInAt,
        checkedOutAt: now,
        spaceType: visit.spaceType,
        spaceName: visit.spaceName,
        notes: visit.notes,
        amount: visit.amount,
        paymentMethod: method,
        isPaid: visit.isPaid || collectPayment || visit.amount == 0,
      ),
    );
    for (final response in answers.entries) {
      widget.repository.createQuestionResponse(
        CustomerQuestionResponse(
          id: newWorkspaceId('answer'),
          questionId: response.key,
          answer: response.value,
          answeredAt: now,
          customerId: visit.customerId,
          visitId: visit.id,
        ),
      );
    }
    if (collectPayment) {
      widget.repository.createMoneyEntry(
        MoneyEntry(
          id: newWorkspaceId('money'),
          kind: MoneyEntryKind.income,
          amount: visit.amount,
          occurredAt: now,
          currency: widget.currency,
          description: 'Visit · ${_customerName(visit.customerId)}',
          customerId: visit.customerId,
          paymentMethod: method,
        ),
      );
      final customer = visit.customerId == null
          ? null
          : widget.repository.customerById(visit.customerId!);
      if (customer != null) {
        widget.repository.updateCustomer(
          _copyCustomer(
            customer,
            balance: (customer.balance - visit.amount)
                .clamp(0, double.infinity)
                .toDouble(),
          ),
        );
      }
    }
    _changed();
  }

  Customer _copyCustomer(Customer customer, {required double balance}) =>
      Customer(
        id: customer.id,
        name: customer.name,
        email: customer.email,
        phone: customer.phone,
        notes: customer.notes,
        profession: customer.profession,
        area: customer.area,
        source: customer.source,
        plan: customer.plan,
        balance: balance,
        createdAt: customer.createdAt,
      );

  String _customerName(String? id) => id == null
      ? 'Walk-in'
      : widget.repository.customerById(id)?.name ?? 'Customer';

  void _completeTask(WorkspaceTask task) {
    widget.repository.updateTask(
      WorkspaceTask(
        id: task.id,
        title: task.title,
        description: task.description,
        assignedToId: task.assignedToId,
        dueAt: task.dueAt,
        repeat: task.repeat,
        completedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final visits = widget.repository.activeVisits();
    final bookings = widget.repository.bookingsForToday();
    final now = DateTime.now();
    final tasks = widget.repository.tasks
        .where(
          (task) =>
              !task.isCompleted &&
              (task.dueAt == null ||
                  task.dueAt!.isBefore(
                    DateTime(now.year, now.month, now.day + 1),
                  )),
        )
        .toList();
    final activeBySpace = <String, int>{};
    for (final visit in visits) {
      final key = visit.spaceType?.name ?? 'other';
      activeBySpace[key] = (activeBySpace[key] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Front desk',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: _checkIn,
              icon: const Icon(Icons.login, size: 17),
              label: const Text('Check in'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visits.isEmpty)
          DashboardPanel(
            child: Row(
              children: [
                const Icon(Icons.door_front_door_outlined),
                const SizedBox(width: 10),
                const Expanded(child: Text('No one is checked in right now.')),
                TextButton(onPressed: _checkIn, child: const Text('Check in')),
              ],
            ),
          )
        else
          for (final visit in visits) ...[
            const SizedBox(height: 7),
            DashboardPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName(visit.customerId),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          [
                            visit.spaceName ?? visit.spaceType?.label,
                            'Since ${formatWorkspaceTime(visit.checkedInAt)}',
                            if (!visit.isPaid && visit.amount > 0)
                              'Due ${formatWorkspaceAmount(visit.amount, widget.currency)}',
                          ].whereType<String>().join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _checkOut(visit),
                    child: const Text('Check out'),
                  ),
                ],
              ),
            ),
          ],
        if (widget.setup.selectedSpaces.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Space availability',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final type in widget.setup.selectedSpaces)
                Chip(
                  avatar: const Icon(Icons.meeting_room_outlined, size: 16),
                  label: Text(
                    '${type.label}: ${activeBySpace[type.name] ?? 0} in use',
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bookings today',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: widget.onOpenBookings,
              child: const Text('Manage bookings'),
            ),
          ],
        ),
        if (bookings.isEmpty)
          DashboardPanel(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'No bookings yet. When staff book on Today, it shows up here.',
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenBookings,
                  child: const Text('Add booking'),
                ),
              ],
            ),
          )
        else
          for (final booking in bookings)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: DashboardPanel(
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_customerName(booking.customerId)} · ${booking.spaceName ?? booking.spaceType?.label ?? 'Space'}',
                      ),
                    ),
                    Text(
                      '${formatWorkspaceTime(booking.startsAt)}–${formatWorkspaceTime(booking.endsAt)}',
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 14),
        const Text(
          'Tasks for today',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (tasks.isEmpty)
          DashboardPanel(child: const Text('No tasks due today.'))
        else
          for (final task in tasks) ...[
            const SizedBox(height: 6),
            DashboardPanel(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: CheckboxListTile(
                value: false,
                contentPadding: EdgeInsets.zero,
                title: Text(task.title),
                subtitle: Text(task.assignedToId ?? 'Unassigned'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (_) => _completeTask(task),
              ),
            ),
          ],
      ],
    );
  }
}

class _CheckInDraft {
  const _CheckInDraft({
    required this.customerName,
    required this.phone,
    required this.amount,
    required this.paymentMethod,
    required this.responses,
    this.spaceType,
    this.spaceName,
  });

  final String customerName;
  final String phone;
  final double amount;
  final String paymentMethod;
  final Map<String, String> responses;
  final SetupSpaceType? spaceType;
  final String? spaceName;
}

class _CheckInDialog extends StatefulWidget {
  const _CheckInDialog({
    required this.repository,
    required this.setup,
    required this.currency,
  });

  final WorkspaceRepository repository;
  final StartupSetup setup;
  final String currency;

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController(text: '0');
  String _paymentMethod = 'Cash';
  String? _spaceKey;

  List<WorkspaceSpaceOption> get _spaceOptions =>
      workspaceSpaceOptions(widget.setup);

  @override
  void initState() {
    super.initState();
    if (_spaceOptions.isNotEmpty) _spaceKey = _keyFor(_spaceOptions.first);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  String _keyFor(WorkspaceSpaceOption option) =>
      '${option.type.name}|${option.name}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final responses = await _collectQuestionAnswers(
      context,
      widget.repository.questions
          .where(
            (question) => question.timing == CustomerQuestionTiming.checkIn,
          )
          .toList(),
    );
    if (responses == null || !mounted) return;
    WorkspaceSpaceOption? selected;
    for (final option in _spaceOptions) {
      if (_keyFor(option) == _spaceKey) {
        selected = option;
        break;
      }
    }
    Navigator.pop(
      context,
      _CheckInDraft(
        customerName: _name.text.trim(),
        phone: _phone.text.trim(),
        amount: double.tryParse(_amount.text.trim()) ?? 0,
        paymentMethod: _paymentMethod,
        responses: responses,
        spaceType: selected?.type,
        spaceName: selected?.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Check in customer'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('checkin-customer-name'),
                controller: _name,
                autofocus: true,
                decoration: workspaceInputDecoration('Customer name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('checkin-phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: workspaceInputDecoration('Phone (optional)'),
              ),
              const SizedBox(height: 10),
              if (_spaceOptions.isNotEmpty)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _spaceKey,
                  decoration: workspaceInputDecoration('Space'),
                  items: [
                    for (final option in _spaceOptions)
                      DropdownMenuItem(
                        value: _keyFor(option),
                        child: Text('${option.type.label} · ${option.name}'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _spaceKey = value),
                ),
              if (_spaceOptions.isNotEmpty) const SizedBox(height: 10),
              TextFormField(
                key: const ValueKey('checkin-charge'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: workspaceInputDecoration(
                  'Charge (${widget.currency})',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || !amount.isFinite || amount < 0
                      ? 'Enter a valid amount'
                      : null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _paymentMethod,
                decoration: workspaceInputDecoration('Payment'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                  DropdownMenuItem(
                    value: 'Pay later',
                    child: Text('Pay later'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? 'Cash'),
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
      FilledButton(
        key: const ValueKey('submit-checkin'),
        onPressed: _save,
        child: const Text('Check in'),
      ),
    ],
  );
}

Future<Map<String, String>?> _collectQuestionAnswers(
  BuildContext context,
  List<CustomerQuestion> questions,
) {
  if (questions.isEmpty) return Future.value(const {});
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => _QuestionAnswersDialog(questions: questions),
  );
}

class _QuestionAnswersDialog extends StatefulWidget {
  const _QuestionAnswersDialog({required this.questions});

  final List<CustomerQuestion> questions;

  @override
  State<_QuestionAnswersDialog> createState() => _QuestionAnswersDialogState();
}

class _QuestionAnswersDialogState extends State<_QuestionAnswersDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _textControllers = {
    for (final question in widget.questions)
      if (question.type == CustomerQuestionType.shortText)
        question.id: TextEditingController(),
  };
  final Map<String, String> _selections = {};

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final answers = <String, String>{};
    for (final question in widget.questions) {
      final answer = question.type == CustomerQuestionType.shortText
          ? _textControllers[question.id]!.text.trim()
          : _selections[question.id] ?? '';
      if (answer.isNotEmpty) answers[question.id] = answer;
    }
    Navigator.pop(context, answers);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('A few questions'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final question in widget.questions) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${question.prompt}${question.required ? ' *' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                if (question.type == CustomerQuestionType.shortText)
                  TextFormField(
                    controller: _textControllers[question.id],
                    decoration: workspaceInputDecoration('Your answer'),
                    validator: (value) =>
                        question.required &&
                            (value == null || value.trim().isEmpty)
                        ? 'This answer is required'
                        : null,
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selections[question.id] ?? '',
                    decoration: workspaceInputDecoration('Choose an answer'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Choose an answer'),
                      ),
                      for (final option in question.options)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selections[question.id] = value ?? '';
                      });
                    },
                    validator: (value) =>
                        question.required && (value == null || value.isEmpty)
                        ? 'Choose an answer'
                        : null,
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      if (widget.questions.every((question) => !question.required))
        TextButton(
          onPressed: () => Navigator.pop(context, const <String, String>{}),
          child: const Text('Skip'),
        ),
      FilledButton(onPressed: _save, child: const Text('Continue')),
    ],
  );
}
