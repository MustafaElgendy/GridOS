import 'package:flutter/material.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/spaces_page_widgets.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_models.dart';
import 'package:grid_os/Sign_Up_pages/Startup_Pages/startup_setup_widgets.dart';
import 'package:grid_os/theme/app_theme.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key, required this.setup});

  final StartupSetup setup;

  Future<void> _goToDashboard(BuildContext context) async {
    if (setup.staff.isNotEmpty && setup.staffUsesThisComputer == null) {
      final usesComputer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Will staff use this computer?'),
          content: const Text(
            'Staff can use their PIN to access this workspace on this computer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (!context.mounted || usesComputer == null) return;
      setup.staffUsesThisComputer = usesComputer;
    }

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
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        title: const Text('GridOS dashboard'),
        backgroundColor: AppColors.authBackground,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SetupPanel(
              backgroundColor: AppColors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.authGreen,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${setup.workspaceName} is ready',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authHeading,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${setup.selectedSpaces.length} space types · '
                    '${setup.country.name}${setup.city == null ? '' : ', ${setup.city}'}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authDescription,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
