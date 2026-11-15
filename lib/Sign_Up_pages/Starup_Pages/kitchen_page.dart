import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/preview_page.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/spaces_page_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/staff_page.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Starup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

class KitchenPage extends StatefulWidget {
  const KitchenPage({super.key, required this.setup});

  final StartupSetup setup;

  @override
  State<KitchenPage> createState() => _KitchenPageState();
}

class _KitchenPageState extends State<KitchenPage> {
  final Map<KitchenItemSetup, TextEditingController> _names = {};
  final Map<KitchenItemSetup, TextEditingController> _prices = {};
  final Map<KitchenItemSetup, TextEditingController> _quantities = {};
  final Map<KitchenItemSetup, TextEditingController> _costs = {};
  final Map<KitchenItemSetup, FocusNode> _priceFocus = {};
  final ValueNotifier<int> _itemsRevision = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    for (final item in widget.setup.kitchenItems) {
      _addControllers(item);
    }
  }

  void _addControllers(KitchenItemSetup item) {
    _names[item] = TextEditingController(text: item.name);
    _prices[item] = TextEditingController(text: item.price);
    _quantities[item] = TextEditingController(text: item.quantity);
    _costs[item] = TextEditingController(text: item.costsYou);
    _priceFocus[item] = FocusNode();
  }

  void _disposeControllersFor(KitchenItemSetup item) {
    _names.remove(item)?.dispose();
    _prices.remove(item)?.dispose();
    _quantities.remove(item)?.dispose();
    _costs.remove(item)?.dispose();
    _priceFocus.remove(item)?.dispose();
  }

  @override
  void dispose() {
    for (final controller in [
      ..._names.values,
      ..._prices.values,
      ..._quantities.values,
      ..._costs.values,
    ]) {
      controller.dispose();
    }
    for (final focus in _priceFocus.values) {
      focus.dispose();
    }
    _itemsRevision.dispose();
    super.dispose();
  }

  void _notifyItemsChanged() {
    _itemsRevision.value++;
  }

  bool _hasValues(KitchenItemSetup item) =>
      item.name.trim().isNotEmpty ||
      item.price.trim().isNotEmpty ||
      item.quantity.trim().isNotEmpty ||
      item.costsYou.trim().isNotEmpty;

  bool get _hasItems => widget.setup.kitchenItems.any(_hasValues);

  void _continue() {
    final retainedItems = <KitchenItemSetup>[];
    final removedItems = <KitchenItemSetup>[];
    for (final item in widget.setup.kitchenItems) {
      (_hasValues(item) ? retainedItems : removedItems).add(item);
    }
    widget.setup.kitchenItems = retainedItems;
    if (removedItems.isNotEmpty) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final item in removedItems) {
          _disposeControllersFor(item);
        }
      });
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StaffPage(setup: widget.setup)),
    );
  }

  void _addRow() {
    setState(() {
      widget.setup.kitchenItems.add(KitchenItemSetup());
      _addControllers(widget.setup.kitchenItems.last);
    });
  }

  void _fillName(String name) {
    var index = widget.setup.kitchenItems.indexWhere(
      (item) => item.name.trim().isEmpty,
    );
    if (index < 0) {
      final item = KitchenItemSetup();
      setState(() {
        widget.setup.kitchenItems.add(item);
        _addControllers(item);
      });
      index = widget.setup.kitchenItems.length - 1;
    }

    final item = widget.setup.kitchenItems[index];
    item.name = name;
    _names[item]!.text = name;
    _names[item]!.selection = TextSelection.collapsed(offset: name.length);
    _notifyItemsChanged();
    final focusNode = _priceFocus[item]!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(focusNode);
    });
  }

  void _finishLater() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SetupDashboardPage(setup: widget.setup),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SetupPageFrame(
      step: 4,
      workspaceName: widget.setup.workspaceName,
      title: 'Your kitchen',
      description:
          'Drinks and snacks you sell. Staff add them to the bill at check-out. '
          'You can skip this and add them later.',
      onBack: () => Navigator.of(context).pop(),
      onFinishLater: _finishLater,
      onContinue: _continue,
      panelChild: false,
      summary: ValueListenableBuilder<int>(
        valueListenable: _itemsRevision,
        builder: (context, _, _) => SetupProgressSummary(
          setup: widget.setup,
          activeStep: 4,
          onEditStep: (step) =>
              returnToSetupStep(context, currentStep: 4, targetStep: step),
        ),
      ),
      secondaryAction: ValueListenableBuilder<int>(
        valueListenable: _itemsRevision,
        builder: (context, _, _) => !_hasItems
            ? TextButton(
                onPressed: _continue,
                child: const Text('Skip for now'),
              )
            : const SizedBox.shrink(),
      ),
      child: SetupPanel(
        backgroundColor: AppColors.white,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (
              var index = 0;
              index < widget.setup.kitchenItems.length;
              index++
            )
              _itemRow(widget.setup.kitchenItems[index], index),
            const SizedBox(height: 2),
            Text(
              'Quantity: how many you have now. Leave it empty for things you '
              'don’t count one by one, like coffee. Costs you: what you pay '
              'for one, so we can show your profit.',
              style: const TextStyle(
                color: AppColors.authMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.authBorder),
            ),
            const Text(
              'Or tap one to fill it in',
              style: TextStyle(
                color: AppColors.authInk,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final name in const [
                  'Water',
                  'Coffee',
                  'Tea',
                  'Pepsi',
                  'Chips',
                  'Sandwich',
                ])
                  _suggestionChip(name),
                _kitchenChip(
                  key: const ValueKey('kitchen-empty-row'),
                  label: 'Empty row',
                  onPressed: _addRow,
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'It fills in the name. You type the price.',
              style: TextStyle(
                color: AppColors.authMuted,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(KitchenItemSetup item, int index) {
    final isFirst = index == 0;
    final fields = [
      _itemField(
        key: ValueKey('kitchen-name-$index'),
        label: 'Name',
        hintText: isFirst ? 'e.g. Pepsi' : 'Name',
        controller: _names[item]!,
        textCapitalization: TextCapitalization.words,
        onChanged: (value) {
          item.name = value;
          _notifyItemsChanged();
        },
      ),
      _itemField(
        key: ValueKey('kitchen-price-$index'),
        label: 'Price',
        hintText: isFirst ? '20' : 'Price',
        controller: _prices[item]!,
        focusNode: _priceFocus[item],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffixText: widget.setup.country.currency,
        onChanged: (value) {
          item.price = value;
          _notifyItemsChanged();
        },
      ),
      _itemField(
        key: ValueKey('kitchen-quantity-$index'),
        label: 'Quantity',
        hintText: isFirst ? '24' : 'Quantity',
        controller: _quantities[item]!,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          item.quantity = value;
          _notifyItemsChanged();
        },
      ),
      _itemField(
        key: ValueKey('kitchen-costs-$index'),
        label: 'Costs you (optional)',
        hintText: isFirst ? '11' : 'Costs you',
        controller: _costs[item]!,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffixText: widget.setup.country.currency,
        onChanged: (value) {
          item.costsYou = value;
          _notifyItemsChanged();
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 340) {
            return _fieldRow(fields, [5, 4, 4, 6]);
          }
          return Column(
            children: [
              _fieldRow(fields.take(2).toList(), [1, 1]),
              const SizedBox(height: 8),
              _fieldRow(fields.skip(2).toList(), [1, 1]),
            ],
          );
        },
      ),
    );
  }

  Widget _fieldRow(List<Widget> fields, List<int> flexes) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(flex: flexes[index], child: fields[index]),
        ],
      ],
    );
  }

  Widget _itemField({
    required Key key,
    required String label,
    required String hintText,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.authInk,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          key: key,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 11),
          decoration: setupInputDecoration(
            hintText: hintText,
            suffixText: suffixText,
          ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 8)),
        ),
      ],
    );
  }

  Widget _suggestionChip(String name) =>
      _kitchenChip(label: name, onPressed: () => _fillName(name));

  Widget _kitchenChip({
    Key? key,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      key: key,
      avatar: const Icon(Icons.add, color: AppColors.authGreen, size: 13),
      label: Text(label),
      labelStyle: const TextStyle(
        color: AppColors.authInk,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: AppColors.white,
      side: const BorderSide(color: AppColors.authBorder),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      onPressed: onPressed,
    );
  }
}
