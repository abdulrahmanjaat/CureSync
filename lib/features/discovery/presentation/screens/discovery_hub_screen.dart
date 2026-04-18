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
import '../../data/models/discovery_profile_model.dart';

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

// ─── Category Enum ────────────────────────────────────────────────────────────

enum _Cat { all, doctors, caregivers, hospitals, pharmacy }

extension _CatX on _Cat {
  String get label => switch (this) {
        _Cat.all => 'All',
        _Cat.doctors => 'Doctors',
        _Cat.caregivers => 'Caregivers',
        _Cat.hospitals => 'Hospitals',
        _Cat.pharmacy => 'Pharmacy',
      };

  IconData get icon => switch (this) {
        _Cat.all => Icons.grid_view_rounded,
        _Cat.doctors => Icons.medical_services_rounded,
        _Cat.caregivers => Icons.health_and_safety_rounded,
        _Cat.hospitals => Icons.local_hospital_rounded,
        _Cat.pharmacy => Icons.local_pharmacy_rounded,
      };

  Color get color => switch (this) {
        _Cat.all => const Color(0xFF0D9488),
        _Cat.doctors => const Color(0xFF0D9488),
        _Cat.caregivers => const Color(0xFF7C3AED),
        _Cat.hospitals => const Color(0xFF0891B2),
        _Cat.pharmacy => const Color(0xFFD97706),
      };

  List<Color> get gradient => switch (this) {
        _Cat.all => [const Color(0xFF0D9488), const Color(0xFF065F46)],
        _Cat.doctors => [const Color(0xFF0D9488), const Color(0xFF065F46)],
        _Cat.caregivers => [const Color(0xFF7C3AED), const Color(0xFF4C1D95)],
        _Cat.hospitals => [const Color(0xFF0891B2), const Color(0xFF0E4C7A)],
        _Cat.pharmacy => [const Color(0xFFD97706), const Color(0xFF92400E)],
      };

  String get emptyLabel => switch (this) {
        _Cat.all => 'No professionals found',
        _Cat.doctors => 'No doctors found',
        _Cat.caregivers => 'No caregivers found',
        _Cat.hospitals => 'No hospitals found',
        _Cat.pharmacy => 'No pharmacies found',
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DiscoveryHubScreen extends ConsumerStatefulWidget {
  const DiscoveryHubScreen({super.key});

  @override
  ConsumerState<DiscoveryHubScreen> createState() =>
      _DiscoveryHubScreenState();
}

class _DiscoveryHubScreenState extends ConsumerState<DiscoveryHubScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _Cat _selected = _Cat.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(_proDoctors).valueOrNull ?? [];
    final caregivers = ref.watch(_proCaregivers).valueOrNull ?? [];
    final hospitals = ref.watch(_proHospitals).valueOrNull ?? [];
    final pharmacies = ref.watch(_proPharmacies).valueOrNull ?? [];

    final List<({DiscoveryProfile profile, _Cat cat})> allTagged = [
      ...doctors.map((p) => (profile: p, cat: _Cat.doctors)),
      ...caregivers.map((p) => (profile: p, cat: _Cat.caregivers)),
      ...hospitals.map((p) => (profile: p, cat: _Cat.hospitals)),
      ...pharmacies.map((p) => (profile: p, cat: _Cat.pharmacy)),
    ];

    final visibleTagged = allTagged.where((e) {
      final matchesCat =
          _selected == _Cat.all || e.cat == _selected;
      if (!matchesCat) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.profile.name.toLowerCase().contains(q) ||
          e.profile.specialty.toLowerCase().contains(q);
    }).toList();

    final featured = visibleTagged
        .where((e) => (e.profile.avgRating ?? 0) >= 4.0)
        .toList();

    final regular = visibleTagged
        .where((e) => (e.profile.avgRating ?? 0) < 4.0)
        .toList();

    // Role-aware brand override: manager uses rose instead of teal
    final userData = ref.watch(currentUserDataProvider).valueOrNull;
    final isManager = userData?.role == 'manager';
    const rose   = Color(0xFFDB2777);
    const roseDk = Color(0xFF9D174D);

    Color accentColor = _selected.color;
    List<Color> gradientColors = _selected.gradient;
    Color? allPillOverride;

    if (isManager && _selected == _Cat.all) {
      accentColor     = rose;
      gradientColors  = [rose, roseDk];
      allPillOverride = rose;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(
              gradientColors: gradientColors,
              accentColor: accentColor,
              query: _query,
              controller: _searchCtrl,
              onSearchChanged: (v) => setState(() => _query = v.trim()),
              onClearSearch: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),

          // ── Category Pills ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CategoryPills(
              selected: _selected,
              allPillOverride: allPillOverride,
              onSelect: (c) {
                HapticFeedback.selectionClick();
                setState(() => _selected = c);
              },
            ).animate().fadeIn(duration: 300.ms, delay: 50.ms),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 4.h)),

          // ── Featured / Top Rated ─────────────────────────────────────────
          if (featured.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.star_rounded,
                label: 'Top Rated',
                color: const Color(0xFFF59E0B),
              ).animate().fadeIn(duration: 280.ms, delay: 80.ms),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                  physics: const BouncingScrollPhysics(),
                  itemCount: featured.length,
                  itemBuilder: (ctx, i) {
                    final e = featured[i];
                    return _FeaturedCard(
                      profile: e.profile,
                      cat: e.cat,
                      showHire: e.cat == _Cat.caregivers,
                    )
                        .animate()
                        .fadeIn(duration: 280.ms, delay: (i * 60).ms)
                        .slideX(
                            begin: 0.08,
                            end: 0,
                            duration: 280.ms,
                            delay: (i * 60).ms);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 4.h)),
          ],

          // ── Verified on CureSync ─────────────────────────────────────────
          if (regular.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                icon: Icons.verified_rounded,
                label: 'On CureSync',
                color: accentColor,
              ).animate().fadeIn(duration: 280.ms, delay: 100.ms),
            ),
            SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final e = regular[i];
                    return _ProfileCard(
                      profile: e.profile,
                      cat: e.cat,
                      showHire: e.cat == _Cat.caregivers,
                    )
                        .animate()
                        .fadeIn(
                            duration: 280.ms,
                            delay: (i * 50).ms)
                        .slideY(
                            begin: 0.04,
                            end: 0,
                            duration: 280.ms,
                            delay: (i * 50).ms);
                  },
                  childCount: regular.length,
                ),
              ),
            ),
          ],

          // ── Empty State ──────────────────────────────────────────────────
          if (visibleTagged.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(cat: _selected)
                  .animate()
                  .fadeIn(duration: 400.ms),
            ),

          // ── Near Me ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: _NearMeCard(
                accentColor: accentColor,
                gradientColors: gradientColors,
                label: _selected == _Cat.all
                    ? 'healthcare providers'
                    : _selected.label.toLowerCase(),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 120.ms),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final List<Color> gradientColors;
  final Color accentColor;
  final String query;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _HeroHeader({
    required this.gradientColors,
    required this.accentColor,
    required this.query,
    required this.controller,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discovery Hub',
                          style: GoogleFonts.poppins(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Doctors · Caregivers · Hospitals · Pharmacy',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Healthcare icon cluster
                  Container(
                    height: 52.w,
                    width: 52.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.health_and_safety_rounded,
                      size: 28.w,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18.h),

              // Search bar
              Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by name or specialty…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20.w,
                      color: accentColor,
                    ),
                    suffixIcon: query.isNotEmpty
                        ? GestureDetector(
                            onTap: onClearSearch,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18.w,
                              color: const Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.04, end: 0, duration: 350.ms);
  }
}

// ─── Category Pills ───────────────────────────────────────────────────────────

class _CategoryPills extends StatelessWidget {
  final _Cat selected;
  final ValueChanged<_Cat> onSelect;
  final Color? allPillOverride;

  const _CategoryPills({
    required this.selected,
    required this.onSelect,
    this.allPillOverride,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
        physics: const BouncingScrollPhysics(),
        children: _Cat.values.map((cat) {
          final isActive = selected == cat;
          final pillColor = (cat == _Cat.all && allPillOverride != null)
              ? allPillOverride!
              : cat.color;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isActive
                    ? pillColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: isActive
                      ? pillColor
                      : const Color(0xFFE2E8F0),
                  width: isActive ? 0 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: pillColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 14.w,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    cat.label,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
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
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
      child: Row(
        children: [
          Container(
            height: 28.w,
            width: 28.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 15.w, color: color),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Featured Card (horizontal scroll) ───────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final DiscoveryProfile profile;
  final _Cat cat;
  final bool showHire;

  const _FeaturedCard({
    required this.profile,
    required this.cat,
    required this.showHire,
  });

  @override
  Widget build(BuildContext context) {
    final color = cat.color;
    final gradient = cat.gradient;

    return GestureDetector(
      onTap: showHire && profile.isAvailableForHire
          ? () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _HireSheet(profile: profile),
              );
            }
          : () => HapticFeedback.lightImpact(),
      child: Container(
        width: 190.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                height: 90.w,
                width: 90.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 48.w,
                        width: 48.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: profile.photoUrl != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(14.r),
                                child: Image.network(
                                  profile.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _avatarText(Colors.white),
                                ),
                              )
                            : _avatarText(Colors.white),
                      ),
                      const Spacer(),
                      if (profile.avgRating != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 11.w,
                                  color: const Color(0xFFFDE68A)),
                              SizedBox(width: 3.w),
                              Text(
                                profile.avgRating!
                                    .toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  // Name
                  Text(
                    profile.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 2.h),

                  // Specialty
                  Text(
                    profile.specialty,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Bottom row
                  Row(
                    children: [
                      if (profile.isVerified)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 9.w, color: Colors.white),
                              SizedBox(width: 3.w),
                              Text(
                                'Verified',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (showHire)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            profile.isAvailableForHire
                                ? 'Hire'
                                : 'View',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'Contact',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarText(Color color) {
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

// ─── Profile Card (vertical list) ────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final DiscoveryProfile profile;
  final _Cat cat;
  final bool showHire;

  const _ProfileCard({
    required this.profile,
    required this.cat,
    required this.showHire,
  });

  @override
  Widget build(BuildContext context) {
    final color = cat.color;

    return GestureDetector(
      onTap: showHire && profile.isAvailableForHire
          ? () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _HireSheet(profile: profile),
              );
            }
          : () => HapticFeedback.lightImpact(),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Colored accent top bar
            Container(
              height: 4.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                children: [
                  // ── Top row: avatar + info + action ─────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        height: 56.w,
                        width: 56.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: cat.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(16.r),
                        ),
                        child: profile.photoUrl != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(16.r),
                                child: Image.network(
                                  profile.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _avatarFallback(color),
                                ),
                              )
                            : _avatarFallback(color),
                      ),

                      SizedBox(width: 12.w),

                      // Name + specialty + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (profile.isVerified)
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 15.w,
                                    color: color,
                                  ),
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
                            SizedBox(height: 6.h),
                            // Star rating
                            if (profile.avgRating != null)
                              Row(
                                children: [
                                  ...List.generate(5, (i) {
                                    final full =
                                        i < profile.avgRating!.floor();
                                    final half = !full &&
                                        i < profile.avgRating! &&
                                        (profile.avgRating! - i) >= 0.5;
                                    return Icon(
                                      full
                                          ? Icons.star_rounded
                                          : half
                                              ? Icons.star_half_rounded
                                              : Icons.star_outline_rounded,
                                      size: 13.w,
                                      color: const Color(0xFFF59E0B),
                                    );
                                  }),
                                  SizedBox(width: 4.w),
                                  Text(
                                    profile.avgRating!.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (profile.reviewCount > 0) ...[
                                    Text(
                                      ' (${profile.reviewCount})',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // ── Info chips row ───────────────────────────────────────
                  Row(
                    children: [
                      if (profile.yearsOfExperience > 0)
                        _InfoPill(
                          icon: Icons.workspace_premium_rounded,
                          label: '${profile.yearsOfExperience} yrs',
                          color: color,
                        ),
                      if (profile.yearsOfExperience > 0)
                        SizedBox(width: 6.w),
                      if (profile.location != null)
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.location_on_rounded,
                            label: profile.location!,
                            color: const Color(0xFF64748B),
                            maxWidth: true,
                          ),
                        ),
                      if (profile.successRate != null) ...[
                        SizedBox(width: 6.w),
                        _InfoPill(
                          icon: Icons.trending_up_rounded,
                          label:
                              '${profile.successRate!.toInt()}%',
                          color: const Color(0xFF16A34A),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // ── Action row ───────────────────────────────────────────
                  Row(
                    children: [
                      // Category pill
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 11.w, color: color),
                            SizedBox(width: 4.w),
                            Text(
                              cat.label,
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (showHire && profile.hourlyRate > 0) ...[
                        SizedBox(width: 8.w),
                        Text(
                          '\$${profile.hourlyRate.toStringAsFixed(0)}/hr',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Action button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (showHire) {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) =>
                                  _HireSheet(profile: profile),
                            );
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: showHire && !profile.isAvailableForHire
                                ? const Color(0xFFE2E8F0)
                                : color,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: showHire &&
                                    profile.isAvailableForHire
                                ? [
                                    BoxShadow(
                                      color:
                                          color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            showHire
                                ? (profile.isAvailableForHire
                                    ? 'Hire'
                                    : 'Unavailable')
                                : 'Contact',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: showHire &&
                                      !profile.isAvailableForHire
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(Color color) {
    return Center(
      child: Text(
        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
        style: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Info Pill ────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool maxWidth;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    this.maxWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.w, color: color),
        SizedBox(width: 4.w),
        maxWidth
            ? Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: child,
    );
  }
}

// ─── Near Me Card ─────────────────────────────────────────────────────────────

class _NearMeCard extends StatelessWidget {
  final Color accentColor;
  final List<Color> gradientColors;
  final String label;

  const _NearMeCard({
    required this.accentColor,
    required this.gradientColors,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withValues(alpha: 0.08),
            gradientColors[1].withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Container(
              height: 52.w,
              width: 52.w,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.my_location_rounded,
                size: 26.w,
                color: accentColor,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Near You',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Enable location to find $label within 5 km',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () => HapticFeedback.lightImpact(),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Allow',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _Cat cat;
  const _EmptyState({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 20.w),
      child: Column(
        children: [
          Container(
            height: 72.w,
            width: 72.w,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(cat.icon, size: 34.w, color: cat.color),
          ),
          SizedBox(height: 14.h),
          Text(
            cat.emptyLabel,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Check back later or search by name.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hire Sheet (logic unchanged) ────────────────────────────────────────────

class _HireSheet extends ConsumerStatefulWidget {
  final DiscoveryProfile profile;
  const _HireSheet({required this.profile});

  @override
  ConsumerState<_HireSheet> createState() => _HireSheetState();
}

class _HireSheetState extends ConsumerState<_HireSheet> {
  bool _isPaid = true;
  bool _sending = false;
  PatientModel? _selectedPatient;

  bool get _isManager {
    final roleStr = ref.read(currentUserDataProvider).valueOrNull?.role;
    return UserRoleX.fromString(roleStr) == UserRole.manager;
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    final authUser = ref.read(authStateProvider).valueOrNull;

    PatientModel? patient;
    if (_isManager) {
      patient = _selectedPatient;
    } else {
      final patientId = ref.read(resolvedActivePatientIdProvider);
      final patients =
          ref.read(patientsStreamProvider).valueOrNull ?? [];
      patient = patients.firstWhere(
        (p) => p.patientId == patientId,
        orElse: () =>
            patients.isNotEmpty ? patients.first : patients.first,
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
    final patients =
        ref.watch(patientsStreamProvider).valueOrNull ?? [];
    final canSend =
        !_sending && (!isManager || _selectedPatient != null);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Row(
              children: [
                Container(
                  height: 48.w,
                  width: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488)
                        .withValues(alpha: 0.1),
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
                    border:
                        Border.all(color: const Color(0xFFFED7AA)),
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
                  final isSelected =
                      _selectedPatient?.patientId == p.patientId;
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
                            ? const Color(0xFF0D9488)
                                .withValues(alpha: 0.06)
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
                              borderRadius:
                                  BorderRadius.circular(10.r),
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          const Color(0xFF0F172A),
                                    )),
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
                            Icon(Icons.check_circle_rounded,
                                size: 20.w,
                                color: const Color(0xFF0D9488)),
                        ],
                      ),
                    ),
                  );
                }),
              SizedBox(height: 16.h),
            ],

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
              Icon(icon,
                  size: 22.w,
                  color: selected
                      ? const Color(0xFF0D9488)
                      : const Color(0xFF94A3B8)),
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
