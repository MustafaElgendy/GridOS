import 'package:flutter/material.dart';
import 'package:grid_os/Main Pages/dashboard_widgets.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';

import 'workspace_page_utils.dart';

class WorkspaceProductsPage extends StatefulWidget {
  const WorkspaceProductsPage({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.currency,
  });

  final WorkspaceRepository repository;
  final VoidCallback onChanged;
  final String currency;

  @override
  State<WorkspaceProductsPage> createState() => _WorkspaceProductsPageState();
}

class _WorkspaceProductsPageState extends State<WorkspaceProductsPage> {
  String _category = 'All';

  List<String> get _categories => [
    'All',
    ...widget.repository.products.map((product) => product.category).toSet()
      ..remove('All'),
  ];

  Future<void> _addProduct() async {
    final draft = await showDialog<Product>(
      context: context,
      builder: (context) => const _ProductFormDialog(),
    );
    if (draft == null) return;
    widget.repository.createProduct(
      Product(
        id: newWorkspaceId('product'),
        name: draft.name,
        category: draft.category,
        quantityOnHand: draft.quantityOnHand,
        lowStockThreshold: draft.lowStockThreshold,
        unit: draft.unit,
        sku: draft.sku,
        price: draft.price,
        cost: draft.cost,
        freeForMembers: draft.freeForMembers,
      ),
    );
    _changed();
  }

  Future<void> _editProduct(Product product) async {
    final draft = await showDialog<Product>(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );
    if (draft == null) return;
    widget.repository.updateProduct(
      Product(
        id: product.id,
        name: draft.name,
        category: draft.category,
        quantityOnHand: draft.quantityOnHand,
        lowStockThreshold: draft.lowStockThreshold,
        unit: draft.unit,
        sku: draft.sku,
        price: draft.price,
        cost: draft.cost,
        freeForMembers: draft.freeForMembers,
      ),
    );
    _changed();
  }

  Future<void> _addStock(Product product) async {
    final result = await showDialog<_StockAddition>(
      context: context,
      builder: (context) => _AddStockDialog(product: product),
    );
    if (result == null) return;
    widget.repository.updateProduct(
      Product(
        id: product.id,
        name: product.name,
        category: product.category,
        quantityOnHand: product.quantityOnHand + result.quantity,
        lowStockThreshold: product.lowStockThreshold,
        unit: product.unit,
        sku: product.sku,
        price: product.price,
        cost: product.cost,
        freeForMembers: product.freeForMembers,
      ),
    );
    if (result.cost > 0) {
      widget.repository.createMoneyEntry(
        MoneyEntry(
          id: newWorkspaceId('money'),
          kind: MoneyEntryKind.expense,
          amount: result.cost,
          occurredAt: DateTime.now(),
          currency: widget.currency,
          description: 'Stock purchase · ${product.name}',
        ),
      );
    }
    _changed();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove ${product.name} from the product list?'),
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
      widget.repository.deleteProduct(product.id);
      _changed();
    }
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final products =
        widget.repository.products
            .where(
              (product) => _category == 'All' || product.category == _category,
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        workspacePageHeader(
          'Products',
          'Manage what you sell and keep an eye on stock.',
          trailing: widget.repository.products.isEmpty
              ? null
              : FilledButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Add product'),
                ),
        ),
        if (widget.repository.lowStockProducts().isNotEmpty) ...[
          const SizedBox(height: 12),
          DashboardPanel(
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.repository.lowStockProducts().length} product(s) are low on stock.',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_categories.length > 1)
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final category in _categories)
                ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
        if (_categories.length > 1) const SizedBox(height: 12),
        if (products.isEmpty)
          DashboardEmptyState(
            icon: Icons.inventory_2_outlined,
            title: widget.repository.products.isEmpty
                ? 'No products yet'
                : 'No products in this category',
            description: widget.repository.products.isEmpty
                ? 'Add products, set stock levels and track low stock.'
                : 'Choose another category or add a product.',
            actionLabel: 'Add product',
            onPressed: _addProduct,
          )
        else
          for (final product in products) ...[
            const SizedBox(height: 8),
            DashboardPanel(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFF0F7F4),
                    child: Icon(Icons.inventory_2_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${product.category} · ${product.quantityOnHand.toStringAsFixed(product.quantityOnHand % 1 == 0 ? 0 : 1)} ${product.unit} in stock · ${formatWorkspaceAmount(product.price, widget.currency)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (product.isLowStock)
                          const Text(
                            'Low stock',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add stock',
                    onPressed: () => _addStock(product),
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                  IconButton(
                    tooltip: 'Edit product',
                    onPressed: () => _editProduct(product),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete product',
                    onPressed: () => _deleteProduct(product),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _category = TextEditingController(
    text: widget.product?.category ?? 'Drinks',
  );
  late final _price = TextEditingController(
    text: widget.product?.price.toString() ?? '',
  );
  late final _cost = TextEditingController(
    text: widget.product?.cost.toString() ?? '',
  );
  late final _quantity = TextEditingController(
    text: widget.product?.quantityOnHand.toString() ?? '0',
  );
  late final _threshold = TextEditingController(
    text: widget.product?.lowStockThreshold.toString() ?? '5',
  );
  late final _unit = TextEditingController(
    text: widget.product?.unit ?? 'item',
  );
  late final _sku = TextEditingController(text: widget.product?.sku);
  late bool _freeForMembers = widget.product?.freeForMembers ?? false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _category,
      _price,
      _cost,
      _quantity,
      _threshold,
      _unit,
      _sku,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Product(
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        category: _category.text.trim().isEmpty
            ? 'Other'
            : _category.text.trim(),
        price: _number(_price),
        cost: _number(_cost),
        quantityOnHand: _number(_quantity),
        lowStockThreshold: _number(_threshold),
        unit: _unit.text.trim().isEmpty ? 'item' : _unit.text.trim(),
        sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        freeForMembers: _freeForMembers,
      ),
    );
  }

  String? _validateNumber(String? value, {bool allowZero = true}) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        (!allowZero && number == 0)) {
      return 'Enter a valid non-negative number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('workspace-product-name'),
                  controller: _name,
                  autofocus: true,
                  decoration: workspaceInputDecoration('Product name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a product name'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _category,
                  decoration: workspaceInputDecoration(
                    'Category',
                    hint: 'Drinks, food, supplies…',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('workspace-product-price'),
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: workspaceInputDecoration('Selling price'),
                        validator: _validateNumber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('workspace-product-cost'),
                        controller: _cost,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: workspaceInputDecoration('Your cost'),
                        validator: _validateNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const ValueKey('workspace-product-stock'),
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: workspaceInputDecoration('Stock on hand'),
                        validator: _validateNumber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _threshold,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: workspaceInputDecoration('Low-stock at'),
                        validator: _validateNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: workspaceInputDecoration('Unit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _sku,
                        decoration: workspaceInputDecoration('SKU / code'),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _freeForMembers,
                  onChanged: (value) =>
                      setState(() => _freeForMembers = value ?? false),
                  title: const Text('Free for members'),
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
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _StockAddition {
  const _StockAddition({required this.quantity, required this.cost});

  final double quantity;
  final double cost;
}

class _AddStockDialog extends StatefulWidget {
  const _AddStockDialog({required this.product});

  final Product product;

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _cost = TextEditingController();

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _save() {
    final quantity = double.tryParse(_quantity.text.trim());
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    if (!_formKey.currentState!.validate() || quantity == null) return;
    Navigator.pop(context, _StockAddition(quantity: quantity, cost: cost));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Add ${widget.product.name} stock'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _quantity,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: workspaceInputDecoration('Quantity to add'),
            validator: (value) {
              final quantity = double.tryParse(value?.trim() ?? '');
              return quantity == null ||
                      !quantity.isFinite ||
                      quantity <= 0
                  ? 'Enter a quantity greater than zero'
                  : null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: workspaceInputDecoration('Total cost (optional)'),
            validator: (value) {
              final cost = double.tryParse(value?.trim() ?? '');
              return value != null &&
                      value.trim().isNotEmpty &&
                      (cost == null || !cost.isFinite || cost < 0)
                  ? 'Enter a valid cost'
                  : null;
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Add stock')),
    ],
  );
}
