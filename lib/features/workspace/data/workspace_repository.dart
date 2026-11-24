import '../domain/workspace_models.dart';

/// In-memory workspace data store; replaceable with a persistent repository.
class WorkspaceRepository {
  final Map<String, Customer> _customers = {};
  final Map<String, Visit> _visits = {};
  final Map<String, Booking> _bookings = {};
  final Map<String, WorkspaceTask> _tasks = {};
  final Map<String, Product> _products = {};
  final Map<String, MoneyEntry> _moneyEntries = {};
  final Map<String, Bill> _bills = {};
  final Map<String, CustomerQuestion> _questions = {};
  final Map<String, CustomerQuestionResponse> _questionResponses = {};
  final Map<String, WorkspaceShift> _shifts = {};
  WorkspaceSettings _settings = const WorkspaceSettings();

  List<Customer> get customers => List.unmodifiable(_customers.values);
  List<Visit> get visits => List.unmodifiable(_visits.values);
  List<Booking> get bookings => List.unmodifiable(_bookings.values);
  List<WorkspaceTask> get tasks => List.unmodifiable(_tasks.values);
  List<Product> get products => List.unmodifiable(_products.values);
  List<MoneyEntry> get moneyEntries => List.unmodifiable(_moneyEntries.values);
  List<Bill> get bills => List.unmodifiable(_bills.values);
  List<CustomerQuestion> get questions => List.unmodifiable(
    _questions.values.toList()..sort((a, b) => a.order.compareTo(b.order)),
  );
  List<CustomerQuestionResponse> get questionResponses =>
      List.unmodifiable(_questionResponses.values);
  List<WorkspaceShift> get shifts => List.unmodifiable(_shifts.values);
  List<WorkspaceShift> get activeShifts =>
      List.unmodifiable(_shifts.values.where((shift) => shift.isActive));
  WorkspaceSettings get settings => _settings;

  void updateSettings(WorkspaceSettings value) {
    _settings = value;
  }

  Customer? customerById(String id) => _customers[id];
  Visit? visitById(String id) => _visits[id];
  Booking? bookingById(String id) => _bookings[id];
  WorkspaceTask? taskById(String id) => _tasks[id];
  Product? productById(String id) => _products[id];
  MoneyEntry? moneyEntryById(String id) => _moneyEntries[id];
  Bill? billById(String id) => _bills[id];
  CustomerQuestion? questionById(String id) => _questions[id];
  WorkspaceShift? shiftById(String id) => _shifts[id];

  Customer createCustomer(Customer value) =>
      _create(_customers, value.id, value);
  Customer updateCustomer(Customer value) =>
      _update(_customers, value.id, value);
  bool deleteCustomer(String id) => _customers.remove(id) != null;

  Visit createVisit(Visit value) => _create(_visits, value.id, value);
  Visit updateVisit(Visit value) => _update(_visits, value.id, value);
  bool deleteVisit(String id) => _visits.remove(id) != null;

  Booking createBooking(Booking value) => _create(_bookings, value.id, value);
  Booking updateBooking(Booking value) => _update(_bookings, value.id, value);
  bool deleteBooking(String id) => _bookings.remove(id) != null;

  WorkspaceTask createTask(WorkspaceTask value) =>
      _create(_tasks, value.id, value);
  WorkspaceTask updateTask(WorkspaceTask value) =>
      _update(_tasks, value.id, value);
  bool deleteTask(String id) => _tasks.remove(id) != null;

  Product createProduct(Product value) => _create(_products, value.id, value);
  Product updateProduct(Product value) => _update(_products, value.id, value);
  bool deleteProduct(String id) => _products.remove(id) != null;

  MoneyEntry createMoneyEntry(MoneyEntry value) =>
      _create(_moneyEntries, value.id, value);
  MoneyEntry updateMoneyEntry(MoneyEntry value) =>
      _update(_moneyEntries, value.id, value);
  bool deleteMoneyEntry(String id) => _moneyEntries.remove(id) != null;

  Bill createBill(Bill value) => _create(_bills, value.id, value);
  Bill updateBill(Bill value) => _update(_bills, value.id, value);
  bool deleteBill(String id) => _bills.remove(id) != null;
  CustomerQuestion createQuestion(CustomerQuestion value) =>
      _create(_questions, value.id, value);
  CustomerQuestion updateQuestion(CustomerQuestion value) =>
      _update(_questions, value.id, value);
  bool deleteQuestion(String id) {
    final removed = _questions.remove(id) != null;
    _questionResponses.removeWhere((_, response) => response.questionId == id);
    return removed;
  }

  CustomerQuestionResponse createQuestionResponse(
    CustomerQuestionResponse value,
  ) => _create(_questionResponses, value.id, value);
  bool deleteQuestionResponse(String id) =>
      _questionResponses.remove(id) != null;
  WorkspaceShift createShift(WorkspaceShift value) =>
      _create(_shifts, value.id, value);
  WorkspaceShift updateShift(WorkspaceShift value) =>
      _update(_shifts, value.id, value);
  bool deleteShift(String id) => _shifts.remove(id) != null;

  WorkspaceShift? activeShiftFor(String personName) {
    for (final shift in _shifts.values) {
      if (shift.isActive && shift.personName == personName) return shift;
    }
    return null;
  }

  List<Visit> visitsForCustomer(String customerId) =>
      _visits.values.where((visit) => visit.customerId == customerId).toList()
        ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));

  List<MoneyEntry> moneyEntriesFor(MoneyEntryKind kind) =>
      _moneyEntries.values.where((entry) => entry.kind == kind).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  List<CustomerQuestionResponse> responsesForQuestion(String questionId) =>
      _questionResponses.values
          .where((response) => response.questionId == questionId)
          .toList()
        ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));

  List<Visit> activeVisits({DateTime? at}) {
    final now = at ?? DateTime.now();
    return _visits.values
        .where(
          (visit) =>
              visit.checkedOutAt == null && !visit.checkedInAt.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.checkedInAt.compareTo(b.checkedInAt));
  }

  List<Booking> bookingsForToday({DateTime? on}) {
    final today = (on ?? DateTime.now()).toLocal();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startOfNextDay = DateTime(today.year, today.month, today.day + 1);
    return _bookings.values
        .where(
          (booking) =>
              _isScheduled(booking) &&
              _bookingOccursOn(booking, startOfDay, startOfNextDay),
        )
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  List<Booking> upcomingBookings({DateTime? after}) {
    final now = after ?? DateTime.now();
    return _bookings.values
        .where(
          (booking) =>
              _isScheduled(booking) && _nextOccurrence(booking, now) != null,
        )
        .toList()
      ..sort(
        (a, b) => _nextOccurrence(a, now)!.compareTo(_nextOccurrence(b, now)!),
      );
  }

  List<WorkspaceTask> recurringTasks({bool includeCompleted = false}) => _tasks
      .values
      .where(
        (task) => task.isRecurring && (includeCompleted || !task.isCompleted),
      )
      .toList();

  List<Product> lowStockProducts() =>
      _products.values.where((product) => product.isLowStock).toList();

  /// Totals entries in [from] (inclusive) to [until] (exclusive).
  ///
  /// Entries are grouped by their currency so unlike currencies are not added
  /// together. Bills are not included; record payments as money entries.
  Map<String, MoneyTotals> moneyTotals({DateTime? from, DateTime? until}) {
    final totals = <String, ({double income, double expenses})>{};
    for (final entry in _moneyEntries.values) {
      if (from != null && entry.occurredAt.isBefore(from)) continue;
      if (until != null && !entry.occurredAt.isBefore(until)) continue;

      final current = totals[entry.currency] ?? (income: 0.0, expenses: 0.0);
      totals[entry.currency] = entry.kind == MoneyEntryKind.income
          ? (income: current.income + entry.amount, expenses: current.expenses)
          : (income: current.income, expenses: current.expenses + entry.amount);
    }

    return Map.unmodifiable({
      for (final entry in totals.entries)
        entry.key: MoneyTotals(
          income: entry.value.income,
          expenses: entry.value.expenses,
          currency: entry.key,
        ),
    });
  }

  static T _create<T>(Map<String, T> store, String id, T value) {
    if (store.containsKey(id)) {
      throw StateError('An item with id "$id" already exists.');
    }
    store[id] = value;
    return value;
  }

  static T _update<T>(Map<String, T> store, String id, T value) {
    if (!store.containsKey(id)) {
      throw StateError('No item with id "$id" exists.');
    }
    store[id] = value;
    return value;
  }

  static bool _isScheduled(Booking booking) =>
      booking.status != BookingStatus.cancelled &&
      booking.status != BookingStatus.completed;

  static bool _bookingOccursOn(
    Booking booking,
    DateTime startOfDay,
    DateTime startOfNextDay,
  ) {
    if (booking.weekdays.isEmpty) {
      return booking.startsAt.isBefore(startOfNextDay) &&
          booking.endsAt.isAfter(startOfDay);
    }
    if (booking.weekdays.contains(startOfDay.weekday) &&
        !startOfDay.isBefore(
          DateTime(
            booking.startsAt.year,
            booking.startsAt.month,
            booking.startsAt.day,
          ),
        ) &&
        (booking.until == null ||
            !startOfDay.isAfter(
              DateTime(
                booking.until!.year,
                booking.until!.month,
                booking.until!.day,
              ),
            ))) {
      return true;
    }
    return false;
  }

  static DateTime? _nextOccurrence(Booking booking, DateTime after) {
    if (booking.weekdays.isEmpty) {
      return booking.startsAt.isAfter(after) ? booking.startsAt : null;
    }
    final firstDay = DateTime(
      booking.startsAt.year,
      booking.startsAt.month,
      booking.startsAt.day,
    );
    final startDay = after.isBefore(firstDay) ? firstDay : after;
    for (var offset = 0; offset <= 370; offset++) {
      final day = DateTime(
        startDay.year,
        startDay.month,
        startDay.day + offset,
      );
      if (booking.until != null && day.isAfter(booking.until!)) return null;
      if (booking.weekdays.contains(day.weekday)) {
        final occurrence = DateTime(
          day.year,
          day.month,
          day.day,
          booking.startsAt.hour,
          booking.startsAt.minute,
        );
        if (occurrence.isAfter(after)) return occurrence;
      }
    }
    return null;
  }
}
