import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/data/workspace_repository.dart';
import 'package:grid_os/features/workspace/presentation/workspace_bookings_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_customers_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_dashboard_overview.dart';
import 'package:grid_os/features/workspace/presentation/workspace_dialogs.dart';
import 'package:grid_os/features/front_desk/presentation/front_desk_page.dart';
import 'package:grid_os/features/front_desk/presentation/widgets/shift_selection_dialog.dart';
import 'package:grid_os/features/front_desk/presentation/widgets/owner_unlock_dialog.dart';
import 'package:grid_os/features/workspace/presentation/workspace_insights_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_money_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_products_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_settings_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_spaces_management_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_tasks_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_page_utils.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/theme/app_theme.dart';

import 'dashboard_widgets.dart';
import 'staff_page.dart';

String frontDeskPreferenceKey(StartupSetup setup) {
  final owner = Uri.encodeComponent(setup.ownerName.trim().toLowerCase());
  final workspace = Uri.encodeComponent(
    setup.workspaceName.trim().toLowerCase(),
  );
  return 'front_desk_use_${owner}_$workspace';
}

enum _DashboardSection {
  dashboard,
  today,
  bookings,
  tasks,
  customers,
  money,
  insights,
  spaces,
  products,
  staff,
  settings,
}

enum _OwnerMenuAction { addStaff, openFrontDesk, settings }

enum _SpacesTab { spaces, prices }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.setup, this.repository});

  final StartupSetup setup;
  final WorkspaceRepository? repository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _workingStaffPins = <String>{};
  late final WorkspaceRepository _workspaceRepository;

  _DashboardSection _section = _DashboardSection.dashboard;
  final _SpacesTab _spacesTab = _SpacesTab.spaces;
  bool _ownerOnShift = false;
  bool _openingFrontDesk = false;
  bool _preferArabic = false;

  @override
  void initState() {
    super.initState();
    _workspaceRepository = widget.repository ?? WorkspaceRepository();
    _seedProductsFromSetup();
    _loadOwnerShellPrefs();
  }

  Future<void> _loadOwnerShellPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final arabic = prefs.getBool(_arabicPreferenceKey(_setup)) ?? false;
    if (!mounted) return;
    setState(() => _preferArabic = arabic);
  }

  String _arabicPreferenceKey(StartupSetup setup) {
    final owner = Uri.encodeComponent(setup.ownerName.trim().toLowerCase());
    final workspace = Uri.encodeComponent(
      setup.workspaceName.trim().toLowerCase(),
    );
    return 'owner_prefer_arabic_${owner}_$workspace';
  }

  void _seedProductsFromSetup() {
    for (var index = 0; index < _setup.kitchenItems.length; index++) {
      final item = _setup.kitchenItems[index];
      final name = item.name.trim();
      final price = double.tryParse(item.price.trim()) ?? 0;
      final quantity = double.tryParse(item.quantity.trim()) ?? 0;
      final cost = double.tryParse(item.costsYou.trim()) ?? 0;
      if (name.isEmpty &&
          item.price.trim().isEmpty &&
          item.quantity.trim().isEmpty &&
          item.costsYou.trim().isEmpty) {
        continue;
      }
      _workspaceRepository.createProduct(
        Product(
          id: 'setup_kitchen_$index',
          name: name.isEmpty ? 'Product ${index + 1}' : name,
          category: 'Kitchen',
          price: price,
          cost: cost,
          quantityOnHand: quantity < 0 ? 0 : quantity,
          lowStockThreshold: 5,
        ),
      );
    }
  }

  void _workspaceDataChanged() {
    _setup.kitchenItems = [
      for (final product in _workspaceRepository.products)
        KitchenItemSetup()
          ..name = product.name
          ..price = product.price.toString()
          ..quantity = product.quantityOnHand.toString()
          ..costsYou = product.cost.toString(),
    ];
    if (mounted) setState(() {});
  }

  StartupSetup get _setup => widget.setup;
  String get _ownerName =>
      _setup.ownerName.trim().isEmpty ? 'Owner' : _setup.ownerName.trim();
  String get _currency => _setup.country.currency;
  bool get _isStaffView => _section == _DashboardSection.today;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final isFrontDesk = _section == _DashboardSection.today;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.authBackground,
          drawer: desktop
              ? null
              : Drawer(
                  width: 250,
                  child: SafeArea(child: _navigationSidebar()),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (desktop && !isFrontDesk) _navigationSidebar(),
                Expanded(
                  child: isFrontDesk
                      ? FrontDeskPage(
                          setup: _setup,
                          repository: _workspaceRepository,
                          currency: _currency,
                          onChanged: _workspaceDataChanged,
                          onSwitchToOwner: () =>
                              _switchToOwnerView(skipPrompt: true),
                          workingStaffPins: _workingStaffPins,
                          ownerOnShift: _ownerOnShift,
                          onStartShift: _startShift,
                          onEndShift: _endShift,
                          embedded: true,
                        )
                      : Column(
                          children: [
                            _topBar(desktop: desktop),
                            Expanded(
                              child: SingleChildScrollView(
                                key: const PageStorageKey<String>(
                                  'dashboard-page',
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: desktop ? 28 : 16,
                                  vertical: desktop ? 22 : 16,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 1120),
                                    child: _selectedPage(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _navigationSidebar() {
    return Container(
      width: 228,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.authBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.authGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 9),
                const Text('GridOS', style: AppTextStyles.authBrand),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.authBackground,
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _setup.city ?? _setup.country.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 15),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final item in _primaryNavigation)
                  _navigationItem(
                    item.$1,
                    item.$2,
                    item.$3,
                    badge: item.$4,
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 17, 10, 7),
                  child: Text(
                    'YOUR WORKSPACE',
                    style: TextStyle(
                      color: AppColors.authMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                for (final item in _workspaceNavigation)
                  _navigationItem(item.$1, item.$2, item.$3),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.authBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: _navigationItem(
              _DashboardSection.settings,
              'Settings',
              Icons.settings_outlined,
            ),
          ),
        ],
      ),
    );
  }

  static const _primaryNavigation =
      <(_DashboardSection, String, IconData, String?)>[
    (_DashboardSection.dashboard, 'Dashboard', Icons.home_outlined, null),
    (
      _DashboardSection.today,
      'Front desk',
      Icons.desktop_windows_outlined,
      'Staff view',
    ),
    (_DashboardSection.bookings, 'Bookings', Icons.calendar_month_outlined, null),
    (_DashboardSection.tasks, 'Tasks', Icons.checklist_outlined, null),
    (_DashboardSection.customers, 'Customers', Icons.people_outline, null),
    (
      _DashboardSection.money,
      'Money',
      Icons.account_balance_wallet_outlined,
      null,
    ),
    (_DashboardSection.insights, 'Insights', Icons.bar_chart_outlined, null),
  ];

  static const _workspaceNavigation = <(_DashboardSection, String, IconData)>[
    (_DashboardSection.spaces, 'Spaces & rooms', Icons.grid_view_outlined),
    (_DashboardSection.products, 'Products', Icons.inventory_2_outlined),
    (_DashboardSection.staff, 'Staff', Icons.badge_outlined),
  ];

  Widget _navigationItem(
    _DashboardSection section,
    String label,
    IconData icon, {
    String? badge,
  }) {
    final selected = _section == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          key: ValueKey('nav-${section.name}'),
          dense: true,
          visualDensity: const VisualDensity(vertical: -2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          selected: selected,
          selectedTileColor: AppColors.homePaleGreen,
          selectedColor: AppColors.authGreen,
          leading: Icon(icon, size: 17),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.authGreen
                        : AppColors.authBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.white : AppColors.authMuted,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () => _selectSection(section),
        ),
      ),
    );
  }

  void _selectSection(_DashboardSection section) {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    if (section == _DashboardSection.today) {
      _openFrontDesk();
      return;
    }
    if (mounted) setState(() => _section = section);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Widget _topBar({required bool desktop}) {
    return Container(
      height: 58,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 24 : 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.authBorder)),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            IconButton(
              key: const ValueKey('dashboard-drawer-menu'),
              tooltip: 'Open navigation',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, size: 20),
            ),
            const SizedBox(width: 4),
            const Text('GridOS', style: AppTextStyles.authBrand),
          ] else
            Row(
              children: [
                Text(
                  _sectionTitle(_section),
                  style: const TextStyle(
                    color: AppColors.authInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isStaffView) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.homePaleGreen,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: const Text(
                      'Staff view',
                      style: TextStyle(
                        color: AppColors.authGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const Spacer(),
          if (desktop)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(_dateLabel(), style: AppTextStyles.authHelper),
            ),
          TextButton.icon(
            key: const ValueKey('topbar-today'),
            onPressed: _openFrontDesk,
            icon: const Icon(Icons.desktop_windows_outlined, size: 16),
            label: Text(desktop ? 'Front desk' : ''),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<_OwnerMenuAction>(
            key: const ValueKey('owner-menu'),
            tooltip: 'Owner menu',
            onSelected: _handleOwnerMenuAction,
            itemBuilder: _ownerMenuItems,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.authBorder),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.homePaleGreen,
                    child: Text(
                      _ownerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.authGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (desktop) ...[
                    const SizedBox(width: 7),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ownerName,
                          style: const TextStyle(
                            color: AppColors.authInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Owner',
                          style: TextStyle(
                            color: AppColors.authMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Icon(Icons.expand_more, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOwnerMenuAction(_OwnerMenuAction action) {
    switch (action) {
      case _OwnerMenuAction.addStaff:
        _selectSection(_DashboardSection.staff);
        break;
      case _OwnerMenuAction.openFrontDesk:
        _openFrontDesk();
        break;
      case _OwnerMenuAction.settings:
        _selectSection(_DashboardSection.settings);
        break;
    }
  }

  List<PopupMenuEntry<_OwnerMenuAction>> _ownerMenuItems(
    BuildContext context,
  ) => [
    PopupMenuItem(
      value: _OwnerMenuAction.addStaff,
      child: _menuRow(Icons.person_add_alt_1, 'Add staff'),
    ),
    PopupMenuItem(
      key: const ValueKey('owner-open-front-desk'),
      value: _OwnerMenuAction.openFrontDesk,
      child: _menuRow(Icons.desktop_windows_outlined, 'Open the front desk'),
    ),
    PopupMenuItem(
      value: _OwnerMenuAction.settings,
      child: _menuRow(Icons.settings_outlined, 'Settings'),
    ),
  ];

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _selectedPage() {
    return switch (_section) {
      _DashboardSection.dashboard => WorkspaceDashboardOverview(
        setup: _setup,
        repository: _workspaceRepository,
        currency: _currency,
        onOpenTasks: () => _selectSection(_DashboardSection.tasks),
        onOpenProducts: () => _selectSection(_DashboardSection.products),
        onOpenSpaces: () => _selectSection(_DashboardSection.spaces),
      ),
      _DashboardSection.today => FrontDeskPage(
        setup: _setup,
        repository: _workspaceRepository,
        currency: _currency,
        onChanged: _workspaceDataChanged,
        onSwitchToOwner: () => _switchToOwnerView(skipPrompt: true),
        workingStaffPins: _workingStaffPins,
        ownerOnShift: _ownerOnShift,
        onStartShift: _startShift,
        onEndShift: _endShift,
      ),
      _DashboardSection.bookings => WorkspaceBookingsPage(
        repository: _workspaceRepository,
        setup: _setup,
        onChanged: _workspaceDataChanged,
        onOpenFrontDesk: _openFrontDesk,
      ),
      _DashboardSection.tasks => WorkspaceTasksPage(
        repository: _workspaceRepository,
        onChanged: _workspaceDataChanged,
        assignees: [
          '$_ownerName · Owner',
          for (final member in _setup.staff) member.name,
        ],
      ),
      _DashboardSection.customers => WorkspaceCustomersPage(
        repository: _workspaceRepository,
        onChanged: _workspaceDataChanged,
        currency: _currency,
      ),
      _DashboardSection.products => WorkspaceProductsPage(
        repository: _workspaceRepository,
        onChanged: _workspaceDataChanged,
        currency: _currency,
      ),
      _DashboardSection.insights => WorkspaceInsightsPage(
        repository: _workspaceRepository,
        currency: _currency,
        onOpenSpaces: () => _selectSection(_DashboardSection.spaces),
        onOpenQuestions: () => _selectSection(_DashboardSection.settings),
      ),
      _DashboardSection.spaces => WorkspaceSpacesManagementPage(
        setup: _setup,
        initialTab: _spacesTab == _SpacesTab.spaces
            ? SpacesManagementTab.spaces
            : SpacesManagementTab.prices,
        onChanged: _workspaceDataChanged,
      ),
      _DashboardSection.staff => DashboardStaffPage(
        setup: _setup,
        onSetOwnerPin: _setOwnerPin,
        onAddStaff: _addStaff,
        onRemoveStaff: _confirmRemoveStaff,
      ),
      _DashboardSection.money => WorkspaceMoneyPage(
        repository: _workspaceRepository,
        onChanged: _workspaceDataChanged,
        currency: _currency,
      ),
      _DashboardSection.settings => WorkspaceSettingsPage(
        setup: _setup,
        repository: _workspaceRepository,
        onChanged: _workspaceDataChanged,
      ),
    };
  }

  Future<void> _switchToOwnerView({bool skipPrompt = false}) async {
    if (!skipPrompt && (_setup.ownerPin != null || _setup.staff.isNotEmpty)) {
      if (_setup.ownerPin != null) {
        final pin = await showDialog<String>(
          context: context,
          builder: (context) => OwnerUnlockDialog(
            ownerName: _ownerName,
            staffName: _ownerOnShift
                ? _ownerShiftName
                : (_setup.staff.isNotEmpty ? _setup.staff.first.name : 'Staff'),
            expectedPin: _setup.ownerPin,
          ),
        );
        if (!mounted || pin == null || pin != _setup.ownerPin) {
          _showMessage('Owner authorization required to enter owner side.');
          return;
        }
      } else if (_setup.staff.isNotEmpty) {
        final pin = await _askForOwnerPin();
        if (!mounted || pin == null) return;
        _setup.ownerPin = pin;
      }
    }
    if (mounted) {
      setState(() => _section = _DashboardSection.dashboard);
    }
  }

  Future<void> _startShift({
    required String? pin,
    required bool isOwner,
  }) async {
    if (isOwner && _setup.staff.isEmpty) {
      final openingCash = await _openingCashForShift();
      if (!mounted || openingCash == null) return;
      _createShift(_ownerShiftName, openingCash);
      setState(() => _ownerOnShift = true);
      return;
    }
    final enteredPin = await _askForShiftPin(isOwner: isOwner, ending: true);
    if (!mounted || enteredPin == null) return;
    final expectedPin = isOwner ? _setup.ownerPin : pin;
    if (enteredPin != expectedPin) {
      _showMessage('That PIN does not match.');
      return;
    }
    final openingCash = await _openingCashForShift();
    if (!mounted || openingCash == null) return;
    _createShift(
      isOwner ? _ownerShiftName : _staffNameForPin(pin),
      openingCash,
    );
    setState(() {
      if (isOwner) {
        _ownerOnShift = true;
      } else {
        _workingStaffPins.add(pin!);
      }
    });
  }

  String get _ownerShiftName => '$_ownerName · Owner';

  String _staffNameForPin(String? pin) {
    for (final member in _setup.staff) {
      if (member.pin == pin) return member.name;
    }
    return 'Staff member';
  }

  double _expectedCash(WorkspaceShift shift, DateTime end) {
    final cashMovement = _workspaceRepository.moneyEntries
        .where(
          (entry) =>
              entry.currency == _currency &&
              entry.paymentMethod == 'Cash' &&
              !entry.occurredAt.isBefore(shift.startedAt) &&
              !entry.occurredAt.isAfter(end),
        )
        .fold<double>(
          0,
          (total, entry) =>
              total +
              (entry.kind == MoneyEntryKind.income
                  ? entry.amount
                  : -entry.amount),
        );
    return shift.openingCash + cashMovement;
  }

  void _createShift(String personName, double openingCash) {
    if (_workspaceRepository.activeShiftFor(personName) != null) return;
    _workspaceRepository.createShift(
      WorkspaceShift(
        id: newWorkspaceId('shift'),
        personName: personName,
        startedAt: DateTime.now(),
        openingCash: openingCash,
      ),
    );
  }

  Future<double?> _openingCashForShift() async {
    if (!_workspaceRepository.settings.askOpeningCash) return 0;
    return showDialog<double>(
      context: context,
      builder: (context) => const CashCountDialog(
        title: 'Opening cash',
        actionLabel: 'Start shift',
      ),
    );
  }

  Future<void> _endShift({required String? pin, required bool isOwner}) async {
    if (_setup.staff.isNotEmpty) {
      final enteredPin = await _askForShiftPin(isOwner: isOwner);
      if (!mounted || enteredPin == null) return;
      final expectedPin = isOwner ? _setup.ownerPin : pin;
      if (enteredPin != expectedPin) {
        _showMessage('That PIN does not match.');
        return;
      }
    }

    final personName = isOwner ? _ownerShiftName : _staffNameForPin(pin);
    final shift = _workspaceRepository.activeShiftFor(personName);
    final now = DateTime.now();
    final double expected = shift == null ? 0 : _expectedCash(shift, now);
    double? closingCash;
    if (_workspaceRepository.settings.cashDrawerEnabled &&
        _workspaceRepository.settings.requireShiftReconciliation) {
      closingCash = await showDialog<double>(
        context: context,
        builder: (context) => CashCountDialog(
          title: 'Count closing cash',
          actionLabel: 'End shift',
          expectedCash: expected,
        ),
      );
      if (!mounted || closingCash == null) return;
    }
    if (shift != null) {
      _workspaceRepository.updateShift(
        WorkspaceShift(
          id: shift.id,
          personName: shift.personName,
          startedAt: shift.startedAt,
          endedAt: now,
          openingCash: shift.openingCash,
          closingCash: closingCash,
          expectedCash: expected,
        ),
      );
    }
    setState(() {
      if (isOwner) {
        _ownerOnShift = false;
      } else if (pin != null) {
        _workingStaffPins.remove(pin);
      }
    });
    if (closingCash != null && closingCash != expected) {
      _showMessage(
        'Shift ended. Cash counted: ${closingCash.toStringAsFixed(2)} $_currency; expected ${expected.toStringAsFixed(2)} $_currency.',
      );
    }
  }

  Future<String?> _askForShiftPin({
    required bool isOwner,
    bool ending = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ShiftPinDialog(
        person: isOwner ? '$_ownerName · Owner' : 'Staff member',
        digits: isOwner ? 6 : 4,
        action: ending ? 'End shift' : 'End shift',
      ),
    );
  }

  Future<void> _addStaff() async {
    final member = await showDialog<StaffSetup>(
      context: context,
      builder: (context) => AddStaffDialog(existingPins: _setup.staffPins),
    );
    if (!mounted || member == null) return;
    setState(() {
      _setup.staff.add(member);
      _setup.staffPins.add(member.pin);
      _ownerOnShift = false;
    });
  }

  Future<void> _confirmRemoveStaff(StaffSetup member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: const Text('They will no longer be able to start a shift.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep staff member'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _setup.staff.remove(member);
      _setup.staffPins.remove(member.pin);
      _workingStaffPins.remove(member.pin);
    });
  }

  Future<void> _setOwnerPin() async {
    final pin = await _askForOwnerPin();
    if (!mounted || pin == null) return;
    setState(() => _setup.ownerPin = pin);
    _showMessage('Your owner PIN is set.');
  }

  Future<String?> _askForOwnerPin() {
    return showDialog<String>(
      context: context,
      builder: (context) => const OwnerPinDialog(),
    );
  }

  Future<void> _openFrontDesk() async {
    if (_openingFrontDesk) return;
    setState(() => _openingFrontDesk = true);
    try {
      if (_setup.staff.isEmpty) {
        final openingCash = await _openingCashForShift();
        if (!mounted || openingCash == null) return;
        _createShift(_ownerShiftName, openingCash);
        setState(() {
          _section = _DashboardSection.today;
          _ownerOnShift = true;
        });
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      final key = frontDeskPreferenceKey(_setup);
      final savedChoice = preferences.getBool(key);
      if (savedChoice == false) {
        _showOwnerOnlyInstructions();
        return;
      }

      var useAsFrontDesk = savedChoice;
      if (useAsFrontDesk == null) {
        useAsFrontDesk = await showDialog<bool>(
          context: context,
          builder: (context) => const FrontDeskChoiceDialog(),
        );
        if (!mounted || useAsFrontDesk == null) return;
      }

      if (!useAsFrontDesk) {
        final saved = await preferences.setBool(key, false);
        if (!mounted) return;
        if (!saved) {
          _showMessage(
            'Could not save this computer’s front-desk setting. Please try again.',
          );
          return;
        }
        _showOwnerOnlyInstructions();
        return;
      }

      if (_setup.ownerPin == null) {
        final pin = await _askForOwnerPin();
        if (!mounted || pin == null) return;
        _setup.ownerPin = pin;
      }

      if (savedChoice == null) {
        final saved = await preferences.setBool(key, true);
        if (!mounted) return;
        if (!saved) {
          _showMessage(
            'Could not save this computer’s front-desk setting. Please try again.',
          );
          return;
        }
      }

      if (mounted) setState(() => _section = _DashboardSection.today);
    } finally {
      if (mounted) setState(() => _openingFrontDesk = false);
    }
  }

  void _showOwnerOnlyInstructions() {
    _showMessage(
      'On the front desk computer, log in and tap Open the front desk.',
      duration: const Duration(seconds: 6),
    );
  }

  void _showMessage(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _sectionTitle(_DashboardSection section) => switch (section) {
    _DashboardSection.dashboard => 'Dashboard',
    _DashboardSection.today => 'Front desk',
    _DashboardSection.bookings => 'Bookings',
    _DashboardSection.tasks => 'Tasks',
    _DashboardSection.customers => 'Customers',
    _DashboardSection.money => 'Money',
    _DashboardSection.insights => 'Insights',
    _DashboardSection.spaces => 'Spaces & rooms',
    _DashboardSection.products => 'Products',
    _DashboardSection.staff => 'Staff',
    _DashboardSection.settings => 'Settings',
  };

  String _dateLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
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
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}
