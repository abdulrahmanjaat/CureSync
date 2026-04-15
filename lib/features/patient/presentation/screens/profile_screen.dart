import 'dart:io';

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
import '../providers/profile_provider.dart';

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
