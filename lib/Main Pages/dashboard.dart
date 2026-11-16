import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/prices_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart'
    show spaceSummary;
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/features/workspace/presentation/workspace_bookings_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_customers_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_insights_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_money_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_products_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_settings_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_tasks_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_today_operations.dart';
import 'package:grid_os/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_widgets.dart';
import 'staff_page.dart';
import 'package:grid_os/features/workspace/presentation/workspace_page_utils.dart';

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

enum _ChartMetric { money, visits }

enum _SpacesTab { spaces, prices }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.setup});

  final StartupSetup setup;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _workingStaffPins = <String>{};
  final _expandedSpaceDetails = <String>{};
  late final WorkspaceRepository _workspaceRepository;

  _DashboardSection _section = _DashboardSection.dashboard;
  _SpacesTab _spacesTab = _SpacesTab.spaces;
  _ChartMetric _chartMetric = _ChartMetric.money;
  String _period = 'This month';
  String _comparison = 'Nothing';
  bool _ownerOnShift = false;
  bool _openingFrontDesk = false;
  bool _showWorkspaceTip = true;

  @override
  void initState() {
    super.initState();
    _workspaceRepository = WorkspaceRepository();
    _seedProductsFromSetup();
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
  DateTime? get _dashboardFromDate {
    final now = DateTime.now();
    return switch (_period) {
      'Today' => DateTime(now.year, now.month, now.day),
      'This week' => DateTime(now.year, now.month, now.day - now.weekday + 1),
      'This year' => DateTime(now.year),
      _ => DateTime(now.year, now.month),
    };
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
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
                if (desktop) _navigationSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _topBar(desktop: desktop),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const PageStorageKey<String>('dashboard-page'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: desktop ? 28 : 16,
                            vertical: desktop ? 22 : 16,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
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
      width: 218,
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
                  _navigationItem(item.$1, item.$2, item.$3),
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

  static const _primaryNavigation = <(_DashboardSection, String, IconData)>[
    (_DashboardSection.dashboard, 'Dashboard', Icons.home_outlined),
    (_DashboardSection.today, 'Today', Icons.today_outlined),
    (_DashboardSection.bookings, 'Bookings', Icons.calendar_month_outlined),
    (_DashboardSection.tasks, 'Tasks', Icons.checklist_outlined),
    (_DashboardSection.customers, 'Customers', Icons.people_outline),
    (_DashboardSection.money, 'Money', Icons.account_balance_wallet_outlined),
    (_DashboardSection.insights, 'Insights', Icons.bar_chart_outlined),
  ];

  static const _workspaceNavigation = <(_DashboardSection, String, IconData)>[
    (_DashboardSection.spaces, 'Spaces & rooms', Icons.grid_view_outlined),
    (_DashboardSection.products, 'Products', Icons.inventory_2_outlined),
    (_DashboardSection.staff, 'Staff', Icons.badge_outlined),
  ];

  Widget _navigationItem(
    _DashboardSection section,
    String label,
    IconData icon,
  ) {
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
          title: Text(label, style: const TextStyle(fontSize: 11)),
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
            Text(
              _sectionTitle(_section),
              style: const TextStyle(
                color: AppColors.authInk,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
            icon: const Icon(Icons.today_outlined, size: 16),
            label: Text(desktop ? 'Today' : ''),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<_OwnerMenuAction>(
            key: const ValueKey('owner-menu'),
            tooltip: 'Owner menu',
            onSelected: (action) {
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
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _OwnerMenuAction.addStaff,
                child: _menuRow(Icons.person_add_alt_1, 'Add staff'),
              ),
              PopupMenuItem(
                key: const ValueKey('owner-open-front-desk'),
                value: _OwnerMenuAction.openFrontDesk,
                child: _menuRow(
                  Icons.desktop_windows_outlined,
                  'Open the front desk',
                ),
              ),
              PopupMenuItem(
                value: _OwnerMenuAction.settings,
                child: _menuRow(Icons.settings_outlined, 'Settings'),
              ),
            ],
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
      _DashboardSection.dashboard => _dashboardOverview(),
      _DashboardSection.today => _todayPage(),
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
      _DashboardSection.spaces => _spacesPage(),
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

  Widget _dashboardOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeader(
          '$_greeting, $_ownerName',
          '${_dateLabel()} · ${_setup.workspaceName} · '
              '${_setup.city ?? _setup.country.name}',
          titleKey: const ValueKey('dashboard-greeting'),
        ),
        if (_showWorkspaceTip) ...[const SizedBox(height: 14), _workspaceTip()],
        const SizedBox(height: 14),
        _dashboardFilters(),
        const SizedBox(height: 12),
        _metricGrid(),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  _chartCard(),
                  const SizedBox(height: 12),
                  _standsOutCard(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _chartCard()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _standsOutCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _spacePerformanceCard(),
      ],
    );
  }

  Widget _pageHeader(String title, String subtitle, {Key? titleKey}) {
    return DashboardPageHeader(
      title: title,
      subtitle: subtitle,
      titleKey: titleKey,
      trailing: MediaQuery.sizeOf(context).width > 500
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.authBorder),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: AppColors.authGreen),
                  SizedBox(width: 6),
                  Text(
                    'Right now · all quiet',
                    style: AppTextStyles.authHelper,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _workspaceTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        border: Border.all(color: const Color(0xFFCBE3D9)),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.authGreen, size: 18),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your workspace at a glance',
                  style: TextStyle(
                    color: AppColors.authInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Money, visits and how full each space is, for the dates you pick. '
                  'Not sure what a number means? Tap the ? next to it.',
                  style: AppTextStyles.authHelper,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showWorkspaceTip = false),
            child: const Text('Got it', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _dashboardFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterMenu(
          label: 'Showing',
          value: _period,
          options: const ['Today', 'This week', 'This month', 'This year'],
          onSelected: (value) => setState(() => _period = value),
        ),
        _filterMenu(
          label: 'Compared with',
          value: _comparison,
          options: const ['Nothing', 'Last week', 'Last month', 'Last year'],
          onSelected: (value) => setState(() => _comparison = value),
        ),
      ],
    );
  }

  Widget _filterMenu({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      width: 240,
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final option in options)
            PopupMenuItem(value: option, child: Text(option)),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.authBorder),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 14, color: AppColors.authMuted),
              const SizedBox(width: 7),
              Text(label, style: AppTextStyles.authHelper),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.authInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.expand_more, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricGrid() {
    final from = _dashboardFromDate;
    final totals = _workspaceRepository.moneyTotals(from: from)[_currency];
    final visits = _workspaceRepository.visits.where((visit) {
      return from == null || !visit.checkedInAt.isBefore(from);
    }).length;
    final newCustomers = _workspaceRepository.customers.where((customer) {
      final createdAt = customer.createdAt;
      return createdAt != null && (from == null || !createdAt.isBefore(from));
    }).length;
    final capacity = workspaceSpaceOptions(_setup).length;
    final occupancy = capacity == 0
        ? 0
        : ((_workspaceRepository.activeVisits().length / capacity) * 100)
              .round()
              .clamp(0, 100);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850
            ? 4
            : constraints.maxWidth >= 500
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: columns == 1 ? 2.5 : 1.65,
          children: [
            _metricCard(
              keyName: 'metric-money-in',
              label: 'Money in',
              detail: 'Everything customers paid',
              value: '${(totals?.income ?? 0).toStringAsFixed(0)} $_currency',
              icon: Icons.account_balance_wallet_outlined,
            ),
            _metricCard(
              keyName: 'metric-visits',
              label: 'Visits',
              detail: 'Times customers came in',
              value: '$visits',
              icon: Icons.door_front_door_outlined,
            ),
            _metricCard(
              keyName: 'metric-new-customers',
              label: 'New customers',
              detail: 'Came for the first time',
              value: '$newCustomers',
              icon: Icons.person_add_alt_outlined,
            ),
            _metricCard(
              keyName: 'metric-how-full',
              label: 'How full',
              detail: 'How much space was used',
              value: '$occupancy%',
              icon: Icons.speed_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required String keyName,
    required String label,
    required String detail,
    required String value,
    required IconData icon,
  }) {
    return Container(
      key: ValueKey(keyName),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.authGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.authInk,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.help_outline, size: 13, color: AppColors.authMuted),
            ],
          ),
          Text(detail, style: AppTextStyles.authHelper),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.authInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _chartMetric == _ChartMetric.money
                      ? 'Money in, day by day'
                      : 'Visits, day by day',
                  style: AppTextStyles.workspaceTitle,
                ),
              ),
              SegmentedButton<_ChartMetric>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _ChartMetric.money,
                    label: Text('Money'),
                  ),
                  ButtonSegment(
                    value: _ChartMetric.visits,
                    label: Text('Visits'),
                  ),
                ],
                selected: {_chartMetric},
                onSelectionChanged: (selection) =>
                    setState(() => _chartMetric = selection.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_period, style: AppTextStyles.authHelper),
          SizedBox(
            key: const ValueKey('flat-dashboard-chart'),
            height: 150,
            child: CustomPaint(
              painter: _FlatChartPainter(values: _dashboardChartValues()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in _chartLabels())
                Text(label, style: AppTextStyles.authHelper),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _dashboardChartValues() {
    final end = DateTime.now();
    final start = _dashboardFromDate ?? DateTime(end.year, end.month);
    final span = end.difference(start);
    final interval = Duration(microseconds: (span.inMicroseconds / 7).round());
    if (interval <= Duration.zero) return List.filled(7, 0);
    return List.generate(7, (index) {
      final bucketStart = start.add(interval * index);
      final bucketEnd = index == 6
          ? end.add(const Duration(microseconds: 1))
          : bucketStart.add(interval);
      if (_chartMetric == _ChartMetric.money) {
        return _workspaceRepository.moneyEntries
            .where(
              (entry) =>
                  entry.kind == MoneyEntryKind.income &&
                  entry.currency == _currency &&
                  !entry.occurredAt.isBefore(bucketStart) &&
                  entry.occurredAt.isBefore(bucketEnd),
            )
            .fold(0.0, (total, entry) => total + entry.amount);
      }
      return _workspaceRepository.visits
          .where(
            (visit) =>
                !visit.checkedInAt.isBefore(bucketStart) &&
                visit.checkedInAt.isBefore(bucketEnd),
          )
          .length
          .toDouble();
    });
  }

  List<String> _chartLabels() => switch (_period) {
    'Today' => const ['00', '04', '08', '12', '16', '20', '24'],
    'This week' => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'This year' => const ['Jan', 'Mar', 'May', 'Jul', 'Sep', 'Nov', 'Dec'],
    _ => const ['1', '5', '10', '15', '20', '25', '30'],
  };

  Widget _standsOutCard() {
    final lowStock = _workspaceRepository.lowStockProducts().length;
    final overdueTasks = _workspaceRepository.tasks.where((task) {
      return !task.isCompleted &&
          task.dueAt != null &&
          task.dueAt!.isBefore(DateTime.now());
    }).length;
    final visitCount = _workspaceRepository.visits.length;
    final insight = lowStock > 0
        ? '$lowStock product${lowStock == 1 ? '' : 's'} running low on stock'
        : overdueTasks > 0
        ? '$overdueTasks task${overdueTasks == 1 ? '' : 's'} past due'
        : visitCount > 0
        ? '$visitCount customer visit${visitCount == 1 ? '' : 's'} recorded'
        : 'Nothing to point out yet';
    return Container(
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What stands out', style: AppTextStyles.workspaceTitle),
          const SizedBox(height: 3),
          Text(_period, style: AppTextStyles.authHelper),
          const Divider(height: 20),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  insight == 'Nothing to point out yet'
                      ? Icons.auto_awesome_outlined
                      : Icons.lightbulb_outline,
                  color: AppColors.authMuted,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.authDescription,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _spacePerformanceCard() {
    final spaces = _setup.selectedSpaces;
    final kitchenItems = _setup.kitchenItems
        .where(
          (item) =>
              item.name.trim().isNotEmpty ||
              item.price.trim().isNotEmpty ||
              item.quantity.trim().isNotEmpty ||
              item.costsYou.trim().isNotEmpty,
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final isEmpty = spaces.isEmpty && kitchenItems.isEmpty;
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How each space is doing',
                style: AppTextStyles.workspaceTitle,
              ),
              const SizedBox(height: 3),
              const Text(
                'From what you set up in Spaces & rooms',
                style: AppTextStyles.authHelper,
              ),
              const SizedBox(height: 12),
              if (isEmpty)
                const Text(
                  'No spaces set up yet.',
                  style: AppTextStyles.authDescription,
                )
              else ...[
                if (!compact) _performanceTableHeader(),
                for (var index = 0; index < spaces.length; index++)
                  _spacePerformanceRow(
                    spaces[index],
                    isLast: index == spaces.length - 1 && kitchenItems.isEmpty,
                    compact: compact,
                  ),
                if (kitchenItems.isNotEmpty)
                  _performanceRow(
                    id: 'kitchen',
                    title: 'Kitchen',
                    details: '${kitchenItems.length} products',
                    items: [
                      for (var index = 0; index < kitchenItems.length; index++)
                        kitchenItems[index].name.trim().isEmpty
                            ? 'Product ${index + 1}'
                            : kitchenItems[index].name.trim(),
                    ],
                    used: '0 sold',
                    moneyIn: 0,
                    isLast: true,
                    compact: compact,
                    icon: Icons.local_cafe_outlined,
                  ),
              ],
              if (isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _selectSection(_DashboardSection.spaces),
                    child: const Text('Set up spaces'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _performanceTableHeader() {
    const style = TextStyle(
      color: AppColors.authMuted,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: .3,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('SPACE', style: style)),
          Expanded(flex: 2, child: Text('HOW FULL', style: style)),
          Expanded(flex: 2, child: Text('USED', style: style)),
          Expanded(flex: 2, child: Text('MONEY IN', style: style)),
          Expanded(flex: 1, child: Text('CHANGE', style: style)),
        ],
      ),
    );
  }

  Widget _spacePerformanceRow(
    SetupSpaceType type, {
    required bool isLast,
    required bool compact,
  }) {
    final details = spaceSummary(type, _setup.spaces[type]!);
    return _performanceRow(
      id: type.name,
      title: type.label,
      details: details,
      items: _spaceItemNames(type),
      used: _spaceUsage(type),
      moneyIn: _spaceIncome(type),
      isLast: isLast,
      compact: compact,
      icon: type == SetupSpaceType.rooms
          ? Icons.meeting_room_outlined
          : Icons.chair_outlined,
    );
  }

  List<String> _spaceItemNames(SetupSpaceType type) =>
      workspaceSpaceOptions(_setup)
          .where((option) => option.type == type)
          .map((option) => option.name)
          .toList();

  String _spaceUsage(SetupSpaceType type) {
    final visits = _workspaceRepository.visits.where(
      (visit) =>
          visit.spaceType == type &&
          (_dashboardFromDate == null ||
              !visit.checkedInAt.isBefore(_dashboardFromDate!)),
    );
    return switch (type) {
      SetupSpaceType.sharedArea => '${visits.length} visits',
      SetupSpaceType.rooms => '${visits.length} bookings',
      SetupSpaceType.computers => '${visits.length} sessions',
      SetupSpaceType.privateOffices => '${visits.length} rentals',
      SetupSpaceType.virtualOffice => '${visits.length} visits',
      SetupSpaceType.other => '${visits.length} bookings',
    };
  }

  double _spaceIncome(SetupSpaceType type) => _workspaceRepository.visits
      .where(
        (visit) =>
            visit.spaceType == type &&
            visit.isPaid &&
            (_dashboardFromDate == null ||
                !visit.checkedInAt.isBefore(_dashboardFromDate!)),
      )
      .fold(0, (total, visit) => total + visit.amount);

  Widget _performanceRow({
    required String id,
    required String title,
    required String details,
    required List<String> items,
    required String used,
    required double moneyIn,
    required bool isLast,
    required bool compact,
    required IconData icon,
  }) {
    final expanded = _expandedSpaceDetails.contains(id);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.authBorder)),
      ),
      child: Column(
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _performanceName(id, title, details, items, icon, expanded),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _fullCell()),
                    Expanded(
                      child: Text(used, style: AppTextStyles.authHelper),
                    ),
                    Expanded(
                      child: Text(
                        '${moneyIn.toStringAsFixed(0)} $_currency',
                        textAlign: TextAlign.right,
                        style: AppTextStyles.authHelper,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _performanceName(
                    id,
                    title,
                    details,
                    items,
                    icon,
                    expanded,
                  ),
                ),
                Expanded(flex: 2, child: _fullCell()),
                Expanded(
                  flex: 2,
                  child: Text(used, style: AppTextStyles.authHelper),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${moneyIn.toStringAsFixed(0)} $_currency',
                    style: AppTextStyles.authHelper,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _comparison == 'Nothing' ? '—' : '0%',
                    style: AppTextStyles.authHelper,
                  ),
                ),
              ],
            ),
          if (expanded)
            Padding(
              padding: EdgeInsets.only(
                left: compact ? 27 : 26,
                top: 7,
                right: 3,
              ),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.subdirectory_arrow_right,
                            size: 13,
                            color: AppColors.authMuted,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(item, style: AppTextStyles.authHelper),
                          ),
                          const Text(
                            '0% full · 0 activity',
                            style: AppTextStyles.authHelper,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _performanceName(
    String id,
    String title,
    String details,
    List<String> items,
    IconData icon,
    bool expanded,
  ) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.authMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.authInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(details, style: AppTextStyles.authHelper),
            ],
          ),
        ),
        if (items.isNotEmpty)
          TextButton(
            key: ValueKey('show-space-details-$id'),
            onPressed: () => setState(() {
              if (expanded) {
                _expandedSpaceDetails.remove(id);
              } else {
                _expandedSpaceDetails.add(id);
              }
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(expanded ? 'Hide' : 'Show all ${items.length}'),
          ),
      ],
    );
  }

  Widget _fullCell() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('0% full', style: AppTextStyles.authHelper),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0,
            minHeight: 4,
            backgroundColor: AppColors.authBorder,
            color: AppColors.authGreen,
          ),
        ),
      ],
    );
  }

  Widget _todayPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeader('Today', _dateLabel()),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Who’s working?', style: AppTextStyles.workspaceTitle),
              const SizedBox(height: 4),
              const Text(
                'The owner is always listed first.',
                style: AppTextStyles.authHelper,
              ),
              const SizedBox(height: 10),
              _workerRow(
                name: '$_ownerName · Owner',
                pin: null,
                isOwner: true,
                isWorking: _ownerOnShift,
              ),
              for (final member in _setup.staff)
                _workerRow(
                  name: member.name,
                  pin: member.pin,
                  isOwner: false,
                  isWorking: _workingStaffPins.contains(member.pin),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WorkspaceTodayOperations(
          repository: _workspaceRepository,
          setup: _setup,
          currency: _currency,
          onChanged: _workspaceDataChanged,
          onOpenBookings: () => _selectSection(_DashboardSection.bookings),
        ),
      ],
    );
  }

  Widget _workerRow({
    required String name,
    required String? pin,
    required bool isOwner,
    required bool isWorking,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.authBorder)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: isWorking
                ? AppColors.homePaleGreen
                : AppColors.authBackground,
            child: Icon(
              isOwner ? Icons.star_outline : Icons.person_outline,
              size: 17,
              color: AppColors.authGreen,
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
                Text(
                  isWorking ? 'On shift' : 'Not started',
                  style: AppTextStyles.authHelper,
                ),
              ],
            ),
          ),
          if (isWorking)
            OutlinedButton(
              onPressed: () => _endShift(pin: pin, isOwner: isOwner),
              child: const Text('End shift'),
            )
          else
            OutlinedButton(
              key: ValueKey(isOwner ? 'start-shift-owner' : 'start-shift-$pin'),
              onPressed: () => _startShift(pin: pin, isOwner: isOwner),
              child: const Text('Start shift'),
            ),
        ],
      ),
    );
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
      builder: (context) => const _CashCountDialog(
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
        builder: (context) => _CashCountDialog(
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
      builder: (context) => _ShiftPinDialog(
        person: isOwner ? '$_ownerName · Owner' : 'Staff member',
        digits: isOwner ? 6 : 4,
        action: ending ? 'End shift' : 'Start shift',
      ),
    );
  }

  Widget _spacesPage() {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = const Text(
                  'Spaces & rooms',
                  style: TextStyle(
                    color: AppColors.authInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                );
                if (constraints.maxWidth >= 500) {
                  return Row(
                    children: [
                      Expanded(child: title),
                      _spacesTabSelector(),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    _spacesTabSelector(),
                  ],
                );
              },
            ),
            const SizedBox(height: 17),
            Text(
              _spacesTab == _SpacesTab.spaces ? 'Spaces' : 'Prices',
              style: AppTextStyles.workspaceTitle,
            ),
            const SizedBox(height: 3),
            Text(
              _spacesTab == _SpacesTab.spaces
                  ? 'Spaces in ${_setup.city ?? _setup.country.name}. '
                        'Tick what customers can use; each one opens with its details. '
                        'Staff see changes on Today right away.'
                  : 'Set walk-in prices and optional plans for each space.',
              style: AppTextStyles.authHelper,
            ),
            const SizedBox(height: 12),
            if (_spacesTab == _SpacesTab.spaces)
              SpacesPage(
                setup: _setup,
                embedded: true,
                onChanged: () {
                  if (mounted) setState(() {});
                },
              )
            else
              PricesPage(setup: _setup, embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _spacesTabSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _spacesTabButton(_SpacesTab.spaces, 'Spaces'),
          _spacesTabButton(_SpacesTab.prices, 'Prices'),
        ],
      ),
    );
  }

  Widget _spacesTabButton(_SpacesTab tab, String label) {
    final selected = _spacesTab == tab;
    return Material(
      color: selected ? AppColors.authGreen : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.control - 2),
      child: InkWell(
        key: ValueKey('spaces-tab-${tab.name}'),
        borderRadius: BorderRadius.circular(AppRadii.control - 2),
        onTap: () => setState(() => _spacesTab = tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.authInk,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addStaff() async {
    final member = await showDialog<StaffSetup>(
      context: context,
      builder: (context) => _AddStaffDialog(existingPins: _setup.staffPins),
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
      builder: (context) => const _OwnerPinDialog(),
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
          builder: (context) => const _FrontDeskChoiceDialog(),
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
    _DashboardSection.today => 'Today',
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

  BoxDecoration _cardDecoration() => dashboardCardDecoration();
}

class _FlatChartPainter extends CustomPainter {
  const _FlatChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.authBorder
      ..strokeWidth = 1;
    final line = Paint()
      ..color = AppColors.authGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final chartTop = 12.0;
    final chartBottom = size.height - 12;

    for (var index = 0; index < 4; index++) {
      final y = chartTop + (chartBottom - chartTop) * index / 3;
      canvas.drawLine(Offset(26, y), Offset(size.width, y), grid);
    }
    final maxValue = values.fold<double>(0, (max, value) {
      return value > max ? value : max;
    });
    final usableHeight = chartBottom - chartTop - 8;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length <= 1
          ? 26.0
          : 26 + (size.width - 26) * index / (values.length - 1);
      final y = maxValue <= 0
          ? chartBottom - 2
          : chartBottom - 2 - (values[index] / maxValue) * usableHeight;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);

    if (maxValue <= 0) {
      final zeroLabel = TextPainter(
        text: const TextSpan(
          text: '0',
          style: TextStyle(color: AppColors.authMuted, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      zeroLabel.paint(
        canvas,
        Offset(3, chartBottom - 2 - zeroLabel.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlatChartPainter oldDelegate) {
    if (values.length != oldDelegate.values.length) return true;
    for (var index = 0; index < values.length; index++) {
      if (values[index] != oldDelegate.values[index]) return true;
    }
    return false;
  }
}

class _FrontDeskChoiceDialog extends StatefulWidget {
  const _FrontDeskChoiceDialog();

  @override
  State<_FrontDeskChoiceDialog> createState() => _FrontDeskChoiceDialogState();
}

class _FrontDeskChoiceDialogState extends State<_FrontDeskChoiceDialog> {
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
            description: 'Staff start their shifts here with their PIN. Your side gets a lock.',
            onTap: () => setState(() => _isFrontDesk = true),
          ),
          const SizedBox(height: 8),
          _choiceCard(
            key: const ValueKey('frontdesk-choice-no'),
            selected: !_isFrontDesk,
            title: 'No, it’s just mine',
            description: 'Staff use another computer. On the front desk computer, log in and tap Open the front desk.',
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

class _OwnerPinDialog extends StatefulWidget {
  const _OwnerPinDialog();

  @override
  State<_OwnerPinDialog> createState() => _OwnerPinDialogState();
}

class _OwnerPinDialogState extends State<_OwnerPinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    final pin = _pinController.text;
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
      title: const Text('Set your owner PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Your 6-digit PIN protects your side and lets you start a shift.',
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
          ),
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
          ),
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
          onPressed: _save,
          child: const Text('Save PIN'),
        ),
      ],
    );
  }
}

class _ShiftPinDialog extends StatefulWidget {
  const _ShiftPinDialog({
    required this.person,
    required this.digits,
    this.action = 'Start shift',
  });

  final String person;
  final int digits;
  final String action;

  @override
  State<_ShiftPinDialog> createState() => _ShiftPinDialogState();
}

class _ShiftPinDialogState extends State<_ShiftPinDialog> {
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
          ),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
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
          onPressed: () {
            if (_controller.text.length != widget.digits) {
              setState(() => _error = 'Enter a ${widget.digits}-digit PIN.');
              return;
            }
            Navigator.pop(context, _controller.text);
          },
          child: Text(widget.action),
        ),
      ],
    );
  }
}

class _CashCountDialog extends StatefulWidget {
  const _CashCountDialog({
    required this.title,
    required this.actionLabel,
    this.expectedCash,
  });

  final String title;
  final String actionLabel;
  final double? expectedCash;

  @override
  State<_CashCountDialog> createState() => _CashCountDialogState();
}

class _CashCountDialogState extends State<_CashCountDialog> {
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

class _AddStaffDialog extends StatefulWidget {
  const _AddStaffDialog({required this.existingPins});

  final Set<String> existingPins;

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
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
            decoration: setupInputDecoration(hintText: '4-digit PIN')
                .copyWith(counterText: ''),
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
