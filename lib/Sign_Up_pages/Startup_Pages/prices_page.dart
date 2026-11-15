import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/kitchen_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/preview_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

class PricesPage extends StatefulWidget {
  const PricesPage({super.key, required this.setup});

  final StartupSetup setup;

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  late final List<SetupSpaceType> _spaces;
  int _expandedIndex = 0;
  final Set<SetupSpaceType> _issues = {};
  final ValueNotifier<int> _priceRevision = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _spaces = widget.setup.selectedSpaces;
  }

  @override
  void dispose() {
    _priceRevision.dispose();
    super.dispose();
  }

  void _notifyPriceChanged() {
    _priceRevision.value++;
  }

  bool _hasPrice(SetupSpaceType type) {
    final price = widget.setup.prices[type]!;
    var walkInIsValid = false;
    if (type == SetupSpaceType.rooms) {
      walkInIsValid =
          _validAmount(price.hourlyPrice) &&
          (!price.hasPeopleTier ||
              (_positive(price.peopleIncluded) &&
                  _positive(price.additionalPeople) &&
                  _validAmount(price.additionalPrice)));
    } else if (type == SetupSpaceType.computers) {
      final count = int.tryParse(widget.setup.spaces[type]!.computerCount) ?? 0;
      if (price.pricePerComputer) {
        walkInIsValid =
            count > 0 &&
            List.generate(
              count,
              (index) => index,
            ).every((index) => _validAmount(price.computerPrices[index] ?? ''));
      } else {
        walkInIsValid = _validAmount(price.hourlyPrice);
      }
    } else {
      walkInIsValid = switch (price.walkInMode) {
        WalkInPriceMode.byHours =>
          price.walkInSteps.isNotEmpty &&
              price.walkInSteps.every(
                (step) =>
                    _validAmount(step.price) && _positive(step.untilHours),
              ) &&
              _validAmount(price.moreHoursPrice),
        WalkInPriceMode.perHour =>
          _validAmount(price.hourlyPrice) &&
              (!price.hasDailyCap || _validAmount(price.dailyCap)),
        WalkInPriceMode.byShift =>
          price.shifts.isNotEmpty &&
              price.shifts.every(
                (shift) =>
                    shift.name.trim().isNotEmpty && _validAmount(shift.price),
              ),
        WalkInPriceMode.dayPrice => _validAmount(price.dayPrice),
      };
    }

    final plansAreValid = price.plans.every(
      (plan) =>
          plan.name.trim().isNotEmpty &&
          _validAmount(plan.price) &&
          plan.duration.trim().isNotEmpty,
    );
    final monthlyDeskIsValid =
        type != SetupSpaceType.sharedArea ||
        !price.monthlyDesksEnabled ||
        _validAmount(price.monthlyDeskPrice);
    return walkInIsValid && plansAreValid && monthlyDeskIsValid;
  }

  bool _positive(String value) {
    final count = int.tryParse(value);
    return count != null && count > 0;
  }

  bool _validAmount(String value) {
    final amount = double.tryParse(value);
    return amount != null && amount >= 0;
  }

  void _doneCard(int index) {
    final type = _spaces[index];
    if (!_hasPrice(type)) {
      setState(() {
        _issues.add(type);
        _expandedIndex = index;
      });
      return;
    }
    setState(() {
      _issues.remove(type);
      _expandedIndex = index + 1 < _spaces.length ? index + 1 : -1;
    });
  }

  void _continue() {
    for (var index = 0; index < _spaces.length; index++) {
      final type = _spaces[index];
      if (!_hasPrice(type)) {
        setState(() {
          _issues.add(type);
          _expandedIndex = index;
        });
        return;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => KitchenPage(setup: widget.setup)),
    );
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
      step: 3,
      workspaceName: widget.setup.workspaceName,
      title: 'Set your prices',
      description: 'Choose walk-in prices and optional plans for each space.',
      onBack: () => Navigator.of(context).pop(),
      onFinishLater: _finishLater,
      onContinue: _continue,
      panelChild: false,
      summary: ValueListenableBuilder<int>(
        valueListenable: _priceRevision,
        builder: (context, _, _) => SetupProgressSummary(
          setup: widget.setup,
          activeStep: 3,
          onEditStep: (step) =>
              returnToSetupStep(context, currentStep: 3, targetStep: step),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < _spaces.length; index++)
            _priceCard(index, _spaces[index]),
        ],
      ),
    );
  }

  Widget _priceCard(int index, SetupSpaceType type) {
    final config = widget.setup.prices[type]!;
    final expanded = _expandedIndex == index;
    return Container(
      key: ValueKey('price-card-${type.name}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: expanded ? AppColors.authGreen : AppColors.authBorder,
          width: expanded ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: expanded ? AppColors.homePaleGreen : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.control - 1),
            ),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.control - 1),
              ),
              onTap: () =>
                  setState(() => _expandedIndex = expanded ? -1 : index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: AppColors.authGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.label,
                            style: const TextStyle(
                              color: AppColors.authInk,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!expanded)
                            Text(
                              _priceCardSummary(type, config),
                              style: const TextStyle(
                                color: AppColors.authMuted,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (expanded)
                      const Text(
                        'Editing',
                        style: TextStyle(
                          color: AppColors.authGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 5),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.authMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (type == SetupSpaceType.rooms)
                    _roomPrices(config)
                  else if (type == SetupSpaceType.computers)
                    _computerPrices(config, type)
                  else
                    _walkInPrices(config),
                  if (type == SetupSpaceType.sharedArea) _monthlyDesks(config),
                  const SizedBox(height: 12),
                  _plans(config, type),
                  if (_issues.contains(type)) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Add a valid price to continue.',
                      style: TextStyle(color: Color(0xFFB05D00), fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => _doneCard(index),
                      child: Text(
                        index + 1 < _spaces.length ? 'Done · next' : 'Done',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _priceCardSummary(SetupSpaceType type, SpacePriceSetup config) {
    final currency = widget.setup.country.currency;
    if (type == SetupSpaceType.rooms) {
      return config.hourlyPrice.isEmpty
          ? 'Add room pricing'
          : '${config.hourlyPrice} $currency / hour';
    }
    if (type == SetupSpaceType.computers) {
      if (config.pricePerComputer) return 'Individual computer prices';
      return config.hourlyPrice.isEmpty
          ? 'Add computer pricing'
          : '${config.hourlyPrice} $currency / hour';
    }
    return switch (config.walkInMode) {
      WalkInPriceMode.byHours =>
        config.walkInSteps.isEmpty
            ? 'Add walk-in prices'
            : 'By hours · ${config.walkInSteps.length} price steps',
      WalkInPriceMode.perHour =>
        config.hourlyPrice.isEmpty
            ? 'Per hour · price not set'
            : '${config.hourlyPrice} $currency / hour',
      WalkInPriceMode.byShift => 'By shift · ${config.shifts.length} shifts',
      WalkInPriceMode.dayPrice =>
        config.dayPrice.isEmpty
            ? 'Day price · not set'
            : '${config.dayPrice} $currency / day',
    };
  }

  Widget _walkInPrices(SpacePriceSetup config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'How do walk-ins pay?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _walkInModeSelector(config),
        const SizedBox(height: 12),
        switch (config.walkInMode) {
          WalkInPriceMode.byHours => _hourSteps(config),
          WalkInPriceMode.perHour => _perHour(config),
          WalkInPriceMode.byShift => _shifts(config),
          WalkInPriceMode.dayPrice => _amountField(
            'Day price',
            config.dayPrice,
            (value) => config.dayPrice = value,
          ),
        },
      ],
    );
  }

  Widget _walkInModeSelector(SpacePriceSetup config) {
    const options = [
      (
        mode: WalkInPriceMode.byHours,
        title: 'By hours',
        subtitle: 'Price steps',
      ),
      (
        mode: WalkInPriceMode.perHour,
        title: 'Per hour',
        subtitle: 'Hourly rate',
      ),
      (
        mode: WalkInPriceMode.byShift,
        title: 'By shift',
        subtitle: 'Named shifts',
      ),
      (
        mode: WalkInPriceMode.dayPrice,
        title: 'Day price',
        subtitle: 'One day rate',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 500 ? 4 : 2;
        final spacing = 7.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: _walkInModeOption(
                  config: config,
                  mode: option.mode,
                  title: option.title,
                  subtitle: option.subtitle,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _walkInModeOption({
    required SpacePriceSetup config,
    required WalkInPriceMode mode,
    required String title,
    required String subtitle,
  }) {
    final selected = config.walkInMode == mode;
    return Material(
      color: selected ? AppColors.homePaleGreen : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
        onTap: () => setState(() => config.walkInMode = mode),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.authGreen : AppColors.authBorder,
            ),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.authGreen : AppColors.authMuted,
                size: 15,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.authInk,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.authMuted,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hourSteps(SpacePriceSetup config) {
    return Column(
      children: [
        for (var index = 0; index < config.walkInSteps.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SetupQuantityInput(
                    valueKey: 'walk-in-until-hours-$index',
                    label: 'Up to hours',
                    value: config.walkInSteps[index].untilHours,
                    onChanged: (value) {
                      config.walkInSteps[index].untilHours = value;
                      _notifyPriceChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: AppTextStyles.authHelper.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 38,
                        child: _amountField(
                          'Price',
                          config.walkInSteps[index].price,
                          (value) => config.walkInSteps[index].price = value,
                          key: ValueKey('walk-in-step-price-$index'),
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: IconButton(
                    key: ValueKey('delete-walk-in-step-$index'),
                    tooltip: 'Delete price step ${index + 1}',
                    onPressed: () {
                      setState(() => config.walkInSteps.removeAt(index));
                      _notifyPriceChanged();
                    },
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () {
            setState(() => config.walkInSteps.add(WalkInStep()));
            _notifyPriceChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add price step'),
        ),
        _amountField(
          config.walkInSteps.isEmpty
              ? 'Price for more hours'
              : 'More than ${config.walkInSteps.last.untilHours} hours',
          config.moreHoursPrice,
          (value) => config.moreHoursPrice = value,
          key: const ValueKey('walk-in-more-price'),
        ),
      ],
    );
  }

  Widget _perHour(SpacePriceSetup config) {
    return Column(
      children: [
        _amountField(
          'Price per hour',
          config.hourlyPrice,
          (value) => config.hourlyPrice = value,
        ),
        _setupSwitch(
          title: 'Set a daily cap',
          value: config.hasDailyCap,
          onChanged: (value) => setState(() => config.hasDailyCap = value),
        ),
        if (config.hasDailyCap)
          _amountField(
            'Daily cap',
            config.dailyCap,
            (value) => config.dailyCap = value,
          ),
      ],
    );
  }

  Widget _shifts(SpacePriceSetup config) {
    return Column(
      children: [
        for (var index = 0; index < config.shifts.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                TextFormField(
                  initialValue: config.shifts[index].name,
                  onChanged: (value) {
                    config.shifts[index].name = value;
                    _notifyPriceChanged();
                  },
                  decoration: setupInputDecoration(hintText: 'Shift name'),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _timeField(
                        config.shifts[index].from,
                        (value) => config.shifts[index].from = value,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: _timeField(
                        config.shifts[index].to,
                        (value) => config.shifts[index].to = value,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _amountField(
                        'Price',
                        config.shifts[index].price,
                        (value) => config.shifts[index].price = value,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () =>
              setState(() => config.shifts.add(ShiftSetup(name: 'New shift'))),
          icon: const Icon(Icons.add),
          label: const Text('Add shift'),
        ),
      ],
    );
  }

  Widget _roomPrices(SpacePriceSetup config) {
    final setup = widget.setup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _amountField(
          'Price per hour',
          config.hourlyPrice,
          (value) => config.hourlyPrice = value,
        ),
        _setupSwitch(
          title: 'Price goes up with more people',
          value: config.hasPeopleTier,
          onChanged: (value) => setState(() => config.hasPeopleTier = value),
        ),
        if (config.hasPeopleTier) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 160,
                child: SetupQuantityInput(
                  valueKey: 'people-included',
                  label: 'Includes up to',
                  value: config.peopleIncluded,
                  onChanged: (value) {
                    config.peopleIncluded = value;
                    _notifyPriceChanged();
                  },
                ),
              ),
              SizedBox(
                width: 160,
                child: SetupQuantityInput(
                  valueKey: 'additional-people',
                  label: 'Every more people',
                  value: config.additionalPeople,
                  onChanged: (value) {
                    config.additionalPeople = value;
                    _notifyPriceChanged();
                  },
                ),
              ),
              SizedBox(
                width: 160,
                child: _amountField(
                  'Add / hour',
                  config.additionalPrice,
                  (value) => config.additionalPrice = value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: _priceRevision,
            builder: (context, _, _) => Text(
              'Example: ${config.peopleIncluded} included, then every '
              '${config.additionalPeople} more adds '
              '${config.additionalPrice.isEmpty ? '—' : '${config.additionalPrice} ${setup.country.currency}'}/hour.',
              style: const TextStyle(color: Color(0xFF737B75), fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _computerPrices(SpacePriceSetup config, SetupSpaceType type) {
    final count = int.tryParse(widget.setup.spaces[type]!.computerCount) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _setupSwitch(
          title: 'Set a different price for each computer',
          value: config.pricePerComputer,
          onChanged: (value) => setState(() => config.pricePerComputer = value),
        ),
        if (!config.pricePerComputer)
          _amountField(
            'Price per hour',
            config.hourlyPrice,
            (value) => config.hourlyPrice = value,
          )
        else
          for (var index = 0; index < count; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _amountField(
                _computerLabel(index),
                config.computerPrices[index] ?? '',
                (value) => config.computerPrices[index] = value,
              ),
            ),
      ],
    );
  }

  String _computerLabel(int index) {
    final space = widget.setup.spaces[SetupSpaceType.computers]!;
    if (space.computerNaming == 'Letters') {
      return 'Computer ${String.fromCharCode(65 + index)}';
    }
    if (space.computerNaming == 'Custom') {
      if (index < space.computerNames.length &&
          space.computerNames[index].trim().isNotEmpty) {
        return space.computerNames[index].trim();
      }
    }
    return 'Computer ${index + 1}';
  }

  Widget _monthlyDesks(SpacePriceSetup config) {
    return Column(
      children: [
        _setupSwitch(
          title: 'Offer monthly desks',
          value: config.monthlyDesksEnabled,
          onChanged: (value) =>
              setState(() => config.monthlyDesksEnabled = value),
        ),
        if (config.monthlyDesksEnabled)
          _amountField(
            'Monthly desk price',
            config.monthlyDeskPrice,
            (value) => config.monthlyDeskPrice = value,
          ),
      ],
    );
  }

  Widget _plans(SpacePriceSetup config, SetupSpaceType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Plans & packs',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          children: [
            for (final idea in _planIdeas(type))
              ActionChip(
                label: Text(idea),
                onPressed: () =>
                    setState(() => config.plans.add(PlanSetup(name: idea))),
              ),
          ],
        ),
        for (var index = 0; index < config.plans.length; index++)
          Padding(
            key: ObjectKey(config.plans[index]),
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: config.plans[index].name,
                        onChanged: (value) {
                          config.plans[index].name = value;
                          _notifyPriceChanged();
                        },
                        decoration: setupInputDecoration(hintText: 'Plan name'),
                      ),
                    ),
                    IconButton(
                      key: ValueKey('delete-plan-${type.name}-$index'),
                      tooltip: 'Delete plan',
                      onPressed: () =>
                          setState(() => config.plans.removeAt(index)),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _amountField(
                        'Price',
                        config.plans[index].price,
                        (value) => config.plans[index].price = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                          'plan-interval-${config.plans[index].interval}-$index',
                        ),
                        initialValue: config.plans[index].interval,
                        isExpanded: true,
                        decoration: setupInputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'one time',
                            child: Text('One time'),
                          ),
                          DropdownMenuItem(
                            value: 'day',
                            child: Text('Per day'),
                          ),
                          DropdownMenuItem(
                            value: 'week',
                            child: Text('Per week'),
                          ),
                          DropdownMenuItem(
                            value: 'month',
                            child: Text('Per month'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => config.plans[index].interval = value ?? 'month',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                TextFormField(
                  initialValue: config.plans[index].duration,
                  onChanged: (value) => config.plans[index].duration = value,
                  decoration: setupInputDecoration(
                    hintText: 'Days or hours included',
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => config.plans.add(PlanSetup())),
          icon: const Icon(Icons.add),
          label: const Text('Add a plan or pack'),
        ),
      ],
    );
  }

  List<String> _planIdeas(SetupSpaceType type) {
    return switch (type) {
      SetupSpaceType.sharedArea => ['10-day pass', 'Monthly desk', 'Week pass'],
      SetupSpaceType.rooms => ['5-hour pack', '10-hour pack', 'Full day'],
      SetupSpaceType.computers => ['5-hour pack', 'Day pass', 'Monthly access'],
      SetupSpaceType.privateOffices => ['Weekly office', 'Monthly office'],
      SetupSpaceType.virtualOffice => ['Starter', 'Business', 'Premium'],
      SetupSpaceType.other => ['5-use pack', 'Weekly pass', 'Monthly pass'],
    };
  }

  Widget _amountField(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    Key? key,
    bool compact = false,
  }) {
    return TextFormField(
      key: key,
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) {
        onChanged(value);
        _notifyPriceChanged();
      },
      decoration:
          setupInputDecoration(
            hintText: label,
            suffixText: widget.setup.country.currency,
          ).copyWith(
            contentPadding: compact
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
                : null,
          ),
    );
  }

  Widget _setupSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _timeField(String value, ValueChanged<String> onSelected) {
    return OutlinedButton(
      onPressed: () async {
        final time = await pickSetupTime(context, value);
        if (time != null) setState(() => onSelected(time));
      },
      child: Text(value),
    );
  }
}
