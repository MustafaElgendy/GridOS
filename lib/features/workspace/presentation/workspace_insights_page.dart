import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';

import 'workspace_page_utils.dart';

class WorkspaceInsightsPage extends StatefulWidget {
  const WorkspaceInsightsPage({
    super.key,
    required this.repository,
    required this.currency,
    required this.onOpenSpaces,
    required this.onOpenQuestions,
  });

  final WorkspaceRepository repository;
  final String currency;
  final VoidCallback onOpenSpaces;
  final VoidCallback onOpenQuestions;

  @override
  State<WorkspaceInsightsPage> createState() => _WorkspaceInsightsPageState();
}

class _WorkspaceInsightsPageState extends State<WorkspaceInsightsPage> {
  String _period = 'This month';

  DateTime? get _fromDate {
    final now = DateTime.now();
    return switch (_period) {
      'Today' => DateTime(now.year, now.month, now.day),
      'This week' => DateTime(now.year, now.month, now.day - now.weekday + 1),
      'This year' => DateTime(now.year),
      'All time' => null,
      _ => DateTime(now.year, now.month),
    };
  }

  @override
  Widget build(BuildContext context) {
    final visits = widget.repository.visits.where((visit) {
      return _fromDate == null || !visit.checkedInAt.isBefore(_fromDate!);
    }).toList();
    final activeVisits = visits.where((visit) => visit.isActive).length;
    final totals = widget.repository.moneyTotals(from: _fromDate)[
        widget.currency] ??
        MoneyTotals(income: 0, expenses: 0, currency: widget.currency);
    final bySpace = <SetupSpaceType, int>{};
    for (final visit in visits) {
      final type = visit.spaceType;
      if (type != null) bySpace[type] = (bySpace[type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Insights',
          'Understand what is happening in your space.',
          trailing: PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (value) => setState(() => _period = value),
            itemBuilder: (context) => [
              for (final period in [
                'Today',
                'This week',
                'This month',
                'This year',
                'All time',
              ])
                PopupMenuItem(value: period, child: Text(period)),
            ],
            child: Chip(
              avatar: const Icon(Icons.date_range, size: 17),
              label: Text(_period),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (visits.isEmpty && totals.income == 0 && totals.expenses == 0)
          DashboardEmptyState(
            icon: Icons.insights_outlined,
            title: 'Insights will grow with your workspace',
            description:
                'Once you have visits and sales, useful patterns will show up here.',
            actionLabel: 'View your spaces',
            onPressed: widget.onOpenSpaces,
          )
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 540
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InsightMetric(
                    width: width,
                    label: 'Visits',
                    value: visits.length.toString(),
                    icon: Icons.meeting_room_outlined,
                  ),
                  _InsightMetric(
                    width: width,
                    label: 'On site now',
                    value: activeVisits.toString(),
                    icon: Icons.people_outline,
                  ),
                  _InsightMetric(
                    width: width,
                    label: 'Money in',
                    value: formatWorkspaceAmount(totals.income, widget.currency),
                    icon: Icons.south_west,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'What stands out',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  visits.isEmpty
                      ? 'Nothing to point out yet.'
                      : '${visits.length} visit${visits.length == 1 ? '' : 's'} recorded ${_period.toLowerCase()}.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How each space is doing',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (bySpace.isEmpty)
                  const Text('No visits by space yet.')
                else
                  for (final entry in bySpace.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key.label)),
                          Text('${entry.value} visit${entry.value == 1 ? '' : 's'}'),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer questions',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.repository.questions.length} question(s) configured. '
                  'Answers will appear as customers respond at check-in or check-out.',
                ),
                TextButton(
                  onPressed: widget.onOpenQuestions,
                  child: const Text('Manage questions'),
                ),
              ],
            ),
          ),
          if (widget.repository.questions.isNotEmpty) ...[
            const SizedBox(height: 12),
            DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Question answers',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 7),
                  for (final question in widget.repository.questions) ...[
                    Text(
                      question.prompt,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    ..._answerSummary(question.id),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<Widget> _answerSummary(String questionId) {
    final responses = widget.repository.responsesForQuestion(questionId);
    if (responses.isEmpty) return [const Text('No answers yet.')];
    final counts = <String, int>{};
    for (final response in responses) {
      counts[response.answer] = (counts[response.answer] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Expanded(child: Text(entry.key)),
              Text('${entry.value}'),
            ],
          ),
        ),
    ];
  }
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}
