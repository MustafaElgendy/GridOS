import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/front_desk/presentation/front_desk_page.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';

export 'package:grid_os/features/front_desk/presentation/front_desk_page.dart';

class WorkspaceFrontDeskPage extends StatelessWidget {
  const WorkspaceFrontDeskPage({
    super.key,
    required this.setup,
    required this.repository,
    required this.currency,
    required this.onChanged,
    required this.onOpenBookings,
    required this.onSwitchToOwner,
    required this.workingStaffPins,
    required this.ownerOnShift,
    required this.onStartShift,
    required this.onEndShift,
  });

  final StartupSetup setup;
  final WorkspaceRepository repository;
  final String currency;
  final VoidCallback onChanged;
  final VoidCallback onOpenBookings;
  final VoidCallback onSwitchToOwner;
  final Set<String> workingStaffPins;
  final bool ownerOnShift;
  final Future<void> Function({required String? pin, required bool isOwner})
      onStartShift;
  final Future<void> Function({required String? pin, required bool isOwner})
      onEndShift;

  @override
  Widget build(BuildContext context) {
    return FrontDeskPage(
      setup: setup,
      repository: repository,
      currency: currency,
      onChanged: onChanged,
      onSwitchToOwner: onSwitchToOwner,
      workingStaffPins: workingStaffPins,
      ownerOnShift: ownerOnShift,
      onStartShift: onStartShift,
      onEndShift: onEndShift,
      embedded: true,
    );
  }
}
