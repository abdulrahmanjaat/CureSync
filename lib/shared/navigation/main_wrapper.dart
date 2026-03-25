import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final initial = (user?.displayName ?? 'U')[0].toUpperCase();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2F2E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _DockItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _DockItem(
              icon: Icons.medication_rounded,
              label: 'Meds',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            /// Avatar tab
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.all(_currentIndex == 2 ? 3.w : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _currentIndex == 2
                      ? Border.all(
                          color: const Color(0xFF0D9488),
                          width: 2,
                        )
                      : null,
                ),
                child: CircleAvatar(
                  radius: 16.w,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.3),
                  backgroundImage:
                      user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? Text(
                          initial,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16.w : 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0D9488).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22.w,
              color: isActive
                  ? const Color(0xFF5EEAD4)
                  : Colors.white.withValues(alpha: 0.4),
            ),
            if (isActive) ...[
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5EEAD4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
