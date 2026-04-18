import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/role_provider.dart';
import '../../features/caregiver/presentation/providers/caregiver_provider.dart';
import '../../features/caregiver/presentation/screens/caregiver_home_screen.dart';
import '../../shared/widgets/custom_bottom_sheet.dart';

// Patient tabs
import '../../features/patient/presentation/screens/home_screen.dart';
import '../../features/patient/presentation/screens/medications_screen.dart';
import '../../features/discovery/presentation/screens/discovery_hub_screen.dart';
import '../../features/patient/presentation/widgets/add_patient_sheet.dart';

// Family tabs
import '../../features/family/presentation/screens/family_home_screen.dart';
import '../../features/shared/presentation/screens/schedule_screen.dart';

// Pro-Caregiver tabs
import '../../features/caregiver/presentation/screens/pending_deals_screen.dart';

// Manager tabs
import '../../features/manager/presentation/screens/manager_dashboard_screen.dart';

// ── Nav sets ──────────────────────────────────────────────────────────────────

const _patientScreens = [
  HomeScreen(),
  MedicationsScreen(),
  DiscoveryHubScreen(),
];

const _patientNavItems = [
  _NavData(icon: Icons.home_rounded, label: 'Home'),
  _NavData(icon: Icons.medication_rounded, label: 'Meds'),
  _NavData(icon: Icons.explore_rounded, label: 'Discover'),
];

const _familyScreens = [
  FamilyHomeScreen(),
  ScheduleScreen(),
];

const _familyNavItems = [
  _NavData(icon: Icons.home_rounded, label: 'Home'),
  _NavData(icon: Icons.calendar_today_rounded, label: 'Schedule'),
];

const _proScreens = [
  CaregiverHomeScreen(),
  ScheduleScreen(),
  PendingDealsScreen(),
];

const _proNavItems = [
  _NavData(icon: Icons.grid_view_rounded, label: 'Home'),
  _NavData(icon: Icons.calendar_today_rounded, label: 'Schedule'),
  _NavData(icon: Icons.handshake_rounded, label: 'Requests'),
];

const _managerScreens = [
  ManagerDashboardScreen(),
  DiscoveryHubScreen(),
];

const _managerNavItems = [
  _NavData(icon: Icons.manage_accounts_rounded, label: 'Patients'),
  _NavData(icon: Icons.explore_rounded, label: 'Discover'),
];

// ── Main Wrapper ──────────────────────────────────────────────────────────────

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(currentUserDataProvider);
    final roleStr  = userData.valueOrNull?.role;
    final role     = UserRoleX.fromString(roleStr);

    final (screens, navItems) = switch (role) {
      UserRole.family      => (_familyScreens, _familyNavItems),
      UserRole.proCaregiver => (_proScreens, _proNavItems),
      UserRole.manager     => (_managerScreens, _managerNavItems),
      _                    => (_patientScreens, _patientNavItems),
    };

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    // Role-specific nav accent colour
    final activeColor = switch (role) {
      UserRole.manager => const Color(0xFFDB2777), // rose
      UserRole.family  => const Color(0xFF7C3AED), // purple
      _                => const Color(0xFF0D9488), // teal
    };

    // Manager gets a centre "+" FAB inside the nav bar
    VoidCallback? centerFab;
    if (role == UserRole.manager) {
      centerFab = () {
        HapticFeedback.lightImpact();
        CustomBottomSheet.show(
          context: context,
          useDraggable: false,
          child: const AddPatientSheet(),
        );
      };
    }

    // SOS overlay — only relevant for roles that have assigned patients.
    final showSos  = role == UserRole.proCaregiver || role == UserRole.family;
    final sosPatient = showSos ? ref.watch(sosTriggerProvider) : null;

    final scaffold = Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: safeIndex,
        items: navItems,
        onTap: (i) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = i);
        },
        activeColor: activeColor,
        onCenterFab: centerFab,
      ),
    );

    if (sosPatient == null) return scaffold;

    return Stack(
      children: [
        scaffold,
        SosAlertOverlay(
          patient: sosPatient,
          onNavigate: () =>
              context.push('/caregiver/patient/${sosPatient.patientId}'),
        ),
      ],
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData({required this.icon, required this.label});
}

// ── Floating Nav Bar ──────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavData> items;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final VoidCallback? onCenterFab;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.activeColor = const Color(0xFF0D9488),
    this.onCenterFab,
  });

  @override
  Widget build(BuildContext context) {
    // Insertion point for the centre FAB (between items[mid-1] and items[mid])
    final mid = items.length ~/ 2;

    // Build a single tab pill
    Widget buildTab(int i) {
      final isActive = i == currentIndex;
      final item     = items[i];
      return Expanded(
        child: GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(horizontal: 1.w),
            decoration: BoxDecoration(
              color: isActive ? activeColor : const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 20.w,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: isActive
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 5.w),
                              Flexible(
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Build the centre FAB button
    Widget buildFab() {
      return GestureDetector(
        onTap: onCenterFab,
        child: Container(
          width: 52.w,
          height: 52.w,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: activeColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.40),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, size: 26.w, color: Colors.white),
        ),
      );
    }

    // Assemble row: interleave FAB at the mid-point when provided
    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (onCenterFab != null && i == mid) children.add(buildFab());
      children.add(buildTab(i));
    }
    // Edge case: mid == items.length (0 or 1 item list)
    if (onCenterFab != null && mid >= items.length) children.add(buildFab());

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 22.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(children: children),
          ),
        ),
      ),
    );
  }
}
