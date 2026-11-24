import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/prices_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/theme/app_theme.dart';

enum SpacesManagementTab { spaces, prices }

class WorkspaceSpacesManagementPage extends StatefulWidget {
  const WorkspaceSpacesManagementPage({
    super.key,
    required this.setup,
    required this.initialTab,
    required this.onChanged,
  });

  final StartupSetup setup;
  final SpacesManagementTab initialTab;
  final VoidCallback onChanged;

  @override
  State<WorkspaceSpacesManagementPage> createState() =>
      _WorkspaceSpacesManagementPageState();
}

class _WorkspaceSpacesManagementPageState
    extends State<WorkspaceSpacesManagementPage> {
  late SpacesManagementTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                const title = Text(
                  'Spaces & rooms',
                  style: TextStyle(
                    color: AppColors.authInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                );
                if (constraints.maxWidth >= 500) {
                  return Row(
                    children: [
                      const Expanded(child: title),
                      _spacesTabSelector(),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    _spacesTabSelector(),
                  ],
                );
              },
            ),
            const SizedBox(height: 17),
            Text(
              _tab == SpacesManagementTab.spaces ? 'Spaces' : 'Prices',
              style: AppTextStyles.workspaceTitle,
            ),
            const SizedBox(height: 3),
            Text(
              _tab == SpacesManagementTab.spaces
                  ? 'Spaces in ${widget.setup.city ?? widget.setup.country.name}. '
                        'Tick what customers can use; each one opens with its details. '
                        'Staff see changes on Today right away.'
                  : 'Set walk-in prices and optional plans for each space.',
              style: AppTextStyles.authHelper,
            ),
            const SizedBox(height: 12),
            if (_tab == SpacesManagementTab.spaces)
              SpacesPage(
                setup: widget.setup,
                embedded: true,
                onChanged: () {
                  widget.onChanged();
                  if (mounted) setState(() {});
                },
              )
            else
              PricesPage(setup: widget.setup, embedded: true),
          ],
        ),
      ),
    );
  }

  Widget _spacesTabSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.authBorder),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _spacesTabButton(SpacesManagementTab.spaces, 'Spaces'),
          _spacesTabButton(SpacesManagementTab.prices, 'Prices'),
        ],
      ),
    );
  }

  Widget _spacesTabButton(SpacesManagementTab tab, String label) {
    final selected = _tab == tab;
    return Material(
      color: selected ? AppColors.authGreen : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.control - 2),
      child: InkWell(
        key: ValueKey('spaces-tab-${tab.name}'),
        borderRadius: BorderRadius.circular(AppRadii.control - 2),
        onTap: () => setState(() => _tab = tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.authInk,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
