import 'package:flutter/material.dart';
import 'package:grid_os/Home_Page/desktop_size.dart';
import 'package:grid_os/Home_Page/mobile_size.dart';
import 'package:grid_os/Sign_Up_pages/first_sign_up.dart';
import 'package:grid_os/Sign_Up_pages/login_page.dart';
import 'package:grid_os/Sign_Up_pages/sign_up_models.dart';
import 'package:grid_os/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.submitSignup});

  final SignUpSubmitter? submitSignup;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ResponsivePage(),
      routes: {
        '/sign-up': (context) =>
            FirstSignUpPage(submitSignup: submitSignup),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return const MobilePage();
        }
        return const DesktopPage();
      },
    );
  }
}
