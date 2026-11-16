import '../../../Sign_Up_pages/Startup_Pages/startup_setup_models.dart';

enum BookingKind { oneTime, longTerm }

enum BookingStatus { reserved, confirmed, cancelled, completed }

enum TaskRepeat { none, daily, weekly, monthly }

enum MoneyEntryKind { income, expense }

enum BillFrequency { oneTime, weekly, monthly, yearly }

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.notes,
    this.profession,
    this.area,
    this.source,
    this.plan,
    this.balance = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? notes;
  final String? profession;
  final String? area;
  final String? source;
  final String? plan;
  final double balance;
  final DateTime? createdAt;
}

class Visit {
  const Visit({
    required this.id,
    required this.checkedInAt,
    this.customerId,
    this.checkedOutAt,
    this.spaceType,
    this.spaceName,
    this.notes,
    this.amount = 0,
    this.paymentMethod,
    this.isPaid = false,
  });

  final String id;
  final String? customerId;
  final DateTime checkedInAt;
  final DateTime? checkedOutAt;
  final SetupSpaceType? spaceType;
  final String? spaceName;
  final String? notes;
  final double amount;
  final String? paymentMethod;
  final bool isPaid;

  bool get isActive => checkedOutAt == null;
}

class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    this.status = BookingStatus.confirmed,
    this.spaceType,
    this.spaceName,
    this.notes,
    this.amount = 0,
    this.paidAmount = 0,
    this.weekdays = const {},
    this.until,
  }) : assert(amount >= 0),
       assert(paidAmount >= 0),
       assert(paidAmount <= amount);

  final String id;
  final String customerId;
  final BookingKind kind;
  final DateTime startsAt;
  final DateTime endsAt;
  final BookingStatus status;
  final SetupSpaceType? spaceType;
  final String? spaceName;
  final String? notes;
  final double amount;
  final double paidAmount;
  final Set<int> weekdays;
  final DateTime? until;
}

class WorkspaceTask {
  const WorkspaceTask({
    required this.id,
    required this.title,
    this.description,
    this.assignedToId,
    this.dueAt,
    this.repeat = TaskRepeat.none,
    this.completedAt,
    this.isRequired = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? assignedToId;
  final DateTime? dueAt;
  final TaskRepeat repeat;
  final DateTime? completedAt;
  final bool isRequired;

  bool get isCompleted => completedAt != null;
  bool get isRecurring => repeat != TaskRepeat.none;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.quantityOnHand,
    required this.lowStockThreshold,
    this.unit = 'item',
    this.sku,
    this.category = 'Other',
    this.price = 0,
    this.cost = 0,
    this.freeForMembers = false,
  }) : assert(quantityOnHand >= 0),
       assert(lowStockThreshold >= 0);

  final String id;
  final String name;
  final double quantityOnHand;
  final double lowStockThreshold;
  final String unit;
  final String? sku;
  final String category;
  final double price;
  final double cost;
  final bool freeForMembers;

  bool get isLowStock => quantityOnHand <= lowStockThreshold;
}

class MoneyEntry {
  const MoneyEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.occurredAt,
    required this.currency,
    this.description,
    this.customerId,
    this.billId,
    this.paymentMethod,
  }) : assert(amount >= 0);

  final String id;
  final MoneyEntryKind kind;
  final double amount;
  final DateTime occurredAt;
  final String currency;
  final String? description;
  final String? customerId;
  final String? billId;
  final String? paymentMethod;
}

class Bill {
  const Bill({
    required this.id,
    required this.amount,
    required this.currency,
    required this.issuedAt,
    required this.dueAt,
    this.customerId,
    this.description = '',
    this.paidAt,
    this.frequency = BillFrequency.oneTime,
  }) : assert(amount >= 0);

  final String id;
  final String? customerId;
  final double amount;
  final String currency;
  final String description;
  final DateTime issuedAt;
  final DateTime dueAt;
  final DateTime? paidAt;
  final BillFrequency frequency;

  bool get isPaid => paidAt != null;
}

class MoneyTotals {
  const MoneyTotals({
    required this.income,
    required this.expenses,
    required this.currency,
  });

  final double income;
  final double expenses;
  final String currency;

  double get net => income - expenses;
}

class WorkspaceShift {
  const WorkspaceShift({
    required this.id,
    required this.personName,
    required this.startedAt,
    this.endedAt,
    this.openingCash = 0,
    this.closingCash,
    this.expectedCash,
  });

  final String id;
  final String personName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;

  bool get isActive => endedAt == null;
}

enum CustomerQuestionType { shortText, multipleChoice }

enum CustomerQuestionTiming { checkIn, checkOut }

class CustomerQuestion {
  const CustomerQuestion({
    required this.id,
    required this.prompt,
    this.type = CustomerQuestionType.multipleChoice,
    this.options = const [],
    this.timing = CustomerQuestionTiming.checkIn,
    this.required = false,
    this.order = 0,
  });

  final String id;
  final String prompt;
  final CustomerQuestionType type;
  final List<String> options;
  final CustomerQuestionTiming timing;
  final bool required;
  final int order;
}

class CustomerQuestionResponse {
  const CustomerQuestionResponse({
    required this.id,
    required this.questionId,
    required this.answer,
    required this.answeredAt,
    this.customerId,
    this.visitId,
  });

  final String id;
  final String questionId;
  final String answer;
  final DateTime answeredAt;
  final String? customerId;
  final String? visitId;
}

class WorkspaceSettings {
  const WorkspaceSettings({
    this.cashDrawerEnabled = false,
    this.askOpeningCash = false,
    this.requireShiftReconciliation = false,
    this.whatsappNumber = '',
    this.whatsappMessage = '',
    this.invoicePrefix = '',
    this.invoiceFooter = '',
  });

  final bool cashDrawerEnabled;
  final bool askOpeningCash;
  final bool requireShiftReconciliation;
  final String whatsappNumber;
  final String whatsappMessage;
  final String invoicePrefix;
  final String invoiceFooter;
}
