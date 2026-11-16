import 'package:flutter/material.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';

import 'workspace_page_utils.dart';

class WorkspaceCustomersPage extends StatefulWidget {
  const WorkspaceCustomersPage({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.currency,
  });

  final WorkspaceRepository repository;
  final VoidCallback onChanged;
  final String currency;

  @override
  State<WorkspaceCustomersPage> createState() => _WorkspaceCustomersPageState();
}

class _WorkspaceCustomersPageState extends State<WorkspaceCustomersPage> {
  String _query = '';

  List<Customer> get _customers {
    final query = _query.trim().toLowerCase();
    return widget.repository.customers.where((customer) {
      if (query.isEmpty) return true;
      return [
        customer.name,
        customer.phone,
        customer.email,
        customer.area,
        customer.profession,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList()..sort(
      (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
        a.createdAt ?? DateTime(2000),
      ),
    );
  }

  Future<void> _addCustomer() async {
    final draft = await showDialog<Customer>(
      context: context,
      builder: (context) => const _CustomerFormDialog(),
    );
    if (draft == null) return;
    widget.repository.createCustomer(
      Customer(
        id: newWorkspaceId('customer'),
        name: draft.name,
        phone: draft.phone,
        email: draft.email,
        profession: draft.profession,
        area: draft.area,
        source: draft.source,
        plan: draft.plan,
        notes: draft.notes,
        balance: draft.balance,
        createdAt: DateTime.now(),
      ),
    );
    widget.onChanged();
    setState(() {});
  }

  Future<void> _editCustomer(Customer customer) async {
    final draft = await showDialog<Customer>(
      context: context,
      builder: (context) => _CustomerFormDialog(customer: customer),
    );
    if (draft == null) return;
    widget.repository.updateCustomer(
      Customer(
        id: customer.id,
        name: draft.name,
        phone: draft.phone,
        email: draft.email,
        profession: draft.profession,
        area: draft.area,
        source: draft.source,
        plan: draft.plan,
        notes: draft.notes,
        balance: draft.balance,
        createdAt: customer.createdAt,
      ),
    );
    widget.onChanged();
    setState(() {});
  }

  Future<void> _showCustomer(Customer customer) async {
    final visits = widget.repository.visitsForCustomer(customer.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone?.isNotEmpty == true)
              _CustomerDetail(label: 'Phone', value: customer.phone!),
            if (customer.profession?.isNotEmpty == true)
              _CustomerDetail(label: 'Profession', value: customer.profession!),
            if (customer.area?.isNotEmpty == true)
              _CustomerDetail(label: 'Area', value: customer.area!),
            if (customer.source?.isNotEmpty == true)
              _CustomerDetail(label: 'Source', value: customer.source!),
            if (customer.plan?.isNotEmpty == true)
              _CustomerDetail(label: 'Plan', value: customer.plan!),
            _CustomerDetail(label: 'Visits', value: visits.length.toString()),
            if (visits.isNotEmpty)
              _CustomerDetail(
                label: 'Last visit',
                value: formatWorkspaceDate(visits.first.checkedInAt),
              ),
            if (customer.balance != 0)
              _CustomerDetail(
                label: 'Balance',
                value: formatWorkspaceAmount(customer.balance, widget.currency),
              ),
            if (customer.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(customer.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _editCustomer(customer);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await _confirmDelete(customer.name);
              if (!confirmed || !context.mounted) return;
              widget.repository.deleteCustomer(customer.id);
              Navigator.pop(context);
              widget.onChanged();
              setState(() {});
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete customer?'),
          content: Text('Remove $name from your customer list?'),
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
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final customers = _customers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Customers',
          'Keep customer details and visits together.',
          trailing: widget.repository.customers.isEmpty
              ? null
              : FilledButton.icon(
                  onPressed: _addCustomer,
                  icon: const Icon(Icons.person_add_alt_1, size: 17),
                  label: const Text('Add customer'),
                ),
        ),
        const SizedBox(height: 16),
        if (widget.repository.customers.isNotEmpty) ...[
          TextField(
            decoration: workspaceInputDecoration(
              'Search customers',
              hint: 'Name, phone, area or profession',
            ).copyWith(prefixIcon: const Icon(Icons.search)),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
        ],
        if (customers.isEmpty)
          DashboardEmptyState(
            icon: Icons.people_outline,
            title: _query.isEmpty ? 'No customers yet' : 'No matches',
            description: _query.isEmpty
                ? 'Add your first customer to keep their visits and details together.'
                : 'Try a different name, phone number or area.',
            actionLabel: _query.isEmpty ? 'Add customer' : 'Clear search',
            onPressed: _query.isEmpty
                ? _addCustomer
                : () => setState(() => _query = ''),
          )
        else
          for (final customer in customers) ...[
            const SizedBox(height: 8),
            DashboardPanel(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () => _showCustomer(customer),
                  leading: CircleAvatar(
                    child: Text(
                      customer.name.trim().isEmpty
                          ? '?'
                          : customer.name.trim()[0].toUpperCase(),
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(
                    [
                          customer.phone,
                          customer.area,
                          '${widget.repository.visitsForCustomer(customer.id).length} visits',
                        ]
                        .whereType<String>()
                        .where((text) => text.isNotEmpty)
                        .join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          ],
      ],
    );
  }
}

class _CustomerDetail extends StatelessWidget {
  const _CustomerDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text('$label: $value'),
  );
}

class _CustomerFormDialog extends StatefulWidget {
  const _CustomerFormDialog({this.customer});

  final Customer? customer;

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _profession = TextEditingController(
    text: widget.customer?.profession,
  );
  late final _area = TextEditingController(text: widget.customer?.area);
  late final _source = TextEditingController(text: widget.customer?.source);
  late final _plan = TextEditingController(text: widget.customer?.plan);
  late final _notes = TextEditingController(text: widget.customer?.notes);
  late final _balance = TextEditingController(
    text: widget.customer != null && widget.customer!.balance != 0
        ? widget.customer!.balance.toString()
        : '',
  );

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _profession,
      _area,
      _source,
      _plan,
      _notes,
      _balance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        id: widget.customer?.id ?? '',
        name: _name.text.trim(),
        phone: _optional(_phone),
        email: _optional(_email),
        profession: _optional(_profession),
        area: _optional(_area),
        source: _optional(_source),
        plan: _optional(_plan),
        notes: _optional(_notes),
        balance: double.tryParse(_balance.text.trim()) ?? 0,
      ),
    );
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add customer' : 'Edit customer'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: workspaceInputDecoration('Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: workspaceInputDecoration('Phone'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _profession,
                  decoration: workspaceInputDecoration('Profession'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _area,
                  decoration: workspaceInputDecoration('Area'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _source,
                  decoration: workspaceInputDecoration('How they found you'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _plan,
                  decoration: workspaceInputDecoration('Plan or membership'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _balance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: workspaceInputDecoration('Balance owed'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: workspaceInputDecoration('Email'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: workspaceInputDecoration('Notes'),
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
