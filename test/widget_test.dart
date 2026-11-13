import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    expect(find.text('Almost there'), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-full-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-workspace-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace setup validates details and waits for the API', (
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

    await tester.tap(find.byKey(const ValueKey('start-setup')));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('signup-full-name')),
      'Karim Hassan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-workspace-name')),
      'Ramla Workspace',
    );
    await tester.tap(find.byKey(const ValueKey('start-setup')));
    await tester.pumpAndSettle();

    expect(find.text('Account setup is waiting for the API.'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('start-setup')));
    await tester.pumpAndSettle();

    expect(submittedRequest?.email, 'team@example.com');
    expect(submittedRequest?.password, 'StrongPass1!');
    expect(submittedRequest?.fullName, 'Karim Hassan');
    expect(submittedRequest?.workspaceName, 'Ramla Workspace');
    expect(find.text('Your account is ready.'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
