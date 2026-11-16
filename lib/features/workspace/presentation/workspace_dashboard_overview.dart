import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:grid_os/Main Pages/dashboard_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart'
    show spaceSummary;
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/features/workspace/presentation/workspace_page_utils.dart';
import 'package:grid_os/theme/app_theme.dart';

enum _DashboardChartMetric { money, visits }

class WorkspaceDashboardOverview extends StatefulWidget {
  const WorkspaceDashboardOverview({
    super.key,
    required this.setup,
    required this.repository,
    required this.currency,
    required this.onOpenTasks,
    required this.onOpenProducts,
    required this.onOpenSpaces,
  });

  final StartupSetup setup;
  final WorkspaceRepository repository;
  final String currency;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenSpaces;

  @override
  State<WorkspaceDashboardOverview> createState() =>
      _WorkspaceDashboardOverviewState();
}

class _WorkspaceDashboardOverviewState
    extends State<WorkspaceDashboardOverview> {
  String _period = 'This month';
  String _comparison = 'Nothing';
  late _DashboardDateRange _currentRange = _DashboardDateRange.forPreset(
    _period,
    DateTime.now(),
  );
  _DashboardDateRange? _customComparisonRange;
  _DashboardChartMetric _chartMetric = _DashboardChartMetric.money;
  final Set<String> _expandedSpaces = {};

  _DashboardDateRange? get _comparisonRange => switch (_comparison) {
    'Nothing' => null,
    'Custom dates' => _customComparisonRange,
    _ => _DashboardDateRange.comparison(_currentRange, _comparison),
  };

  @override
  Widget build(BuildContext context) {
    final range = _currentRange;
    final comparisonRange = _comparisonRange;
    return Column(
      key: const ValueKey('dashboard-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filters(range, comparisonRange),
        const SizedBox(height: 12),
        _metrics(range, comparisonRange),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                children: [
                  _chart(range, comparisonRange),
                  const SizedBox(height: 12),
                  _highlights(range, comparisonRange),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _chart(range, comparisonRange)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _highlights(range, comparisonRange)),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _spacePerformance(),
      ],
    );
  }

  Widget _filters(
    _DashboardDateRange range,
    _DashboardDateRange? comparisonRange,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DashboardFilterButton(
          key: const ValueKey('dashboard-period-filter'),
          label: 'Showing',
          value: _period,
          rangeLabel: range.label,
          icon: Icons.calendar_month_outlined,
          onPressed: _pickShowingRange,
        ),
        _comparisonFilter(
          key: const ValueKey('dashboard-comparison-filter'),
          range: comparisonRange,
        ),
      ],
    );
  }

  Widget _comparisonFilter({
    required Key key,
    required _DashboardDateRange? range,
  }) {
    const options = [
      'Nothing',
      'Previous period',
      'Same time last year',
      'Custom dates',
    ];
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: PopupMenuButton<String>(
              key: key,
              tooltip: 'Compared with $_comparison',
              onSelected: _selectComparison,
              itemBuilder: (context) => [
                for (final option in options)
                  PopupMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        Expanded(child: Text(option)),
                        if (_comparison == option)
                          const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.authGreen,
                          ),
                      ],
                    ),
                  ),
              ],
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_outlined,
                    size: 15,
                    color: AppColors.authMuted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Compared with',
                          style: AppTextStyles.authHelper,
                        ),
                        Text(
                          _comparison == 'Nothing'
                              ? 'Nothing'
                              : '$_comparison${range == null ? '' : ' · ${range.label}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.authInk,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 15),
                ],
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('dashboard-comparison-custom-date'),
            tooltip: 'Choose custom comparison dates',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            onPressed: _openComparisonRangePicker,
            icon: const Icon(Icons.calendar_month_outlined, size: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _pickShowingRange() async {
    final selected = await showDialog<_SelectedDashboardRange>(
      context: context,
      builder: (context) => _DashboardRangePickerDialog(
        initialRange: _currentRange,
        initialPreset: _period,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _currentRange = selected.range;
      _period = selected.label;
    });
  }

  Future<void> _selectComparison(String value) async {
    if (value != 'Custom dates') {
      setState(() {
        _comparison = value;
        _customComparisonRange = null;
      });
      return;
    }

    await _openComparisonRangePicker();
  }

  Future<void> _openComparisonRangePicker() async {
    final previousComparison = _comparison;
    setState(() => _comparison = 'Custom dates');
    final selected = await showDialog<_SelectedDashboardRange>(
      context: context,
      builder: (context) => _DashboardRangePickerDialog(
        initialRange: _customComparisonRange ?? _currentRange,
        initialPreset: 'Custom dates',
      ),
    );
    if (!mounted) return;
    if (selected == null) {
      setState(() => _comparison = previousComparison);
      return;
    }
    setState(() => _customComparisonRange = selected.range);
  }

  Widget _metrics(
    _DashboardDateRange range,
    _DashboardDateRange? comparisonRange,
  ) {
    final values = [
      _DashboardMetric(
        keyName: 'metric-money-in',
        label: 'Money in',
        detail: 'Everything customers paid',
        value: _moneyIn(range),
        previousValue: comparisonRange == null
            ? null
            : _moneyIn(comparisonRange),
        format: (value) => '${_formatNumber(value)} ${widget.currency}',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _DashboardMetric(
        keyName: 'metric-visits',
        label: 'Visits',
        detail: 'Times customers came in',
        value: _visitCount(range).toDouble(),
        previousValue: comparisonRange == null
            ? null
            : _visitCount(comparisonRange).toDouble(),
        format: (value) => _formatNumber(value),
        icon: Icons.door_front_door_outlined,
      ),
      _DashboardMetric(
        keyName: 'metric-new-customers',
        label: 'New customers',
        detail: 'Came for the first time',
        value: _newCustomerCount(range).toDouble(),
        previousValue: comparisonRange == null
            ? null
            : _newCustomerCount(comparisonRange).toDouble(),
        format: (value) => _formatNumber(value),
        icon: Icons.person_add_alt_outlined,
      ),
      _DashboardMetric(
        keyName: 'metric-how-full',
        label: 'How full',
        detail: 'How much space was used',
        value: _occupancy(range),
        previousValue: comparisonRange == null
            ? null
            : _occupancy(comparisonRange),
        format: (value) => '${value.round()}%',
        icon: Icons.speed_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 760
            ? 205.0
            : (constraints.maxWidth - 24) / 4;
        return SingleChildScrollView(
          key: const ValueKey('dashboard-metrics-scroll'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < values.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                SizedBox(
                  width: width,
                  child: _MetricCard(
                    metric: values[index],
                    comparisonLabel: comparisonRange?.label,
                    comparisonName: _comparison,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _chart(
    _DashboardDateRange range,
    _DashboardDateRange? comparisonRange,
  ) {
    final buckets = _chartBuckets(range, comparisonRange);
    final metricLabel = _chartMetric == _DashboardChartMetric.money
        ? 'Money in, day by day'
        : 'Visits, day by day';
    return DashboardPanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(metricLabel, style: AppTextStyles.workspaceTitle),
              ),
              SegmentedButton<_DashboardChartMetric>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _DashboardChartMetric.money,
                    label: Text('Money'),
                  ),
                  ButtonSegment(
                    value: _DashboardChartMetric.visits,
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
          Wrap(
            spacing: 14,
            children: [
              _ChartLegend(label: range.label, color: AppColors.authGreen),
              if (comparisonRange != null)
                _ChartLegend(
                  label: comparisonRange.label,
                  color: const Color(0xFFC5CBC7),
                ),
            ],
          ),
          SizedBox(
            key: const ValueKey('dashboard-comparison-chart'),
            height: 190,
            child: CustomPaint(
              painter: _ComparisonChartPainter(
                values: buckets,
                isMoney: _chartMetric == _DashboardChartMetric.money,
                currency: widget.currency,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final bucket in buckets)
                Expanded(
                  child: Text(
                    bucket.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.authHelper,
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('dashboard-see-numbers'),
              onPressed: () => _showChartNumbers(buckets, comparisonRange),
              child: const Text('See the numbers'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlights(
    _DashboardDateRange range,
    _DashboardDateRange? comparisonRange,
  ) {
    final insights = _buildInsights(range, comparisonRange);
    return DashboardPanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('What stands out', style: AppTextStyles.workspaceTitle),
          const SizedBox(height: 3),
          Text(
            comparisonRange == null
                ? range.label
                : '${range.label} compared with ${comparisonRange.label}',
            style: AppTextStyles.authHelper,
          ),
          const Divider(height: 18),
          if (insights.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Nothing to point out yet',
                textAlign: TextAlign.center,
                style: AppTextStyles.authDescription,
              ),
            )
          else
            for (var index = 0; index < insights.length; index++) ...[
              if (index > 0)
                const Divider(height: 14, color: AppColors.authBorder),
              _InsightRow(insight: insights[index]),
            ],
        ],
      ),
    );
  }

  List<_DashboardInsight> _buildInsights(
    _DashboardDateRange range,
    _DashboardDateRange? comparisonRange,
  ) {
    final insights = <_DashboardInsight>[];
    final lowStock = widget.repository.lowStockProducts();
    for (final product in lowStock.take(2)) {
      insights.add(
        _DashboardInsight(
          icon: Icons.inventory_2_outlined,
          tint: const Color(0xFFFAE9D7),
          title: '${product.name} needs stock',
          description:
              '${_formatNumber(product.quantityOnHand)} ${product.unit} left.',
          actionLabel: 'Review products',
          onTap: widget.onOpenProducts,
        ),
      );
    }

    final topSpace = _topEarningSpace(range);
    final previousTopSpace = comparisonRange == null
        ? null
        : _topEarningSpace(comparisonRange);
    if (topSpace != null) {
      insights.add(
        _DashboardInsight(
          icon: Icons.workspace_premium_outlined,
          tint: const Color(0xFFFFF3D7),
          title: '${topSpace.$1.label} made the most money',
          description: '${_formatNumber(topSpace.$2)} ${widget.currency}.',
          actionLabel: 'View spaces',
          onTap: widget.onOpenSpaces,
        ),
      );
    }
    if (topSpace != null &&
        previousTopSpace != null &&
        topSpace.$2 > previousTopSpace.$2 &&
        topSpace.$2 > 0) {
      final change = previousTopSpace.$2 <= 0
          ? null
          : ((topSpace.$2 - previousTopSpace.$2) / previousTopSpace.$2 * 100)
                .round();
      if (change != null && change > 0) {
        insights.add(
          _DashboardInsight(
            icon: Icons.trending_up,
            tint: const Color(0xFFE0F1E9),
            title: '${topSpace.$1.label} grew the most',
            description: '$change% more than ${_comparison.toLowerCase()}.',
            actionLabel: 'View spaces',
            onTap: widget.onOpenSpaces,
          ),
        );
      }
    }

    final overdueTasks =
        widget.repository.tasks
            .where(
              (task) =>
                  !task.isCompleted &&
                  task.dueAt != null &&
                  task.dueAt!.isBefore(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    for (final task in overdueTasks.take(2)) {
      insights.add(
        _DashboardInsight(
          icon: Icons.assignment_late_outlined,
          tint: const Color(0xFFFBE7E5),
          title: 'Task wasn’t done on time',
          description: task.title,
          actionLabel: 'Review tasks',
          onTap: widget.onOpenTasks,
        ),
      );
    }

    return insights.take(5).toList();
  }

  Widget _spacePerformance() {
    final spaces = widget.setup.selectedSpaces;
    final kitchenItems = widget.setup.kitchenItems
        .where(
          (item) =>
              item.name.trim().isNotEmpty ||
              item.price.trim().isNotEmpty ||
              item.quantity.trim().isNotEmpty ||
              item.costsYou.trim().isNotEmpty,
        )
        .toList();
    final isEmpty = spaces.isEmpty && kitchenItems.isEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return DashboardPanel(
          padding: const EdgeInsets.all(15),
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
                if (!compact) _spaceTableHeader(),
                for (var index = 0; index < spaces.length; index++)
                  _spaceRow(
                    spaces[index],
                    compact: compact,
                    isLast: index == spaces.length - 1 && kitchenItems.isEmpty,
                  ),
                if (kitchenItems.isNotEmpty)
                  _spaceItemRow(
                    id: 'kitchen',
                    title: 'Kitchen',
                    detail: '${kitchenItems.length} products',
                    items: [
                      for (var index = 0; index < kitchenItems.length; index++)
                        kitchenItems[index].name.trim().isEmpty
                            ? 'Product ${index + 1}'
                            : kitchenItems[index].name.trim(),
                    ],
                    used: '0 sold',
                    income: 0,
                    occupiedPercent: 0,
                    isLast: true,
                    compact: compact,
                    icon: Icons.local_cafe_outlined,
                  ),
              ],
              if (isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: widget.onOpenSpaces,
                    child: const Text('Set up spaces'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _spaceTableHeader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(flex: 4, child: Text('SPACE', style: _tableHeading)),
        Expanded(flex: 2, child: Text('HOW FULL', style: _tableHeading)),
        Expanded(flex: 2, child: Text('USED', style: _tableHeading)),
        Expanded(flex: 2, child: Text('MONEY IN', style: _tableHeading)),
        Expanded(flex: 1, child: Text('CHANGE', style: _tableHeading)),
      ],
    ),
  );

  static const _tableHeading = TextStyle(
    color: AppColors.authMuted,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: .3,
  );

  Widget _spaceRow(
    SetupSpaceType type, {
    required bool compact,
    required bool isLast,
  }) {
    final options = workspaceSpaceOptions(widget.setup)
        .where((option) => option.type == type)
        .toList();
    final visits = _visitsIn(_currentRange)
        .where((visit) => visit.spaceType == type);
    final income = visits
        .where((visit) => visit.isPaid)
        .fold<double>(0, (total, visit) => total + visit.amount);
    final activeVisits = widget.repository.activeVisits().where(
      (visit) => visit.spaceType == type,
    );
    final occupiedPercent = options.isEmpty
        ? 0
        : (activeVisits.length / options.length * 100).round().clamp(0, 100);
    final usedLabel = switch (type) {
      SetupSpaceType.sharedArea ||
      SetupSpaceType.virtualOffice => '${visits.length} visits',
      SetupSpaceType.rooms ||
      SetupSpaceType.other => '${visits.length} bookings',
      SetupSpaceType.computers => '${visits.length} sessions',
      SetupSpaceType.privateOffices => '${visits.length} rentals',
    };
    return _spaceItemRow(
      id: type.name,
      title: type.label,
      detail: spaceSummary(type, widget.setup.spaces[type]!),
      items: options.map((option) => option.name).toList(),
      used: usedLabel,
      income: income,
      occupiedPercent: occupiedPercent,
      isLast: isLast,
      compact: compact,
      icon: type == SetupSpaceType.rooms
          ? Icons.meeting_room_outlined
          : Icons.chair_outlined,
    );
  }

  Widget _spaceItemRow({
    required String id,
    required String title,
    required String detail,
    required List<String> items,
    required String used,
    required double income,
    required int occupiedPercent,
    required bool isLast,
    required bool compact,
    required IconData icon,
  }) {
    final expanded = _expandedSpaces.contains(id);
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
                _spaceName(id, title, detail, items, icon, expanded),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _OccupancyCell(value: occupiedPercent)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(used, style: AppTextStyles.authHelper),
                    ),
                    Expanded(
                      child: Text(
                        '${_formatNumber(income)} ${widget.currency}',
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
                  child: _spaceName(id, title, detail, items, icon, expanded),
                ),
                Expanded(
                  flex: 2,
                  child: _OccupancyCell(value: occupiedPercent),
                ),
                Expanded(
                  flex: 2,
                  child: Text(used, style: AppTextStyles.authHelper),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${_formatNumber(income)} ${widget.currency}',
                    style: AppTextStyles.authHelper,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text('—', style: AppTextStyles.authHelper),
                ),
              ],
            ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 7, right: 3),
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

  Widget _spaceName(
    String id,
    String title,
    String detail,
    List<String> items,
    IconData icon,
    bool expanded,
  ) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.authMuted),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.authInk,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.authHelper,
            ),
          ],
        ),
      ),
      if (items.isNotEmpty)
        TextButton(
          key: ValueKey('show-space-details-$id'),
          onPressed: () => setState(() {
            if (expanded) {
              _expandedSpaces.remove(id);
            } else {
              _expandedSpaces.add(id);
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

  double _moneyIn(_DashboardDateRange range) {
    return widget.repository.moneyEntries
        .where(
          (entry) =>
              entry.kind == MoneyEntryKind.income &&
              entry.currency == widget.currency &&
              range.contains(entry.occurredAt),
        )
        .fold<double>(0, (total, entry) => total + entry.amount);
  }

  int _visitCount(_DashboardDateRange range) => _visitsIn(range).length;

  List<Visit> _visitsIn(_DashboardDateRange range) => widget.repository.visits
      .where((visit) => range.contains(visit.checkedInAt))
      .toList();

  int _newCustomerCount(_DashboardDateRange range) =>
      widget.repository.customers.where((customer) {
        final createdAt = customer.createdAt;
        return createdAt != null && range.contains(createdAt);
      }).length;

  double _occupancy(_DashboardDateRange range) {
    final capacity = workspaceSpaceOptions(widget.setup).length;
    if (capacity == 0) return 0;
    final now = DateTime.now();
    final events = <(DateTime, int)>[];
    for (final visit in widget.repository.visits) {
      final checkedOutAt = visit.checkedOutAt ?? now;
      final start = visit.checkedInAt.isBefore(range.start)
          ? range.start
          : visit.checkedInAt;
      final end = checkedOutAt.isAfter(range.endExclusive)
          ? range.endExclusive
          : checkedOutAt;
      if (!start.isBefore(end)) continue;
      events
        ..add((start, 1))
        ..add((end, -1));
    }
    events.sort((left, right) {
      final byTime = left.$1.compareTo(right.$1);
      return byTime != 0 ? byTime : left.$2.compareTo(right.$2);
    });
    var active = 0;
    var peak = 0;
    for (final event in events) {
      active += event.$2;
      if (active > peak) peak = active;
    }
    return (peak / capacity * 100).clamp(0, 100).toDouble();
  }

  (SetupSpaceType, double)? _topEarningSpace(_DashboardDateRange range) {
    final totals = <SetupSpaceType, double>{};
    for (final visit in _visitsIn(range)) {
      if (!visit.isPaid || visit.spaceType == null) continue;
      totals.update(
        visit.spaceType!,
        (value) => value + visit.amount,
        ifAbsent: () => visit.amount,
      );
    }
    if (totals.isEmpty) return null;
    final entry = totals.entries.reduce(
      (best, candidate) => candidate.value > best.value ? candidate : best,
    );
    return (entry.key, entry.value);
  }

  List<_ChartBucket> _chartBuckets(
    _DashboardDateRange range,
    _DashboardDateRange? comparisonRange,
  ) {
    final dayCount = math.max(1, range.duration.inDays);
    final count = math.min(8, dayCount);
    return List.generate(count, (index) {
      final bucketStart = range.start.add(
        Duration(microseconds: range.duration.inMicroseconds * index ~/ count),
      );
      final bucketEnd = range.start.add(
        Duration(
          microseconds: range.duration.inMicroseconds * (index + 1) ~/ count,
        ),
      );
      final previousStart = comparisonRange?.start.add(
        Duration(
          microseconds:
              comparisonRange.duration.inMicroseconds * index ~/ count,
        ),
      );
      final previousEnd = comparisonRange?.start.add(
        Duration(
          microseconds:
              comparisonRange.duration.inMicroseconds * (index + 1) ~/ count,
        ),
      );
      return _ChartBucket(
        label: _bucketLabel(bucketStart),
        current: _chartValue(bucketStart, bucketEnd),
        previous: previousStart == null || previousEnd == null
            ? null
            : _chartValue(previousStart, previousEnd),
      );
    });
  }

  double _chartValue(DateTime start, DateTime end) {
    if (_chartMetric == _DashboardChartMetric.money) {
      return widget.repository.moneyEntries
          .where(
            (entry) =>
                entry.kind == MoneyEntryKind.income &&
                entry.currency == widget.currency &&
                !entry.occurredAt.isBefore(start) &&
                entry.occurredAt.isBefore(end),
          )
          .fold<double>(0, (total, entry) => total + entry.amount);
    }
    return widget.repository.visits
        .where(
          (visit) =>
              !visit.checkedInAt.isBefore(start) &&
              visit.checkedInAt.isBefore(end),
        )
        .length
        .toDouble();
  }

  String _bucketLabel(DateTime value) {
    if (_currentRange.duration.inDays > 45) return _monthShort(value.month);
    if (_currentRange.duration.inDays <= 7) {
      return const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][value.weekday - 1];
    }
    return value.day.toString();
  }

  Future<void> _showChartNumbers(
    List<_ChartBucket> buckets,
    _DashboardDateRange? comparisonRange,
  ) async {
    final isMoney = _chartMetric == _DashboardChartMetric.money;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard numbers'),
        content: SingleChildScrollView(
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Date')),
              DataColumn(label: Text(_currentRange.label)),
              if (comparisonRange != null)
                DataColumn(label: Text(comparisonRange.label)),
            ],
            rows: [
              for (final bucket in buckets)
                DataRow(
                  cells: [
                    DataCell(Text(bucket.label)),
                    DataCell(Text(_chartDisplayValue(bucket.current, isMoney))),
                    if (comparisonRange != null)
                      DataCell(
                        Text(_chartDisplayValue(bucket.previous ?? 0, isMoney)),
                      ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _chartDisplayValue(double value, bool isMoney) => isMoney
      ? '${_formatNumber(value)} ${widget.currency}'
      : _formatNumber(value);
}

class _DashboardFilterButton extends StatelessWidget {
  const _DashboardFilterButton({
    super.key,
    required this.label,
    required this.value,
    required this.rangeLabel,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String value;
  final String rangeLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('dashboard-period-filter-button'),
    onTap: onPressed,
    borderRadius: BorderRadius.circular(AppRadii.control),
    child: Container(
      constraints: const BoxConstraints(minWidth: 165),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.authMuted),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.authHelper),
              Text(
                '$value  $rangeLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.authInk,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 5),
          const Icon(Icons.expand_more, size: 15),
        ],
      ),
    ),
  );
}

class _SelectedDashboardRange {
  const _SelectedDashboardRange({required this.label, required this.range});

  final String label;
  final _DashboardDateRange range;
}

class _DashboardRangePickerDialog extends StatefulWidget {
  const _DashboardRangePickerDialog({
    required this.initialRange,
    required this.initialPreset,
  });

  final _DashboardDateRange initialRange;
  final String initialPreset;

  @override
  State<_DashboardRangePickerDialog> createState() =>
      _DashboardRangePickerDialogState();
}

class _DashboardRangePickerDialogState
    extends State<_DashboardRangePickerDialog> {
  static const _presets = [
    'Today',
    'Last 7 days',
    'This month',
    'Last month',
    'Last 3 months',
    'Last 6 months',
    'This year',
    'Last 12 months',
  ];

  late _DashboardDateRange _range = widget.initialRange;
  late DateTime _visibleMonth = DateTime(
    widget.initialRange.start.year,
    widget.initialRange.start.month,
  );
  late String _selectedPreset = widget.initialPreset;
  DateTime? _monthAnchor;

  DateTime get _inclusiveEnd =>
      _range.endExclusive.subtract(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    final width = math.min(490.0, MediaQuery.sizeOf(context).width - 40);
    return Dialog(
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 470;
              final monthPicker = _monthPicker(compact: compact);
              return SingleChildScrollView(
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _quickRanges(compact: true),
                          const Divider(height: 20),
                          monthPicker,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 142, child: _quickRanges()),
                          const SizedBox(width: 14),
                          const SizedBox(
                            height: 325,
                            child: VerticalDivider(width: 1),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: monthPicker),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _quickRanges({bool compact = false}) {
    final now = DateTime.now();
    if (compact) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final preset in _presets)
            ActionChip(
              key: ValueKey('dashboard-preset-$preset'),
              label: Text(preset, style: const TextStyle(fontSize: 10)),
              backgroundColor: _selectedPreset == preset
                  ? AppColors.homePaleGreen
                  : AppColors.white,
              onPressed: () => _selectPreset(preset, now),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final preset in _presets)
          InkWell(
            key: ValueKey('dashboard-preset-$preset'),
            onTap: () => _selectPreset(preset, now),
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedPreset == preset
                    ? AppColors.homePaleGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                children: [
                  if (_selectedPreset == preset) ...[
                    const Icon(
                      Icons.check,
                      size: 13,
                      color: AppColors.authGreen,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _DashboardDateRange.forPreset(preset, now).label,
                          style: AppTextStyles.authHelper,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _monthPicker({required bool compact}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Pick months',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Previous year',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(
              () => _visibleMonth = DateTime(_visibleMonth.year - 1),
            ),
            icon: const Icon(Icons.chevron_left, size: 18),
          ),
          Text(
            '${_visibleMonth.year}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Next year',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(
              () => _visibleMonth = DateTime(_visibleMonth.year + 1),
            ),
            icon: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
      GridView.builder(
        key: const ValueKey('dashboard-month-grid'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: compact ? 3 : 4,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: compact ? 2.4 : 2.2,
        ),
        itemBuilder: (context, index) {
          final month = DateTime(_visibleMonth.year, index + 1);
          final selected = _containsMonth(_range, month);
          return OutlinedButton(
            key: ValueKey('dashboard-month-${month.year}-${month.month}'),
            onPressed: () => _selectMonth(month),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: selected ? AppColors.authGreen : AppColors.white,
              foregroundColor: selected ? AppColors.white : AppColors.authInk,
              side: BorderSide(
                color: selected ? AppColors.authGreen : AppColors.authBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(_monthShort(month.month)),
          );
        },
      ),
      const SizedBox(height: 8),
      const Text(
        'Tap one month, or tap two to get everything between them.',
        style: AppTextStyles.authHelper,
      ),
      const SizedBox(height: 11),
      const Text(
        'Or your own dates',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          Expanded(child: _datePickerButton('From', _range.start)),
          const SizedBox(width: 7),
          Expanded(child: _datePickerButton('To', _inclusiveEnd)),
        ],
      ),
      const SizedBox(height: 11),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          key: const ValueKey('dashboard-range-show'),
          onPressed: _applyRange,
          child: const Text('Show'),
        ),
      ),
    ],
  );

  Widget _datePickerButton(String label, DateTime date) => OutlinedButton(
    onPressed: () => _pickDate(label),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      alignment: Alignment.centerLeft,
      side: const BorderSide(color: AppColors.authBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.authHelper),
        Text(
          _dateInputLabel(date),
          style: const TextStyle(fontSize: 10, color: AppColors.authInk),
        ),
      ],
    ),
  );

  Future<void> _pickDate(String field) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: field == 'From' ? _range.start : _inclusiveEnd,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    var start = _range.start;
    var end = _inclusiveEnd;
    if (field == 'From') {
      start = selected;
      if (start.isAfter(end)) end = start;
    } else {
      end = selected;
      if (end.isBefore(start)) start = end;
    }
    setState(() {
      _range = _DashboardDateRange(
        start: DateTime(start.year, start.month, start.day),
        endExclusive: DateTime(end.year, end.month, end.day + 1),
      );
      _selectedPreset = 'Custom dates';
    });
  }

  void _selectPreset(String preset, DateTime now) {
    Navigator.pop(
      context,
      _SelectedDashboardRange(
        label: preset,
        range: _DashboardDateRange.forPreset(preset, now),
      ),
    );
  }

  void _selectMonth(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month);
    final anchor = _monthAnchor;
    final first = anchor == null || firstOfMonth.isBefore(anchor)
        ? firstOfMonth
        : anchor;
    final last = anchor == null || firstOfMonth.isAfter(anchor)
        ? firstOfMonth
        : anchor;
    setState(() {
      _monthAnchor = firstOfMonth;
      _selectedPreset = 'Custom dates';
      _range = _DashboardDateRange(
        start: first,
        endExclusive: DateTime(last.year, last.month + 1),
      );
    });
  }

  bool _containsMonth(_DashboardDateRange range, DateTime month) {
    final start = DateTime(range.start.year, range.start.month);
    final end = DateTime(
      range.endExclusive.subtract(const Duration(days: 1)).year,
      range.endExclusive.subtract(const Duration(days: 1)).month,
    );
    final current = DateTime(month.year, month.month);
    return !current.isBefore(start) && !current.isAfter(end);
  }

  void _applyRange() {
    Navigator.pop(
      context,
      _SelectedDashboardRange(label: _selectedPreset, range: _range),
    );
  }
}

class _DashboardDateRange {
  const _DashboardDateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  Duration get duration => endExclusive.difference(start);

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(endExclusive);

  String get label {
    final lastDay = endExclusive.subtract(const Duration(days: 1));
    final year = start.year == DateTime.now().year ? '' : ', ${start.year}';
    if (start.year == lastDay.year && start.month == lastDay.month) {
      return '${_monthShort(start.month)} ${start.day}–${lastDay.day}$year';
    }
    return '${_monthShort(start.month)} ${start.day}–'
        '${_monthShort(lastDay.month)} ${lastDay.day}'
        '${start.year == lastDay.year ? year : ', ${start.year}–${lastDay.year}'}';
  }

  static _DashboardDateRange forPreset(String period, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisMonth = DateTime(today.year, today.month);
    final start = switch (period) {
      'Today' => today,
      'Last 7 days' => today.subtract(const Duration(days: 6)),
      'Last month' => DateTime(today.year, today.month - 1),
      'Last 3 months' => DateTime(today.year, today.month - 3),
      'Last 6 months' => DateTime(today.year, today.month - 6),
      'Last 12 months' => DateTime(today.year, today.month - 12),
      'This year' => DateTime(today.year),
      _ => thisMonth,
    };
    final end = switch (period) {
      'Last month' ||
      'Last 3 months' ||
      'Last 6 months' ||
      'Last 12 months' => thisMonth,
      _ => tomorrow,
    };
    return _DashboardDateRange(start: start, endExclusive: end);
  }

  static _DashboardDateRange? comparison(
    _DashboardDateRange current,
    String comparison,
  ) {
    if (comparison == 'Nothing') return null;
    if (comparison == 'Previous period') {
      return _DashboardDateRange(
        start: current.start.subtract(current.duration),
        endExclusive: current.endExclusive.subtract(current.duration),
      );
    }
    final start = _sameDayLastYear(current.start);
    final endLastIncludedDay = _sameDayLastYear(
      current.endExclusive.subtract(const Duration(days: 1)),
    );
    return _DashboardDateRange(
      start: start,
      endExclusive: endLastIncludedDay.add(const Duration(days: 1)),
    );
  }

  static DateTime _sameDayLastYear(DateTime value) {
    final year = value.year - 1;
    final lastDay = DateTime(year, value.month + 1, 0).day;
    return DateTime(year, value.month, math.min(value.day, lastDay));
  }
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.keyName,
    required this.label,
    required this.detail,
    required this.value,
    required this.previousValue,
    required this.format,
    required this.icon,
  });

  final String keyName;
  final String label;
  final String detail;
  final double value;
  final double? previousValue;
  final String Function(double) format;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
    required this.comparisonName,
    required this.comparisonLabel,
  });

  final _DashboardMetric metric;
  final String comparisonName;
  final String? comparisonLabel;

  @override
  Widget build(BuildContext context) {
    final previous = metric.previousValue;
    final delta = previous == null ? null : metric.value - previous;
    final percent = previous == null || previous == 0
        ? null
        : (delta! / previous * 100).round();
    final hasNoChange = delta == 0;
    final positive = delta != null && delta > 0;
    final changeLabel = comparisonLabel == null
        ? 'Choose a comparison period'
        : hasNoChange
        ? 'No change from $comparisonName'
        : percent == null
        ? (positive ? 'New in this period' : 'No activity')
        : '${percent.abs()}% ${positive ? 'more' : 'less'} than ${comparisonName.toLowerCase()}';
    final changeColor = delta == null || hasNoChange
        ? AppColors.authMuted
        : positive
        ? AppColors.authGreen
        : AppColors.error;

    return Container(
      key: ValueKey(metric.keyName),
      constraints: const BoxConstraints(minHeight: 125),
      padding: const EdgeInsets.all(12),
      decoration: dashboardCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.homePaleGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(metric.icon, size: 14, color: AppColors.authGreen),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.authInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(metric.detail, style: AppTextStyles.authHelper),
                  ],
                ),
              ),
              Icon(Icons.help_outline, size: 13, color: AppColors.authMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.format(metric.value),
            style: const TextStyle(
              color: AppColors.authInk,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              changeLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: changeColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (comparisonLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              '$comparisonLabel: ${metric.format(previous ?? 0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.authHelper,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartBucket {
  const _ChartBucket({
    required this.label,
    required this.current,
    required this.previous,
  });

  final String label;
  final double current;
  final double? previous;
}

class _ComparisonChartPainter extends CustomPainter {
  const _ComparisonChartPainter({
    required this.values,
    required this.isMoney,
    required this.currency,
  });

  final List<_ChartBucket> values;
  final bool isMoney;
  final String currency;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0;
    const right = 6.0;
    const top = 14.0;
    const bottom = 16.0;
    final chartWidth = math.max(1, size.width - left - right);
    final chartHeight = math.max(1, size.height - top - bottom);
    final maxValue = values.fold<double>(0, (maximum, bucket) {
      final previous = bucket.previous ?? 0;
      return math.max(maximum, math.max(bucket.current, previous));
    });
    final scaleMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final gridPaint = Paint()
      ..color = AppColors.authBorder
      ..strokeWidth = 1;

    for (var index = 0; index < 3; index++) {
      final ratio = (2 - index) / 2;
      final y = top + chartHeight * index / 2;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final label = TextPainter(
        text: TextSpan(
          text: _axisLabel(scaleMax * ratio),
          style: const TextStyle(color: AppColors.authMuted, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: left - 6);
      label.paint(canvas, Offset(left - label.width - 6, y - label.height / 2));
    }

    final currentPaint = Paint()
      ..color = AppColors.authGreen
      ..style = PaintingStyle.fill;
    final previousPaint = Paint()
      ..color = const Color(0xFFC5CBC7)
      ..style = PaintingStyle.fill;
    final slotWidth = chartWidth / math.max(1, values.length);
    final barWidth = math.min(13.0, slotWidth * .28);
    for (var index = 0; index < values.length; index++) {
      final bucket = values[index];
      final center = left + slotWidth * (index + .5);
      final currentHeight = chartHeight * bucket.current / scaleMax;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center + (bucket.previous == null ? -barWidth / 2 : 1),
            top + chartHeight - currentHeight,
            barWidth,
            currentHeight,
          ),
          const Radius.circular(2),
        ),
        currentPaint,
      );
      if (bucket.previous != null) {
        final previousHeight = chartHeight * bucket.previous! / scaleMax;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              center - barWidth - 1,
              top + chartHeight - previousHeight,
              barWidth,
              previousHeight,
            ),
            const Radius.circular(2),
          ),
          previousPaint,
        );
      }
    }
  }

  String _axisLabel(double value) =>
      isMoney ? _compactNumber(value) : _formatNumber(value);

  @override
  bool shouldRepaint(covariant _ComparisonChartPainter oldDelegate) {
    if (isMoney != oldDelegate.isMoney ||
        currency != oldDelegate.currency ||
        values.length != oldDelegate.values.length) {
      return true;
    }
    for (var index = 0; index < values.length; index++) {
      final old = oldDelegate.values[index];
      final current = values[index];
      if (old.label != current.label ||
          old.current != current.current ||
          old.previous != current.previous) {
        return true;
      }
    }
    return false;
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: AppTextStyles.authHelper),
    ],
  );
}

class _DashboardInsight {
  const _DashboardInsight({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final _DashboardInsight insight;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: insight.tint,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(insight.icon, size: 14, color: AppColors.authInk),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insight.title,
              style: const TextStyle(
                color: AppColors.authInk,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(insight.description, style: AppTextStyles.authHelper),
            TextButton(
              onPressed: insight.onTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 25),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                insight.actionLabel,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _OccupancyCell extends StatelessWidget {
  const _OccupancyCell({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$value% full', style: AppTextStyles.authHelper),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value / 100,
          minHeight: 4,
          backgroundColor: AppColors.authBorder,
          color: AppColors.authGreen,
        ),
      ),
    ],
  );
}

String _monthShort(int month) => const [
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
][month - 1];

String _formatNumber(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

String _dateInputLabel(DateTime value) =>
    '${value.month.toString().padLeft(2, '0')}/'
    '${value.day.toString().padLeft(2, '0')}/${value.year}';

String _compactNumber(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}m';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return _formatNumber(value);
}
