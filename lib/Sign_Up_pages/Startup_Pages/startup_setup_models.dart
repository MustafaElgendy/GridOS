enum SetupSpaceType {
  sharedArea('Shared area'),
  rooms('Rooms & studios'),
  computers('Computers'),
  privateOffices('Private offices'),
  virtualOffice('Virtual office'),
  other('Something else');

  const SetupSpaceType(this.label);

  final String label;
}

enum SetupHoursMode { twentyFourHours, sameEveryDay, perDay }

enum WalkInPriceMode { byHours, perHour, byShift, dayPrice }

class SetupCountry {
  const SetupCountry({
    required this.name,
    required this.flag,
    required this.phoneCode,
    required this.currency,
    required this.cities,
  });

  final String name;
  final String flag;
  final String phoneCode;
  final String currency;
  final List<String> cities;
}

const setupCountries = [
  SetupCountry(
    name: 'Egypt',
    flag: '🇪🇬',
    phoneCode: '+20',
    currency: 'EGP',
    cities: ['Cairo', 'Giza', 'Alexandria', 'Other'],
  ),
  SetupCountry(
    name: 'Saudi Arabia',
    flag: '🇸🇦',
    phoneCode: '+966',
    currency: 'SAR',
    cities: ['Riyadh', 'Jeddah', 'Dammam', 'Other'],
  ),
  SetupCountry(
    name: 'United Arab Emirates',
    flag: '🇦🇪',
    phoneCode: '+971',
    currency: 'AED',
    cities: ['Dubai', 'Abu Dhabi', 'Sharjah', 'Other'],
  ),
  SetupCountry(
    name: 'United Kingdom',
    flag: '🇬🇧',
    phoneCode: '+44',
    currency: 'GBP',
    cities: ['London', 'Manchester', 'Birmingham', 'Other'],
  ),
  SetupCountry(
    name: 'United States',
    flag: '🇺🇸',
    phoneCode: '+1',
    currency: 'USD',
    cities: ['New York', 'Los Angeles', 'Chicago', 'Other'],
  ),
];

class SetupScheduleDay {
  SetupScheduleDay({
    required this.day,
    this.isOpen = true,
    this.opensAt = '09:00',
    this.closesAt = '17:00',
  });

  final String day;
  bool isOpen;
  String opensAt;
  String closesAt;
}

class SharedAreaSetup {
  SharedAreaSetup({this.name = 'Shared area', this.chairs = '40'});

  String name;
  String chairs;
}

class RoomSetup {
  RoomSetup({required this.name, required this.seats});

  String name;
  String seats;
}

class VirtualPackageSetup {
  VirtualPackageSetup({this.name = 'Virtual office', Set<String>? included})
    : included = included ?? {'Business address', 'Mail & packages'};

  String name;
  final Set<String> included;
  String customIncludedDraft = '';
}

class PrivateOfficeSetup {
  PrivateOfficeSetup({required this.name, this.desks = '4'});

  String name;
  String desks;
}

class OtherSpaceSetup {
  OtherSpaceSetup({
    this.name = '',
    this.chargePeriod = 'day',
    this.quantity = '1',
  });

  String name;
  String chargePeriod;
  String quantity;
}

class SpaceSetup {
  SpaceSetup(SetupSpaceType type)
    : type = type,
      selected = type == SetupSpaceType.sharedArea,
      sharedAreas = type == SetupSpaceType.sharedArea
          ? [SharedAreaSetup()]
          : [],
      rooms = type == SetupSpaceType.rooms
          ? [
              RoomSetup(name: 'Room 1', seats: '6'),
              RoomSetup(name: 'Room 2', seats: '4'),
            ]
          : [];

  final SetupSpaceType type;
  bool selected;
  List<SharedAreaSetup> sharedAreas;
  List<RoomSetup> rooms;
  String computerCount = '6';
  String computerNaming = 'Numbers';
  List<String> computerNames = [];
  List<PrivateOfficeSetup> offices = [PrivateOfficeSetup(name: 'Office 1')];
  List<VirtualPackageSetup> packages = [VirtualPackageSetup()];
  List<OtherSpaceSetup> otherItems = [OtherSpaceSetup()];
}

class WalkInStep {
  WalkInStep({this.untilHours = '3', this.price = ''});

  String untilHours;
  String price;
}

class ShiftSetup {
  ShiftSetup({this.name = '', this.from = '09:00', this.to = '17:00'});

  String name;
  String from;
  String to;
  String price = '';
}

class PlanSetup {
  PlanSetup({this.name = ''});

  String name;
  String price = '';
  String interval = 'month';
  String duration = '';
}

class SpacePriceSetup {
  WalkInPriceMode walkInMode = WalkInPriceMode.byHours;
  List<WalkInStep> walkInSteps = [WalkInStep()];
  String moreHoursPrice = '';
  String hourlyPrice = '';
  bool hasDailyCap = false;
  String dailyCap = '';
  List<ShiftSetup> shifts = [ShiftSetup(name: 'Morning')];
  String dayPrice = '';
  bool hasPeopleTier = false;
  String peopleIncluded = '4';
  String additionalPeople = '2';
  String additionalPrice = '';
  bool pricePerComputer = false;
  Map<int, String> computerPrices = {};
  List<PlanSetup> plans = [];
  bool monthlyDesksEnabled = false;
  String monthlyDeskPrice = '';
}

class KitchenItemSetup {
  String name = '';
  String price = '';
  String quantity = '';
  String costsYou = '';
}

class StaffSetup {
  StaffSetup({required this.name, required this.pin});

  final String name;
  final String pin;
}

class StartupSetup {
  StartupSetup({required this.ownerName, required this.workspaceName})
    : spaces = {
        for (final type in SetupSpaceType.values) type: SpaceSetup(type),
      },
      prices = {
        for (final type in SetupSpaceType.values) type: SpacePriceSetup(),
      };

  String ownerName;
  String workspaceName;
  String phone = '';
  SetupCountry country = setupCountries.first;
  String? city;
  String? cityChoice;
  String area = '';
  SetupHoursMode hoursMode = SetupHoursMode.sameEveryDay;
  String opensAt = '09:00';
  String closesAt = '17:00';
  final List<SetupScheduleDay> schedule = [
    for (final day in ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'])
      SetupScheduleDay(day: day),
  ];
  final Map<SetupSpaceType, SpaceSetup> spaces;
  final Map<SetupSpaceType, SpacePriceSetup> prices;
  List<KitchenItemSetup> kitchenItems = [KitchenItemSetup()];
  final List<StaffSetup> staff = [];
  final Set<String> staffPins = {};
  bool? staffUsesThisComputer;

  List<SetupSpaceType> get selectedSpaces =>
      SetupSpaceType.values.where((type) => spaces[type]!.selected).toList();
}
