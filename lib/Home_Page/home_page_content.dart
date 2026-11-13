import 'package:flutter/material.dart';

const _ink = Color(0xFF17231C);
const _muted = Color(0xFF68756D);
const _green = Color(0xFF16834A);
const _paleGreen = Color(0xFFEAF5ED);
const _line = Color(0xFFE8ECE8);

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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 22 : 48,
                ),
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
            _NavButton(
              label: 'Plans',
              onPressed: () => _scrollTo(_plansKey),
            ),
            const SizedBox(width: 26),
            _NavButton(label: 'About', onPressed: () => _scrollTo(_featuresKey)),
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
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
              ),
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
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: _green, size: 15),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'A smarter way to run your space',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Text.rich(
          TextSpan(
            style: TextStyle(
              color: _ink,
              fontSize: isMobile ? 43 : 58,
              height: 1.04,
              letterSpacing: isMobile ? -1.6 : -2.6,
              fontWeight: FontWeight.w700,
            ),
            children: const [
              TextSpan(text: 'Make room\nfor '),
              TextSpan(
                text: 'better work.',
                style: TextStyle(color: _green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'The all-in-one workspace platform that helps you manage your people, places, and day-to-day operations — beautifully.',
          style: TextStyle(color: _muted, fontSize: 16, height: 1.7),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'See how it works',
                style: TextStyle(fontWeight: FontWeight.w600),
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
                style: TextStyle(color: _muted, fontSize: 12),
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
          style: TextStyle(color: _muted, fontSize: 13),
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
                  Icon(company.$2, size: 20, color: const Color(0xFF98A39B)),
                  const SizedBox(width: 7),
                  Text(
                    company.$1,
                    style: const TextStyle(
                      color: Color(0xFF89958C),
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
          subtitle:
              'One calm, connected way to manage the moving parts of your workspace.',
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
        color: const Color(0xFFF0F7F1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1EEE3)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _planCopy(),
                const SizedBox(height: 28),
                _planCard(),
              ],
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
        Text(
          'A SPACE THAT GROWS WITH YOU',
          style: TextStyle(
            color: _green,
            fontSize: 11,
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Your next great workday starts here.',
          style: TextStyle(
            color: _ink,
            fontSize: 32,
            height: 1.15,
            letterSpacing: -1,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Bring your workspace together with a plan that fits the way your team works.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.65),
        ),
      ],
    );
  }

  Widget _planCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B18331F),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'GridOS for your team',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
              style: TextStyle(color: _muted, fontSize: 11),
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
          const Text(
            'Make room for better work.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        const Text(
          '© GridOS',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
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
            borderRadius: BorderRadius.circular(small ? 8 : 10),
          ),
          child: Icon(Icons.grid_view_rounded, color: Colors.white, size: size * .6),
        ),
        SizedBox(width: small ? 8 : 10),
        Text(
          'GridOS',
          style: TextStyle(
            color: _ink,
            fontSize: small ? 16 : 21,
            letterSpacing: -.7,
            fontWeight: FontWeight.w800,
          ),
        ),
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
      style: TextButton.styleFrom(foregroundColor: _muted),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 20,
          vertical: compact ? 13 : 17,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: TextStyle(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (icon != null) ...[
            const SizedBox(width: 9),
            Icon(icon, size: 17),
          ],
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
          style: const TextStyle(
            color: _green,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 13),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 32,
            height: 1.2,
            letterSpacing: -.9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 14, height: 1.6),
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
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _paleGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _green, size: 21),
          ),
          const SizedBox(height: 19),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.6),
          ),
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ),
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
        color: const Color(0xFFF0F5F0),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7EDE7)),
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1018331F),
              blurRadius: 24,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Workspace overview',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _paleGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '●  Live',
                    style: TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tuesday, October 24',
              style: TextStyle(color: _muted, fontSize: 10),
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
              style: TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Expanded(
              child: _RoomSchedule(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: _green, size: 17),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your space is 82% utilized this week',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F2F0)),
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
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    change,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: change.startsWith('+') ? _green : _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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
              padding: EdgeInsets.only(bottom: index == _events.length - 1 ? 0 : 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      _events[index].$1,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: index == 1
                          ? const Color(0xFFF0BD6B)
                          : const Color(0xFF78B68B),
                      borderRadius: BorderRadius.circular(3),
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
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _events[index].$3,
                          style: const TextStyle(color: _muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: index == 1
                        ? const Color(0xFFFCEEDB)
                        : _paleGreen,
                    child: Text(
                      _events[index].$4,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
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
