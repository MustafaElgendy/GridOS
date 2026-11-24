import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/data/workspace_repository.dart';

class SpaceCapacityInfo {
  const SpaceCapacityInfo({
    required this.type,
    required this.label,
    required this.capacity,
    required this.occupied,
    required this.free,
    required this.isFull,
  });

  final SetupSpaceType type;
  final String label;
  final int capacity;
  final int occupied;
  final int free;
  final bool isFull;
}

/// Service that computes space capacity and prevents adding customers
/// when a space has no free seats/rooms/places left.
class FrontDeskCapacityService {
  const FrontDeskCapacityService({
    required this.setup,
    required this.repository,
  });

  final StartupSetup setup;
  final WorkspaceRepository repository;

  int capacityFor(SetupSpaceType type) {
    switch (type) {
      case SetupSpaceType.sharedArea:
        final shared = setup.spaces[SetupSpaceType.sharedArea];
        if (shared == null || shared.sharedAreas.isEmpty) return 30;
        return shared.sharedAreas.fold<int>(
          0,
          (sum, area) => sum + (int.tryParse(area.chairs.trim()) ?? 0),
        );
      case SetupSpaceType.rooms:
        final rooms = setup.spaces[SetupSpaceType.rooms];
        return rooms?.rooms.length ?? 3;
      case SetupSpaceType.computers:
        final comps = setup.spaces[SetupSpaceType.computers];
        return int.tryParse(comps?.computerCount.trim() ?? '6') ?? 6;
      case SetupSpaceType.privateOffices:
        final offices = setup.spaces[SetupSpaceType.privateOffices];
        return offices?.offices.length ?? 0;
      case SetupSpaceType.virtualOffice:
      case SetupSpaceType.other:
        return 50;
    }
  }

  int occupiedCount(SetupSpaceType type) {
    return repository
        .activeVisits()
        .where((visit) => visit.spaceType == type)
        .length;
  }

  int freeCount(SetupSpaceType type) {
    final cap = capacityFor(type);
    final occ = occupiedCount(type);
    return (cap - occ).clamp(0, cap);
  }

  bool isSpaceFull(SetupSpaceType type) {
    final cap = capacityFor(type);
    if (cap <= 0) return true;
    return freeCount(type) <= 0;
  }

  SpaceCapacityInfo infoFor(SetupSpaceType type) {
    final cap = capacityFor(type);
    final occ = occupiedCount(type);
    final free = (cap - occ).clamp(0, cap);
    return SpaceCapacityInfo(
      type: type,
      label: type.label,
      capacity: cap,
      occupied: occ,
      free: free,
      isFull: cap > 0 && free <= 0,
    );
  }

  List<SpaceCapacityInfo> allConfiguredSpaces() {
    final selectedTypes = setup.selectedSpaces.isNotEmpty
        ? setup.selectedSpaces
        : {
            SetupSpaceType.sharedArea,
            if ((setup.spaces[SetupSpaceType.rooms]?.rooms.length ?? 0) > 0)
              SetupSpaceType.rooms,
            if ((int.tryParse(setup.spaces[SetupSpaceType.computers]?.computerCount ?? '0') ?? 0) > 0)
              SetupSpaceType.computers,
          };

    return selectedTypes.map(infoFor).toList();
  }
}
