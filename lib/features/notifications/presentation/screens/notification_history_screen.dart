import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../patient/presentation/providers/medication_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';

// ─── Simple in-memory notification model ─────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}

enum NotifType { upcoming, missed, taken, system }

// ─── Provider: derive notifications from medication data ──────────────────────

final notificationHistoryProvider =
    Provider<List<AppNotification>>((ref) {
  final patients = ref.watch(patientsStreamProvider).valueOrNull ?? [];

  final List<AppNotification> notifs = [];

  for (final patient in patients) {
    final pid = patient.patientId;
    if (pid == null) continue;

    final entries =
        ref.watch(todayPillTimelineProvider(pid));

    for (final e in entries) {
      if (e.isTaken) {
        notifs.add(AppNotification(
          id: '${pid}_${e.medId}_taken',
          title: 'Dose Taken ✓',
          body: '${e.medName} — ${e.time} (${patient.name})',
          type: NotifType.taken,
          time: DateTime.now(),
          isRead: true,
        ));
      } else {
        final parts = e.rawTime.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final doseTime =
            DateTime.now().copyWith(hour: hour, minute: minute, second: 0);
        final isPast = doseTime.isBefore(DateTime.now());

        notifs.add(AppNotification(
          id: '${pid}_${e.medId}_${e.rawTime}',
          title: isPast ? 'Missed Dose' : 'Upcoming Dose',
          body: '${e.medName} — ${e.time} (${patient.name})',
          type: isPast ? NotifType.missed : NotifType.upcoming,
          time: doseTime,
          isRead: false,
        ));
      }
    }
  }

  // Sort: most recent first
  notifs.sort((a, b) => b.time.compareTo(a.time));

  // Append static system notifications
  notifs.addAll([
    AppNotification(
      id: 'sys_welcome',
      title: 'Welcome to CureSync',
      body: 'Your health dashboard is ready. Add medications to start tracking.',
      type: NotifType.system,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    AppNotification(
      id: 'sys_backup',
      title: 'Data Synced',
      body: 'All your medication data has been securely backed up.',
      type: NotifType.system,
      time: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: true,
    ),
  ]);

  return notifs;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationHistoryProvider);
    final medAlerts =
        notifications.where((n) => n.type != NotifType.system).toList();
    final systemAlerts =
        notifications.where((n) => n.type == NotifType.system).toList();

    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: Column(
          children: [
            /// ─── Header ─────────────────────────────────────────────────────
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: Container(
                      height: 40.w,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16.w, color: const Color(0xFF0F172A)),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount unread',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Mark all read button
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF0D9488).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Mark all read',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.05, end: 0, duration: 300.ms),

            /// ─── Tab Bar ────────────────────────────────────────────────────
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              height: 44.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Medication Alerts'),
                        if (medAlerts.any((n) => !n.isRead)) ...[
                          SizedBox(width: 6.w),
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const Tab(text: 'System'),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 80.ms),

            SizedBox(height: 12.h),

            /// ─── Tab Content ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NotifList(items: medAlerts),
                  _NotifList(items: systemAlerts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification List ────────────────────────────────────────────────────────

class _NotifList extends StatelessWidget {
  final List<AppNotification> items;
  const _NotifList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 48.w, color: const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text(
              'No notifications yet',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      itemCount: items.length,
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, i) {
        return _NotifCard(notif: items[i])
            .animate()
            .fadeIn(duration: 300.ms, delay: (i * 50).ms)
            .slideX(begin: 0.03, end: 0, duration: 300.ms, delay: (i * 50).ms);
      },
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig(notif.type);
    final timeStr = _relativeTime(notif.time);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: notif.isRead
            ? Colors.white
            : cfg.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFE2E8F0)
              : cfg.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            height: 40.w,
            width: 40.w,
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(cfg.icon, size: 20.w, color: cfg.color),
          ),
          SizedBox(width: 12.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        notif.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  notif.body,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    cfg.label,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: cfg.color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Unread dot
          if (!notif.isRead) ...[
            SizedBox(width: 8.w),
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: cfg.color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _TypeConfig _typeConfig(NotifType type) {
    switch (type) {
      case NotifType.upcoming:
        return _TypeConfig(
          icon: Icons.alarm_rounded,
          color: const Color(0xFF0891B2),
          label: 'UPCOMING',
        );
      case NotifType.missed:
        return _TypeConfig(
          icon: Icons.alarm_off_rounded,
          color: const Color(0xFFEF4444),
          label: 'MISSED',
        );
      case NotifType.taken:
        return _TypeConfig(
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF16A34A),
          label: 'TAKEN',
        );
      case NotifType.system:
        return _TypeConfig(
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF7C3AED),
          label: 'SYSTEM',
        );
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig(
      {required this.icon, required this.color, required this.label});
}
