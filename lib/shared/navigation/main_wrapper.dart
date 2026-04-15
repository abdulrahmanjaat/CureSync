import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/role_provider.dart';

// Patient tabs
import '../../features/patient/presentation/screens/home_screen.dart';
import '../../features/patient/presentation/screens/medications_screen.dart';
import '../../features/patient/presentation/screens/patients_tab_screen.dart';
import '../../features/discovery/presentation/screens/discovery_hub_screen.dart';

// Family tabs
import '../../features/family/presentation/screens/family_home_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_alerts_screen.dart';
import '../../features/shared/presentation/screens/schedule_screen.dart';

// Pro-Caregiver tabs
import '../../features/caregiver/presentation/screens/caregiver_home_screen.dart';

// Manager tabs
import '../../features/manager/presentation/screens/manager_dashboard_screen.dart';
// ── Nav sets ──────────────────────────────────────────────────────────────────

const _patientScreens = [
  HomeScreen(),
  MedicationsScreen(),
  PatientsTabScreen(),
  DiscoveryHubScreen(),
];

const _patientNavItems = [
  _NavData(icon: Icons.home_rounded, label: 'Home'),
  _NavData(icon: Icons.medication_rounded, label: 'Meds'),
  _NavData(icon: Icons.people_rounded, label: 'Patients'),
  _NavData(icon: Icons.explore_rounded, label: 'Discover'),
];

const _familyScreens = [
  FamilyHomeScreen(),
  CaregiverAlertsScreen(),
  ScheduleScreen(),
];

const _familyNavItems = [
  _NavData(icon: Icons.home_rounded, label: 'Home'),
  _NavData(icon: Icons.notifications_rounded, label: 'Alerts'),
  _NavData(icon: Icons.calendar_today_rounded, label: 'Schedule'),
];

const _proScreens = [
  CaregiverHomeScreen(),
  CaregiverAlertsScreen(),
  ScheduleScreen(),
];

const _proNavItems = [
  _NavData(icon: Icons.grid_view_rounded, label: 'Home'),
  _NavData(icon: Icons.notifications_rounded, label: 'Alerts'),
  _NavData(icon: Icons.calendar_today_rounded, label: 'Schedule'),
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
    final roleStr = userData.valueOrNull?.role;
    final role = UserRoleX.fromString(roleStr);

    final (screens, navItems) = switch (role) {
      UserRole.family => (_familyScreens, _familyNavItems),
      UserRole.proCaregiver => (_proScreens, _proNavItems),
      UserRole.manager => (_managerScreens, _managerNavItems),
      _ => (_patientScreens, _patientNavItems), // patient + null fallback
    };

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
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
      ),
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

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 22.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64.h,
            padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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
            child: Row(
              children: List.generate(items.length, (i) {
                final isActive = i == currentIndex;
                final item = items[i];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.symmetric(horizontal: 1.w),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF2A2A3E),
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
                                            overflow:
                                                TextOverflow.ellipsis,
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
              }),
            ),
          ),
        ),
      ),
    );
  }
}
