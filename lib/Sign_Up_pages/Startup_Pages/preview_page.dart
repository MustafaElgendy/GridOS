import 'package:flutter/material.dart';
import 'package:grid_os/Main Pages/dashboard.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key, required this.setup});

  final StartupSetup setup;

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => SetupDashboardPage(setup: setup)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: SafeArea(
        child: Column(
          children: [
            SetupProgressAppBar(
              workspaceName: setup.workspaceName,
              title: 'Preview your setup',
              step: 6,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const PageStorageKey<String>('setup-preview'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Review your setup',
                          style: AppTextStyles.authHeading,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check your details. Use Edit to make changes before '
                          'opening your dashboard.',
                          style: AppTextStyles.authDescription,
                        ),
                        const SizedBox(height: 18),
                        SetupProgressSummary(
                          setup: setup,
                          activeStep: 6,
                          onEditStep: (step) => returnToSetupStep(
                            context,
                            currentStep: 6,
                            targetStep: step,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            key: const ValueKey('go-to-dashboard'),
                            onPressed: () => _goToDashboard(context),
                            child: const Text('Go to dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupDashboardPage extends StatelessWidget {
  const SetupDashboardPage({super.key, required this.setup});

  final StartupSetup setup;

  @override
  Widget build(BuildContext context) {
    return DashboardPage(setup: setup);
  }
}
