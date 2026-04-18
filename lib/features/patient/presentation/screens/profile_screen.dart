import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../caregiver/data/models/caregiver_profile_model.dart';
import '../../../caregiver/presentation/providers/caregiver_provider.dart';
import '../providers/profile_provider.dart';

// ─── Shared style constants (used by profile + edit sheet) ───────────────────
const _kAccent  = Color(0xFF0891B2);
const _kTeal    = Color(0xFF0D9488);
const _kBorder  = Color(0xFFE2E8F0);
const _kMuted   = Color(0xFF94A3B8);
const _kText    = Color(0xFF0F172A);
const _kSubtext = Color(0xFF64748B);

// ─── 8 Premium Medical Icon Avatars (offline, no Firebase Storage) ────────────

const _medicalAvatars = [
  _AvatarOption(icon: Icons.medical_services_rounded, color: Color(0xFF0D9488), label: 'Medical'),
  _AvatarOption(icon: Icons.favorite_rounded,         color: Color(0xFFEF4444), label: 'Heart'),
  _AvatarOption(icon: Icons.monitor_heart_rounded,    color: Color(0xFF0891B2), label: 'Monitor'),
  _AvatarOption(icon: Icons.local_hospital_rounded,   color: Color(0xFFDB2777), label: 'Hospital'),
  _AvatarOption(icon: Icons.psychology_rounded,       color: Color(0xFF7C3AED), label: 'Mind'),
  _AvatarOption(icon: Icons.medication_rounded,       color: Color(0xFFEA580C), label: 'Meds'),
  _AvatarOption(icon: Icons.biotech_rounded,          color: Color(0xFF16A34A), label: 'Bio'),
  _AvatarOption(icon: Icons.shield_rounded,           color: Color(0xFF475569), label: 'Shield'),
];

class _AvatarOption {
  final IconData icon;
  final Color color;
  final String label;
  const _AvatarOption({required this.icon, required this.color, required this.label});
}

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(authStateProvider).valueOrNull;
    final userData    = ref.watch(currentUserDataProvider).valueOrNull;
    final imageRecord = ref.watch(profileImageRecordProvider).valueOrNull;

    // Role-aware brand colors
    final roleStr = userData?.role;
    final (gradStart, gradEnd) = switch (roleStr) {
      'manager'       => (const Color(0xFF9D174D), const Color(0xFFDB2777)),
      'family'        => (const Color(0xFF4C1D95), const Color(0xFF7C3AED)),
      'pro_caregiver' => (const Color(0xFF0E7490), const Color(0xFF0891B2)),
      _               => (const Color(0xFF115E59), const Color(0xFF0D9488)),
    };
    final roleAccent = gradEnd;

    // Pro-caregiver professional profile — null for all other roles
    final isProCaregiver = userData?.role == 'pro_caregiver';
    final caregiverProfile = isProCaregiver
        ? ref.watch(caregiverProfileProvider).valueOrNull
        : null;

    // Resolve what to display in the avatar circle
    final localPath   = imageRecord?.localImagePath;
    final hasPhoto    = localPath != null && File(localPath).existsSync();
    final avatarIdx   = (imageRecord?.avatarIndex ?? 0).clamp(0, _medicalAvatars.length - 1);
    final selectedAvatar = _medicalAvatars[avatarIdx];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          children: [
            // ── Back + title ──────────────────────────────────────────────
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
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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

            // ── User info card ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradStart, gradEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: [
                  BoxShadow(
                    color: roleAccent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ── Avatar — tap to change ──
                  GestureDetector(
                    onTap: () => _changePhoto(context, ref, hasPhoto, localPath, avatarIdx),
                    child: SizedBox(
                      height: 64.w,
                      width: 64.w,
                      child: Stack(
                        children: [
                          // Photo or icon
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: hasPhoto
                                ? Image.file(
                                    File(localPath),
                                    width: 64.w,
                                    height: 64.w,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 64.w,
                                    height: 64.w,
                                    decoration: BoxDecoration(
                                      color: selectedAvatar.color
                                          .withValues(alpha: 0.25),
                                      borderRadius:
                                          BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        selectedAvatar.icon,
                                        size: 30.w,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                          // Edit badge
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
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 10.w,
                                color: roleAccent,
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
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
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

            Center(
              child: Text(
                'Tap avatar to change your profile photo',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),

            // ── Pro Caregiver professional profile ────────────────────────
            if (caregiverProfile != null) ...[
              SizedBox(height: 28.h),
              _ProCaregiverSection(
                profile: caregiverProfile,
                onEdit: () => _showEditSheet(context, ref, caregiverProfile),
              ),
            ],

            SizedBox(height: 28.h),

            // ── Settings section ──────────────────────────────────────────
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

            // ── Sign out ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                await ref.read(authControllerProvider.notifier).signOut();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 20.w, color: roleAccent),
                    SizedBox(width: 8.w),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: roleAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // ── Delete account ────────────────────────────────────────────
            GestureDetector(
              onTap: () => _showDeleteDialog(context, ref),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
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

  // ── Role label ───────────────────────────────────────────────────────────────

  String _roleLabel(String? role) => switch (role) {
        'patient'      => 'PATIENT',
        'family'       => 'FAMILY',
        'pro_caregiver'=> 'PRO CAREGIVER',
        'manager'      => 'MANAGER',
        _              => 'USER',
      };

  // ── Photo change sheet ───────────────────────────────────────────────────────

  void _changePhoto(
    BuildContext context,
    WidgetRef ref,
    bool hasPhoto,
    String? currentPath,
    int currentAvatarIdx,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PhotoPickerSheet(
        hasPhoto: hasPhoto,
        onGallery: () => _pickFromSource(context, ref, ImageSource.gallery),
        onCamera:  () => _pickFromSource(context, ref, ImageSource.camera),
        onIcon:    () => _showIconPicker(context, ref, currentAvatarIdx),
        onRemove:  hasPhoto
            ? () => _removePhoto(ref)
            : null,
      ),
    );
  }

  // ── Pick from gallery or camera ──────────────────────────────────────────────

  Future<void> _pickFromSource(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final user     = ref.read(authStateProvider).valueOrNull;
    final userData = ref.read(currentUserDataProvider).valueOrNull;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     512,
      maxHeight:    512,
    );
    if (file == null) return;

    final role = userData?.role ?? 'patient';

    // Copy to a stable, app-owned path so the file survives cache clears
    final appDir     = await getApplicationDocumentsDirectory();
    final stablePath = p.join(
        appDir.path, 'profile_${user.uid}_$role.jpg');
    await File(file.path).copy(stablePath);

    // Persist to Drift (preserves existing avatarIndex for revert)
    await ref
        .read(appDatabaseProvider)
        .upsertProfileImagePath(user.uid, role, stablePath);

    // SharedPreferences fallback marker (index 0 = photo mode)
    await PreferencesService.setAvatarIndex(0);

    if (context.mounted) {
      SnackbarService.showSuccess('Profile photo updated');
    }
  }

  // ── Remove photo ─────────────────────────────────────────────────────────────

  Future<void> _removePhoto(WidgetRef ref) async {
    final user     = ref.read(authStateProvider).valueOrNull;
    final userData = ref.read(currentUserDataProvider).valueOrNull;
    if (user == null) return;

    final role = userData?.role ?? 'patient';

    // Delete local file if it exists
    final appDir     = await getApplicationDocumentsDirectory();
    final stablePath = p.join(appDir.path, 'profile_${user.uid}_$role.jpg');
    final file = File(stablePath);
    if (await file.exists()) await file.delete();

    // Clear path in Drift (reverts to icon avatar)
    await ref
        .read(appDatabaseProvider)
        .upsertProfileImagePath(user.uid, role, null);
  }

  // ── Icon avatar picker ───────────────────────────────────────────────────────

  void _showIconPicker(BuildContext context, WidgetRef ref, int currentIdx) {
    final user     = ref.read(authStateProvider).valueOrNull;
    final userData = ref.read(currentUserDataProvider).valueOrNull;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPickerSheet(
        currentIndex: currentIdx,
        onPick: (i) {
          HapticFeedback.selectionClick();
          if (user != null) {
            // upsertProfileImage clears localImagePath → reverts to icon mode
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

  // ── Pro-caregiver edit sheet ─────────────────────────────────────────────────

  void _showEditSheet(
      BuildContext context, WidgetRef ref, CaregiverProfileModel profile) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProProfileSheet(profile: profile),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
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

// ─── Photo Picker Bottom Sheet ────────────────────────────────────────────────
// Three options: Gallery, Camera, Choose Icon Avatar
// Optional fourth option: Remove Photo (only shown when a photo is active)

class _PhotoPickerSheet extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onIcon;
  final VoidCallback? onRemove;

  const _PhotoPickerSheet({
    required this.hasPhoto,
    required this.onGallery,
    required this.onCamera,
    required this.onIcon,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
            'Change Profile Photo',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 20.h),

          _PickerOption(
            icon: Icons.photo_library_rounded,
            color: const Color(0xFF0891B2),
            label: 'Choose from Gallery',
            onTap: () {
              Navigator.pop(context);
              onGallery();
            },
          ),
          SizedBox(height: 10.h),
          _PickerOption(
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFF16A34A),
            label: 'Take a Photo',
            onTap: () {
              Navigator.pop(context);
              onCamera();
            },
          ),
          SizedBox(height: 10.h),
          _PickerOption(
            icon: Icons.face_rounded,
            color: const Color(0xFF7C3AED),
            label: 'Choose Icon Avatar',
            onTap: () {
              Navigator.pop(context);
              onIcon();
            },
          ),

          if (onRemove != null) ...[
            SizedBox(height: 10.h),
            _PickerOption(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFEF4444),
              label: 'Remove Current Photo',
              onTap: () {
                Navigator.pop(context);
                onRemove!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              height: 36.w,
              width: 36.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 20.w, color: color),
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 20.w, color: const Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// ─── Icon Avatar Picker Sheet ─────────────────────────────────────────────────

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
            'Choose Icon Avatar',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'No photo upload required',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 24.h),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      color:
                          isSelected ? av.color : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: av.color.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
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
                  ),
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

// ─── Pro Caregiver Profile Section ───────────────────────────────────────────

class _ProCaregiverSection extends StatelessWidget {
  final CaregiverProfileModel profile;
  final VoidCallback onEdit;

  const _ProCaregiverSection({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Professional Profile',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 13.w, color: _kAccent),
                    SizedBox(width: 5.w),
                    Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: _kAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // ── Bio ──────────────────────────────────────────────────────────────
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          _InfoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded, size: 20.w, color: _kAccent),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    profile.bio!,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: _kSubtext,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],

        // ── Stats row ────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatChipCard(
                icon: Icons.workspace_premium_rounded,
                label: 'Experience',
                value:
                    '${profile.yearsOfExperience} yr${profile.yearsOfExperience == 1 ? '' : 's'}',
                color: _kTeal,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _StatChipCard(
                icon: Icons.schedule_rounded,
                label: 'Availability',
                value: profile.availability.label,
                color: _kAccent,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _StatChipCard(
                icon: profile.isAvailableForHire
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                label: 'Status',
                value: profile.isAvailableForHire ? 'Open' : 'Closed',
                color: profile.isAvailableForHire
                    ? const Color(0xFF16A34A)
                    : _kMuted,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // ── Rates ────────────────────────────────────────────────────────────
        _InfoCard(
          child: Column(
            children: [
              _RateInfoRow(
                icon: Icons.schedule_rounded,
                label: 'Hourly',
                value: '\$${profile.hourlyRate.toStringAsFixed(0)}/hr',
                color: _kAccent,
              ),
              Divider(height: 18.h, color: _kBorder),
              _RateInfoRow(
                icon: Icons.wb_sunny_rounded,
                label: 'Full-Day',
                value: '\$${profile.dailyRate.toStringAsFixed(0)}/day',
                color: const Color(0xFFF59E0B),
              ),
              Divider(height: 18.h, color: _kBorder),
              _RateInfoRow(
                icon: Icons.calendar_month_rounded,
                label: 'Monthly',
                value: '\$${profile.monthlyRate.toStringAsFixed(0)}/mo',
                color: _kTeal,
              ),
            ],
          ),
        ),

        // ── Specializations ──────────────────────────────────────────────────
        if (profile.specializations.isNotEmpty) ...[
          SizedBox(height: 14.h),
          _SectionLabel('Specializations'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: profile.specializations
                .map((s) => _ProfileChip(label: s, color: _kTeal))
                .toList(),
          ),
        ],

        // ── Qualifications ───────────────────────────────────────────────────
        if (profile.certifications.isNotEmpty) ...[
          SizedBox(height: 14.h),
          _SectionLabel('Qualifications'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: profile.certifications
                .map((c) => _ProfileChip(
                      label: c.name,
                      color: _kAccent,
                      icon: Icons.verified_rounded,
                    ))
                .toList(),
          ),
        ],

        // ── Work History ─────────────────────────────────────────────────────
        if (profile.workHistory.isNotEmpty) ...[
          SizedBox(height: 14.h),
          _SectionLabel('Work History'),
          SizedBox(height: 8.h),
          ...profile.workHistory.map(
            (w) => Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40.w,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.local_hospital_rounded,
                        size: 18.w, color: _kTeal),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.organization,
                            style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: _kText)),
                        Text(
                          '${w.role}  ·  ${w.yearsWorked} yr${w.yearsWorked == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: _kSubtext),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── Languages ────────────────────────────────────────────────────────
        if (profile.languages.isNotEmpty) ...[
          SizedBox(height: 14.h),
          _SectionLabel('Languages'),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: profile.languages
                .map((l) => _ProfileChip(
                      label: l,
                      color: const Color(0xFF7C3AED),
                      icon: Icons.language_rounded,
                    ))
                .toList(),
          ),
        ],

        // ── License & background check ────────────────────────────────────────
        if (profile.licenseNumber != null ||
            profile.backgroundCheckAcknowledged) ...[
          SizedBox(height: 14.h),
          _InfoCard(
            child: Column(
              children: [
                if (profile.licenseNumber != null) ...[
                  Row(
                    children: [
                      Icon(Icons.badge_rounded,
                          size: 16.w, color: _kAccent),
                      SizedBox(width: 10.w),
                      Text('License / Reg. No.',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp, color: _kSubtext)),
                      const Spacer(),
                      Text(profile.licenseNumber!,
                          style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: _kText)),
                    ],
                  ),
                  if (profile.backgroundCheckAcknowledged)
                    Divider(height: 18.h, color: _kBorder),
                ],
                if (profile.backgroundCheckAcknowledged)
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          size: 16.w,
                          color: const Color(0xFF16A34A)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Background check declaration acknowledged',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Pro Profile Info helpers ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 0),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

class _StatChipCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChipCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18.w, color: color),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style:
                GoogleFonts.inter(fontSize: 9.sp, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _RateInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RateInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34.w,
          width: 34.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, size: 16.w, color: color),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: _kSubtext)),
        ),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: _kText,
            )),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: _kText,
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _ProfileChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.w, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Pro Profile Sheet ───────────────────────────────────────────────────

class _EditProProfileSheet extends ConsumerStatefulWidget {
  final CaregiverProfileModel profile;
  const _EditProProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProProfileSheet> createState() =>
      _EditProProfileSheetState();
}

class _EditProProfileSheetState extends ConsumerState<_EditProProfileSheet> {
  bool _saving = false;

  late final TextEditingController _bioCtrl;
  late int _years;
  late AvailabilityPreference _availability;
  late List<String> _specializations;
  late List<String> _languages;
  late final TextEditingController _langCtrl;
  late List<String> _qualifications;
  late List<WorkHistoryItem> _workHistory;
  late final TextEditingController _licenseCtrl;
  late bool _bgCheck;
  late double _hourly;
  late double _daily;
  late double _monthly;
  late bool _available;

  static const _allSpecializations = [
    'Post-Surgery Care', 'Elderly Care', 'Palliative Care', 'Paediatric Care',
    'Mental Health', 'Wound Management', 'Physiotherapy', 'Dementia Care',
    'Diabetes Management', 'Stroke Rehabilitation', 'ICU / Critical Care',
    'Oncology Care', 'Cardiac Care', 'Orthopaedic Care', 'Neurological Care',
  ];

  static const _allQualifications = [
    'Registered Nurse (RN)', 'Licensed Practical Nurse (LPN)',
    'Certified Nursing Assistant (CNA)', 'Certified Home Health Aide (CHHA)',
    'First Aid & CPR Certified', 'Dementia Care Specialist',
    'Palliative Care Certification', 'Paediatric Care Certification',
    'Medication Management Certified', 'Physical Therapy Assistant',
    'Mental Health First Aid', 'Wound Care Certified',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bioCtrl       = TextEditingController(text: p.bio ?? '');
    _years         = p.yearsOfExperience;
    _availability  = p.availability;
    _specializations = List.from(p.specializations);
    _languages     = List.from(p.languages);
    _langCtrl      = TextEditingController();
    _qualifications = p.certifications.map((c) => c.name).toList();
    _workHistory   = List.from(p.workHistory);
    _licenseCtrl   = TextEditingController(text: p.licenseNumber ?? '');
    _bgCheck       = p.backgroundCheckAcknowledged;
    _hourly        = p.hourlyRate;
    _daily         = p.dailyRate;
    _monthly       = p.monthlyRate;
    _available     = p.isAvailableForHire;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _langCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.profile.copyWith(
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      yearsOfExperience: _years,
      availability: _availability,
      specializations: _specializations,
      languages: _languages,
      certifications: _qualifications.map((q) => CertificationItem(name: q)).toList(),
      workHistory: _workHistory,
      licenseNumber: _licenseCtrl.text.trim().isEmpty
          ? null
          : _licenseCtrl.text.trim(),
      backgroundCheckAcknowledged: _bgCheck,
      hourlyRate: _hourly,
      dailyRate: _daily,
      monthlyRate: _monthly,
      isAvailableForHire: _available,
    );
    try {
      await ref.read(caregiverRepositoryProvider).saveProfile(updated);
      await ref.read(caregiverRepositoryProvider).syncToDiscoveryHub(updated);
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pop();
      SnackbarService.showSuccess('Profile updated');
    } catch (_) {
      setState(() => _saving = false);
      SnackbarService.showError('Failed to save — please try again');
    }
  }

  Future<void> _pickRates() async {
    double tH = _hourly, tD = _daily, tM = _monthly;
    final hourlyItems  = List.generate(200, (i) => (i + 1).toDouble());
    final dailyItems   = List.generate(500, (i) => (i + 20).toDouble());
    final monthlyItems = List.generate(240, (i) => ((i + 1) * 100).toDouble());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (_) => StatefulBuilder(
        builder: (_, setLocal) => SizedBox(
          height: 360.h,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                height: 4, width: 40.w,
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2.r)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 15.sp, color: _kMuted)),
                    ),
                    Text('Set Rates',
                        style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: _kText)),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _hourly = tH;
                          _daily  = tD;
                          _monthly = tM;
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Done',
                          style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _kTeal)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Expanded(child: Center(child: Text('Hourly (\$)', style: GoogleFonts.inter(fontSize: 11.sp, color: _kMuted)))),
                    Container(width: 1, height: 16.h, color: _kBorder),
                    Expanded(child: Center(child: Text('Daily (\$)', style: GoogleFonts.inter(fontSize: 11.sp, color: _kMuted)))),
                    Container(width: 1, height: 16.h, color: _kBorder),
                    Expanded(child: Center(child: Text('Monthly (\$)', style: GoogleFonts.inter(fontSize: 11.sp, color: _kMuted)))),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
              Expanded(
                child: Row(
                  children: [
                    _CupertinoPicker(items: hourlyItems, initial: tH, suffix: '/hr', onChanged: (v) => setLocal(() => tH = v)),
                    Container(width: 1, color: _kBorder),
                    _CupertinoPicker(items: dailyItems, initial: tD, suffix: '/day', onChanged: (v) => setLocal(() => tD = v)),
                    Container(width: 1, color: _kBorder),
                    _CupertinoPicker(items: monthlyItems, initial: tM, suffix: '/mo', onChanged: (v) => setLocal(() => tM = v)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          // Handle + header
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    height: 4, width: 40.w,
                    decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Professional Profile',
                        style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: _kText)),
                    GestureDetector(
                      onTap: _saving ? null : _save,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kTeal, _kAccent]),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: _saving
                            ? SizedBox(
                                height: 16.w, width: 16.w,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Save',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Divider(height: 1, color: _kBorder),
              ],
            ),
          ),

          // Scrollable fields
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
              children: [
                // Bio
                _EditLabel('About You'),
                SizedBox(height: 8.h),
                _EditField(controller: _bioCtrl, hint: 'Short bio…', maxLines: 4, maxLength: 300),
                SizedBox(height: 18.h),

                // Years
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EditLabel('Years of Experience'),
                    _Stepper(
                      value: _years, min: 0, max: 50,
                      label: '$_years yr${_years == 1 ? '' : 's'}',
                      onChanged: (v) => setState(() => _years = v),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                // Availability
                _EditLabel('Availability'),
                SizedBox(height: 8.h),
                ...AvailabilityPreference.values.map((pref) {
                  final sel = pref == _availability;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _availability = pref);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: sel
                            ? _kAccent.withValues(alpha: 0.07)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: sel ? _kAccent : _kBorder,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sel
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 16.w,
                            color: sel ? _kAccent : _kMuted,
                          ),
                          SizedBox(width: 10.w),
                          Text(pref.label,
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? _kText : _kSubtext,
                              )),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 18.h),

                // Available for hire
                _EditLabel('Availability Status'),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _available = !_available);
                  },
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: _available
                          ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _available
                            ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                            : _kBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _available
                              ? Icons.check_circle_rounded
                              : Icons.pause_circle_outline_rounded,
                          size: 20.w,
                          color: _available
                              ? const Color(0xFF16A34A)
                              : _kMuted,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _available
                                ? 'Open to New Patients'
                                : 'Not Available for Hire',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: _available
                                  ? const Color(0xFF16A34A)
                                  : _kSubtext,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: _available,
                          onChanged: (v) =>
                              setState(() => _available = v),
                          activeTrackColor: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // Rates
                _EditLabel('Service Rates'),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: _pickRates,
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Column(
                      children: [
                        _RateInfoRow(
                            icon: Icons.schedule_rounded,
                            label: 'Hourly',
                            value: '\$${_hourly.toStringAsFixed(0)}/hr',
                            color: _kAccent),
                        Divider(height: 16.h, color: _kBorder),
                        _RateInfoRow(
                            icon: Icons.wb_sunny_rounded,
                            label: 'Full-Day',
                            value: '\$${_daily.toStringAsFixed(0)}/day',
                            color: const Color(0xFFF59E0B)),
                        Divider(height: 16.h, color: _kBorder),
                        _RateInfoRow(
                            icon: Icons.calendar_month_rounded,
                            label: 'Monthly',
                            value: '\$${_monthly.toStringAsFixed(0)}/mo',
                            color: _kTeal),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 5.h),
                    child: Text('Tap card to adjust rates',
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: _kMuted)),
                  ),
                ),
                SizedBox(height: 18.h),

                // Specializations
                _EditLabel('Specializations'),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w, runSpacing: 8.h,
                  children: _allSpecializations.map((s) {
                    final sel = _specializations.contains(s);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          sel
                              ? _specializations.remove(s)
                              : _specializations.add(s);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: sel ? _kTeal : Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                              color: sel ? _kTeal : _kBorder),
                        ),
                        child: Text(s,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  sel ? Colors.white : _kSubtext,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 18.h),

                // Qualifications
                _EditLabel('Qualifications'),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w, runSpacing: 8.h,
                  children: _allQualifications.map((q) {
                    final sel = _qualifications.contains(q);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          sel
                              ? _qualifications.remove(q)
                              : _qualifications.add(q);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: sel
                              ? _kAccent.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                              color: sel ? _kAccent : _kBorder,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sel) ...[
                              Icon(Icons.check_circle_rounded,
                                  size: 12.w, color: _kAccent),
                              SizedBox(width: 4.w),
                            ],
                            Text(q,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? _kAccent : _kSubtext,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 18.h),

                // Work History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _EditLabel('Work History'),
                    if (_workHistory.length < 4)
                      GestureDetector(
                        onTap: () => _showAddWorkSheet(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: _kTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 13.w, color: _kTeal),
                              SizedBox(width: 4.w),
                              Text('Add',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _kTeal,
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (_workHistory.isEmpty)
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: _kBorder)),
                    child: Row(
                      children: [
                        Icon(Icons.work_history_rounded,
                            size: 18.w, color: _kMuted),
                        SizedBox(width: 10.w),
                        Text('No entries yet',
                            style: GoogleFonts.inter(
                                fontSize: 13.sp, color: _kMuted)),
                      ],
                    ),
                  )
                else
                  ..._workHistory.asMap().entries.map((e) {
                    final item = e.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: _kBorder)),
                      child: Row(
                        children: [
                          Container(
                            height: 36.w, width: 36.w,
                            decoration: BoxDecoration(
                              color: _kTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9.r),
                            ),
                            child: Icon(Icons.local_hospital_rounded,
                                size: 16.w, color: _kTeal),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.organization,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: _kText)),
                                Text(
                                  '${item.role}  ·  ${item.yearsWorked} yr${item.yearsWorked == 1 ? '' : 's'}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11.sp, color: _kSubtext),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _workHistory.removeAt(e.key)),
                            child: Icon(Icons.close_rounded,
                                size: 17.w, color: _kMuted),
                          ),
                        ],
                      ),
                    );
                  }),
                SizedBox(height: 18.h),

                // Languages
                _EditLabel('Languages'),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w, runSpacing: 8.h,
                  children: _languages.map((l) {
                    final isEn = l == 'English';
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: _kAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l,
                              style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _kAccent)),
                          if (!isEn) ...[
                            SizedBox(width: 5.w),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _languages.remove(l)),
                              child: Icon(Icons.close_rounded,
                                  size: 12.w, color: _kAccent),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: _EditField(
                          controller: _langCtrl,
                          hint: 'Add language…',
                          maxLines: 1,
                          onSubmitted: (_) => _addLanguage()),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: _addLanguage,
                      child: Container(
                        height: 46.h, width: 46.h,
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.add_rounded,
                            size: 20.w, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                // License
                _EditLabel('License / Registration No. (Optional)'),
                SizedBox(height: 8.h),
                _EditField(
                    controller: _licenseCtrl,
                    hint: 'e.g. RN-123456',
                    maxLines: 1),
                SizedBox(height: 18.h),

                // Background check
                _EditLabel('Background Check Declaration'),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _bgCheck = !_bgCheck);
                  },
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: _bgCheck
                          ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _bgCheck
                            ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                            : _kBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _bgCheck
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 20.w,
                          color: _bgCheck
                              ? const Color(0xFF16A34A)
                              : _kMuted,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'I confirm I am willing to undergo a background check and that all information provided is accurate.',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: _bgCheck ? _kText : _kSubtext,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addLanguage() {
    final lang = _langCtrl.text.trim();
    if (lang.isNotEmpty && !_languages.contains(lang)) {
      HapticFeedback.selectionClick();
      setState(() {
        _languages.add(lang);
        _langCtrl.clear();
      });
    }
  }

  void _showAddWorkSheet(BuildContext ctx) {
    final orgCtrl  = TextEditingController();
    final roleCtrl = TextEditingController();
    int years = 1;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (_) => StatefulBuilder(
        builder: (_, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              20.w, 20.h, 20.w,
              MediaQuery.of(ctx).viewInsets.bottom + 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4, width: 40.w,
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Add Work History',
                  style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              SizedBox(height: 14.h),
              _EditLabel('Organisation / Hospital'),
              SizedBox(height: 6.h),
              _EditField(
                  controller: orgCtrl,
                  hint: 'e.g. City General Hospital',
                  maxLines: 1),
              SizedBox(height: 12.h),
              _EditLabel('Role / Position'),
              SizedBox(height: 6.h),
              _EditField(
                  controller: roleCtrl,
                  hint: 'e.g. Senior Caregiver',
                  maxLines: 1),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _EditLabel('Years Worked'),
                  _Stepper(
                    value: years, min: 1, max: 40,
                    label: '$years yr${years == 1 ? '' : 's'}',
                    onChanged: (v) => set(() => years = v),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  if (orgCtrl.text.trim().isEmpty ||
                      roleCtrl.text.trim().isEmpty) {
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  setState(() => _workHistory.add(WorkHistoryItem(
                    organization: orgCtrl.text.trim(),
                    role: roleCtrl.text.trim(),
                    yearsWorked: years,
                  )));
                  Navigator.pop(ctx);
                },
                child: Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kTeal, _kAccent]),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text('Add',
                        style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared edit-sheet helpers ────────────────────────────────────────────────

class _EditLabel extends StatelessWidget {
  final String text;
  const _EditLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _kText));
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  const _EditField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.maxLength,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction:
            maxLines == 1 ? TextInputAction.done : TextInputAction.newline,
        onSubmitted: onSubmitted,
        style: GoogleFonts.inter(fontSize: 13.sp, color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(fontSize: 13.sp, color: _kMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12.w),
          counterStyle: GoogleFonts.inter(
              fontSize: 10.sp, color: const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final String label;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallBtn(
          icon: Icons.remove_rounded,
          onTap: () {
            if (value > min) {
              HapticFeedback.selectionClick();
              onChanged(value - 1);
            }
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: _kText),
          ),
        ),
        _SmallBtn(
          icon: Icons.add_rounded,
          onTap: () {
            if (value < max) {
              HapticFeedback.selectionClick();
              onChanged(value + 1);
            }
          },
        ),
      ],
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30.w, width: 30.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 14.w, color: _kText),
      ),
    );
  }
}

class _CupertinoPicker extends StatelessWidget {
  final List<double> items;
  final double initial;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _CupertinoPicker({
    required this.items,
    required this.initial,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 42,
        scrollController: FixedExtentScrollController(
          initialItem: items
              .indexWhere((v) => v == initial)
              .clamp(0, items.length - 1),
        ),
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          SystemSound.play(SystemSoundType.click);
          onChanged(items[i]);
        },
        children: items
            .map((v) => Center(
                  child: Text(
                    '\$${v.toStringAsFixed(0)}$suffix',
                    style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ))
            .toList(),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
