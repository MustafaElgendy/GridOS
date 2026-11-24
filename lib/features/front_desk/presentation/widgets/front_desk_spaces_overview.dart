import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskSpacesOverview extends StatelessWidget {
  const FrontDeskSpacesOverview({
    super.key,
    required this.setup,
    required this.repository,
  });

  final StartupSetup setup;
  final WorkspaceRepository repository;

  @override
  Widget build(BuildContext context) {
    final visits = repository.activeVisits();
    final cards = <Widget>[];

    // Shared area card (only if configured)
    final hasShared = setup.selectedSpaces.contains(SetupSpaceType.sharedArea) ||
        setup.spaces[SetupSpaceType.sharedArea]?.selected == true;
    if (hasShared) {
      final sharedChairs = int.tryParse(
            setup.spaces[SetupSpaceType.sharedArea]?.sharedAreas.fold<int>(
                  0,
                  (prev, element) =>
                      prev + (int.tryParse(element.chairs.trim()) ?? 0),
                )
                .toString() ??
                '30',
          ) ??
          30;
      final sharedOccupied = visits
          .where((v) => v.spaceType == SetupSpaceType.sharedArea)
          .length;
      final sharedFree = (sharedChairs - sharedOccupied).clamp(0, sharedChairs);
      cards.add(
        _spaceCard(
          title: 'Shared area',
          metric: '$sharedFree of $sharedChairs free',
          ratio: sharedChairs == 0 ? 0 : sharedOccupied / sharedChairs,
          subtitle: sharedOccupied > 0
              ? '$sharedOccupied seats taken'
              : 'All seats free',
        ),
      );
    }

    // Rooms card (only if configured)
    final hasRooms = setup.selectedSpaces.contains(SetupSpaceType.rooms) ||
        setup.spaces[SetupSpaceType.rooms]?.selected == true;
    if (hasRooms) {
      final roomCount = setup.spaces[SetupSpaceType.rooms]?.rooms.length ?? 0;
      if (roomCount > 0) {
        final roomsOccupied =
            visits.where((v) => v.spaceType == SetupSpaceType.rooms).length;
        final roomsFree = (roomCount - roomsOccupied).clamp(0, roomCount);
        cards.add(
          _spaceCard(
            title: 'Rooms',
            metric: '$roomsFree of $roomCount free',
            ratio: roomCount == 0 ? 0 : roomsOccupied / roomCount,
            subtitle: roomsOccupied > 0
                ? '$roomsOccupied in use'
                : 'All rooms free',
          ),
        );
      }
    }

    // Computers card (only if configured)
    final hasComputers =
        setup.selectedSpaces.contains(SetupSpaceType.computers) ||
            setup.spaces[SetupSpaceType.computers]?.selected == true;
    if (hasComputers) {
      final computerCount = int.tryParse(
            setup.spaces[SetupSpaceType.computers]?.computerCount.trim() ?? '0',
          ) ??
          0;
      if (computerCount > 0) {
        final computersOccupied = visits
            .where((v) => v.spaceType == SetupSpaceType.computers)
            .length;
        final computersFree =
            (computerCount - computersOccupied).clamp(0, computerCount);
        cards.add(
          _spaceCard(
            title: 'Computers',
            metric: '$computersFree of $computerCount free',
            ratio: computerCount == 0 ? 0 : computersOccupied / computerCount,
            subtitle: computersOccupied > 0
                ? '$computersOccupied in use'
                : 'All PCs ready',
          ),
        );
      }
    }

    // Private offices card (only if configured)
    final hasOffices =
        setup.selectedSpaces.contains(SetupSpaceType.privateOffices) ||
            setup.spaces[SetupSpaceType.privateOffices]?.selected == true;
    if (hasOffices) {
      final officeCount =
          setup.spaces[SetupSpaceType.privateOffices]?.offices.length ?? 0;
      if (officeCount > 0) {
        final occupied = visits
            .where((v) => v.spaceType == SetupSpaceType.privateOffices)
            .length;
        final free = (officeCount - occupied).clamp(0, officeCount);
        cards.add(
          _spaceCard(
            title: 'Private offices',
            metric: '$free of $officeCount free',
            ratio: officeCount == 0 ? 0 : occupied / officeCount,
            subtitle: occupied > 0 ? '$occupied in use' : 'All offices free',
          ),
        );
      }
    }

    if (cards.isEmpty) {
      // Default to shared area if nothing explicitly set yet
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = cards.isEmpty ? 1 : cards.length;
        final double cardWidth;
        if (constraints.maxWidth < 420) {
          cardWidth = constraints.maxWidth;
        } else if (constraints.maxWidth < 650) {
          cardWidth = (constraints.maxWidth - 9) / 2;
        } else {
          cardWidth = (constraints.maxWidth - ((count - 1) * 9)) / count;
        }

        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth.clamp(120.0, 500.0),
                child: card,
              ),
          ],
        );
      },
    );
  }

  Widget _spaceCard({
    required String title,
    required String metric,
    required double ratio,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.authBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authInk,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.authMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metric,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.authInk,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFE8ECE9),
              color: ratio > 0.85 ? AppColors.error : AppColors.authGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.authMuted,
            ),
          ),
        ],
      ),
    );
  }
}
