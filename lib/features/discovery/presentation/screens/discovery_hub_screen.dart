import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/auth/data/models/patient_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/presentation/providers/role_provider.dart';
import '../../../../features/patient/presentation/providers/medication_provider.dart';
import '../../../../features/patient/presentation/providers/patient_provider.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class DiscoveryProfile {
  final String id;
  final String name;
  final String specialty;
  final String? location;
  final double? avgRating;
  final int reviewCount;
  final double? successRate;
  final int yearsOfExperience;
  final bool isVerified;
  final bool isAvailableForHire;
  final String? photoUrl;
  final String? bio;
  final double hourlyRate;

  const DiscoveryProfile({
    required this.id,
    required this.name,
    required this.specialty,
    this.location,
    this.avgRating,
    this.reviewCount = 0,
    this.successRate,
    this.yearsOfExperience = 0,
    this.isVerified = false,
    this.isAvailableForHire = false,
    this.photoUrl,
    this.bio,
    this.hourlyRate = 0,
  });

  factory DiscoveryProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    // Support both 'avgRating' (new) and legacy 'rating' string
    final rawAvg = d['avgRating'] ?? d['rating'];
    return DiscoveryProfile(
      id: doc.id,
      name: d['name'] as String? ?? 'Unknown',
      specialty: d['specialty'] as String? ??
          (d['specializations'] as List?)?.firstOrNull?.toString() ??
          d['type'] as String? ??
          '',
      location: d['location'] as String?,
      avgRating: rawAvg != null
          ? double.tryParse(rawAvg.toString())
          : null,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      successRate: (d['successRate'] as num?)?.toDouble(),
      yearsOfExperience: (d['yearsOfExperience'] as num?)?.toInt() ?? 0,
      isVerified: d['isVerified'] as bool? ?? false,
      isAvailableForHire: d['isAvailableForHire'] as bool? ?? false,
      photoUrl: d['photoUrl'] as String?,
      bio: d['bio'] as String?,
      hourlyRate: (d['hourlyRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _proCaregivers = StreamProvider<List<DiscoveryProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection('pro_caregivers')
      .where('isAvailableForHire', isEqualTo: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(DiscoveryProfile.fromFirestore).toList());
});

final _proDoctors = StreamProvider<List<DiscoveryProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection('pro_doctors')
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(DiscoveryProfile.fromFirestore).toList());
});

final _proHospitals = StreamProvider<List<DiscoveryProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection('pro_hospitals')
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(DiscoveryProfile.fromFirestore).toList());
});

final _proPharmacies = StreamProvider<List<DiscoveryProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection('pro_pharmacies')
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(DiscoveryProfile.fromFirestore).toList());
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class DiscoveryHubScreen extends ConsumerStatefulWidget {
  const DiscoveryHubScreen({super.key});

  @override
  ConsumerState<DiscoveryHubScreen> createState() => _DiscoveryHubScreenState();
}

class _DiscoveryHubScreenState extends ConsumerState<DiscoveryHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  static const _tabs = [
    _TabMeta(icon: Icons.medical_services_rounded, label: 'Doctors'),
    _TabMeta(icon: Icons.health_and_safety_rounded, label: 'Caregivers'),
    _TabMeta(icon: Icons.local_hospital_rounded, label: 'Hospitals'),
    _TabMeta(icon: Icons.local_pharmacy_rounded, label: 'Pharmacy'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(_proDoctors).valueOrNull ?? [];
    final caregivers = ref.watch(_proCaregivers).valueOrNull ?? [];
    final hospitals = ref.watch(_proHospitals).valueOrNull ?? [];
    final pharmacies = ref.watch(_proPharmacies).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: Column(
          children: [
            /// ─── Header ─────────────────────────────────────────────────────
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discovery Hub',
                    style: GoogleFonts.poppins(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Find doctors, caregivers & more near you',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.05, end: 0, duration: 300.ms),

            /// ─── Custom Tab Bar ──────────────────────────────────────────────
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = _tabController.index == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _tabController.animateTo(i);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF0D9488)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _tabs[i].icon,
                              size: 15.w,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _tabs[i].label,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 80.ms),

            SizedBox(height: 12.h),

            /// ─── Tab Content ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Doctors
                  _HybridTab(
                    appProfiles: _filter(doctors),
                    nearMePlaceholder: 'Doctors near you',
                    emptyMessage: 'No registered doctors found',
                    emptyIcon: Icons.medical_services_outlined,
                    accentColor: const Color(0xFF0D9488),
                    showHire: false,
                  ),

                  // Caregivers — Pro Caregivers from Firestore
                  _CaregiverTab(
                    caregivers: _filter(caregivers),
                  ),

                  // Hospitals
                  _HybridTab(
                    appProfiles: _filter(hospitals),
                    nearMePlaceholder: 'Hospitals near you',
                    emptyMessage: 'No registered hospitals found',
                    emptyIcon: Icons.local_hospital_outlined,
                    accentColor: const Color(0xFF0891B2),
                    showHire: false,
                  ),

                  // Pharmacy
                  _HybridTab(
                    appProfiles: _filter(pharmacies),
                    nearMePlaceholder: 'Pharmacies near you',
                    emptyMessage: 'No registered pharmacies found',
                    emptyIcon: Icons.local_pharmacy_outlined,
                    accentColor: const Color(0xFF7C3AED),
                    showHire: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DiscoveryProfile> _filter(List<DiscoveryProfile> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.specialty.toLowerCase().contains(q))
        .toList();
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 14.sp, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search by name or specialty…',
          hintStyle:
              GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF94A3B8)),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20.w, color: const Color(0xFF94A3B8)),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: Icon(Icons.close_rounded,
                      size: 18.w, color: const Color(0xFF94A3B8)),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }
}

// ─── Caregiver Tab ────────────────────────────────────────────────────────────

class _CaregiverTab extends StatelessWidget {
  final List<DiscoveryProfile> caregivers;
  const _CaregiverTab({required this.caregivers});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        if (caregivers.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.verified_rounded,
            label: 'Pro Caregivers on CureSync',
            color: const Color(0xFF0D9488),
          ),
          SizedBox(height: 8.h),
          ...caregivers.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ProfileCard(
                  profile: e.value,
                  showHire: true,
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (e.key * 60).ms)
                    .slideX(
                        begin: 0.03,
                        end: 0,
                        duration: 300.ms,
                        delay: (e.key * 60).ms),
              )),
        ],
        _SectionHeader(
          icon: Icons.location_on_rounded,
          label: 'Caregivers Near You',
          color: const Color(0xFF0891B2),
        ),
        SizedBox(height: 8.h),
        _NearMePlaceholder(label: 'caregivers'),
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ─── Hybrid Tab ───────────────────────────────────────────────────────────────

class _HybridTab extends StatelessWidget {
  final List<DiscoveryProfile> appProfiles;
  final String nearMePlaceholder;
  final String emptyMessage;
  final IconData emptyIcon;
  final Color accentColor;
  final bool showHire;

  const _HybridTab({
    required this.appProfiles,
    required this.nearMePlaceholder,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.accentColor,
    required this.showHire,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      children: [
        if (appProfiles.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.verified_rounded,
            label: 'On CureSync',
            color: accentColor,
          ),
          SizedBox(height: 8.h),
          ...appProfiles.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ProfileCard(
                  profile: e.value,
                  accentColor: accentColor,
                  showHire: showHire,
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (e.key * 60).ms)
                    .slideX(
                        begin: 0.03,
                        end: 0,
                        duration: 300.ms,
                        delay: (e.key * 60).ms),
              )),
          SizedBox(height: 8.h),
        ] else ...[
          SizedBox(height: 8.h),
          Center(
            child: Column(
              children: [
                Icon(emptyIcon, size: 36.w, color: const Color(0xFFCBD5E1)),
                SizedBox(height: 8.h),
                Text(
                  emptyMessage,
                  style: GoogleFonts.inter(
                      fontSize: 13.sp, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        _SectionHeader(
          icon: Icons.location_on_rounded,
          label: nearMePlaceholder,
          color: const Color(0xFF64748B),
        ),
        SizedBox(height: 8.h),
        _NearMePlaceholder(label: nearMePlaceholder.toLowerCase()),
        SizedBox(height: 16.h),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: color),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final DiscoveryProfile profile;
  final Color accentColor;
  final bool showHire;

  const _ProfileCard({
    required this.profile,
    this.accentColor = const Color(0xFF0D9488),
    this.showHire = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                height: 52.w,
                width: 52.w,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: profile.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: Image.network(
                          profile.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _avatarFallback(accentColor),
                        ),
                      )
                    : _avatarFallback(accentColor),
              ),
              SizedBox(width: 12.w),

              // Name + specialty + location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + verified badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (profile.isVerified) ...[
                          SizedBox(width: 5.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 10.w, color: accentColor),
                                SizedBox(width: 2.w),
                                Text(
                                  'Verified',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 2.h),
                    Text(
                      profile.specialty,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),

                    if (profile.yearsOfExperience > 0) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '${profile.yearsOfExperience} yrs experience',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],

                    if (profile.location != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12.w,
                              color: const Color(0xFF94A3B8)),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: Text(
                              profile.location!,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Rating + action button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (profile.avgRating != null)
                    _RatingBadge(
                      rating: profile.avgRating!,
                      count: profile.reviewCount,
                    ),
                  SizedBox(height: 8.h),
                  showHire
                      ? _HireButton(profile: profile, accentColor: accentColor)
                      : _ContactButton(accentColor: accentColor),
                ],
              ),
            ],
          ),

          // Stats row: success rate + availability
          if (profile.successRate != null || showHire) ...[
            SizedBox(height: 10.h),
            Divider(color: const Color(0xFFE2E8F0), height: 1.h),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (profile.successRate != null) ...[
                  Icon(Icons.trending_up_rounded,
                      size: 13.w, color: const Color(0xFF16A34A)),
                  SizedBox(width: 4.w),
                  Text(
                    '${profile.successRate}% success rate',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
                if (showHire) ...[
                  Container(
                    height: 7.w,
                    width: 7.w,
                    decoration: BoxDecoration(
                      color: profile.isAvailableForHire
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    profile.isAvailableForHire
                        ? 'Available for hire'
                        : 'Not available',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: profile.isAvailableForHire
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  if (profile.hourlyRate > 0) ...[
                    const Spacer(),
                    Text(
                      '\$${profile.hourlyRate.toStringAsFixed(0)}/hr',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarFallback(Color color) {
    return Center(
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Rating Badge ─────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rating;
  final int count;
  const _RatingBadge({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded,
                size: 14.w, color: const Color(0xFFF59E0B)),
            SizedBox(width: 2.w),
            Text(
              rating.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        if (count > 0)
          Text(
            '($count)',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
      ],
    );
  }
}

// ─── Contact Button ───────────────────────────────────────────────────────────

class _ContactButton extends StatelessWidget {
  final Color accentColor;
  const _ContactButton({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Contact',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Hire Button ──────────────────────────────────────────────────────────────

class _HireButton extends StatelessWidget {
  final DiscoveryProfile profile;
  final Color accentColor;
  const _HireButton({required this.profile, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: profile.isAvailableForHire
          ? () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _HireSheet(profile: profile),
              );
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: profile.isAvailableForHire
              ? accentColor
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Hire',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: profile.isAvailableForHire
                ? Colors.white
                : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

// ─── Hire Sheet ───────────────────────────────────────────────────────────────

class _HireSheet extends ConsumerStatefulWidget {
  final DiscoveryProfile profile;
  const _HireSheet({required this.profile});

  @override
  ConsumerState<_HireSheet> createState() => _HireSheetState();
}

class _HireSheetState extends ConsumerState<_HireSheet> {
  bool _isPaid = true;
  bool _sending = false;
  PatientModel? _selectedPatient; // manager-only: patient picker selection

  bool get _isManager {
    final roleStr =
        ref.read(currentUserDataProvider).valueOrNull?.role;
    return UserRoleX.fromString(roleStr) == UserRole.manager;
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);

    final authUser = ref.read(authStateProvider).valueOrNull;

    // Resolve the patient — manager picks explicitly, patient uses active id
    PatientModel? patient;
    if (_isManager) {
      patient = _selectedPatient;
    } else {
      final patientId = ref.read(resolvedActivePatientIdProvider);
      final patients = ref.read(patientsStreamProvider).valueOrNull ?? [];
      patient = patients.firstWhere(
        (p) => p.patientId == patientId,
        orElse: () => patients.isNotEmpty ? patients.first : patients.first,
      );
    }

    if (authUser == null || patient == null) {
      if (mounted) setState(() => _sending = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(widget.profile.id)
          .collection('deal_requests')
          .add({
        'patientId': patient.patientId,
        'patientName': patient.name,
        'managerId': authUser.uid,
        'managerName': authUser.displayName ?? '',
        'accessCode': patient.accessCode,
        'paymentType': _isPaid ? 'paid' : 'volunteer',
        'hourlyRate': widget.profile.hourlyRate,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hire request sent to ${widget.profile.name}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _isManager;
    final patients = ref.watch(patientsStreamProvider).valueOrNull ?? [];

    // For manager: button is only enabled when a patient is selected
    final canSend = !_sending &&
        (!isManager || _selectedPatient != null);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Caregiver summary
            Row(
              children: [
                Container(
                  height: 48.w,
                  width: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      widget.profile.name.isNotEmpty
                          ? widget.profile.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        widget.profile.specialty,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.profile.hourlyRate > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${widget.profile.hourlyRate.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'per hour',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 24.h),

            // ── Manager-only: Patient Picker ─────────────────────────────
            if (isManager) ...[
              Text(
                'Select Patient',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 10.h),
              if (patients.isEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    'No patients found. Add a patient first from your dashboard.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                )
              else
                ...patients.map((p) {
                  final isSelected = _selectedPatient?.patientId == p.patientId;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPatient = p);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D9488).withValues(alpha: 0.06)
                            : const Color(0xFFF8FBFA),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0D9488)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 36.w,
                            width: 36.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D9488),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${p.relation} · ${p.age} yrs',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20.w,
                              color: const Color(0xFF0D9488),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              SizedBox(height: 16.h),
            ],

            // Payment terms
            Text(
              'Payment Terms',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                _TermChip(
                  label: 'Paid',
                  icon: Icons.attach_money_rounded,
                  selected: _isPaid,
                  onTap: () => setState(() => _isPaid = true),
                ),
                SizedBox(width: 10.w),
                _TermChip(
                  label: 'Volunteer',
                  icon: Icons.volunteer_activism_rounded,
                  selected: !_isPaid,
                  onTap: () => setState(() => _isPaid = false),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _isPaid
                    ? 'A paid request will be sent. Payment terms are agreed between you and the caregiver directly.'
                    : 'A volunteer request will be sent. The caregiver provides care without payment.',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: canSend ? _sendRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF0D9488).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
                child: _sending
                    ? SizedBox(
                        height: 20.w,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isManager && _selectedPatient == null
                            ? 'Select a patient above'
                            : 'Send Hire Request',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TermChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0D9488)
                  : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22.w,
                color: selected
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF94A3B8),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Near Me Placeholder ──────────────────────────────────────────────────────

class _NearMePlaceholder extends StatelessWidget {
  final String label;
  const _NearMePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.location_searching_rounded,
              size: 32.w, color: const Color(0xFF0D9488)),
          SizedBox(height: 10.h),
          Text(
            'Enable Location for Near Me',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Find $label within 5 km via Google Places',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 14.h),
          GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Allow Location',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Metadata ─────────────────────────────────────────────────────────────

class _TabMeta {
  final IconData icon;
  final String label;
  const _TabMeta({required this.icon, required this.label});
}
