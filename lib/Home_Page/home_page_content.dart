import 'package:flutter/material.dart';
import 'package:grid_os/theme/app_theme.dart';

const _muted = AppColors.homeMuted;
const _green = AppColors.homeGreen;
const _paleGreen = AppColors.homePaleGreen;
const _line = AppColors.homeLine;

class GridOsHomePage extends StatefulWidget {
  const GridOsHomePage({super.key, required this.isMobile});

  final bool isMobile;

  @override
  State<GridOsHomePage> createState() => _GridOsHomePageState();
}

class _GridOsHomePageState extends State<GridOsHomePage> {
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _plansKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: 0.06,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 22 : 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 42 : 74),
                    _buildHero(isMobile),
                    SizedBox(height: isMobile ? 52 : 76),
                    _buildTrustRow(isMobile),
                    SizedBox(height: isMobile ? 76 : 112),
                    _buildFeatures(isMobile),
                    SizedBox(height: isMobile ? 72 : 104),
                    _buildPlans(isMobile),
                    const SizedBox(height: 48),
                    _buildFooter(isMobile),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 16 : 24),
      child: Row(
        children: [
          const _Brand(),
          const Spacer(),
          if (!isMobile) ...[
            _NavButton(label: 'Plans', onPressed: () => _scrollTo(_plansKey)),
            const SizedBox(width: 26),
            _NavButton(
              label: 'About',
              onPressed: () => _scrollTo(_featuresKey),
            ),
            const SizedBox(width: 30),
            _PrimaryButton(
              label: 'Get started',
              onPressed: () => Navigator.of(context).pushNamed('/sign-up'),
              compact: true,
            ),
          ] else
            IconButton(
              tooltip: 'View plans',
              onPressed: () => _scrollTo(_plansKey),
              style: AppButtonStyles.homeIcon,
              icon: const Icon(Icons.arrow_downward_rounded, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isMobile) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _paleGreen,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: _green, size: 15),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'A smarter way to run your space',
                  style: AppTextStyles.heroBadge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Text.rich(
          TextSpan(
            style: AppTextStyles.heroHeading(isMobile),
            children: const [
              TextSpan(text: 'Make room\nfor '),
              TextSpan(
                text: 'better work.',
                style: AppTextStyles.heroHighlight,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'The all-in-one workspace platform that helps you manage your people, places, and day-to-day operations — beautifully.',
          style: AppTextStyles.heroBody,
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _PrimaryButton(
              label: 'Explore plans',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _scrollTo(_plansKey),
            ),
            OutlinedButton(
              onPressed: () => _scrollTo(_featuresKey),
              style: AppButtonStyles.homeSecondary,
              child: const Text(
                'See how it works',
                style: AppTextStyles.navButton,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 17, color: _green),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Easy to set up  ·  Made for modern teams',
                style: AppTextStyles.heroFootnote,
              ),
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          copy,
          const SizedBox(height: 42),
          const _WorkspacePreview(isMobile: true),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 10, child: copy),
        const SizedBox(width: 48),
        const Expanded(flex: 11, child: _WorkspacePreview(isMobile: false)),
      ],
    );
  }

  Widget _buildTrustRow(bool isMobile) {
    final companies = const [
      ('NORTHSTAR', Icons.explore_outlined),
      ('COMMON GROUND', Icons.circle_outlined),
      ('FIELDWORK', Icons.grass_rounded),
      ('MONDAY CO.', Icons.wb_sunny_outlined),
    ];
    return Column(
      children: [
        const Text(
          'A better workday starts with a better-run space',
          textAlign: TextAlign.center,
          style: AppTextStyles.trustCaption,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: isMobile ? 24 : 54,
          runSpacing: 20,
          children: [
            for (final company in companies)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(company.$2, size: 20, color: AppColors.partnerIcon),
                  const SizedBox(width: 7),
                  Text(company.$1, style: AppTextStyles.partnerName),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatures(bool isMobile) {
    final features = [
      (
        Icons.meeting_room_outlined,
        'Spaces that work',
        'Keep rooms, desks, and shared areas organized and easy to book.',
      ),
      (
        Icons.groups_2_outlined,
        'Teams in sync',
        'Give everyone a clear view of where to be and what is available.',
      ),
      (
        Icons.insights_rounded,
        'Decisions made simple',
        'See how your space is being used and make every square foot count.',
      ),
    ];
    return Column(
      key: _featuresKey,
      children: [
        const _SectionHeading(
          eyebrow: 'LESS ADMIN. MORE MOMENTUM.',
          title: 'Everything in its right place.',
          subtitle: 'One calm, connected way to manage the moving parts of your workspace.',
        ),
        const SizedBox(height: 34),
        if (isMobile)
          Column(
            children: [
              for (var index = 0; index < features.length; index++) ...[
                _FeatureCard(
                  icon: features[index].$1,
                  title: features[index].$2,
                  description: features[index].$3,
                ),
                if (index != features.length - 1) const SizedBox(height: 14),
              ],
            ],
          )
        else
          Row(
            children: [
              for (var index = 0; index < features.length; index++) ...[
                Expanded(
                  child: _FeatureCard(
                    icon: features[index].$1,
                    title: features[index].$2,
                    description: features[index].$3,
                  ),
                ),
                if (index != features.length - 1) const SizedBox(width: 18),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildPlans(bool isMobile) {
    return Container(
      key: _plansKey,
      padding: EdgeInsets.all(isMobile ? 24 : 46),
      decoration: BoxDecoration(
        color: AppColors.planBackground,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.planBorder),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_planCopy(), const SizedBox(height: 28), _planCard()],
            )
          : Row(
              children: [
                Expanded(flex: 11, child: _planCopy()),
                const SizedBox(width: 48),
                Expanded(flex: 9, child: _planCard()),
              ],
            ),
    );
  }

  Widget _planCopy() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('A SPACE THAT GROWS WITH YOU', style: AppTextStyles.planEyebrow),
        SizedBox(height: 14),
        Text(
          'Your next great workday starts here.',
          style: AppTextStyles.planHeading,
        ),
        SizedBox(height: 12),
        Text(
          'Bring your workspace together with a plan that fits the way your team works.',
          style: AppTextStyles.planDescription,
        ),
      ],
    );
  }

  Widget _planCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.planCardBorder),
        boxShadow: AppShadows.planCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'GridOS for your team',
                  style: AppTextStyles.planCardTitle,
                ),
              ),
              Icon(Icons.stars_rounded, color: _green, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          const _PlanPerk(label: 'Space and room management'),
          const SizedBox(height: 11),
          const _PlanPerk(label: 'Simple team scheduling'),
          const SizedBox(height: 11),
          const _PlanPerk(label: 'Useful workspace insights'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'Start your subscription',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.of(context).pushNamed('/sign-up'),
            ),
          ),
          const SizedBox(height: 9),
          const Center(
            child: Text(
              'Flexible plans for the way you work',
              style: AppTextStyles.planFootnote,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _Brand(small: true),
        if (!isMobile)
          const Text('Make room for better work.', style: AppTextStyles.footer),
        const Text('© GridOS', style: AppTextStyles.footer),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 26.0 : 34.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(
              small ? AppRadii.brandSmall : AppRadii.control,
            ),
          ),
          child: Icon(
            Icons.grid_view_rounded,
            color: AppColors.white,
            size: size * .6,
          ),
        ),
        SizedBox(width: small ? 8 : 10),
        Text('GridOS', style: AppTextStyles.brand(small: small)),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: AppButtonStyles.homeNavigation,
      child: Text(label, style: AppTextStyles.navButton),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: AppButtonStyles.homePrimary(compact: compact),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (icon != null) ...[const SizedBox(width: 9), Icon(icon, size: 17)],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionEyebrow,
        ),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionSubtitle,
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(AppRadii.featureCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: BorderRadius.circular(AppRadii.icon),
            ),
            child: Icon(icon, color: _green, size: 21),
          ),
          const SizedBox(height: 19),
          Text(title, style: AppTextStyles.featureTitle),
          const SizedBox(height: 8),
          Text(description, style: AppTextStyles.featureDescription),
        ],
      ),
    );
  }
}

class _PlanPerk extends StatelessWidget {
  const _PlanPerk({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: _green, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.perk)),
      ],
    );
  }
}

class _WorkspacePreview extends StatelessWidget {
  const _WorkspacePreview({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.previewBackground,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.previewBorder),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.previewCard),
          boxShadow: AppShadows.previewCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Workspace overview',
                    style: AppTextStyles.workspaceTitle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _paleGreen,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: const Text('●  Live', style: AppTextStyles.liveLabel),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tuesday, October 24',
              style: AppTextStyles.workspaceDate,
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                Expanded(
                  child: _MetricTile(
                    label: 'People in',
                    value: '38',
                    change: '+12%',
                    icon: Icons.people_alt_outlined,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Rooms free',
                    value: '6',
                    change: 'right now',
                    icon: Icons.meeting_room_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Today at a glance',
              style: AppTextStyles.workspaceSectionTitle,
            ),
            const SizedBox(height: 10),
            const Expanded(child: _RoomSchedule()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.insightBackground,
                borderRadius: BorderRadius.circular(AppRadii.icon),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: _green, size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your space is 82% utilized this week',
                      style: AppTextStyles.workspaceInsight,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: _muted, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
  });

  final String label;
  final String value;
  final String change;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.metricBackground,
        borderRadius: BorderRadius.circular(AppRadii.icon),
        border: Border.all(color: AppColors.metricBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _muted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.metricLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.metricValue),
              const SizedBox(width: 6),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    change,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.metricChange.copyWith(
                      color: change.startsWith('+') ? _green : _muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomSchedule extends StatelessWidget {
  const _RoomSchedule();

  static const _events = [
    ('09:00', 'Design sync', 'Studio room', 'AM'),
    ('10:30', 'Weekly planning', 'Focus room', 'JL'),
    ('12:00', 'Client catch-up', 'Meeting room 2', 'SK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _events.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: index == _events.length - 1 ? 0 : 7,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      _events[index].$1,
                      style: AppTextStyles.roomTime,
                    ),
                  ),
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: index == 1
                          ? AppColors.scheduleHighlight
                          : AppColors.scheduleBar,
                      borderRadius: BorderRadius.circular(AppRadii.scheduleBar),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _events[index].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.roomTitle,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _events[index].$3,
                          style: AppTextStyles.roomDescription,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: index == 1
                        ? AppColors.scheduleAvatar
                        : _paleGreen,
                    child: Text(
                      _events[index].$4,
                      style: AppTextStyles.roomAvatar,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
