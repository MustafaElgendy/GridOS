import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

String spaceSummary(SetupSpaceType type, SpaceSetup space) {
  switch (type) {
    case SetupSpaceType.sharedArea:
      final chairs = space.sharedAreas.fold<int>(
        0,
        (total, area) => total + (int.tryParse(area.chairs) ?? 0),
      );
      final areaLabel = space.sharedAreas.length == 1 ? 'area' : 'areas';
      final chairLabel = chairs == 1 ? 'chair' : 'chairs';
      return '${space.sharedAreas.length} $areaLabel · $chairs $chairLabel';
    case SetupSpaceType.rooms:
      final seats = space.rooms.fold<int>(
        0,
        (total, room) => total + (int.tryParse(room.seats) ?? 0),
      );
      final roomLabel = space.rooms.length == 1 ? 'room' : 'rooms';
      final seatLabel = seats == 1 ? 'seat' : 'seats';
      return '${space.rooms.length} $roomLabel · $seats $seatLabel';
    case SetupSpaceType.computers:
      return '${space.computerCount} computers';
    case SetupSpaceType.privateOffices:
      final desks = space.offices.fold<int>(
        0,
        (total, office) => total + (int.tryParse(office.desks) ?? 0),
      );
      return '${space.offices.length} offices · $desks desks';
    case SetupSpaceType.virtualOffice:
      return '${space.packages.length} packages';
    case SetupSpaceType.other:
      return '${space.otherItems.length} items';
  }
}

class SetupProgressSummary extends StatelessWidget {
  const SetupProgressSummary({
    super.key,
    required this.setup,
    required this.activeStep,
    required this.onEditStep,
  });

  final StartupSetup setup;
  final int activeStep;
  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _stepCard(
        title: 'Workspace',
        step: 1,
        rows: _workspaceRows(),
      ),
      if (activeStep >= 2)
        _stepCard(
          title: 'Spaces',
          step: 2,
          rows: _spaceRows(),
        ),
      if (activeStep >= 3)
        _stepCard(
          title: 'Prices',
          step: 3,
          rows: _priceRows(),
        ),
      if (activeStep >= 4)
        _stepCard(
          title: 'Kitchen',
          step: 4,
          rows: _kitchenRows(),
        ),
      if (activeStep >= 5)
        _stepCard(
          title: 'Staff',
          step: 5,
          rows: _staffRows(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Your setup so far', style: AppTextStyles.authFieldLabel),
        const SizedBox(height: 3),
        const Text('Updates as you choose', style: AppTextStyles.authHelper),
        const SizedBox(height: 10),
        ...[
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            cards[index],
          ],
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.authGreen, size: 15),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _stepNote(activeStep),
                style: const TextStyle(
                  color: AppColors.authGreen,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepCard({
    required String title,
    required int step,
    required List<_SummaryRow> rows,
  }) {
    final active = step == activeStep;
    return _SummaryCard(
      title: title,
      step: step,
      active: active,
      trailing: active
          ? null
          : TextButton(
              onPressed: () => onEditStep(step),
              child: const Text('Edit'),
            ),
      rows: rows,
    );
  }

  List<_SummaryRow> _workspaceRows() {
    final location = [
      setup.city,
      if (setup.area.trim().isNotEmpty) setup.area.trim(),
      setup.country.name,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
    final phone = setup.phone.isEmpty
        ? 'Not added yet\nOnly our team sees it'
        : '${setup.country.phoneCode} ${setup.phone}';
    final hours = switch (setup.hoursMode) {
      SetupHoursMode.twentyFourHours => 'Open 24 hours',
      SetupHoursMode.sameEveryDay =>
        'Every day · ${_formatTime(setup.opensAt)} – ${_formatTime(setup.closesAt)}',
      SetupHoursMode.perDay => 'Custom hours',
    };
    return [
      _SummaryRow(
        label: 'Name',
        value: setup.workspaceName.isEmpty ? 'Not added yet' : setup.workspaceName,
      ),
      _SummaryRow(
        label: 'Location',
        value: location.isEmpty ? 'Not added yet' : location,
      ),
      _SummaryRow(label: 'Phone', value: phone),
      _SummaryRow(label: 'Hours', value: hours, isLast: true),
    ];
  }

  List<_SummaryRow> _spaceRows() {
    final selectedSpaces = setup.selectedSpaces;
    return [
      for (var index = 0; index < selectedSpaces.length; index++)
        _SummaryRow(
          label: selectedSpaces[index].label,
          value: spaceSummary(
            selectedSpaces[index],
            setup.spaces[selectedSpaces[index]]!,
          ),
          isLast: index == selectedSpaces.length - 1,
        ),
      if (selectedSpaces.isEmpty)
        const _SummaryRow(
          label: 'Spaces',
          value: 'Choose what you offer',
          isLast: true,
        ),
    ];
  }

  List<_SummaryRow> _priceRows() {
    final spaces = setup.selectedSpaces;
    return [
      for (var index = 0; index < spaces.length; index++)
        _SummaryRow(
          label: spaces[index].label,
          value: _priceSummary(spaces[index]),
          isLast: index == spaces.length - 1,
        ),
      if (spaces.isEmpty)
        const _SummaryRow(
          label: 'Prices',
          value: 'Add a space first',
          isLast: true,
        ),
    ];
  }

  String _priceSummary(SetupSpaceType type) {
    final price = setup.prices[type]!;
    final currency = setup.country.currency;
    if (type == SetupSpaceType.rooms) {
      final hourly = '${_priceAmount(price.hourlyPrice)} / hour';
      if (!price.hasPeopleTier) return hourly;
      return '$hourly · up to ${price.peopleIncluded} people, then '
          '+${price.additionalPrice} $currency per ${price.additionalPeople} more';
    }
    if (type == SetupSpaceType.computers) {
      if (price.pricePerComputer) return 'Individual computer prices';
      return '${_priceAmount(price.hourlyPrice)} / hour';
    }

    final walkIn = switch (price.walkInMode) {
      WalkInPriceMode.byHours => [
        for (final step in price.walkInSteps)
          'Up to ${step.untilHours} h · ${_priceAmount(step.price)}',
        'More hours · ${_priceAmount(price.moreHoursPrice)}',
      ].join('\n'),
      WalkInPriceMode.perHour =>
        '${_priceAmount(price.hourlyPrice)} / hour'
            '${price.hasDailyCap ? ' · cap ${_priceAmount(price.dailyCap)}' : ''}',
      WalkInPriceMode.byShift =>
        price.shifts
            .map((shift) => '${shift.name} · ${_priceAmount(shift.price)}')
            .join('\n'),
      WalkInPriceMode.dayPrice =>
        '${_priceAmount(price.dayPrice)} / day',
    };
    final plans = price.plans.where((plan) => plan.name.trim().isNotEmpty).length;
    final monthlyDesk = type == SetupSpaceType.sharedArea &&
            price.monthlyDesksEnabled
        ? '\nMonthly desk · ${_priceAmount(price.monthlyDeskPrice)}'
        : '';
    return '$walkIn$monthlyDesk'
        '${plans == 0 ? '' : '\n$plans plans & packs'}';
  }

  String _priceAmount(String value) =>
      value.isEmpty ? 'Not set' : '$value ${setup.country.currency}';

  List<_SummaryRow> _kitchenRows() {
    final items = setup.kitchenItems
        .where(
          (item) =>
              item.name.trim().isNotEmpty ||
              item.price.trim().isNotEmpty ||
              item.quantity.trim().isNotEmpty ||
              item.costsYou.trim().isNotEmpty,
        )
        .toList();
    return [
      for (var index = 0; index < items.length; index++)
        _SummaryRow(
          label: items[index].name.trim().isEmpty
              ? 'Item ${index + 1}'
              : items[index].name,
          value: [
            if (items[index].price.isNotEmpty)
              '${items[index].price} ${setup.country.currency}',
            if (items[index].quantity.isNotEmpty)
              'Qty ${items[index].quantity}',
            if (items[index].costsYou.isNotEmpty)
              'Cost ${items[index].costsYou} ${setup.country.currency}',
          ].join(' · '),
          isLast: index == items.length - 1,
        ),
      if (items.isEmpty)
        const _SummaryRow(
          label: 'Kitchen',
          value: 'Nothing yet\nYou can skip this and add it later from Products',
          isLast: true,
        ),
    ];
  }

  List<_SummaryRow> _staffRows() => [
    _SummaryRow(label: 'Owner', value: '${setup.ownerName} · You'),
    for (var index = 0; index < setup.staff.length; index++)
      _SummaryRow(
        label: 'Staff ${index + 1}',
        value: setup.staff[index].name,
        isLast: index == setup.staff.length - 1,
      ),
    if (setup.staff.isEmpty)
      const _SummaryRow(label: 'Staff', value: 'None added', isLast: true),
  ];

  String _stepNote(int step) => switch (step) {
    1 =>
      'Opening hours decide when staff can book rooms. You can change them later.',
    2 =>
      'Only tick what you have today. You can add more spaces later in Settings.',
    3 => 'These are the prices staff see at check-in. Plans and packs are optional.',
    4 =>
      'Without this list, staff can’t put a coffee on the bill, so that money goes unrecorded. You can add or change items any time from Products.',
    _ => 'Staff PINs are private. You can manage the team later in Settings.',
  };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.step,
    required this.rows,
    this.active = false,
    this.trailing,
  });

  final String title;
  final int step;
  final bool active;
  final List<Widget> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: active ? AppColors.authGreen : AppColors.authBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.homePaleGreen : AppColors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.control - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  active ? Icons.radio_button_checked : Icons.check_circle,
                  color: AppColors.authGreen,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP $step INFO',
                        style: const TextStyle(
                          color: AppColors.authMuted,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.authInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
                if (active)
                  const Text(
                    'Filling in now',
                    style: TextStyle(
                      color: AppColors.authGreen,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.authBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(label, style: AppTextStyles.authHelper),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.authInk,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpaceEntryCard extends StatelessWidget {
  const SpaceEntryCard({
    super.key,
    required this.child,
    required this.onDelete,
    required this.deleteTooltip,
    this.deleteKey,
  });

  final Widget child;
  final VoidCallback onDelete;
  final String deleteTooltip;
  final Key? deleteKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: child),
          IconButton(
            key: deleteKey,
            onPressed: onDelete,
            tooltip: deleteTooltip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 19),
          ),
        ],
      ),
    );
  }
}

class SpaceDetailsEditor extends StatelessWidget {
  const SpaceDetailsEditor({
    super.key,
    required this.type,
    required this.space,
    required this.onChanged,
    required this.onStructureChanged,
  });

  final SetupSpaceType type;
  final SpaceSetup space;
  final VoidCallback onChanged;
  final VoidCallback onStructureChanged;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SetupSpaceType.sharedArea:
        return _sharedAreas(context);
      case SetupSpaceType.rooms:
        return _rooms(context);
      case SetupSpaceType.computers:
        return _computers(context);
      case SetupSpaceType.privateOffices:
        return _privateOffice(context);
      case SetupSpaceType.virtualOffice:
        return _virtualOffice(context);
      case SetupSpaceType.other:
        return _other(context);
    }
  }

  Widget _sharedAreas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('How many chairs?', style: AppTextStyles.authFieldLabel),
        const SizedBox(height: 3),
        const Text(
          'Count every chair, including the ones you’ll rent as monthly desks.',
          style: AppTextStyles.authHelper,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < space.sharedAreas.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SpaceEntryCard(
              key: ValueKey('shared-area-entry-$index'),
              deleteKey: ValueKey('delete-shared-area-$index'),
              deleteTooltip: 'Delete area ${index + 1}',
              onDelete: () {
                space.sharedAreas.removeAt(index);
                onStructureChanged();
              },
              child: _spaceItemFields(
                context,
                first: setupTextField(
                  key: ValueKey('shared-area-name-$index'),
                  label: 'Area name',
                  initialValue: space.sharedAreas[index].name,
                  onChanged: (value) {
                    space.sharedAreas[index].name = value;
                    onChanged();
                  },
                ),
                second: SetupQuantityInput(
                  valueKey: 'shared-chairs-$index',
                  label: 'Chairs',
                  value: space.sharedAreas[index].chairs,
                  showLabel: false,
                  onChanged: (value) {
                    space.sharedAreas[index].chairs = value;
                    onChanged();
                  },
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'A desk you rent for the month takes one of these.',
          style: AppTextStyles.authHelper,
        ),
        TextButton(
          key: const ValueKey('add-shared-area'),
          onPressed: () {
            space.sharedAreas.add(
              SharedAreaSetup(name: 'Area ${space.sharedAreas.length + 1}'),
            );
            onStructureChanged();
          },
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          child: const Text('+ Add another area, like a quiet zone'),
        ),
      ],
    );
  }

  Widget _rooms(BuildContext context) {
    const ideas = [
      'Meeting room',
      'Creator studio',
      'Training room',
      'Phone booth',
      'Other',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add each room or studio and how many people fit in it.',
          style: AppTextStyles.authHelper,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < space.rooms.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SpaceEntryCard(
              key: ValueKey('room-entry-$index'),
              deleteKey: ValueKey('delete-room-$index'),
              deleteTooltip: 'Delete room ${index + 1}',
              onDelete: () {
                space.rooms.removeAt(index);
                onStructureChanged();
              },
              child: _spaceItemFields(
                context,
                first: setupTextField(
                  key: ValueKey('room-name-$index'),
                  label: 'Name',
                  initialValue: space.rooms[index].name,
                  onChanged: (value) {
                    space.rooms[index].name = value;
                    onChanged();
                  },
                ),
                second: SetupQuantityInput(
                  valueKey: 'room-seats-$index',
                  label: 'Seats',
                  value: space.rooms[index].seats,
                  onChanged: (value) {
                    space.rooms[index].seats = value;
                    onChanged();
                  },
                ),
              ),
            ),
          ),
        Wrap(
          spacing: 5,
          children: [
            for (final idea in ideas)
              ActionChip(
                label: Text(idea),
                onPressed: () {
                  space.rooms.add(
                    RoomSetup(
                      name: idea,
                      seats: idea == 'Phone booth' ? '1' : '',
                    ),
                  );
                  onStructureChanged();
                },
              ),
          ],
        ),
        TextButton(
          onPressed: () {
            space.rooms.add(RoomSetup(name: '', seats: ''));
            onStructureChanged();
          },
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          child: const Text('+ Add an empty room'),
        ),
      ],
    );
  }

  Widget _computers(BuildContext context) {
    final computerCount = int.tryParse(space.computerCount) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupQuantityInput(
          valueKey: 'computer-count',
          label: 'Number of computers',
          value: space.computerCount,
          onChanged: (value) {
            space.computerCount = value;
            _resizeComputerNames(int.tryParse(value) ?? 0);
            onStructureChanged();
          },
        ),
        const SizedBox(height: 10),
        const Text('Name them (optional)', style: AppTextStyles.authHelper),
        DropdownButton<String>(
          value: space.computerNaming,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'Numbers', child: Text('1, 2, 3…')),
            DropdownMenuItem(value: 'Letters', child: Text('A, B, C…')),
            DropdownMenuItem(value: 'Custom', child: Text('Our own names')),
          ],
          onChanged: (value) {
            final naming = value ?? 'Numbers';
            if (naming == 'Custom') _resizeComputerNames(computerCount);
            space.computerNaming = naming;
            onStructureChanged();
          },
        ),
        if (space.computerNaming == 'Custom') ...[
          const SizedBox(height: 8),
          for (var index = 0; index < computerCount; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: setupTextField(
                key: ValueKey('computer-name-$index'),
                label: 'Computer ${index + 1} name',
                initialValue: index < space.computerNames.length
                    ? space.computerNames[index]
                    : '',
                hintText: 'e.g. Front desk',
                onChanged: (value) {
                  _resizeComputerNames(computerCount);
                  space.computerNames[index] = value;
                  onChanged();
                },
              ),
            ),
        ],
      ],
    );
  }

  void _resizeComputerNames(int count) {
    if (space.computerNames.length > count) {
      space.computerNames = space.computerNames.take(count).toList();
    } else {
      space.computerNames.addAll(
        List<String>.filled(count - space.computerNames.length, ''),
      );
    }
  }

  Widget _privateOffice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Add each office and how many desks are inside.',
          style: AppTextStyles.authHelper,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < space.offices.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SpaceEntryCard(
              key: ValueKey('office-entry-$index'),
              deleteKey: ValueKey('delete-office-$index'),
              deleteTooltip: 'Delete office ${index + 1}',
              onDelete: () {
                space.offices.removeAt(index);
                onStructureChanged();
              },
              child: _spaceItemFields(
                context,
                first: setupTextField(
                  key: ValueKey('office-name-$index'),
                  label: 'Office name',
                  initialValue: space.offices[index].name,
                  onChanged: (value) {
                    space.offices[index].name = value;
                    onChanged();
                  },
                ),
                second: SetupQuantityInput(
                  valueKey: 'office-desks-$index',
                  label: 'Desks inside',
                  value: space.offices[index].desks,
                  onChanged: (value) {
                    space.offices[index].desks = value;
                    onChanged();
                  },
                ),
              ),
            ),
          ),
        _addButton(
          label: '+ Add an office',
          onPressed: () {
            space.offices.add(
              PrivateOfficeSetup(name: 'Office ${space.offices.length + 1}'),
            );
            onStructureChanged();
          },
        ),
      ],
    );
  }

  Widget _virtualOffice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < space.packages.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VirtualPackageCard(
              key: ValueKey('virtual-package-$index'),
              index: index,
              package: space.packages[index],
              onChanged: onChanged,
              onDelete: () {
                space.packages.removeAt(index);
                onStructureChanged();
              },
            ),
          ),
        _addButton(
          label: '+ Add another package, like address only',
          onPressed: () {
            space.packages.add(
              VirtualPackageSetup(
                name: 'Address only',
                included: {'Business address'},
              ),
            );
            onStructureChanged();
          },
        ),
      ],
    );
  }

  Widget _other(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Lockers, parking spots… anything else customers pay to use.',
          style: AppTextStyles.authHelper,
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < space.otherItems.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SpaceEntryCard(
              key: ValueKey('other-entry-$index'),
              deleteKey: ValueKey('delete-other-item-$index'),
              deleteTooltip: 'Delete item ${index + 1}',
              onDelete: () {
                space.otherItems.removeAt(index);
                onStructureChanged();
              },
              child: Column(
                children: [
                  _spaceItemFields(
                    context,
                    first: setupTextField(
                      key: ValueKey('other-name-$index'),
                      label: 'What is it?',
                      initialValue: space.otherItems[index].name,
                      hintText: 'e.g. Locker, Parking spot',
                      onChanged: (value) {
                        space.otherItems[index].name = value;
                        onChanged();
                      },
                    ),
                    second: DropdownButtonFormField<String>(
                      key: ValueKey(
                        'other-period-$index-${space.otherItems[index].chargePeriod}',
                      ),
                      initialValue: space.otherItems[index].chargePeriod,
                      decoration: setupInputDecoration(hintText: 'Charged'),
                      items: const [
                        DropdownMenuItem(
                          value: 'hour',
                          child: Text('By the hour'),
                        ),
                        DropdownMenuItem(
                          value: 'day',
                          child: Text('By the day'),
                        ),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('By the month'),
                        ),
                      ],
                      onChanged: (value) {
                        space.otherItems[index].chargePeriod = value ?? 'day';
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SetupQuantityInput(
                      valueKey: 'other-quantity-$index',
                      label: 'How many?',
                      value: space.otherItems[index].quantity,
                      onChanged: (value) {
                        space.otherItems[index].quantity = value;
                        onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        _addButton(
          label: '+ Add another',
          onPressed: () {
            space.otherItems.add(OtherSpaceSetup());
            onStructureChanged();
          },
        ),
      ],
    );
  }

  Widget _addButton({required String label, required VoidCallback onPressed}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.authGreen,
          side: const BorderSide(color: AppColors.authGreen),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _spaceItemFields(
    BuildContext context, {
    required Widget first,
    required Widget second,
  }) {
    if (MediaQuery.sizeOf(context).width < 520) {
      return Column(children: [first, const SizedBox(height: 8), second]);
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ],
    );
  }
}

class _VirtualPackageCard extends StatefulWidget {
  const _VirtualPackageCard({
    super.key,
    required this.index,
    required this.package,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final VirtualPackageSetup package;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_VirtualPackageCard> createState() => _VirtualPackageCardState();
}

class _VirtualPackageCardState extends State<_VirtualPackageCard> {
  late final TextEditingController _customIncludeController;

  static const _includedOptions = [
    'Business address',
    'Mail & packages',
    'Phone number',
    'Call answering',
    'Address for company papers',
    'Meeting room hours',
  ];

  @override
  void initState() {
    super.initState();
    _customIncludeController = TextEditingController(
      text: widget.package.customIncludedDraft,
    );
  }

  @override
  void dispose() {
    _customIncludeController.dispose();
    super.dispose();
  }

  void _addCustomIncluded() {
    final included = _customIncludeController.text.trim();
    if (included.isEmpty) return;
    widget.package.included.add(included);
    widget.package.customIncludedDraft = '';
    _customIncludeController.clear();
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final includedOptions = [
      ..._includedOptions,
      for (final option in widget.package.included)
        if (!_includedOptions.contains(option)) option,
    ];
    return SpaceEntryCard(
      deleteKey: ValueKey('delete-virtual-package-${widget.index}'),
      onDelete: widget.onDelete,
      deleteTooltip: 'Delete package',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          setupTextField(
            key: ValueKey('virtual-package-name-${widget.index}'),
            label: 'Package name',
            initialValue: widget.package.name,
            onChanged: (value) {
              widget.package.name = value;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'What’s included? Tap to pick.',
            style: AppTextStyles.authHelper,
          ),
          SetupChoiceChips(
            options: includedOptions,
            selected: widget.package.included,
            onSelected: (value) {
              setState(() {
                final included = widget.package.included;
                if (!included.add(value)) included.remove(value);
              });
              widget.onChanged();
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('virtual-custom-included-${widget.index}'),
                  controller: _customIncludeController,
                  onChanged: (value) =>
                      widget.package.customIncludedDraft = value,
                  onSubmitted: (_) => _addCustomIncluded(),
                  decoration: setupInputDecoration(
                    hintText: 'Add your own, e.g. Printing 20 pages',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: _addCustomIncluded,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(String time) {
  final parts = time.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}
