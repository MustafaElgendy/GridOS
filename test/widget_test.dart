import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:grid_os/main.dart';

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
    expect(find.text('Will staff use this computer?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(setup.staffUsesThisComputer, isFalse);
    expect(find.text('GridOS dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every setup page scrolls on a compact screen', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final setup = StartupSetup(ownerName: 'Karim', workspaceName: 'GridOS');
    setup.hoursMode = SetupHoursMode.perDay;
    final pages = <(Widget, String)>[
      (WorkspacePage(setup: setup), 'Your workspace'),
      (SpacesPage(setup: setup), 'Your spaces'),
      (PricesPage(setup: setup), 'Set your prices'),
      (KitchenPage(setup: setup), 'Your kitchen'),
      (StaffPage(setup: setup), 'Your staff'),
      (PreviewPage(setup: setup), 'Review your setup'),
    ];

    for (final (page, title) in pages) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      final pageScroll = title == 'Your workspace'
          ? find.byKey(const PageStorageKey<String>('workspace-setup'))
          : find.ancestor(
              of: find.text(title),
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
}
