import 'package:flutter/material.dart';

import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/features/workspace/data/workspace_repository.dart';
import 'package:grid_os/features/workspace/domain/workspace_models.dart';

/// Clean model representing a search hit when searching customers from the front desk.
/// Designed for easy serialization/deserialization with REST or GraphQL APIs.
class FrontDeskCustomerSearchResult {
  const FrontDeskCustomerSearchResult({
    required this.customer,
    required this.isInsideNow,
    this.activeVisit,
    this.upcomingBooking,
    required this.badgeLabel,
    required this.isBadgeSuccess,
    required this.subtitle,
  });

  final Customer customer;
  final bool isInsideNow;
  final Visit? activeVisit;
  final Booking? upcomingBooking;
  final String badgeLabel;
  final bool isBadgeSuccess;
  final String subtitle;

  String get initials {
    final clean = customer.name.trim();
    if (clean.isEmpty) return 'CU';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Abstract API-ready customer search service interface.
/// Clean Architecture allows swapping with HTTP API client without changing the UI.
abstract class FrontDeskSearchService {
  Future<List<FrontDeskCustomerSearchResult>> searchCustomers(String query);
}

/// Local repository-backed implementation of [FrontDeskSearchService].
class LocalFrontDeskSearchService implements FrontDeskSearchService {
  LocalFrontDeskSearchService({
    required this.repository,
    required this.setup,
  });

  final WorkspaceRepository repository;
  final StartupSetup setup;

  @override
  Future<List<FrontDeskCustomerSearchResult>> searchCustomers(
    String query,
  ) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return const [];

    final activeVisits = repository.activeVisits();
    final allBookings = repository.bookingsForToday();

    final matches = repository.customers.where((customer) {
      final name = customer.name.toLowerCase();
      final phone = customer.phone?.toLowerCase() ?? '';
      return name.contains(cleanQuery) || phone.contains(cleanQuery);
    }).toList();

    final results = <FrontDeskCustomerSearchResult>[];

    for (final customer in matches) {
      // Check if inside now
      final activeVisit = activeVisits
          .where((v) => v.customerId == customer.id)
          .firstOrNull;

      final isInside = activeVisit != null;

      String badge;
      bool isSuccessBadge = false;
      String subtitle;

      if (isInside) {
        badge = 'Inside now';
        isSuccessBadge = true;
        final timeStr = _formatTime(activeVisit.checkedInAt);
        final spaceName = (activeVisit.spaceName?.isNotEmpty ?? false)
            ? activeVisit.spaceName!
            : (activeVisit.spaceType?.label ?? 'Shared area');
        subtitle = '$spaceName · since $timeStr';
      } else {
        // Look for customer's upcoming bookings
        final booking = allBookings
            .where((b) => b.customerId == customer.id)
            .firstOrNull;

        if (customer.plan != null && customer.plan!.isNotEmpty) {
          badge = customer.plan!;
          isSuccessBadge = false;
        } else {
          final visitCount =
              repository.visitsForCustomer(customer.id).length;
          badge = visitCount > 1
              ? 'Returning · $visitCount visits'
              : 'New customer';
          isSuccessBadge = false;
        }

        if (booking != null) {
          final space = (booking.spaceName?.isNotEmpty ?? false)
              ? booking.spaceName!
              : (booking.spaceType?.label ?? 'Room');
          final time = _formatTime(booking.startsAt);
          subtitle = 'Today · $space · $time';
        } else {
          final visits = repository.visitsForCustomer(customer.id);
          if (visits.isNotEmpty) {
            final lastVisit = visits.first;
            subtitle = 'Last visit ${_formatDate(lastVisit.checkedInAt)}';
          } else {
            subtitle = 'Registered customer';
          }
        }
      }

      results.add(
        FrontDeskCustomerSearchResult(
          customer: customer,
          isInsideNow: isInside,
          activeVisit: activeVisit,
          badgeLabel: badge,
          isBadgeSuccess: isSuccessBadge,
          subtitle: subtitle,
        ),
      );
    }

    return results;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }
}
