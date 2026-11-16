import 'package:flutter/material.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';

import 'workspace_page_utils.dart';

enum _TaskView { today, upcoming, repeats, completed, all }

class WorkspaceTasksPage extends StatefulWidget {
  const WorkspaceTasksPage({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.assignees,
  });

  final WorkspaceRepository repository;
  final VoidCallback onChanged;
  final List<String> assignees;

  @override
  State<WorkspaceTasksPage> createState() => _WorkspaceTasksPageState();
}

class _WorkspaceTasksPageState extends State<WorkspaceTasksPage> {
  _TaskView _view = _TaskView.today;

  List<WorkspaceTask> get _tasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return widget.repository.tasks.where((task) {
      switch (_view) {
        case _TaskView.today:
          return !task.isCompleted &&
              (task.dueAt == null ||
                  task.dueAt!.isBefore(tomorrow) ||
                  task.dueAt!.isBefore(today));
        case _TaskView.upcoming:
          return !task.isCompleted &&
              task.dueAt != null &&
              !task.dueAt!.isBefore(tomorrow);
        case _TaskView.repeats:
          return task.isRecurring && !task.isCompleted;
        case _TaskView.completed:
          return task.isCompleted;
        case _TaskView.all:
          return !task.isCompleted;
      }
    }).toList()..sort(
      (a, b) =>
          (a.dueAt ?? DateTime(3000)).compareTo(b.dueAt ?? DateTime(3000)),
    );
  }

  Future<void> _addTask() async {
    final draft = await showDialog<WorkspaceTask>(
      context: context,
      builder: (context) => _TaskFormDialog(assignees: widget.assignees),
    );
    if (draft == null) return;
    widget.repository.createTask(
      WorkspaceTask(
        id: newWorkspaceId('task'),
        title: draft.title,
        description: draft.description,
        assignedToId: draft.assignedToId,
        dueAt: draft.dueAt,
        repeat: draft.repeat,
      ),
    );
    _changed();
  }

  Future<void> _editTask(WorkspaceTask task) async {
    final draft = await showDialog<WorkspaceTask>(
      context: context,
      builder: (context) =>
          _TaskFormDialog(task: task, assignees: widget.assignees),
    );
    if (draft == null) return;
    widget.repository.updateTask(
      WorkspaceTask(
        id: task.id,
        title: draft.title,
        description: draft.description,
        assignedToId: draft.assignedToId,
        dueAt: draft.dueAt,
        repeat: draft.repeat,
        completedAt: task.completedAt,
      ),
    );
    _changed();
  }

  Future<void> _deleteTask(WorkspaceTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove “${task.title}” from the task list?'),
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
      widget.repository.deleteTask(task.id);
      _changed();
    }
  }

  void _toggleComplete(WorkspaceTask task, bool complete) {
    widget.repository.updateTask(
      WorkspaceTask(
        id: task.id,
        title: task.title,
        description: task.description,
        assignedToId: task.assignedToId,
        dueAt: task.dueAt,
        repeat: task.repeat,
        completedAt: complete ? DateTime.now() : null,
      ),
    );
    _changed();
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  String _taskMetadata(WorkspaceTask task) {
    final parts = [
      if (task.assignedToId?.isNotEmpty == true) task.assignedToId!,
      if (task.dueAt != null)
        '${formatWorkspaceDate(task.dueAt!)} · ${formatWorkspaceTime(task.dueAt!)}',
      if (task.isRecurring) 'Repeats ${task.repeat.name}',
    ];
    return parts.isEmpty ? 'No assignee or due date' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Tasks',
          'Keep track of the work that keeps your space running.',
          trailing: widget.repository.tasks.isEmpty
              ? null
              : FilledButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Create task'),
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final view in _TaskView.values)
              ChoiceChip(
                label: Text(_taskViewLabel(view)),
                selected: _view == view,
                onSelected: (_) => setState(() => _view = view),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          DashboardEmptyState(
            icon: Icons.checklist_outlined,
            title: widget.repository.tasks.isEmpty
                ? 'No tasks yet'
                : 'No ${_taskViewLabel(_view).toLowerCase()} tasks',
            description: widget.repository.tasks.isEmpty
                ? 'Create a task to keep your team on the same page.'
                : 'Create a task or choose another view.',
            actionLabel: 'Create task',
            onPressed: _addTask,
          )
        else
          for (final task in tasks) ...[
            const SizedBox(height: 8),
            DashboardPanel(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) => _toggleComplete(task, value ?? false),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _editTask(task),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (task.description?.isNotEmpty == true)
                              Text(
                                task.description!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            const SizedBox(height: 3),
                            Text(
                                  _taskMetadata(task),
                                  style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit task',
                    onPressed: () => _editTask(task),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete task',
                    onPressed: () => _deleteTask(task),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  String _taskViewLabel(_TaskView view) => switch (view) {
    _TaskView.today => 'Today',
    _TaskView.upcoming => 'Upcoming',
    _TaskView.repeats => 'Repeats',
    _TaskView.completed => 'Completed',
    _TaskView.all => 'All open',
  };
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({required this.assignees, this.task});

  final List<String> assignees;
  final WorkspaceTask? task;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _description = TextEditingController(
    text: widget.task?.description,
  );
  late String _assignee = widget.task?.assignedToId ?? '';
  late TaskRepeat _repeat = widget.task?.repeat ?? TaskRepeat.none;
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    _dueAt = widget.task?.dueAt;
    if (_assignee.isNotEmpty && !widget.assignees.contains(_assignee)) {
      _assignee = '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      WorkspaceTask(
        id: widget.task?.id ?? '',
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        assignedToId: _assignee.isEmpty ? null : _assignee,
        dueAt: _dueAt,
        repeat: _repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignees = ['', ...widget.assignees.toSet()];
    return AlertDialog(
      title: Text(widget.task == null ? 'Create task' : 'Edit task'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('workspace-task-title'),
                  controller: _title,
                  autofocus: true,
                  decoration: workspaceInputDecoration('Task'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: workspaceInputDecoration('Details (optional)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _assignee,
                  decoration: workspaceInputDecoration('Assigned to'),
                  items: [
                    for (final name in assignees)
                      DropdownMenuItem(
                        value: name,
                        child: Text(name.isEmpty ? 'No one yet' : name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _assignee = value ?? ''),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskRepeat>(
                  isExpanded: true,
                  initialValue: _repeat,
                  decoration: workspaceInputDecoration('Repeat'),
                  items: [
                    for (final repeat in TaskRepeat.values)
                      DropdownMenuItem(
                        value: repeat,
                        child: Text(
                          repeat == TaskRepeat.none
                              ? 'Does not repeat'
                              : repeat.name,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _repeat = value ?? TaskRepeat.none),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dueAt == null
                            ? 'No due date'
                            : '${formatWorkspaceDate(_dueAt!)} · ${formatWorkspaceTime(_dueAt!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDueDate,
                      child: Text(_dueAt == null ? 'Set date' : 'Change'),
                    ),
                    if (_dueAt != null)
                      IconButton(
                        tooltip: 'Clear due date',
                        onPressed: () => setState(() => _dueAt = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
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
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
