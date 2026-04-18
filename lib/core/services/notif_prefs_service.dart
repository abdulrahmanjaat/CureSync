import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NotifPrefsState {
  final Set<String> readIds;
  final Set<String> deletedIds;

  const NotifPrefsState({
    required this.readIds,
    required this.deletedIds,
  });

  factory NotifPrefsState.empty() =>
      const NotifPrefsState(readIds: {}, deletedIds: {});

  bool isRead(String id)    => readIds.contains(id);
  bool isDeleted(String id) => deletedIds.contains(id);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotifPrefsNotifier extends StateNotifier<NotifPrefsState> {
  NotifPrefsNotifier() : super(NotifPrefsState.empty()) {
    _load();
  }

  SharedPreferences? _prefs;

  static const _keyRead    = 'notif_read';
  static const _keyDeleted = 'notif_deleted';

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = NotifPrefsState(
      readIds:    Set.from(_prefs!.getStringList(_keyRead)    ?? []),
      deletedIds: Set.from(_prefs!.getStringList(_keyDeleted) ?? []),
    );
  }

  /// Mark a single notification as read.
  void markRead(String id) {
    if (state.readIds.contains(id)) return;
    final updated = {...state.readIds, id};
    state = NotifPrefsState(readIds: updated, deletedIds: state.deletedIds);
    _prefs?.setStringList(_keyRead, updated.toList());
  }

  /// Mark every supplied notification ID as read in a single write.
  void markAllRead(List<String> ids) {
    final updated = {...state.readIds, ...ids};
    state = NotifPrefsState(readIds: updated, deletedIds: state.deletedIds);
    _prefs?.setStringList(_keyRead, updated.toList());
  }

  /// Soft-delete a notification so it no longer appears in the list.
  void deleteNotif(String id) {
    if (state.deletedIds.contains(id)) return;
    final updated = {...state.deletedIds, id};
    state = NotifPrefsState(readIds: state.readIds, deletedIds: updated);
    _prefs?.setStringList(_keyDeleted, updated.toList());
  }

  /// Clear all deleted IDs (restore hidden notifications).
  void clearDeleted() {
    state = NotifPrefsState(readIds: state.readIds, deletedIds: {});
    _prefs?.remove(_keyDeleted);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notifPrefsProvider =
    StateNotifierProvider<NotifPrefsNotifier, NotifPrefsState>(
  (ref) => NotifPrefsNotifier(),
);
