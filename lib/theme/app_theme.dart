import 'package:flutter/material.dart';

abstract final class AppColors {
  static const scaffold = Color(0xFFFCFDFB);
  static const themeSeed = Color(0xFF198754);
  static const white = Color(0xFFFFFFFF);

  static const homeInk = Color(0xFF17231C);
  static const homeMuted = Color(0xFF68756D);
  static const homeGreen = Color(0xFF16834A);
  static const homePaleGreen = Color(0xFFEAF5ED);
  static const homeLine = Color(0xFFE8ECE8);
  static const partnerIcon = Color(0xFF98A39B);
  static const partnerName = Color(0xFF89958C);
  static const planBackground = Color(0xFFF0F7F1);
  static const planBorder = Color(0xFFE1EEE3);
  static const planCardBorder = Color(0xFFE3EBE4);
  static const planShadow = Color(0x0B18331F);
  static const previewBackground = Color(0xFFF0F5F0);
  static const previewBorder = Color(0xFFE7EDE7);
  static const previewShadow = Color(0x1018331F);
  static const insightBackground = Color(0xFFF6F8F6);
  static const metricBackground = Color(0xFFF8FAF8);
  static const metricBorder = Color(0xFFF0F2F0);
  static const scheduleHighlight = Color(0xFFF0BD6B);
  static const scheduleBar = Color(0xFF78B68B);
  static const scheduleAvatar = Color(0xFFFCEEDB);

  static const authBackground = Color(0xFFF6F7F3);
  static const authBorder = Color(0xFFE6E9E4);
  static const authInk = Color(0xFF202722);
  static const authMuted = Color(0xFF737B75);
  static const authGreen = Color(0xFF117562);
  static const error = Color(0xFFB3261E);
  static const authShadow = Color(0x080D2017);
  static const googleBorder = Color(0xFFB8BDB9);
  static const googleInk = Color(0xFF6D746F);
  static const inputHint = Color(0xFF9AA19B);
}

abstract final class AppRadii {
  static const brandTile = 1.5;
  static const brandSmall = 8.0;
  static const control = 10.0;
  static const icon = 12.0;
  static const button = 13.0;
  static const authCard = 16.0;
  static const featureCard = 18.0;
  static const previewCard = 19.0;
  static const card = 20.0;
  static const panel = 28.0;
  static const pill = 30.0;
  static const scheduleBar = 3.0;
}

abstract final class AppShadows {
  static const authCard = [
    BoxShadow(
      color: AppColors.authShadow,
      blurRadius: 18,
      offset: Offset(0, 5),
    ),
  ];

  static const planCard = [
    BoxShadow(
      color: AppColors.planShadow,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const previewCard = [
    BoxShadow(
      color: AppColors.previewShadow,
      blurRadius: 24,
      offset: Offset(0, 9),
    ),
  ];
}

abstract final class AppTextStyles {
  static const authHeading = TextStyle(
    color: AppColors.authInk,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const authDescription = TextStyle(
    color: AppColors.authMuted,
    fontSize: 13,
    height: 1.45,
  );
  static const authFieldLabel = TextStyle(
    color: AppColors.authInk,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const authHint = TextStyle(color: AppColors.inputHint, fontSize: 13);
  static const authHelper = TextStyle(
    color: AppColors.authMuted,
    fontSize: 11,
    height: 1.4,
  );
  static const authSmallText = TextStyle(
    color: AppColors.authMuted,
    fontSize: 12,
  );
  static const authLink = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
  );
  static const authBrand = TextStyle(
    color: AppColors.authInk,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const googleMark = TextStyle(
    color: AppColors.googleInk,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static const googleButton = TextStyle(fontWeight: FontWeight.w600);
  static const authDivider = TextStyle(
    color: AppColors.authMuted,
    fontSize: 11,
  );
  static const authSupport = TextStyle(
    color: AppColors.authGreen,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const authButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const heroBadge = TextStyle(
    color: AppColors.homeGreen,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static TextStyle heroHeading(bool isMobile) => TextStyle(
    color: AppColors.homeInk,
    fontSize: isMobile ? 43 : 58,
    height: 1.04,
    letterSpacing: isMobile ? -1.6 : -2.6,
    fontWeight: FontWeight.w700,
  );
  static const heroHighlight = TextStyle(color: AppColors.homeGreen);
  static const heroBody = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 16,
    height: 1.7,
  );
  static const heroFootnote = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 12,
  );
  static const trustCaption = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 13,
  );
  static const partnerName = TextStyle(
    color: AppColors.partnerName,
    fontSize: 12,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w800,
  );
  static const planEyebrow = TextStyle(
    color: AppColors.homeGreen,
    fontSize: 11,
    letterSpacing: 1.3,
    fontWeight: FontWeight.w800,
  );
  static const planHeading = TextStyle(
    color: AppColors.homeInk,
    fontSize: 32,
    height: 1.15,
    letterSpacing: -1,
    fontWeight: FontWeight.w700,
  );
  static const planDescription = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 14,
    height: 1.65,
  );
  static const planCardTitle = TextStyle(
    color: AppColors.homeInk,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const planFootnote = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 11,
  );
  static const footer = TextStyle(color: AppColors.homeMuted, fontSize: 12);
  static TextStyle brand({required bool small}) => TextStyle(
    color: AppColors.homeInk,
    fontSize: small ? 16 : 21,
    letterSpacing: -0.7,
    fontWeight: FontWeight.w800,
  );
  static const navButton = TextStyle(fontWeight: FontWeight.w600);
  static TextStyle homeButton({required bool compact}) =>
      TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w700);
  static const sectionEyebrow = TextStyle(
    color: AppColors.homeGreen,
    fontSize: 11,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w800,
  );
  static const sectionTitle = TextStyle(
    color: AppColors.homeInk,
    fontSize: 32,
    height: 1.2,
    letterSpacing: -0.9,
    fontWeight: FontWeight.w700,
  );
  static const sectionSubtitle = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 14,
    height: 1.6,
  );
  static const featureTitle = TextStyle(
    color: AppColors.homeInk,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const featureDescription = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 13,
    height: 1.6,
  );
  static const perk = TextStyle(color: AppColors.homeMuted, fontSize: 13);
  static const workspaceTitle = TextStyle(
    color: AppColors.homeInk,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const liveLabel = TextStyle(
    color: AppColors.homeGreen,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
  static const workspaceDate = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 10,
  );
  static const workspaceSectionTitle = TextStyle(
    color: AppColors.homeInk,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const workspaceInsight = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static const metricLabel = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 10,
  );
  static const metricValue = TextStyle(
    color: AppColors.homeInk,
    fontSize: 22,
    height: 1,
    fontWeight: FontWeight.w700,
  );
  static const metricChange = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );
  static const roomTime = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );
  static const roomTitle = TextStyle(
    color: AppColors.homeInk,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
  static const roomDescription = TextStyle(
    color: AppColors.homeMuted,
    fontSize: 9,
  );
  static const roomAvatar = TextStyle(
    color: AppColors.homeGreen,
    fontSize: 7,
    fontWeight: FontWeight.w800,
  );
}

abstract final class AppButtonStyles {
  static ButtonStyle homePrimary({required bool compact}) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.homeGreen,
      foregroundColor: AppColors.white,
      minimumSize: Size.zero,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 20,
        vertical: compact ? 13 : 17,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      textStyle: AppTextStyles.homeButton(compact: compact),
    );
  }

  static const homeSecondary = ButtonStyle(
    foregroundColor: WidgetStatePropertyAll(AppColors.homeInk),
    side: WidgetStatePropertyAll(BorderSide(color: AppColors.homeLine)),
    minimumSize: WidgetStatePropertyAll(Size.zero),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
      ),
    ),
    textStyle: WidgetStatePropertyAll(AppTextStyles.navButton),
  );

  static final homeNavigation = TextButton.styleFrom(
    foregroundColor: AppColors.homeMuted,
    textStyle: AppTextStyles.navButton,
  );

  static final homeIcon = IconButton.styleFrom(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.homeInk,
    side: const BorderSide(color: AppColors.homeLine),
  );

  static final authPrimary = _authPrimaryStyle();

  static final authPrimaryDisabled = _authPrimaryStyle(
    disabledBackgroundColor: AppColors.authGreen.withValues(alpha: .5),
    disabledForegroundColor: AppColors.white,
  );

  static final authGoogle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.authInk,
    side: const BorderSide(color: AppColors.authBorder),
    minimumSize: const Size(0, 44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
  );

  static final authInline = TextButton.styleFrom(
    foregroundColor: AppColors.authGreen,
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  static final authToggle = TextButton.styleFrom(
    foregroundColor: AppColors.authGreen,
    padding: const EdgeInsets.symmetric(horizontal: 12),
  );

  static ButtonStyle _authPrimaryStyle({
    Color? disabledBackgroundColor,
    Color? disabledForegroundColor,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.authGreen,
      foregroundColor: AppColors.white,
      disabledBackgroundColor: disabledBackgroundColor,
      disabledForegroundColor: disabledForegroundColor,
      minimumSize: const Size(0, 46),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      textStyle: AppTextStyles.authButton,
    );
  }
}

abstract final class AppInputStyles {
  static InputDecoration authentication({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.authHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      isDense: true,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.authBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.authBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.authGreen, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
    );
  }
}

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.scaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.themeSeed,
      surface: AppColors.scaffold,
    ),
    fontFamily: 'Arial',
    filledButtonTheme: FilledButtonThemeData(
      style: AppButtonStyles.authPrimary,
    ),
  );
}
