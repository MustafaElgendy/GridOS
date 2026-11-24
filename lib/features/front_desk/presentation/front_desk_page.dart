import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/features/workspace/data/workspace_repository.dart';
import 'package:grid_os/features/workspace/domain/workspace_models.dart';
import 'package:grid_os/features/workspace/presentation/workspace_bookings_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_customers_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_dialogs.dart';
import 'package:grid_os/features/workspace/presentation/workspace_page_utils.dart';
import 'package:grid_os/theme/app_theme.dart';

import 'widgets/front_desk_cash_drawer_card.dart';
import 'widgets/front_desk_checkin_card.dart';
import 'widgets/front_desk_checkout_panel.dart';
import 'widgets/front_desk_coming_up_card.dart';
import 'widgets/front_desk_header.dart';
import 'widgets/front_desk_in_now_table.dart';
import 'widgets/front_desk_shifts_card.dart';
import 'widgets/front_desk_spaces_overview.dart';
import 'widgets/front_desk_todo_card.dart';
import 'widgets/owner_unlock_dialog.dart';

class FrontDeskPage extends StatefulWidget {
  const FrontDeskPage({
    super.key,
    required this.setup,
    required this.repository,
    required this.currency,
    required this.onChanged,
    required this.onSwitchToOwner,
    required this.workingStaffPins,
    required this.ownerOnShift,
    required this.onStartShift,
    required this.onEndShift,
    this.embedded = false,
  });

  final StartupSetup setup;
  final WorkspaceRepository repository;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onSwitchToOwner;
  final Set<String> workingStaffPins;
  final bool ownerOnShift;
  final Future<void> Function({required String? pin, required bool isOwner})
      onStartShift;
  final Future<void> Function({required String? pin, required bool isOwner})
      onEndShift;
  final bool embedded;

  @override
  State<FrontDeskPage> createState() => _FrontDeskPageState();
}

class _FrontDeskPageState extends State<FrontDeskPage> {
  FrontDeskTab _selectedTab = FrontDeskTab.today;
  bool _isArabic = false;
  String? _selectedVisitId;
  String _customerFilterQuery = '';

  String get _ownerName => widget.setup.ownerName.trim().isEmpty
      ? 'Owner'
      : widget.setup.ownerName.trim();

  String get _currentStaffName {
    if (widget.ownerOnShift) return '$_ownerName · Owner';
    for (final member in widget.setup.staff) {
      if (widget.workingStaffPins.contains(member.pin)) return member.name;
    }
    return '$_ownerName · Owner';
  }

  void _onDataChanged() {
    setState(() {});
    widget.onChanged();
  }

  Future<void> _requestSwitchToOwner() async {
    // SECURITY: Always require owner authorization before entering owner side
    if (widget.setup.ownerPin != null || widget.setup.staff.isNotEmpty) {
      if (widget.setup.ownerPin == null) {
        final pin = await showDialog<String>(
          context: context,
          builder: (context) => const OwnerPinDialog(
            title: 'Owner authorization required',
            actionLabel: 'Set PIN & Continue',
          ),
        );
        if (!mounted || pin == null) {
          _showAccessDenied();
          return;
        }
        widget.setup.ownerPin = pin;
      }
      final enteredPin = await showDialog<String>(
        context: context,
        builder: (context) => OwnerUnlockDialog(
          ownerName: _ownerName,
          staffName: _currentStaffName,
          expectedPin: widget.setup.ownerPin,
        ),
      );
      if (!mounted || enteredPin == null || enteredPin != widget.setup.ownerPin) {
        _showAccessDenied();
        return;
      }
    }

    widget.onSwitchToOwner();
  }

  void _showAccessDenied() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Owner authorization required to enter owner side.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _checkIn() async {
    final nameController = TextEditingController(text: _customerFilterQuery);
    final phoneController = TextEditingController();
    final amountController = TextEditingController(text: '100');
    SetupSpaceType selectedSpace = SetupSpaceType.sharedArea;
    String paymentMethod = 'Cash';

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Check in'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const ValueKey('checkin-customer-name'),
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: setupInputDecoration(hintText: 'Customer name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: setupInputDecoration(hintText: 'Phone number (optional)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SetupSpaceType>(
                    initialValue: selectedSpace,
                    decoration: setupInputDecoration(hintText: 'Space'),
                    items: const [
                      DropdownMenuItem(
                        value: SetupSpaceType.sharedArea,
                        child: Text('Shared area'),
                      ),
                      DropdownMenuItem(
                        value: SetupSpaceType.rooms,
                        child: Text('Room'),
                      ),
                      DropdownMenuItem(
                        value: SetupSpaceType.computers,
                        child: Text('Computer'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedSpace = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('checkin-charge'),
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: setupInputDecoration(hintText: 'Price (${widget.currency})'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: setupInputDecoration(hintText: 'Payment method'),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'Pay later', child: Text('Pay later')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => paymentMethod = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('submit-checkin'),
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Check in'),
              ),
            ],
          );
        },
      ),
    );

    if (submitted != true || !mounted) return;

    final customerName = nameController.text.trim();
    final phone = phoneController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;

    Customer? customer;
    for (final c in widget.repository.customers) {
      if (c.name.toLowerCase() == customerName.toLowerCase() ||
          (phone.isNotEmpty && c.phone == phone)) {
        customer = c;
        break;
      }
    }

    customer ??= widget.repository.createCustomer(
      Customer(
        id: newWorkspaceId('customer'),
        name: customerName,
        phone: phone.isEmpty ? null : phone,
        createdAt: DateTime.now(),
      ),
    );

    final now = DateTime.now();
    final isPaid = amount == 0 || paymentMethod != 'Pay later';

    widget.repository.createVisit(
      Visit(
        id: newWorkspaceId('visit'),
        customerId: customer.id,
        checkedInAt: now,
        spaceType: selectedSpace,
        spaceName: selectedSpace.label,
        amount: amount,
        paymentMethod: paymentMethod,
        isPaid: isPaid,
      ),
    );

    if (amount > 0 && isPaid) {
      widget.repository.createMoneyEntry(
        MoneyEntry(
          id: newWorkspaceId('money'),
          kind: MoneyEntryKind.income,
          amount: amount,
          occurredAt: now,
          currency: widget.currency,
          description: 'Visit · $customerName',
          customerId: customer.id,
          paymentMethod: paymentMethod,
        ),
      );
    } else if (amount > 0 && !isPaid) {
      widget.repository.updateCustomer(
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
          balance: customer.balance + amount,
          createdAt: customer.createdAt,
        ),
      );
    }

    _onDataChanged();
  }

  Future<void> _checkOut(Visit visit) async {
    final now = DateTime.now();
    widget.repository.updateVisit(
      Visit(
        id: visit.id,
        customerId: visit.customerId,
        checkedInAt: visit.checkedInAt,
        checkedOutAt: now,
        spaceType: visit.spaceType,
        spaceName: visit.spaceName,
        amount: visit.amount,
        paymentMethod: visit.paymentMethod,
        isPaid: true,
      ),
    );
    if (_selectedVisitId == visit.id) {
      _selectedVisitId = null;
    }
    _onDataChanged();
  }

  Future<void> _addExpenseOrCash({required bool isExpense}) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isExpense ? 'Add expense' : 'Add cash to drawer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: setupInputDecoration(hintText: 'Amount (${widget.currency})'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: setupInputDecoration(hintText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (double.tryParse(amountController.text.trim()) == null) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    widget.repository.createMoneyEntry(
      MoneyEntry(
        id: newWorkspaceId('money'),
        kind: isExpense ? MoneyEntryKind.expense : MoneyEntryKind.income,
        amount: amount,
        occurredAt: DateTime.now(),
        currency: widget.currency,
        description: descController.text.trim().isEmpty
            ? (isExpense ? 'Front desk expense' : 'Front desk cash in')
            : descController.text.trim(),
        paymentMethod: 'Cash',
      ),
    );
    _onDataChanged();
  }

  Future<void> _addNewTask() async {
    final titleController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New To-do item'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: setupInputDecoration(hintText: 'What needs to be done?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (added != true || !mounted) return;
    widget.repository.createTask(
      WorkspaceTask(
        id: newWorkspaceId('task'),
        title: titleController.text.trim(),
        description: 'Assigned to Front desk',
      ),
    );
    _onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final visits = widget.repository.activeVisits();
    final bookings = widget.repository.bookingsForToday();
    final tasks = widget.repository.tasks;
    final selectedVisit = _selectedVisitId == null
        ? null
        : visits.where((v) => v.id == _selectedVisitId).firstOrNull;
    final customer = selectedVisit == null
        ? null
        : widget.repository.customerById(selectedVisit.customerId ?? '');

    final content = Column(
      key: const ValueKey('front-desk-staff-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Front desk top header
        FrontDeskHeader(
          setup: widget.setup,
          selectedTab: _selectedTab,
          onTabSelected: (tab) => setState(() => _selectedTab = tab),
          currentStaffName: _currentStaffName,
          isOwner: widget.ownerOnShift,
          onSwitchToOwner: _requestSwitchToOwner,
          onEndShift: () => widget.onEndShift(pin: null, isOwner: widget.ownerOnShift),
          onToggleArabic: () => setState(() => _isArabic = !_isArabic),
          isArabic: _isArabic,
        ),

        // Selected Tab Content
        Expanded(
          child: _selectedTab == FrontDeskTab.today
              ? _todayContent(visits, bookings, tasks, selectedVisit, customer)
              : _selectedTab == FrontDeskTab.bookings
                  ? WorkspaceBookingsPage(
                      repository: widget.repository,
                      setup: widget.setup,
                      onChanged: _onDataChanged,
                      onOpenFrontDesk: () =>
                          setState(() => _selectedTab = FrontDeskTab.today),
                    )
                  : WorkspaceCustomersPage(
                      repository: widget.repository,
                      onChanged: _onDataChanged,
                      currency: widget.currency,
                    ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(child: content),
    );
  }

  Widget _todayContent(
    List<Visit> visits,
    List<Booking> bookings,
    List<WorkspaceTask> tasks,
    Visit? selectedVisit,
    Customer? customer,
  ) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page title & action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Today', style: AppTextStyles.authHeading),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedTab = FrontDeskTab.bookings),
                  icon: const Icon(Icons.add, size: 15, color: AppColors.authGreen),
                  label: const Text(
                    'Book long-term',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authGreen,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.authGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Two-column layout matching the screenshots
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;
                final leftColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FrontDeskCheckinCard(
                      setup: widget.setup,
                      onSearchChanged: (val) =>
                          setState(() => _customerFilterQuery = val),
                      onNewCustomer: _checkIn,
                      currency: widget.currency,
                    ),
                    const SizedBox(height: 12),
                    FrontDeskSpacesOverview(
                      setup: widget.setup,
                      repository: widget.repository,
                    ),
                    const SizedBox(height: 12),
                    FrontDeskInNowTable(
                      visits: visits,
                      repository: widget.repository,
                      currency: widget.currency,
                      onCheckOut: _checkOut,
                      onSelectVisit: (visit) {
                        setState(() => _selectedVisitId = visit.id);
                      },
                      selectedVisitId: _selectedVisitId,
                      onNewCustomer: _checkIn,
                    ),
                    const SizedBox(height: 12),
                    FrontDeskComingUpCard(
                      bookings: bookings,
                      repository: widget.repository,
                      currency: widget.currency,
                      onCheckInBooking: (b) => _checkIn(),
                    ),
                  ],
                );

                final rightColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FrontDeskShiftsCard(
                      setup: widget.setup,
                      ownerName: _ownerName,
                      ownerOnShift: widget.ownerOnShift,
                      workingStaffPins: widget.workingStaffPins,
                      onStartShift: widget.onStartShift,
                      onEndShift: widget.onEndShift,
                    ),
                    const SizedBox(height: 12),
                    FrontDeskCheckoutPanel(
                      selectedVisit: selectedVisit,
                      customer: customer,
                      currency: widget.currency,
                      onCompleteCheckout: (v, method) => _checkOut(v),
                      onCancelSelection: () =>
                          setState(() => _selectedVisitId = null),
                    ),
                    const SizedBox(height: 12),
                    FrontDeskCashDrawerCard(
                      staffName: _currentStaffName,
                      onAddExpense: () => _addExpenseOrCash(isExpense: true),
                      onAddCash: () => _addExpenseOrCash(isExpense: false),
                    ),
                    const SizedBox(height: 12),
                    FrontDeskTodoCard(
                      tasks: tasks,
                      onToggleTask: (task) {
                        widget.repository.updateTask(
                          WorkspaceTask(
                            id: task.id,
                            title: task.title,
                            description: task.description,
                            assignedToId: task.assignedToId,
                            dueAt: task.dueAt,
                            repeat: task.repeat,
                            completedAt: task.isCompleted ? null : DateTime.now(),
                          ),
                        );
                        _onDataChanged();
                      },
                      onAddTask: _addNewTask,
                    ),
                  ],
                );

                if (!isWide) {
                  return Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: 14),
                      rightColumn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: leftColumn),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: rightColumn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.embedded ? 14 : 24,
        vertical: widget.embedded ? 12 : 18,
      ),
      child: body,
    );
  }
}
