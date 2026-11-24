import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/theme/app_theme.dart';

class FrontDeskInNowTable extends StatefulWidget {
  const FrontDeskInNowTable({
    super.key,
    required this.visits,
    required this.repository,
    required this.currency,
    required this.onCheckOut,
    required this.onSelectVisit,
    required this.selectedVisitId,
    this.onNewCustomer,
  });

  final List<Visit> visits;
  final WorkspaceRepository repository;
  final String currency;
  final ValueChanged<Visit> onCheckOut;
  final ValueChanged<Visit> onSelectVisit;
  final String? selectedVisitId;
  final VoidCallback? onNewCustomer;

  @override
  State<FrontDeskInNowTable> createState() => _FrontDeskInNowTableState();
}

class _FrontDeskInNowTableState extends State<FrontDeskInNowTable> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDuration(DateTime checkedInAt) {
    final diff = DateTime.now().difference(checkedInAt);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours == 0) {
      return '$minutes min';
    }
    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  bool _isOverThreeHours(DateTime checkedInAt) {
    return DateTime.now().difference(checkedInAt).inHours >= 3;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = widget.visits.where((visit) {
      final customer = widget.repository.customerById(visit.customerId ?? '');
      final name = customer?.name.toLowerCase() ?? 'walk-in';
      final phone = customer?.phone?.toLowerCase() ?? '';
      final matchesQuery =
          query.isEmpty || name.contains(query) || phone.contains(query);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Shared area' &&
          visit.spaceType == SetupSpaceType.sharedArea) {
        return true;
      }
      if (_selectedFilter == 'Rooms' &&
          visit.spaceType == SetupSpaceType.rooms) {
        return true;
      }
      if (_selectedFilter == 'Computers' &&
          visit.spaceType == SetupSpaceType.computers) {
        return true;
      }
      return false;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppColors.authBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Search
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(
                  'In now · ${widget.visits.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authInk,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 15,
                          color: AppColors.authMuted,
                        ),
                        hintText: 'Find by name or phone to check out',
                        hintStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.authMuted,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 6),
                        filled: true,
                        fillColor: AppColors.authBackground,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadii.control),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _filterChip('All', 'All ${widget.visits.length}'),
                const SizedBox(width: 6),
                _filterChip(
                  'Shared area',
                  'Shared area ${widget.visits.where((v) => v.spaceType == SetupSpaceType.sharedArea).length}',
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'Rooms',
                  'Rooms ${widget.visits.where((v) => v.spaceType == SetupSpaceType.rooms).length}',
                ),
                const SizedBox(width: 6),
                _filterChip(
                  'Computers',
                  'Computers ${widget.visits.where((v) => v.spaceType == SetupSpaceType.computers).length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.authBorder),

          // Table
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      widget.visits.isEmpty
                          ? 'No one is checked in right now.'
                          : 'No matches found.',
                      style: const TextStyle(color: AppColors.authMuted, fontSize: 12),
                    ),
                    if (widget.visits.isEmpty && widget.onNewCustomer != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onNewCustomer,
                        child: const Text('Check in'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            _tableHeader(),
            const Divider(height: 1, color: AppColors.authBorder),
            for (final visit in filtered) ...[
              _tableRow(visit),
              const Divider(height: 1, color: AppColors.authBorder),
            ],
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final selected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.authInk : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? AppColors.authInk : AppColors.authBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.authInk,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    const style = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppColors.authMuted,
      letterSpacing: 0.3,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('CUSTOMER', style: style)),
          Expanded(flex: 3, child: Text('SPACE · PLAN', style: style)),
          Expanded(flex: 2, child: Text('IN AT', style: style)),
          Expanded(flex: 2, child: Text('TIME', style: style)),
          Expanded(flex: 2, child: Text('SO FAR', style: style)),
          SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _tableRow(Visit visit) {
    final customer = widget.repository.customerById(visit.customerId ?? '');
    final customerName = customer?.name ?? 'Walk-in';
    final customerVisits = customer != null
        ? widget.repository.visitsForCustomer(customer.id).length
        : 1;
    final isNew = customerVisits <= 1;
    final owes = (customer?.balance ?? 0) > 0;
    final isSelected = widget.selectedVisitId == visit.id;

    final spaceDisplay = (visit.spaceName?.isEmpty ?? true)
        ? (visit.spaceType?.label ?? 'General')
        : visit.spaceName!;

    return InkWell(
      onTap: () => widget.onSelectVisit(visit),
      child: Container(
        color: isSelected ? const Color(0xFFF7FAF8) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // CUSTOMER
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.authInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isNew
                              ? const Color(0xFFEBF3FB)
                              : const Color(0xFFF0F4F2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isNew ? 'New' : 'Returning · $customerVisits visits',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: isNew
                                ? const Color(0xFF1D64B2)
                                : AppColors.authMuted,
                          ),
                        ),
                      ),
                      if (owes) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'Owes ${customer!.balance.toStringAsFixed(0)} ${widget.currency}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB25E00),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // SPACE · PLAN
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spaceDisplay,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.authInk,
                    ),
                  ),
                  const Text(
                    'Walk-in',
                    style: TextStyle(fontSize: 9, color: AppColors.authMuted),
                  ),
                ],
              ),
            ),

            // IN AT
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(visit.checkedInAt),
                style: const TextStyle(fontSize: 11, color: AppColors.authInk),
              ),
            ),

            // TIME
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDuration(visit.checkedInAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.authInk),
                  ),
                  if (_isOverThreeHours(visit.checkedInAt))
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'Over 3 h',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB25E00),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // SO FAR
            Expanded(
              flex: 2,
              child: Text(
                '${visit.amount.toStringAsFixed(0)} ${widget.currency}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.authInk,
                ),
              ),
            ),

            // ACTION
            OutlinedButton(
              onPressed: () => widget.onCheckOut(visit),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(70, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: const BorderSide(color: AppColors.authBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
              child: const Text(
                'Check out',
                style: TextStyle(fontSize: 10, color: AppColors.authInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
