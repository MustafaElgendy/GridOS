import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';

import 'workspace_page_utils.dart';

enum _SettingsSection { workspace, questions, cash, communications }

class WorkspaceSettingsPage extends StatefulWidget {
  const WorkspaceSettingsPage({
    super.key,
    required this.setup,
    required this.repository,
    required this.onChanged,
  });

  final StartupSetup setup;
  final WorkspaceRepository repository;
  final VoidCallback onChanged;

  @override
  State<WorkspaceSettingsPage> createState() => _WorkspaceSettingsPageState();
}

class _WorkspaceSettingsPageState extends State<WorkspaceSettingsPage> {
  _SettingsSection _section = _SettingsSection.workspace;
  CustomerQuestionTiming _questionTimingFilter = CustomerQuestionTiming.checkIn;
  late final _workspaceName = TextEditingController(
    text: widget.setup.workspaceName,
  );
  late final _ownerName = TextEditingController(text: widget.setup.ownerName);
  late final _phone = TextEditingController(text: widget.setup.phone);
  late final _area = TextEditingController(text: widget.setup.area);
  late final _whatsapp = TextEditingController(
    text: widget.repository.settings.whatsappNumber,
  );
  late final _whatsappMessage = TextEditingController(
    text: widget.repository.settings.whatsappMessage,
  );
  late final _invoicePrefix = TextEditingController(
    text: widget.repository.settings.invoicePrefix,
  );
  late final _invoiceFooter = TextEditingController(
    text: widget.repository.settings.invoiceFooter,
  );
  late SetupCountry _country = widget.setup.country;

  @override
  void dispose() {
    for (final controller in [
      _workspaceName,
      _ownerName,
      _phone,
      _area,
      _whatsapp,
      _whatsappMessage,
      _invoicePrefix,
      _invoiceFooter,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveWorkspace() {
    if (_workspaceName.text.trim().isEmpty || _ownerName.text.trim().isEmpty) {
      _showMessage('Workspace and owner names are required.');
      return;
    }
    widget.setup.workspaceName = _workspaceName.text.trim();
    widget.setup.ownerName = _ownerName.text.trim();
    widget.setup.phone = _phone.text.trim();
    widget.setup.area = _area.text.trim();
    widget.setup.country = _country;
    widget.onChanged();
    _showMessage('Workspace details saved.');
  }

  void _saveCommunications() {
    final old = widget.repository.settings;
    widget.repository.updateSettings(
      WorkspaceSettings(
        cashDrawerEnabled: old.cashDrawerEnabled,
        askOpeningCash: old.askOpeningCash,
        requireShiftReconciliation: old.requireShiftReconciliation,
        whatsappNumber: _whatsapp.text.trim(),
        whatsappMessage: _whatsappMessage.text.trim(),
        invoicePrefix: _invoicePrefix.text.trim(),
        invoiceFooter: _invoiceFooter.text.trim(),
      ),
    );
    widget.onChanged();
    _showMessage('WhatsApp and invoice settings saved.');
  }

  Future<void> _addQuestion() async {
    final draft = await showDialog<CustomerQuestion>(
      context: context,
      builder: (context) =>
          _QuestionDialog(initialTiming: _questionTimingFilter),
    );
    if (draft == null) return;
    widget.repository.createQuestion(
      CustomerQuestion(
        id: newWorkspaceId('question'),
        prompt: draft.prompt,
        type: draft.type,
        options: draft.options,
        timing: draft.timing,
        required: draft.required,
        order: widget.repository.questions.length,
      ),
    );
    _refresh();
  }

  Future<void> _editQuestion(CustomerQuestion question) async {
    final draft = await showDialog<CustomerQuestion>(
      context: context,
      builder: (context) => _QuestionDialog(question: question),
    );
    if (draft == null) return;
    widget.repository.updateQuestion(
      CustomerQuestion(
        id: question.id,
        prompt: draft.prompt,
        type: draft.type,
        options: draft.options,
        timing: draft.timing,
        required: draft.required,
        order: question.order,
      ),
    );
    _refresh();
  }

  Future<void> _deleteQuestion(CustomerQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete question?'),
        content: Text('Remove “${question.prompt}”?'),
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
      widget.repository.deleteQuestion(question.id);
      _refresh();
    }
  }

  void _duplicateQuestion(CustomerQuestion question) {
    widget.repository.createQuestion(
      CustomerQuestion(
        id: newWorkspaceId('question'),
        prompt: '${question.prompt} (copy)',
        type: question.type,
        options: question.options,
        timing: question.timing,
        required: question.required,
        order: widget.repository.questions.length,
      ),
    );
    _refresh();
  }

  void _moveQuestion(CustomerQuestion question, int direction) {
    final ordered = widget.repository.questions.toList();
    final index = ordered.indexWhere((item) => item.id == question.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= ordered.length) return;
    final moved = ordered.removeAt(index);
    ordered.insert(target, moved);
    for (var order = 0; order < ordered.length; order++) {
      final item = ordered[order];
      widget.repository.updateQuestion(
        CustomerQuestion(
          id: item.id,
          prompt: item.prompt,
          type: item.type,
          options: item.options,
          timing: item.timing,
          required: item.required,
          order: order,
        ),
      );
    }
    _refresh();
  }

  void _saveCashSettings({
    required bool drawerEnabled,
    required bool askOpeningCash,
    required bool requireReconciliation,
  }) {
    final old = widget.repository.settings;
    widget.repository.updateSettings(
      WorkspaceSettings(
        cashDrawerEnabled: drawerEnabled,
        askOpeningCash: askOpeningCash,
        requireShiftReconciliation: requireReconciliation,
        whatsappNumber: old.whatsappNumber,
        whatsappMessage: old.whatsappMessage,
        invoicePrefix: old.invoicePrefix,
        invoiceFooter: old.invoiceFooter,
      ),
    );
    widget.onChanged();
    _showMessage('Cash and shift settings saved.');
  }

  void _refresh() {
    setState(() {});
    widget.onChanged();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      workspacePageHeader('Settings', 'Workspace details and preferences.'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final section in _SettingsSection.values)
            ChoiceChip(
              label: Text(switch (section) {
                _SettingsSection.workspace => 'Workspace',
                _SettingsSection.questions => 'Customer questions',
                _SettingsSection.cash => 'Cash & shifts',
                _SettingsSection.communications => 'WhatsApp & invoices',
              }),
              selected: _section == section,
              onSelected: (_) => setState(() => _section = section),
            ),
        ],
      ),
      const SizedBox(height: 12),
      switch (_section) {
        _SettingsSection.workspace => _workspaceSettings(),
        _SettingsSection.questions => _questionSettings(),
        _SettingsSection.cash => _cashSettings(),
        _SettingsSection.communications => _communicationSettings(),
      },
    ],
  );

  Widget _workspaceSettings() => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _workspaceName,
          decoration: workspaceInputDecoration('Workspace name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ownerName,
          decoration: workspaceInputDecoration('Owner name'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: workspaceInputDecoration('Workspace phone'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<SetupCountry>(
          isExpanded: true,
          initialValue: _country,
          decoration: workspaceInputDecoration('Country and currency'),
          items: [
            for (final country in setupCountries)
              DropdownMenuItem(
                value: country,
                child: Text(
                  '${country.flag} ${country.name} · ${country.currency}',
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _country = value);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _area,
          decoration: workspaceInputDecoration('Area / branch'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saveWorkspace,
            child: const Text('Save workspace'),
          ),
        ),
      ],
    ),
  );

  Widget _questionSettings() {
    final questions = widget.repository.questions
        .where((question) => question.timing == _questionTimingFilter)
        .toList();
    final timingLabel = _questionTimingFilter == CustomerQuestionTiming.checkIn
        ? 'check-in'
        : 'check-out';
    final timingVerb = _questionTimingFilter == CustomerQuestionTiming.checkIn
        ? 'in'
        : 'out';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Customer questions',
          'Staff ask these when they check a customer $timingVerb. Changes save by themselves.',
          trailing: IconButton(
            tooltip: 'Add question',
            onPressed: _addQuestion,
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<CustomerQuestionTiming>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: CustomerQuestionTiming.checkIn,
                label: Text('At check-in'),
              ),
              ButtonSegment(
                value: CustomerQuestionTiming.checkOut,
                label: Text('At check-out'),
              ),
            ],
            selected: {_questionTimingFilter},
            onSelectionChanged: (selection) =>
                setState(() => _questionTimingFilter = selection.first),
          ),
        ),
        const SizedBox(height: 10),
        if (questions.isEmpty)
          DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No questions for $timingLabel yet',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use + to add a question for staff to ask at $timingLabel.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        for (final question in questions) ...[
          const SizedBox(height: 8),
          DashboardPanel(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.prompt,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${question.type == CustomerQuestionType.shortText ? 'Short answer' : 'Multiple choice'} · ${question.timing == CustomerQuestionTiming.checkIn ? 'Check-in' : 'Check-out'} · ${question.required ? 'Required' : 'Optional'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (question.options.isNotEmpty)
                        Text(
                          question.options.join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit question',
                  onPressed: () => _editQuestion(question),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete question',
                  onPressed: () => _questionActions(question),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _questionActions(CustomerQuestion question) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () => Navigator.pop(context, 'duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Move up'),
              onTap: () => Navigator.pop(context, 'up'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Move down'),
              onTap: () => Navigator.pop(context, 'down'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'edit':
        await _editQuestion(question);
      case 'duplicate':
        _duplicateQuestion(question);
      case 'up':
        _moveQuestion(question, -1);
      case 'down':
        _moveQuestion(question, 1);
      case 'delete':
        await _deleteQuestion(question);
    }
  }

  Widget _cashSettings() {
    final settings = widget.repository.settings;
    var drawerEnabled = settings.cashDrawerEnabled;
    var askOpeningCash = settings.askOpeningCash;
    var requireReconciliation = settings.requireShiftReconciliation;
    return StatefulBuilder(
      builder: (context, setLocalState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardPanel(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Use the cash drawer'),
                    subtitle: const Text('Track cash movements by shift.'),
                    value: drawerEnabled,
                    onChanged: (value) =>
                        setLocalState(() => drawerEnabled = value),
                  ),
                  SwitchListTile(
                    title: const Text('Ask for opening cash'),
                    value: askOpeningCash,
                    onChanged: (value) =>
                        setLocalState(() => askOpeningCash = value),
                  ),
                  SwitchListTile(
                    title: const Text('Reconcile cash at shift end'),
                    value: requireReconciliation,
                    onChanged: (value) =>
                        setLocalState(() => requireReconciliation = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => _saveCashSettings(
                drawerEnabled: drawerEnabled,
                askOpeningCash: askOpeningCash,
                requireReconciliation: requireReconciliation,
              ),
              child: const Text('Save cash settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communicationSettings() => DashboardPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration: workspaceInputDecoration('WhatsApp number'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _whatsappMessage,
          maxLines: 3,
          decoration: workspaceInputDecoration(
            'Message template',
            hint: 'Use {customer} and {workspace} placeholders',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _invoicePrefix,
          decoration: workspaceInputDecoration('Invoice number prefix'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _invoiceFooter,
          maxLines: 2,
          decoration: workspaceInputDecoration('Invoice footer'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saveCommunications,
            child: const Text('Save settings'),
          ),
        ),
      ],
    ),
  );
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({
    this.question,
    this.initialTiming = CustomerQuestionTiming.checkIn,
  });

  final CustomerQuestion? question;
  final CustomerQuestionTiming initialTiming;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _prompt = TextEditingController(text: widget.question?.prompt);
  late final _options = TextEditingController(
    text: widget.question?.options.join(', '),
  );
  late CustomerQuestionType _type =
      widget.question?.type ?? CustomerQuestionType.multipleChoice;
  late CustomerQuestionTiming _timing =
      widget.question?.timing ?? widget.initialTiming;
  late bool _required = widget.question?.required ?? false;

  @override
  void dispose() {
    _prompt.dispose();
    _options.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final options = _options.text
        .split(',')
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();
    if (_type == CustomerQuestionType.multipleChoice && options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two choices.')),
      );
      return;
    }
    Navigator.pop(
      context,
      CustomerQuestion(
        id: widget.question?.id ?? '',
        prompt: _prompt.text.trim(),
        type: _type,
        options: _type == CustomerQuestionType.multipleChoice
            ? options
            : const [],
        timing: _timing,
        required: _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.question == null ? 'Add question' : 'Edit question'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('customer-question-prompt'),
                controller: _prompt,
                autofocus: true,
                decoration: workspaceInputDecoration('Question'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a question'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<CustomerQuestionType>(
                isExpanded: true,
                initialValue: _type,
                decoration: workspaceInputDecoration('Answer type'),
                items: const [
                  DropdownMenuItem(
                    value: CustomerQuestionType.multipleChoice,
                    child: Text('Multiple choice'),
                  ),
                  DropdownMenuItem(
                    value: CustomerQuestionType.shortText,
                    child: Text('Short text'),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _type = value ?? CustomerQuestionType.multipleChoice,
                ),
              ),
              if (_type == CustomerQuestionType.multipleChoice) ...[
                const SizedBox(height: 10),
                TextFormField(
                  key: const ValueKey('customer-question-options'),
                  controller: _options,
                  decoration: workspaceInputDecoration(
                    'Choices (comma separated)',
                  ),
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<CustomerQuestionTiming>(
                isExpanded: true,
                initialValue: _timing,
                decoration: workspaceInputDecoration('Ask at'),
                items: const [
                  DropdownMenuItem(
                    value: CustomerQuestionTiming.checkIn,
                    child: Text('Check-in'),
                  ),
                  DropdownMenuItem(
                    value: CustomerQuestionTiming.checkOut,
                    child: Text('Check-out'),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _timing = value ?? CustomerQuestionTiming.checkIn,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _required,
                onChanged: (value) =>
                    setState(() => _required = value ?? false),
                title: const Text('Required'),
                controlAffinity: ListTileControlAffinity.leading,
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
      FilledButton(onPressed: _save, child: const Text('Save question')),
    ],
  );
}
