import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/prices_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/preview_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

class SpacesPage extends StatefulWidget {
  const SpacesPage({
    super.key,
    required this.setup,
    this.embedded = false,
    this.onChanged,
  });

  final StartupSetup setup;
  final bool embedded;
  final VoidCallback? onChanged;

  @override
  State<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends State<SpacesPage> {
  SetupSpaceType? _expanded = SetupSpaceType.sharedArea;
  final Map<SetupSpaceType, String> _issues = {};
  final Map<SetupSpaceType, GlobalKey> _cardKeys = {};
  final ValueNotifier<int> _spacesRevision = ValueNotifier(0);
  bool _needsSelection = false;

  @override
  void dispose() {
    _spacesRevision.dispose();
    super.dispose();
  }

  void _refreshSummary() {
    _spacesRevision.value++;
    widget.onChanged?.call();
  }

  void _refreshStructure() {
    setState(() {});
    widget.onChanged?.call();
  }

  int? _positive(String value) {
    final count = int.tryParse(value);
    return count != null && count > 0 ? count : null;
  }

  String? _validate(SetupSpaceType type) {
    final space = widget.setup.spaces[type]!;
    switch (type) {
      case SetupSpaceType.sharedArea:
        if (space.sharedAreas.isEmpty ||
            space.sharedAreas.any((area) => _positive(area.chairs) == null)) {
          return 'Add the number of chairs in each area.';
        }
      case SetupSpaceType.rooms:
        if (space.rooms.isEmpty ||
            space.rooms.any(
              (room) =>
                  room.name.trim().isEmpty || _positive(room.seats) == null,
            )) {
          return 'Add a name and the number of seats for each room.';
        }
      case SetupSpaceType.computers:
        if (_positive(space.computerCount) == null) {
          return 'Enter how many computers you have.';
        }
      case SetupSpaceType.privateOffices:
        if (space.offices.isEmpty ||
            space.offices.any(
              (office) =>
                  office.name.trim().isEmpty || _positive(office.desks) == null,
            )) {
          return 'Add a name and desk count for each office.';
        }
      case SetupSpaceType.virtualOffice:
        if (space.packages.isEmpty ||
            space.packages.any((package) => package.name.trim().isEmpty)) {
          return 'Name each virtual office package.';
        }
      case SetupSpaceType.other:
        if (space.otherItems.isEmpty ||
            space.otherItems.any(
              (item) =>
                  item.name.trim().isEmpty || _positive(item.quantity) == null,
            )) {
          return 'Add a name and quantity for each item.';
        }
    }
    return null;
  }

  void _toggle(SetupSpaceType type) {
    setState(() {
      _expanded = _expanded == type ? null : type;
      _issues.remove(type);
    });
  }

  void _finishCard(SetupSpaceType type) {
    final issue = _validate(type);
    setState(() {
      if (issue == null) {
        _issues.remove(type);
      } else {
        _issues[type] = issue;
      }
      _expanded = null;
    });
  }

  void _continue() {
    final selectedSpaces = widget.setup.selectedSpaces;
    if (selectedSpaces.isEmpty) {
      setState(() => _needsSelection = true);
      return;
    }
    for (final type in selectedSpaces) {
      final issue = _validate(type);
      if (issue == null) continue;
      setState(() {
        _issues[type] = issue;
        _expanded = type;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cardContext = _cardKeys[type]?.currentContext;
        if (cardContext != null) {
          Scrollable.ensureVisible(
            cardContext,
            duration: const Duration(milliseconds: 250),
            alignment: .1,
          );
        }
      });
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PricesPage(setup: widget.setup)),
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
    if (widget.embedded) return _spaceCards();

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            SetupProgressAppBar(
              workspaceName: widget.setup.workspaceName,
              step: 2,
              onBack: () => Navigator.of(context).pop(),
              onFinishLater: _finishLater,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  return SingleChildScrollView(
                    key: const PageStorageKey<String>('spaces-setup'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 28 : 16,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1050),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _pageHeading(),
                                        _spaceCards(),
                                        _bottomActions(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: ValueListenableBuilder<int>(
                                      valueListenable: _spacesRevision,
                                      builder: (context, _, _) {
                                        return SetupProgressSummary(
                                          setup: widget.setup,
                                          activeStep: 2,
                                          onEditStep: (step) =>
                                              returnToSetupStep(
                                                context,
                                                currentStep: 2,
                                                targetStep: step,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _pageHeading(),
                                  _spaceCards(),
                                  const SizedBox(height: 8),
                                  ValueListenableBuilder<int>(
                                    valueListenable: _spacesRevision,
                                    builder: (context, _, _) {
                                      return SetupProgressSummary(
                                        setup: widget.setup,
                                        activeStep: 2,
                                        onEditStep: (step) => returnToSetupStep(
                                          context,
                                          currentStep: 2,
                                          targetStep: step,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _bottomActions(),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageHeading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STEP 2 OF 5',
            style: TextStyle(
              color: AppColors.authGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 5),
          const Text('Your spaces', style: AppTextStyles.authHeading),
          const SizedBox(height: 4),
          const Text(
            'Tick what customers can use here. Each one opens so you can add its details.',
            style: AppTextStyles.authDescription,
          ),
        ],
      ),
    );
  }

  Widget _spaceCards() {
    return Column(
      children: [
        if (_needsSelection)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose at least one type of space.',
                style: TextStyle(color: Color(0xFFB05D00), fontSize: 12),
              ),
            ),
          ),
        for (final type in SetupSpaceType.values) _spaceCard(type),
      ],
    );
  }

  Widget _spaceCard(SetupSpaceType type) {
    final space = widget.setup.spaces[type]!;
    final expanded = _expanded == type;
    final issue = _issues[type];
    return Container(
      key: _cardKeys.putIfAbsent(type, () => GlobalKey()),
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: space.selected ? AppColors.authGreen : AppColors.authBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 5, 10, 5),
            child: Row(
              children: [
                Checkbox(
                  value: space.selected,
                  onChanged: (selected) {
                    setState(() {
                      space.selected = selected ?? false;
                      _issues.remove(type);
                      _needsSelection = false;
                    });
                    widget.onChanged?.call();
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _toggle(type),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.label, style: AppTextStyles.authFieldLabel),
                          if (!expanded)
                            Text(
                              space.selected
                                  ? spaceSummary(type, space)
                                  : _subtitle(type),
                              style: AppTextStyles.authHelper,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggle(type),
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: expanded ? 'Fold' : 'Unfold',
                ),
                if (!expanded && space.selected)
                  TextButton(
                    onPressed: () => _toggle(type),
                    child: const Text('Edit'),
                  ),
              ],
            ),
          ),
          if (expanded && space.selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 2, 15, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SpaceDetailsEditor(
                    type: type,
                    space: space,
                    onChanged: _refreshSummary,
                    onStructureChanged: _refreshStructure,
                  ),
                  if (issue != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      issue,
                      style: const TextStyle(
                        color: Color(0xFFB05D00),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () => _finishCard(type),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            )
          else if (issue != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  issue,
                  style: const TextStyle(
                    color: Color(0xFFB05D00),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle(SetupSpaceType type) {
    return switch (type) {
      SetupSpaceType.sharedArea => 'Chairs anyone can sit in',
      SetupSpaceType.rooms => 'Booked by the hour',
      SetupSpaceType.computers => 'Used by the hour',
      SetupSpaceType.privateOffices => 'Rented by the month',
      SetupSpaceType.virtualOffice => 'Address and mail, monthly',
      SetupSpaceType.other => 'Lockers, parking…',
    };
  }

  Widget _bottomActions() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 15),
          label: const Text('Back'),
        ),
        const Spacer(),
        FilledButton(
          key: const ValueKey('spaces-continue'),
          onPressed: _continue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
