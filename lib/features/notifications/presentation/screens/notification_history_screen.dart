import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/role_provider.dart';
import '../../../patient/presentation/providers/medication_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';
import '../../../../core/services/notif_prefs_service.dart';

// ─── Notification model ───────────────────────────────────────────────────────

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

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id:     id,
        title:  title,
        body:   body,
        type:   type,
        time:   time,
        isRead: isRead ?? this.isRead,
      );
}

enum NotifType { upcoming, missed, taken, system }

// ─── Static system notifications ─────────────────────────────────────────────

List<AppNotification> _staticSystemNotifs() => [
      AppNotification(
        id:    'sys_welcome',
        title: 'Welcome to CureSync',
        body:  'Your health dashboard is ready. Add medications to start tracking.',
        type:  NotifType.system,
        time:  DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id:    'sys_backup',
        title: 'Data Synced',
        body:  'All your medication data has been securely backed up.',
        type:  NotifType.system,
        time:  DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
    ];

// ─── Build dose notifications for one patient ─────────────────────────────────

List<AppNotification> _doseNotifs(
  String pid,
  String patientLabel,
  List<dynamic> entries, // List<PillTimelineEntry>
) {
  final notifs = <AppNotification>[];
  for (final e in entries) {
    if (e.isTaken) {
      // Use the server-recorded takenAt if available; fall back to now.
      final takenTime = (e.takenAt as DateTime?) ?? DateTime.now();
      notifs.add(AppNotification(
        id:     '${pid}_${e.medId}_taken',
        title:  'Dose Taken ✓',
        body:   '${e.medName} — ${e.time} ($patientLabel)',
        type:   NotifType.taken,
        time:   takenTime,
        isRead: true,
      ));
    } else if (e.isMissed) {
      // Missed: timestamp is the end of the grace window (scheduled + window).
      final parts     = (e.rawTime as String).split(':');
      final hour      = int.tryParse(parts[0]) ?? 0;
      final minute    = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final doseTime  = DateTime.now()
          .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);
      notifs.add(AppNotification(
        id:    '${pid}_${e.medId}_${e.rawTime}_missed',
        title: 'Missed Dose ✗',
        body:  '${e.medName} — ${e.time} ($patientLabel)',
        type:  NotifType.missed,
        time:  doseTime,
      ));
    } else {
      // Upcoming (due or future).
      final parts    = (e.rawTime as String).split(':');
      final hour     = int.tryParse(parts[0]) ?? 0;
      final minute   = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final doseTime = DateTime.now()
          .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);
      notifs.add(AppNotification(
        id:    '${pid}_${e.medId}_${e.rawTime}',
        title: e.isDue ? 'Due Now 💊' : 'Upcoming Dose',
        body:  '${e.medName} — ${e.time} ($patientLabel)',
        type:  NotifType.upcoming,
        time:  doseTime,
      ));
    }
  }
  return notifs;
}

// ─── Raw provider (before prefs overlay) ─────────────────────────────────────
//
// Security: strictly scoped to the logged-in user — see patient_provider.dart
// for the full two-layer guard commentary.

final _rawNotifProvider = Provider<List<AppNotification>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final userData = ref.watch(currentUserDataProvider).valueOrNull;
  final role     = UserRoleX.fromString(userData?.role);

  if (role == UserRole.patient) {
    final uid = authUser?.uid;
    if (uid == null) return _staticSystemNotifs();
    final entries     = ref.watch(todayPillTimelineProvider(uid));
    final displayName = authUser?.displayName?.split(' ').first ?? 'You';
    final notifs      = _doseNotifs(uid, displayName, entries);
    notifs.sort((a, b) => b.time.compareTo(a.time));
    return [...notifs, ..._staticSystemNotifs()];
  }

  final patients = ref.watch(patientsStreamProvider).valueOrNull ?? [];
  final notifs   = <AppNotification>[];
  for (final patient in patients) {
    final pid = patient.patientId;
    if (pid == null) continue;
    if (patient.managerId != authUser?.uid) continue;
    final entries = ref.watch(todayPillTimelineProvider(pid));
    notifs.addAll(_doseNotifs(pid, patient.name, entries));
  }
  notifs.sort((a, b) => b.time.compareTo(a.time));
  return [...notifs, ..._staticSystemNotifs()];
});

// ─── Final provider (prefs overlay: read state + deleted filter) ──────────────

final notificationHistoryProvider = Provider<List<AppNotification>>((ref) {
  final raw   = ref.watch(_rawNotifProvider);
  final prefs = ref.watch(notifPrefsProvider);

  return raw
      .where((n) => !prefs.isDeleted(n.id))
      .map((n) => prefs.isRead(n.id) ? n.copyWith(isRead: true) : n)
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends ConsumerState<NotificationHistoryScreen> {
  NotifType? _activeFilter;

  void _markAllRead(List<AppNotification> notifs) {
    HapticFeedback.lightImpact();
    ref
        .read(notifPrefsProvider.notifier)
        .markAllRead(notifs.map((n) => n.id).toList());
  }

  void _deleteNotif(String id) {
    ref.read(notifPrefsProvider.notifier).deleteNotif(id);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notificationHistoryProvider);

    final filtered = _activeFilter == null
        ? all
        : all.where((n) => n.type == _activeFilter).toList();

    final unreadCount   = all.where((n) => !n.isRead).length;
    final missedCount   = all.where((n) => n.type == NotifType.missed).length;
    final upcomingCount = all.where((n) => n.type == NotifType.upcoming).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFC),
      body: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────────────
          _GradientHeader(
            unreadCount:   unreadCount,
            missedCount:   missedCount,
            upcomingCount: upcomingCount,
            hasUnread:     unreadCount > 0,
            onBack:        () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            onMarkAllRead: () => _markAllRead(all),
          ),

          SizedBox(height: 14.h),

          // ── Filter Chips ─────────────────────────────────────────────────
          _FilterRow(
            active:   _activeFilter,
            onSelect: (t) {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = t);
            },
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

          SizedBox(height: 8.h),

          // ── Notification List ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(filter: _activeFilter)
                : ListView.builder(
                    padding:   EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final notif = filtered[i];
                      return Dismissible(
                        key:             ValueKey(notif.id),
                        direction:       DismissDirection.endToStart,
                        onDismissed:     (_) => _deleteNotif(notif.id),
                        background:      _SwipeDeleteBg(),
                        child: _PatientNotifCard(notif: notif, index: i)
                            .animate()
                            .fadeIn(duration: 280.ms, delay: (i * 40).ms)
                            .slideY(
                                begin:    0.04,
                                end:      0,
                                duration: 280.ms,
                                delay:    (i * 40).ms),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Swipe-to-delete background ───────────────────────────────────────────────

class _SwipeDeleteBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin:      EdgeInsets.only(bottom: 10.h),
      decoration:  BoxDecoration(
        color:        const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(18.r),
      ),
      alignment: Alignment.centerRight,
      padding:   EdgeInsets.only(right: 20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded,
              color: Colors.white, size: 22.w),
          SizedBox(height: 3.h),
          Text(
            'Delete',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color:       Colors.white,
              fontWeight:  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gradient Header ──────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  final int unreadCount;
  final int missedCount;
  final int upcomingCount;
  final bool hasUnread;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

  const _GradientHeader({
    required this.unreadCount,
    required this.missedCount,
    required this.upcomingCount,
    required this.hasUnread,
    required this.onBack,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF4F46E5)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back row + Mark All as Read
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      height: 38.w,
                      width:  38.w,
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16.w, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: GoogleFonts.poppins(
                        fontSize:   22.sp,
                        fontWeight: FontWeight.w800,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                  // Unread badge
                  if (unreadCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color:        Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '$unreadCount unread',
                        style: GoogleFonts.inter(
                          fontSize:   11.sp,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white,
                        ),
                      ),
                    ),
                  // Mark All as Read button
                  if (hasUnread) ...[
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: onMarkAllRead,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color:        Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all_rounded,
                                size: 13.w, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              'Mark all read',
                              style: GoogleFonts.inter(
                                fontSize:   10.sp,
                                fontWeight: FontWeight.w700,
                                color:      Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 16.h),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatBubble(
                      icon:  Icons.alarm_off_rounded,
                      label: 'Missed',
                      value: '$missedCount',
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _StatBubble(
                      icon:  Icons.alarm_rounded,
                      label: 'Upcoming',
                      value: '$upcomingCount',
                      color: const Color(0xFF93C5FD),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _StatBubble(
                      icon:  Icons.notifications_active_rounded,
                      label: 'Total',
                      value: '${missedCount + upcomingCount}',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.06, end: 0, duration: 350.ms);
  }
}

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBubble({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize:   14.sp,
                  fontWeight: FontWeight.w800,
                  color:      Colors.white,
                  height:     1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize:   9.sp,
                  color:      Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final NotifType? active;
  final ValueChanged<NotifType?> onSelect;

  const _FilterRow({required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView(
        padding:         EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label:    'All',
            icon:     Icons.notifications_rounded,
            color:    const Color(0xFF0D9488),
            isActive: active == null,
            onTap:    () => onSelect(null),
          ),
          SizedBox(width: 8.w),
          _Chip(
            label:    'Upcoming',
            icon:     Icons.alarm_rounded,
            color:    const Color(0xFF0891B2),
            isActive: active == NotifType.upcoming,
            onTap:    () => onSelect(
                active == NotifType.upcoming ? null : NotifType.upcoming),
          ),
          SizedBox(width: 8.w),
          _Chip(
            label:    'Missed',
            icon:     Icons.alarm_off_rounded,
            color:    const Color(0xFFEF4444),
            isActive: active == NotifType.missed,
            onTap:    () =>
                onSelect(active == NotifType.missed ? null : NotifType.missed),
          ),
          SizedBox(width: 8.w),
          _Chip(
            label:    'Taken',
            icon:     Icons.check_circle_outline_rounded,
            color:    const Color(0xFF16A34A),
            isActive: active == NotifType.taken,
            onTap:    () =>
                onSelect(active == NotifType.taken ? null : NotifType.taken),
          ),
          SizedBox(width: 8.w),
          _Chip(
            label:    'System',
            icon:     Icons.info_outline_rounded,
            color:    const Color(0xFF7C3AED),
            isActive: active == NotifType.system,
            onTap:    () =>
                onSelect(active == NotifType.system ? null : NotifType.system),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color:        isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size:  13.w,
                color: isActive ? Colors.white : color),
            SizedBox(width: 5.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize:   12.sp,
                fontWeight: FontWeight.w600,
                color:      isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _PatientNotifCard extends StatelessWidget {
  final AppNotification notif;
  final int index;

  const _PatientNotifCard({required this.notif, required this.index});

  @override
  Widget build(BuildContext context) {
    final cfg     = _typeConfig(notif.type);
    final timeStr = _relativeTime(notif.time);

    return Container(
      margin:  EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: notif.isRead
            ? Colors.white
            : cfg.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: notif.isRead
              ? const Color(0xFFE2E8F0)
              : cfg.color.withValues(alpha: 0.25),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured icon circle
          Container(
            height: 44.w,
            width:  44.w,
            decoration: BoxDecoration(
              color:        cfg.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(cfg.icon, size: 22.w, color: cfg.color),
          ),
          SizedBox(width: 12.w),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: GoogleFonts.poppins(
                          fontSize:   13.sp,
                          fontWeight: FontWeight.w700,
                          color:      const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color:    const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  notif.body,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color:    const Color(0xFF64748B),
                    height:   1.4,
                  ),
                ),
                SizedBox(height: 7.h),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color:        cfg.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    cfg.label,
                    style: GoogleFonts.inter(
                      fontSize:      9.sp,
                      fontWeight:    FontWeight.w800,
                      color:         cfg.color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Unread dot
          if (!notif.isRead) ...[
            SizedBox(width: 6.w),
            Container(
              width:  8.w,
              height: 8.w,
              margin: EdgeInsets.only(top: 4.h),
              decoration: BoxDecoration(
                  color: cfg.color, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }

  _TypeConfig _typeConfig(NotifType type) {
    return switch (type) {
      NotifType.upcoming => _TypeConfig(
          icon:  Icons.alarm_rounded,
          color: const Color(0xFF0891B2),
          label: 'UPCOMING',
        ),
      NotifType.missed => _TypeConfig(
          icon:  Icons.alarm_off_rounded,
          color: const Color(0xFFEF4444),
          label: 'MISSED',
        ),
      NotifType.taken => _TypeConfig(
          icon:  Icons.check_circle_outline_rounded,
          color: const Color(0xFF16A34A),
          label: 'TAKEN',
        ),
      NotifType.system => _TypeConfig(
          icon:  Icons.info_outline_rounded,
          color: const Color(0xFF7C3AED),
          label: 'SYSTEM',
        ),
    };
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final NotifType? filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 72.w,
            width:  72.w,
            decoration: BoxDecoration(
              color:  const Color(0xFF0D9488).withValues(alpha: 0.08),
              shape:  BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined,
                size: 34.w, color: const Color(0xFF0D9488)),
          ),
          SizedBox(height: 14.h),
          Text(
            filter == null
                ? 'No notifications yet'
                : 'No ${filter!.name} alerts',
            style: GoogleFonts.poppins(
              fontSize:   15.sp,
              color:      const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "You're all caught up!",
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color:    const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.9, 0.9), duration: 400.ms);
  }
}

// ─── Type config ─────────────────────────────────────────────────────────────

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig(
      {required this.icon, required this.color, required this.label});
}
