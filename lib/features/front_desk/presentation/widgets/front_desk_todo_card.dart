import 'package:flutter/material.dart';

import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskTodoCard extends StatelessWidget {
  const FrontDeskTodoCard({
    super.key,
    required this.tasks,
    required this.onToggleTask,
    required this.onAddTask,
  });

  final List<WorkspaceTask> tasks;
  final ValueChanged<WorkspaceTask> onToggleTask;
  final VoidCallback onAddTask;

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.authBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'To do',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.authInk,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$completed of $total done',
                    style: const TextStyle(fontSize: 10, color: AppColors.authMuted),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onAddTask,
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.authGreen),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: const Color(0xFFE8ECE9),
              color: AppColors.authGreen,
            ),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'All caught up! No tasks left.',
                  style: TextStyle(color: AppColors.authMuted, fontSize: 11),
                ),
              ),
            )
          else
            for (final task in tasks) ...[
              _taskRow(task),
              const Divider(height: 12, color: AppColors.authBorder),
            ],
          const SizedBox(height: 6),
          // Assistant / search pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.authBackground,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.authBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 14, color: AppColors.authMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ask anything... free rooms, bookings, ...',
                    style: TextStyle(fontSize: 9, color: AppColors.authMuted),
                  ),
                ),
                Icon(Icons.mic_none, size: 14, color: AppColors.authGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskRow(WorkspaceTask task) {
    final desc = task.description;
    final subtitle = task.isCompleted
        ? 'Done'
        : ((desc == null || desc.isEmpty) ? 'Every day' : desc);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggleTask(task),
            activeColor: AppColors.authGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted
                      ? AppColors.authMuted
                      : AppColors.authInk,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: AppColors.authMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
