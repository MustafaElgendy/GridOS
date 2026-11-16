import 'package:flutter_test/flutter_test.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';

void main() {
  group('WorkspaceRepository', () {
    test('starts empty and enforces CRUD identifiers', () {
      final repository = WorkspaceRepository();
      expect(repository.customers, isEmpty);
      expect(repository.visits, isEmpty);
      expect(repository.bookings, isEmpty);
      expect(repository.products, isEmpty);
      expect(repository.moneyEntries, isEmpty);

      const customer = Customer(id: 'c1', name: 'Rania');
      repository.createCustomer(customer);
      expect(repository.customerById('c1'), customer);
      expect(() => repository.createCustomer(customer), throwsStateError);
      expect(
        () =>
            repository.updateCustomer(const Customer(id: 'missing', name: '')),
        throwsStateError,
      );
      expect(repository.deleteCustomer('c1'), isTrue);
      expect(repository.deleteCustomer('c1'), isFalse);
    });

    test('groups money totals by currency and date range', () {
      final repository = WorkspaceRepository();
      final start = DateTime(2025, 5, 10);
      repository.createMoneyEntry(
        MoneyEntry(
          id: 'income-egp',
          kind: MoneyEntryKind.income,
          amount: 50,
          occurredAt: start,
          currency: 'EGP',
        ),
      );
      repository.createMoneyEntry(
        MoneyEntry(
          id: 'expense-egp',
          kind: MoneyEntryKind.expense,
          amount: 12,
          occurredAt: start.add(const Duration(hours: 1)),
          currency: 'EGP',
        ),
      );
      repository.createMoneyEntry(
        MoneyEntry(
          id: 'income-usd',
          kind: MoneyEntryKind.income,
          amount: 7,
          occurredAt: start.add(const Duration(days: 1)),
          currency: 'USD',
        ),
      );

      final totals = repository.moneyTotals(
        from: start,
        until: start.add(const Duration(days: 1)),
      );
      expect(totals['EGP']?.income, 50);
      expect(totals['EGP']?.expenses, 12);
      expect(totals['EGP']?.net, 38);
      expect(totals.containsKey('USD'), isFalse);
    });

    test('finds recurring bookings on selected weekdays', () {
      final repository = WorkspaceRepository();
      final today = DateTime(2025, 5, 15, 8);
      repository.createBooking(
        Booking(
          id: 'weekly',
          customerId: 'customer',
          kind: BookingKind.longTerm,
          startsAt: DateTime(2025, 5, 8, 9),
          endsAt: DateTime(2025, 5, 8, 10),
          weekdays: const {DateTime.thursday},
          until: DateTime(2025, 6, 30),
        ),
      );

      expect(repository.bookingsForToday(on: today), hasLength(1));
      expect(repository.upcomingBookings(after: today), hasLength(1));
    });

    test('removes question answers when a question is deleted', () {
      final repository = WorkspaceRepository();
      repository.createQuestion(
        const CustomerQuestion(id: 'q1', prompt: 'What do you need?'),
      );
      repository.createQuestionResponse(
        CustomerQuestionResponse(
          id: 'a1',
          questionId: 'q1',
          answer: 'A desk',
          answeredAt: DateTime(2025),
        ),
      );

      expect(repository.responsesForQuestion('q1'), hasLength(1));
      expect(repository.deleteQuestion('q1'), isTrue);
      expect(repository.questionResponses, isEmpty);
    });
  });
}
