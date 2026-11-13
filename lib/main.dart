import 'package:flutter/material.dart';
import 'package:grid_os/Home_Page/desktop_size.dart';
import 'package:grid_os/Home_Page/mobile_size.dart';
import 'package:grid_os/Sign_Up_pages/first_sign_up.dart';
import 'package:grid_os/Sign_Up_pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFCFDFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF198754),
          surface: const Color(0xFFFCFDFB),
        ),
        fontFamily: 'Arial',
      ),
      home: const ResponsivePage(),
      routes: {
        '/sign-up': (context) => const FirstSignUpPage(),
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
