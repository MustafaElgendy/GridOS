import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';

import 'package:grid_os/Main Pages/dashboard_widgets.dart';

int _workspaceIdSequence = 0;

String newWorkspaceId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_workspaceIdSequence++}';

String formatWorkspaceDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$month/$day/${local.year}';
}

String formatWorkspaceTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

String formatWorkspaceAmount(double value, String currency) =>
    '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} $currency';

InputDecoration workspaceInputDecoration(String label, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      isDense: true,
    );

Widget workspacePageHeader(String title, String subtitle, {Widget? trailing}) =>
    DashboardPageHeader(title: title, subtitle: subtitle, trailing: trailing);

class WorkspaceSpaceOption {
  const WorkspaceSpaceOption({required this.type, required this.name});

  final SetupSpaceType type;
  final String name;
}

List<WorkspaceSpaceOption> workspaceSpaceOptions(StartupSetup setup) {
  final options = <WorkspaceSpaceOption>[];
  for (final type in setup.selectedSpaces) {
    final space = setup.spaces[type]!;
    final names = switch (type) {
      SetupSpaceType.sharedArea => [
        for (var index = 0; index < space.sharedAreas.length; index++)
          _displayName(space.sharedAreas[index].name, 'Area ${index + 1}'),
      ],
      SetupSpaceType.rooms => [
        for (var index = 0; index < space.rooms.length; index++)
          _displayName(space.rooms[index].name, 'Room ${index + 1}'),
      ],
      SetupSpaceType.computers => _computerNames(space),
      SetupSpaceType.privateOffices => [
        for (var index = 0; index < space.offices.length; index++)
          _displayName(space.offices[index].name, 'Office ${index + 1}'),
      ],
      SetupSpaceType.virtualOffice => [
        for (var index = 0; index < space.packages.length; index++)
          _displayName(space.packages[index].name, 'Package ${index + 1}'),
      ],
      SetupSpaceType.other => [
        for (var index = 0; index < space.otherItems.length; index++)
          _displayName(space.otherItems[index].name, 'Item ${index + 1}'),
      ],
    };
    if (names.isEmpty) {
      options.add(WorkspaceSpaceOption(type: type, name: type.label));
    } else {
      options.addAll([
        for (final name in names) WorkspaceSpaceOption(type: type, name: name),
      ]);
    }
  }
  return options;
}

String _displayName(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

List<String> _computerNames(SpaceSetup space) {
  final parsedCount = int.tryParse(space.computerCount) ?? 0;
  if (parsedCount <= 0) return const [];
  return List.generate(parsedCount, (index) {
    if (space.computerNaming == 'Custom' &&
        index < space.computerNames.length &&
        space.computerNames[index].trim().isNotEmpty) {
      return space.computerNames[index].trim();
    }
    return space.computerNaming == 'Letters'
        ? 'Computer ${_lettersFor(index)}'
        : 'Computer ${index + 1}';
  });
}

String _lettersFor(int index) {
  var number = index + 1;
  var result = '';
  while (number > 0) {
    number--;
    result = String.fromCharCode(65 + number % 26) + result;
    number ~/= 26;
  }
  return result;
}
