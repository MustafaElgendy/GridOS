import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_os/Main Pages/dashboard.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/preview_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/kitchen_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/prices_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/staff_page.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/workspace_page.dart';
import 'package:grid_os/Sign_Up_pages/first_sign_up.dart';
import 'package:grid_os/Sign_Up_pages/login_page.dart';
import 'package:grid_os/Sign_Up_pages/sign_up_models.dart';
import 'package:grid_os/features/workspace/workspace_data.dart';
import 'package:grid_os/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('desktop landing page renders', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('GridOS'), findsNWidgets(2));
    expect(find.text('Get started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile landing page renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('GridOS'), findsNWidgets(2));
    expect(find.text('Explore plans'), findsOneWidget);
    await tester.ensureVisible(find.text('Start your subscription'));
    await tester.tap(find.text('Start your subscription'));
    await tester.pumpAndSettle();

    expect(find.text('Start free'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up page validates email and password', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FirstSignUpPage()));

    await tester.tap(find.byKey(const ValueKey('create-account')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('signup-email')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password')),
      'weakpass1',
    );
    await tester.tap(find.byKey(const ValueKey('create-account')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Include uppercase, lowercase, a number, and a symbol.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid sign-up details continue to the workspace setup page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FirstSignUpPage()));

    final passwordField = find.byKey(const ValueKey('signup-password'));
    final editablePassword = find.descendant(
      of: passwordField,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editablePassword).obscureText, isTrue);
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(tester.widget<EditableText>(editablePassword).obscureText, isFalse);

    await tester.enterText(
      find.byKey(const ValueKey('signup-email')),
      'team@example.com',
    );
    await tester.enterText(passwordField, 'StrongPass1!');
    await tester.tap(find.byKey(const ValueKey('create-account')));
    await tester.pumpAndSettle();

    expect(find.text('Your workspace'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('signup-full-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-workspace-name')), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace setup validates details and opens the first step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FirstSignUpPage()));
    await tester.enterText(
      find.byKey(const ValueKey('signup-email')),
      'team@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password')),
      'StrongPass1!',
    );
    await tester.tap(find.byKey(const ValueKey('create-account')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('workspace-continue')),
    );
    await tester.tap(find.byKey(const ValueKey('workspace-continue')));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsNWidgets(3));
    expect(find.text('Enter your phone number.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('signup-full-name')),
      'Karim Hassan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-workspace-name')),
      'Ramla Workspace',
    );
    await tester.enterText(
      find.byKey(const ValueKey('setup-phone')),
      '01012345678',
    );
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('workspace-continue')),
    );
    await tester.tap(find.byKey(const ValueKey('workspace-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Your spaces'), findsOneWidget);
    expect(find.text('Ramla Workspace'), findsNWidgets(2));
    expect(find.text('Saved as you go'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace setup sends all fields through the API callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SignUpRequest? submittedRequest;
    await tester.pumpWidget(
      MyApp(
        submitSignup: (request) async {
          submittedRequest = request;
          return SignUpSubmissionResult.created;
        },
      ),
    );
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('signup-email')),
      'team@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-password')),
      'StrongPass1!',
    );
    await tester.tap(find.byKey(const ValueKey('create-account')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('signup-full-name')),
      'Karim Hassan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-workspace-name')),
      'Ramla Workspace',
    );
    await tester.enterText(
      find.byKey(const ValueKey('setup-phone')),
      '01012345678',
    );
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('workspace-continue')),
    );
    await tester.tap(find.byKey(const ValueKey('workspace-continue')));
    await tester.pumpAndSettle();

    expect(submittedRequest?.email, 'team@example.com');
    expect(submittedRequest?.password, 'StrongPass1!');
    expect(submittedRequest?.fullName, 'Karim Hassan');
    expect(submittedRequest?.workspaceName, 'Ramla Workspace');
    expect(find.text('Your spaces'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace step leads to spaces and opens missing details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    setup.spaces[SetupSpaceType.sharedArea]!.sharedAreas.single.chairs = '';
    await tester.pumpWidget(MaterialApp(home: WorkspacePage(setup: setup)));
    await tester.enterText(
      find.byKey(const ValueKey('setup-phone')),
      '01012345678',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your spaces'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Add the number of chairs in each area.'), findsOneWidget);
    expect(find.byKey(const ValueKey('shared-chairs-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('increment-shared-chairs-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('1 area · 1 chair'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('spaces match workspace layout and added items are removable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Alex', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: SpacesPage(setup: setup)));

    expect(find.text('Your spaces'), findsOneWidget);
    expect(find.text('Your setup so far'), findsOneWidget);
    expect(find.text('Saved as you go'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('shared-area-name-0')),
      'Main lounge',
    );
    await tester.pump();
    expect(
      setup.spaces[SetupSpaceType.sharedArea]!.sharedAreas.single.name,
      'Main lounge',
    );
    await tester.enterText(find.byKey(const ValueKey('shared-chairs-0')), '52');
    await tester.pump();
    expect(
      setup.spaces[SetupSpaceType.sharedArea]!.sharedAreas.single.chairs,
      '52',
    );
    expect(find.text('1 area · 52 chairs'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-shared-area')));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.sharedArea]!.sharedAreas, hasLength(2));
    await tester.tap(find.byKey(const ValueKey('delete-shared-area-1')));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.sharedArea]!.sharedAreas, hasLength(1));

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.rooms]!.selected, isTrue);
    await tester.tap(find.text('Rooms & studios').first);
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.rooms]!.rooms, hasLength(2));
    await tester.tap(find.byKey(const ValueKey('delete-room-0')));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.rooms]!.rooms, hasLength(1));

    await tester.tap(find.byType(Checkbox).at(4));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.virtualOffice]!.selected, isTrue);
    await tester.tap(find.text('Virtual office').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('virtual-custom-included-0')),
      'Printing 20 pages',
    );
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(
      setup.spaces[SetupSpaceType.virtualOffice]!.packages.single.included,
      contains('Printing 20 pages'),
    );
    await tester.tap(find.byKey(const ValueKey('delete-virtual-package-0')));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.virtualOffice]!.packages, isEmpty);

    await tester.tap(find.byType(Checkbox).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private offices').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add an office'));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.privateOffices]!.offices, hasLength(2));
    await tester.tap(find.byKey(const ValueKey('delete-office-1')));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.privateOffices]!.offices, hasLength(1));

    await tester.tap(find.byType(Checkbox).at(5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Something else').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add another'));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.other]!.otherItems, hasLength(2));
    await tester.tap(find.byKey(const ValueKey('delete-other-item-1')));
    await tester.pumpAndSettle();
    expect(setup.spaces[SetupSpaceType.other]!.otherItems, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom computer names follow the selected computer count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Alex', workspaceName: 'GridOS');
    final computers = setup.spaces[SetupSpaceType.computers]!;
    computers.computerCount = '2';
    await tester.pumpWidget(MaterialApp(home: SpacesPage(setup: setup)));

    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computers').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Our own names').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('computer-name-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('computer-name-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('computer-name-2')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('computer-name-0')),
      'Front desk',
    );
    await tester.enterText(
      find.byKey(const ValueKey('computer-name-1')),
      'Design PC',
    );
    expect(computers.computerNames, ['Front desk', 'Design PC']);

    await tester.tap(find.byKey(const ValueKey('decrement-computer-count')));
    await tester.pumpAndSettle();
    expect(computers.computerCount, '1');
    expect(computers.computerNames, ['Front desk']);
    expect(find.byKey(const ValueKey('computer-name-1')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kitchen chips fill the name and focus the price field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: KitchenPage(setup: setup)));

    expect(find.text('Skip for now'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Pepsi'));
    await tester.pump();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.first.controller!.text, 'Pepsi');
    expect(fields[1].focusNode!.hasFocus, isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('kitchen-quantity-0')),
      '24',
    );
    expect(setup.kitchenItems.first.quantity, '24');
    expect(find.text('Skip for now'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Coffee'));
    await tester.tap(find.widgetWithText(ActionChip, 'Coffee'));
    await tester.pumpAndSettle();
    expect(setup.kitchenItems, hasLength(2));
    expect(setup.kitchenItems.first.name, 'Pepsi');
    expect(setup.kitchenItems.last.name, 'Coffee');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('kitchen-price-1')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('price step validates before continuing to skippable kitchen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: PricesPage(setup: setup)));

    final walkInSteps = setup.prices[SetupSpaceType.sharedArea]!.walkInSteps;
    await tester.ensureVisible(find.text('Add price step'));
    await tester.tap(find.text('Add price step'));
    await tester.pumpAndSettle();
    expect(walkInSteps, hasLength(2));

    final hoursField = find.byKey(const ValueKey('walk-in-until-hours-1'));
    final priceField = find.byKey(const ValueKey('walk-in-step-price-1'));
    expect(
      tester.getRect(hoursField).center.dy,
      closeTo(tester.getRect(priceField).center.dy, 1),
    );
    final deleteAddedStep = find.byKey(const ValueKey('delete-walk-in-step-1'));
    await tester.ensureVisible(deleteAddedStep);
    await tester.tap(deleteAddedStep);
    await tester.pumpAndSettle();
    expect(walkInSteps, hasLength(1));

    expect(find.text('More than 3 hours'), findsOneWidget);
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Add a valid price to continue.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('walk-in-step-price-0')),
      '50',
    );
    await tester.enterText(
      find.byKey(const ValueKey('walk-in-more-price')),
      '80',
    );
    await tester.pump();
    expect(find.textContaining('50 EGP'), findsOneWidget);
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your kitchen'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    await tester.ensureVisible(find.text('Skip for now'));
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(setup.kitchenItems, isEmpty);
    expect(find.text('Your staff'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plans and packs can be deleted', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    final plan = PlanSetup(name: 'Starter');
    plan.price = '10';
    plan.duration = '1 day';
    setup.prices[SetupSpaceType.sharedArea]!.plans.add(plan);
    await tester.pumpWidget(MaterialApp(home: PricesPage(setup: setup)));

    final deleteButton = find.byKey(const ValueKey('delete-plan-sharedArea-0'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(setup.prices[SetupSpaceType.sharedArea]!.plans, isEmpty);
    expect(find.text('Starter'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff can be deleted and PINs stay private', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: StaffPage(setup: setup)));

    expect(find.text('Karim'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Amina');
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Amina'), findsNWidgets(2));
    expect(find.text('1234'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'Mona');
    await tester.enterText(find.byType(TextField).at(1), '5678');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(setup.staff, hasLength(2));
    expect(setup.staffPins, contains('5678'));
    await tester.tap(find.byKey(const ValueKey('delete-staff-5678')));
    await tester.pumpAndSettle();
    expect(setup.staff, hasLength(1));
    expect(setup.staffPins, isNot(contains('5678')));

    await tester.enterText(find.byType(TextField).at(0), 'Youssef');
    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('That PIN is already in use.'), findsOneWidget);
    expect(setup.staff, hasLength(1));

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Review your setup'), findsOneWidget);
    expect(find.text('Edit'), findsNWidgets(5));

    await tester.ensureVisible(find.text('Edit').last);
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();
    expect(find.text('Your staff'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Review your setup'), findsOneWidget);

    await tester.ensureVisible(find.text('Go to dashboard'));
    await tester.tap(find.text('Go to dashboard'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dashboard-overview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty dashboard uses zero metrics and opens Today without staff',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
      await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

      expect(find.text('0 EGP'), findsWidgets);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Nothing to point out yet'), findsOneWidget);
      expect(find.text('Shared area'), findsOneWidget);
      expect(find.text('0% full'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('owner-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('owner-open-front-desk')));
      await tester.pumpAndSettle();

      expect(find.text('Who’s working?'), findsOneWidget);
      expect(find.text('Karim · Owner'), findsOneWidget);
      expect(find.text('Start shift'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dashboard compares local metrics and lists actionable insights',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      final now = DateTime.now();
      final priorYear = now.year - 1;
      final priorMonthLastDay = DateTime(priorYear, now.month + 1, 0).day;
      final priorDay = now.day > priorMonthLastDay
          ? priorMonthLastDay
          : now.day;
      final currentDate = DateTime(now.year, now.month, now.day, 10);
      final previousDate = DateTime(priorYear, now.month, priorDay, 10);
      final repository = WorkspaceRepository();
      repository.createMoneyEntry(
        MoneyEntry(
          id: 'current-income',
          kind: MoneyEntryKind.income,
          amount: 100,
          occurredAt: currentDate,
          currency: 'EGP',
        ),
      );
      repository.createMoneyEntry(
        MoneyEntry(
          id: 'previous-income',
          kind: MoneyEntryKind.income,
          amount: 80,
          occurredAt: previousDate,
          currency: 'EGP',
        ),
      );
      repository.createProduct(
        const Product(
          id: 'low-stock',
          name: 'Coffee',
          quantityOnHand: 1,
          lowStockThreshold: 5,
        ),
      );
      repository.createVisit(
        Visit(
          id: 'current-visit',
          checkedInAt: currentDate,
          checkedOutAt: currentDate.add(const Duration(hours: 1)),
          spaceType: SetupSpaceType.sharedArea,
          amount: 100,
          isPaid: true,
        ),
      );
      repository.createVisit(
        Visit(
          id: 'previous-visit',
          checkedInAt: previousDate,
          checkedOutAt: previousDate.add(const Duration(hours: 1)),
          spaceType: SetupSpaceType.sharedArea,
          amount: 80,
          isPaid: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(
            setup: StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS'),
            repository: repository,
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('dashboard-comparison-filter')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Same time last year'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('metric-money-in')),
          matching: find.text('100 EGP'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('metric-money-in')),
          matching: find.textContaining('25% more than same time last year'),
        ),
        findsOneWidget,
      );
      expect(find.text('Coffee needs stock'), findsOneWidget);
      expect(find.text('Shared area made the most money'), findsOneWidget);
      expect(find.text('Shared area grew the most'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboard-comparison-chart')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('dashboard-see-numbers')),
      );
      await tester.tap(find.byKey(const ValueKey('dashboard-see-numbers')));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard numbers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dashboard range picker supports presets and month ranges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          setup: StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS'),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('topbar-today')), findsOneWidget);
    expect(find.text('Dashboard'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('dashboard-period-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Pick months'), findsOneWidget);
    expect(find.text('Or your own dates'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('dashboard-preset-Last 7 days')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Last 7 days'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-period-filter')));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final previousMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    await tester.tap(
      find.byKey(ValueKey('dashboard-month-$year-$previousMonth')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dashboard-range-show')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Custom dates'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-comparison-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Previous period'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-comparison-filter')),
        matching: find.textContaining('Previous period'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('dashboard-comparison-custom-date')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pick months'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dashboard-preset-Today')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-comparison-filter')),
        matching: find.textContaining('Custom dates'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dashboard Spaces and Prices reuse setup editors and update overview',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      final setup = StartupSetup(ownerName: 'Alex', workspaceName: 'GridOS');
      setup.kitchenItems.first
        ..name = 'Pepsi'
        ..price = '20';
      await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

      await tester.tap(find.byKey(const ValueKey('nav-spaces')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('spaces-tab-spaces')), findsOneWidget);
      expect(find.byKey(const ValueKey('add-shared-area')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('add-shared-area')));
      await tester.pumpAndSettle();
      expect(
        setup.spaces[SetupSpaceType.sharedArea]!.sharedAreas,
        hasLength(2),
      );

      await tester.tap(find.byKey(const ValueKey('spaces-tab-prices')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('price-card-sharedArea')),
        findsOneWidget,
      );
      expect(find.text('How do walk-ins pay?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How each space is doing'));
      expect(find.text('2 areas · 80 chairs'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('show-space-details-sharedArea')),
      );
      await tester.tap(
        find.byKey(const ValueKey('show-space-details-sharedArea')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Area 2'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('show-space-details-kitchen')),
      );
      await tester.tap(
        find.byKey(const ValueKey('show-space-details-kitchen')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pepsi'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-spaces')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('spaces-tab-spaces')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();
      expect(setup.selectedSpaces, contains(SetupSpaceType.rooms));

      await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How each space is doing'));
      expect(find.text('2 rooms · 10 seats'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('front desk choice is saved per device when staff are added', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    setup.staff.add(StaffSetup(name: 'Mona', pin: '2468'));
    setup.staffPins.add('2468');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

    await tester.tap(find.byKey(const ValueKey('owner-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('owner-open-front-desk')));
    await tester.pumpAndSettle();
    expect(find.text('Will staff use this computer?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('frontdesk-choice-no')));
    await tester.tap(find.byKey(const ValueKey('confirm-frontdesk-choice')));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(frontDeskPreferenceKey(setup)), isFalse);
    expect(
      find.text(
        'On the front desk computer, log in and tap Open the front desk.',
      ),
      findsOneWidget,
    );
    expect(find.text('Who’s working?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('front desk setup rejects weak owner PIN and starts shifts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    setup.staff.add(StaffSetup(name: 'Mona', pin: '2468'));
    setup.staffPins.add('2468');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

    await tester.tap(find.byKey(const ValueKey('owner-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('owner-open-front-desk')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-frontdesk-choice')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-entry')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-confirm')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('save-owner-pin')));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose a less predictable PIN, not a simple sequence.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-entry')),
      '284971',
    );
    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-confirm')),
      '284971',
    );
    await tester.tap(find.byKey(const ValueKey('save-owner-pin')));
    await tester.pumpAndSettle();

    expect(setup.ownerPin, '284971');
    expect(find.text('Who’s working?'), findsOneWidget);
    expect(find.text('Karim · Owner'), findsOneWidget);
    expect(find.text('Mona'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Karim · Owner')).dy,
      lessThan(tester.getTopLeft(find.text('Mona')).dy),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('start-shift-owner')));
    await tester.tap(find.byKey(const ValueKey('start-shift-owner')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('shift-pin-entry')),
      '284971',
    );
    await tester.tap(find.byKey(const ValueKey('submit-shift-pin')));
    await tester.pumpAndSettle();
    expect(find.text('On shift'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('switch-to-owner')));
    await tester.tap(find.byKey(const ValueKey('switch-to-owner')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-entry')),
      '284971',
    );
    await tester.tap(find.byKey(const ValueKey('unlock-owner-view')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('owner-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('owner-open-front-desk')));
    await tester.pumpAndSettle();
    expect(find.text('Will staff use this computer?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard sections provide their empty-state actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

    final emptySections = [
      ('customers', 'No customers yet', 'Add customer'),
      ('products', 'No products yet', 'Add product'),
      ('tasks', 'No tasks yet', 'Create task'),
      (
        'insights',
        'Insights will grow with your workspace',
        'View your spaces',
      ),
    ];
    for (final (section, heading, action) in emptySections) {
      await tester.tap(find.byKey(ValueKey('nav-$section')));
      await tester.pumpAndSettle();
      expect(find.text(heading), findsOneWidget);
      expect(find.text(action), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('nav-bookings')));
    await tester.pumpAndSettle();
    expect(find.text('No bookings yet'), findsOneWidget);
    expect(
      find.text('When staff book on Today, it shows up here.'),
      findsOneWidget,
    );
    expect(find.text('Open the front desk'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-staff')));
    await tester.pumpAndSettle();
    expect(
      find.text('Runs the front desk until you add staff'),
      findsOneWidget,
    );
    await tester.tap(find.text('Set owner PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-entry')),
      '284971',
    );
    await tester.enterText(
      find.byKey(const ValueKey('owner-pin-confirm')),
      '284971',
    );
    await tester.tap(find.byKey(const ValueKey('save-owner-pin')));
    await tester.pumpAndSettle();
    expect(setup.ownerPin, '284971');
    expect(find.text('Change owner PIN'), findsOneWidget);

    await tester.tap(find.text('Add staff'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-staff-name')),
      'Mona',
    );
    await tester.enterText(find.byKey(const ValueKey('new-staff-pin')), '2468');
    await tester.tap(find.byKey(const ValueKey('save-new-staff')));
    await tester.pumpAndSettle();
    expect(setup.staff.map((member) => member.name), contains('Mona'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('front desk visits update customers and money totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));
    await tester.tap(find.byKey(const ValueKey('nav-today')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Today page');
    await tester.tap(find.text('Check in').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Check-in form');
    await tester.enterText(
      find.byKey(const ValueKey('checkin-customer-name')),
      'Rania',
    );
    await tester.enterText(find.byKey(const ValueKey('checkin-charge')), '50');
    await tester.tap(find.byKey(const ValueKey('submit-checkin')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'After check-in');

    expect(find.text('Rania'), findsOneWidget);
    await tester.tap(find.text('Check out'));
    await tester.pumpAndSettle();
    expect(find.text('No one is checked in right now.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('switch-to-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-customers')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Customers page');
    expect(find.text('Rania'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-money')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Money page');
    expect(find.text('50 EGP'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tasks, bookings, products and money can be created', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

    await tester.tap(find.byKey(const ValueKey('nav-tasks')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workspace-task-title')),
      'Wipe desks',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Wipe desks'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-products')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workspace-product-name')),
      'Coffee',
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace-product-price')),
      '30',
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace-product-cost')),
      '12',
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace-product-stock')),
      '6',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    await tester.tap(find.byTooltip('Add stock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '3');
    await tester.enterText(find.byType(TextFormField).last, '10');
    await tester.tap(find.text('Add stock'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-bookings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New booking'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workspace-booking-customer')),
      'Rania',
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace-booking-amount')),
      '800',
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace-booking-paid-amount')),
      '300',
    );
    await tester.tap(find.text('Save booking'));
    await tester.pumpAndSettle();
    expect(find.text('Rania'), findsOneWidget);
    expect(find.text('Shared areas'), findsOneWidget);
    expect(find.text('Shared area'), findsOneWidget);
    expect(find.text('In use now'), findsOneWidget);
    expect(find.text('Paid 300 EGP'), findsOneWidget);
    expect(find.text('Owes 500 EGP'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-money')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add money in').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workspace-money-description')),
      'Desk rental',
    );
    await tester.enterText(
      find.byKey(const ValueKey('workspace-money-amount')),
      '50',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Desk rental'), findsOneWidget);
    expect(find.text('50 EGP'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bookings can be filtered by date presets', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day, 10);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    final repository = WorkspaceRepository();
    repository.createCustomer(
      Customer(id: 'today-customer', name: 'Today customer'),
    );
    repository.createCustomer(
      Customer(id: 'tomorrow-customer', name: 'Tomorrow customer'),
    );
    repository.createBooking(
      Booking(
        id: 'today-booking',
        customerId: 'today-customer',
        kind: BookingKind.oneTime,
        startsAt: todayStart,
        endsAt: todayStart.add(const Duration(hours: 1)),
        spaceType: SetupSpaceType.sharedArea,
        spaceName: 'Shared area',
      ),
    );
    repository.createBooking(
      Booking(
        id: 'tomorrow-booking',
        customerId: 'tomorrow-customer',
        kind: BookingKind.oneTime,
        startsAt: tomorrowStart,
        endsAt: tomorrowStart.add(const Duration(hours: 1)),
        spaceType: SetupSpaceType.sharedArea,
        spaceName: 'Shared area',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(setup: setup, repository: repository),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('nav-bookings')));
    await tester.pumpAndSettle();

    expect(find.text('Today customer'), findsOneWidget);
    expect(find.text('Tomorrow customer'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('workspace-booking-date-filter')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace-booking-date-from')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('workspace-booking-date-preset-Tomorrow')),
    );
    await tester.tap(
      find.byKey(const ValueKey('workspace-booking-date-apply')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today customer'), findsNothing);
    expect(find.text('Tomorrow customer'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('workspace-booking-date-filter')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workspace-booking-date-apply')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace data pages fit on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));
    for (final section in [
      'today',
      'bookings',
      'customers',
      'tasks',
      'money',
      'insights',
      'spaces',
      'products',
      'staff',
      'settings',
    ]) {
      await tester.tap(find.byKey(const ValueKey('dashboard-drawer-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('nav-$section')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$section page');
    }

    for (final label in [
      'Customer questions',
      'Cash & shifts',
      'WhatsApp & invoices',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label settings');
    }
  });

  testWidgets('cash reconciliation records a closing shift count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));
    await tester.tap(find.byKey(const ValueKey('owner-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('owner-open-front-desk')));
    await tester.pumpAndSettle();
    expect(find.text('On shift'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('switch-to-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash & shifts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use the cash drawer'));
    await tester.tap(find.text('Reconcile cash at shift end'));
    await tester.tap(find.text('Save cash settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-today')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End shift'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cash-count-entry')),
      '50',
    );
    await tester.tap(find.byKey(const ValueKey('save-cash-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch-to-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-money')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Counted 50 EGP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer questions are grouped by check-in and check-out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));
    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer questions'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add question'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('customer-question-prompt')),
      'What brings you in?',
    );
    await tester.enterText(
      find.byKey(const ValueKey('customer-question-options')),
      'Work, Study',
    );
    await tester.tap(find.text('Save question'));
    await tester.pumpAndSettle();
    expect(find.text('What brings you in?'), findsOneWidget);

    await tester.tap(find.text('At check-out'));
    await tester.pumpAndSettle();
    expect(find.text('No questions for check-out yet'), findsOneWidget);
    await tester.tap(find.byTooltip('Add question'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('customer-question-prompt')),
      'How was your visit?',
    );
    await tester.enterText(
      find.byKey(const ValueKey('customer-question-options')),
      'Great, Okay',
    );
    await tester.tap(find.text('Save question'));
    await tester.pumpAndSettle();
    expect(find.text('How was your visit?'), findsOneWidget);

    await tester.tap(find.text('At check-in'));
    await tester.pumpAndSettle();
    expect(find.text('What brings you in?'), findsOneWidget);
    expect(find.text('How was your visit?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every setup page scrolls on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    setup.hoursMode = SetupHoursMode.perDay;
    final pages = <(Widget, String?)>[
      (WorkspacePage(setup: setup), 'Your workspace'),
      (SpacesPage(setup: setup), 'Your spaces'),
      (PricesPage(setup: setup), 'Set your prices'),
      (KitchenPage(setup: setup), 'Your kitchen'),
      (StaffPage(setup: setup), 'Your staff'),
      (PreviewPage(setup: setup), 'Review your setup'),
      (DashboardPage(setup: setup), null),
    ];

    for (final (page, title) in pages) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      final titleFinder = title == null
          ? find.byKey(const ValueKey('dashboard-overview'))
          : find.text(title);
      if (title == null) expect(titleFinder, findsOneWidget);
      final pageScroll = title == 'Your workspace'
          ? find.byKey(const PageStorageKey<String>('workspace-setup'))
          : find.ancestor(
              of: titleFinder,
              matching: find.byType(SingleChildScrollView),
            );
      expect(pageScroll, findsOneWidget);
      await tester.drag(pageScroll, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('login page validates inputs and fits mobile layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up and login links navigate between authentication pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'login locks for five minutes after five failed authentications',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var authenticationCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            authenticate: (email, password) async {
              authenticationCalls++;
              return LoginAuthenticationResult.invalidCredentials;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('login-email')),
        'team@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'password',
      );

      final loginButton = find.byKey(const ValueKey('login-submit'));
      for (var attempt = 0; attempt < 5; attempt++) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle();
      }

      expect(authenticationCalls, 5);
      expect(
        find.text('Too many attempts. Try again in 05:00.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(loginButton).onPressed, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Try again in 04:59'), findsOneWidget);

      await tester.pump(const Duration(minutes: 5));
      expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);
      expect(find.text('Log in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owner can switch between Owner view and Front desk Staff view',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
      await tester.pumpWidget(MaterialApp(home: DashboardPage(setup: setup)));

      expect(find.byKey(const ValueKey('dashboard-overview')), findsOneWidget);
      expect(find.text('Front desk'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('nav-today')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('front-desk-staff-view')), findsOneWidget);
      expect(find.text('Staff view'), findsWidgets);
      expect(find.byKey(const ValueKey('switch-to-owner')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('switch-to-owner')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dashboard-overview')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
