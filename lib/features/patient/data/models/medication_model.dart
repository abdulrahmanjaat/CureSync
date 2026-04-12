import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether the medication should be taken before or after a meal.
enum MealTiming { beforeMeal, afterMeal, withMeal, noRestriction }

extension MealTimingX on MealTiming {
  String get firestoreValue => switch (this) {
        MealTiming.beforeMeal => 'before_meal',
        MealTiming.afterMeal => 'after_meal',
        MealTiming.withMeal => 'with_meal',
        MealTiming.noRestriction => 'no_restriction',
      };

  String get label => switch (this) {
        MealTiming.beforeMeal => 'Before Meal',
        MealTiming.afterMeal => 'After Meal',
        MealTiming.withMeal => 'With Meal',
        MealTiming.noRestriction => 'No Restriction',
      };

  String get emoji => switch (this) {
        MealTiming.beforeMeal => '🍽️',
        MealTiming.afterMeal => '✅',
        MealTiming.withMeal => '🥢',
        MealTiming.noRestriction => '⏱️',
      };

  static MealTiming fromString(String? v) => switch (v) {
        'before_meal' => MealTiming.beforeMeal,
        'after_meal' => MealTiming.afterMeal,
        'with_meal' => MealTiming.withMeal,
        _ => MealTiming.noRestriction,
      };
}

class MedicationModel {
  final String? id;
  final String patientId;
  final String name;
  final String dosage;
  final int durationDays;
  final List<String> reminderTimes; // ["08:00", "14:00", "21:00"]
  final MealTiming mealTiming;
  final String? notes;
  final DateTime startDate;
  final bool isActive;

  const MedicationModel({
    this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.durationDays,
    required this.reminderTimes,
    this.mealTiming = MealTiming.noRestriction,
    this.notes,
    required this.startDate,
    this.isActive = true,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MedicationModel(
      id: doc.id,
      patientId: d['patientId'] ?? '',
      name: d['name'] ?? '',
      dosage: d['dosage'] ?? '',
      durationDays: d['durationDays'] ?? 0,
      reminderTimes: List<String>.from(d['reminderTimes'] ?? []),
      mealTiming: MealTimingX.fromString(d['mealTiming'] as String?),
      notes: d['notes'] as String?,
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: d['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'name': name,
      'dosage': dosage,
      'durationDays': durationDays,
      'reminderTimes': reminderTimes,
      'mealTiming': mealTiming.firestoreValue,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'startDate': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  DateTime get endDate => startDate.add(Duration(days: durationDays));
  bool get isExpired => DateTime.now().isAfter(endDate);

  String get frequencyLabel {
    final count = reminderTimes.length;
    if (count == 1) return 'Once daily';
    if (count == 2) return 'Twice daily';
    if (count == 3) return '3 times daily';
    return '$count times daily';
  }
}
