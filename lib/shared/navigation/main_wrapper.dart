import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/patient/presentation/screens/home_screen.dart';
import '../../features/patient/presentation/screens/medications_screen.dart';
import '../../features/patient/presentation/screens/profile_screen.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    MedicationsScreen(),
    ProfileScreen(),
  ];

  final _navItems = const [
    _NavData(icon: Icons.home_rounded, label: 'Home'),
    _NavData(icon: Icons.medication_rounded, label: 'Meds'),
    _NavData(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
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
      margin: EdgeInsets.fromLTRB(32.w, 0, 32.w, 24.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64.h,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(100.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
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
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActive ? 18.w : 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF0D9488)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 22.w,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                            if (isActive) ...[
                              SizedBox(width: 6.w),
                              Text(
                                item.label,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
