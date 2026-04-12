import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─── 8 Premium Medical Avatars (no Firebase Storage required) ────────────────

const _medicalAvatars = [
  _AvatarOption(
    icon: Icons.medical_services_rounded,
    color: Color(0xFF0D9488),
    label: 'Medical',
  ),
  _AvatarOption(
    icon: Icons.favorite_rounded,
    color: Color(0xFFEF4444),
    label: 'Heart',
  ),
  _AvatarOption(
    icon: Icons.monitor_heart_rounded,
    color: Color(0xFF0891B2),
    label: 'Monitor',
  ),
  _AvatarOption(
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFDB2777),
    label: 'Hospital',
  ),
  _AvatarOption(
    icon: Icons.psychology_rounded,
    color: Color(0xFF7C3AED),
    label: 'Mind',
  ),
  _AvatarOption(
    icon: Icons.medication_rounded,
    color: Color(0xFFEA580C),
    label: 'Meds',
  ),
  _AvatarOption(
    icon: Icons.biotech_rounded,
    color: Color(0xFF16A34A),
    label: 'Bio',
  ),
  _AvatarOption(
    icon: Icons.shield_rounded,
    color: Color(0xFF475569),
    label: 'Shield',
  ),
];

class _AvatarOption {
  final IconData icon;
  final Color color;
  final String label;
  const _AvatarOption(
      {required this.icon, required this.color, required this.label});
}

// ─── Per-user avatar index — streamed from Drift, falls back to SharedPreferences

final _profileAvatarProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final userData = ref.watch(currentUserDataProvider).valueOrNull;
  if (user == null) return Stream.value(PreferencesService.avatarIndex);
  final role = userData?.role ?? 'patient';
  return db
      .watchProfileImage(user.uid, role)
      .map((img) => img?.avatarIndex ?? PreferencesService.avatarIndex);
});

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final userData = ref.watch(currentUserDataProvider).valueOrNull;
    final avatarIndex = ref.watch(_profileAvatarProvider).valueOrNull ?? 0;
    final selectedAvatar = _medicalAvatars[avatarIndex.clamp(
        0, _medicalAvatars.length - 1)];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: ListView(
          padding:
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          children: [
            // ── Back + title ──
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                  },
                  child: Container(
                    height: 38.w,
                    width: 38.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16.w, color: const Color(0xFF0F172A)),
                  ),
                ),
                SizedBox(width: 14.w),
                Text(
                  'Account',
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),

            // ── User info card ──
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF115E59), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar — tap to change
                  GestureDetector(
                    onTap: () => _pickAvatar(context, ref),
                    child: Container(
                      height: 64.w,
                      width: 64.w,
                      decoration: BoxDecoration(
                        color: selectedAvatar.color
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              selectedAvatar.icon,
                              size: 30.w,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              height: 18.w,
                              width: 18.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 10.w,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          user?.email ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color:
                                Colors.white.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            _roleLabel(userData?.role),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // ── Avatar picker hint ──
            Center(
              child: Text(
                'Tap avatar to choose your look',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),

            SizedBox(height: 28.h),

            // ── Settings section ──
            Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 12.h),

            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy & Security',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            SizedBox(height: 28.h),

            // ── Sign out ──
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await ref
                    .read(authControllerProvider.notifier)
                    .signOut();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 20.w, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // ── Delete account ──
            GestureDetector(
              onTap: () => _showDeleteDialog(context, ref),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color:
                          AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 20.w, color: AppColors.error),
                    SizedBox(width: 8.w),
                    Text(
                      'Delete Account',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32.h),

            Center(
              child: Text(
                'CureSync v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String? role) => switch (role) {
        'patient' => 'PATIENT',
        'family' => 'FAMILY',
        'pro_caregiver' => 'PRO CAREGIVER',
        _ => 'USER',
      };

  void _pickAvatar(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider).valueOrNull;
    final userData = ref.read(currentUserDataProvider).valueOrNull;
    final currentIndex = ref.read(_profileAvatarProvider).valueOrNull ?? 0;

    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPickerSheet(
        currentIndex: currentIndex,
        onPick: (i) {
          HapticFeedback.selectionClick();
          // Persist per-user in Drift; keep SharedPreferences as fallback
          if (user != null) {
            ref.read(appDatabaseProvider).upsertProfileImage(
                  user.uid,
                  userData?.role ?? 'patient',
                  i,
                );
          }
          PreferencesService.setAvatarIndex(i);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text('Delete Account',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SecureStorageService.clearAll();
                await PreferencesService.clearAll();
                await ref
                    .read(authControllerProvider.notifier)
                    .signOut();
                SnackbarService.showInfo('Account deleted');
              } catch (e) {
                SnackbarService.showError('Failed to delete account');
              }
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar Picker Bottom Sheet ───────────────────────────────────────────────

class _AvatarPickerSheet extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onPick;

  const _AvatarPickerSheet({
    required this.currentIndex,
    required this.onPick,
  });

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Choose Your Avatar',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Free plan — no photo upload needed',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24.h),

          // Grid of 8 avatars
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1,
            ),
            itemCount: _medicalAvatars.length,
            itemBuilder: (_, i) {
              final av = _medicalAvatars[i];
              final isSelected = _selected == i;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? av.color.withValues(alpha: 0.12)
                        : const Color(0xFFF8FBFA),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? av.color
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  av.color.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      av.icon,
                      size: 28.w,
                      color: isSelected
                          ? av.color
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 24.h),

          // Confirm button
          GestureDetector(
            onTap: () {
              widget.onPick(_selected);
              Navigator.pop(context);
            },
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: _medicalAvatars[_selected].color,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: _medicalAvatars[_selected]
                        .color
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  'Select Avatar',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
              color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22.w, color: AppColors.textSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20.w, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
