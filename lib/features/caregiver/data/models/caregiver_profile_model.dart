import 'package:cloud_firestore/cloud_firestore.dart';

enum CaregiverType { family, pro }

// ─── Availability Preference ─────────────────────────────────────────────────

enum AvailabilityPreference { fullTime, partTime, both }

extension AvailabilityPreferenceX on AvailabilityPreference {
  String get label => switch (this) {
        AvailabilityPreference.fullTime => 'Full-time',
        AvailabilityPreference.partTime => 'Part-time',
        AvailabilityPreference.both => 'Full & Part-time',
      };

  String get firestoreValue => name;

  static AvailabilityPreference fromString(String? v) => switch (v) {
        'fullTime' => AvailabilityPreference.fullTime,
        'partTime' => AvailabilityPreference.partTime,
        _ => AvailabilityPreference.both,
      };
}

// ─── Work History Entry ───────────────────────────────────────────────────────

class WorkHistoryItem {
  final String organization;
  final String role;
  final int yearsWorked;

  const WorkHistoryItem({
    required this.organization,
    required this.role,
    required this.yearsWorked,
  });

  factory WorkHistoryItem.fromMap(Map<String, dynamic> m) => WorkHistoryItem(
        organization: m['organization'] as String? ?? '',
        role: m['role'] as String? ?? '',
        yearsWorked: (m['yearsWorked'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'organization': organization,
        'role': role,
        'yearsWorked': yearsWorked,
      };
}

// ─── Certification Item ───────────────────────────────────────────────────────

class CertificationItem {
  final String name;
  final bool isVerified;

  const CertificationItem({required this.name, this.isVerified = false});

  factory CertificationItem.fromMap(Map<String, dynamic> map) =>
      CertificationItem(
        name: map['name'] as String? ?? '',
        isVerified: map['isVerified'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'name': name, 'isVerified': isVerified};
}

// ─── Main Model ───────────────────────────────────────────────────────────────

class CaregiverProfileModel {
  final String uid;
  final String name;
  final String? photoUrl;
  final CaregiverType caregiverType;
  final String? bio;
  final int yearsOfExperience;
  final double hourlyRate;
  final double dailyRate;
  final double monthlyRate;
  final List<CertificationItem> certifications;
  final List<String> specializations;
  final List<String> languages;
  final List<WorkHistoryItem> workHistory;
  final AvailabilityPreference availability;
  final int workHoursStart; // 0–23
  final int workHoursEnd;   // 0–23
  final String? licenseNumber;
  final bool backgroundCheckAcknowledged;
  final bool isVerified;
  final bool isAvailableForHire;
  /// True once the multi-step onboarding has been fully completed.
  /// Used by the router to prevent accessing the dashboard prematurely.
  final bool onboardingComplete;
  final DateTime createdAt;

  const CaregiverProfileModel({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.caregiverType = CaregiverType.family,
    this.bio,
    this.yearsOfExperience = 0,
    this.hourlyRate = 0,
    this.dailyRate = 0,
    this.monthlyRate = 0,
    this.certifications = const [],
    this.specializations = const [],
    this.languages = const ['English'],
    this.workHistory = const [],
    this.availability = AvailabilityPreference.both,
    this.workHoursStart = 8,
    this.workHoursEnd = 18,
    this.licenseNumber,
    this.backgroundCheckAcknowledged = false,
    this.isVerified = false,
    this.isAvailableForHire = false,
    this.onboardingComplete = false,
    required this.createdAt,
  });

  factory CaregiverProfileModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CaregiverProfileModel(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      caregiverType: _parseType(d['caregiverType'] as String?),
      bio: d['bio'] as String?,
      yearsOfExperience: (d['yearsOfExperience'] as num?)?.toInt() ?? 0,
      hourlyRate: (d['hourlyRate'] as num?)?.toDouble() ?? 0,
      dailyRate: (d['dailyRate'] as num?)?.toDouble() ?? 0,
      monthlyRate: (d['monthlyRate'] as num?)?.toDouble() ?? 0,
      certifications: (d['certifications'] as List<dynamic>? ?? [])
          .map((c) => CertificationItem.fromMap(c as Map<String, dynamic>))
          .toList(),
      specializations: (d['specializations'] as List<dynamic>? ?? [])
          .map((s) => s.toString())
          .toList(),
      languages: (d['languages'] as List<dynamic>? ?? ['English'])
          .map((l) => l.toString())
          .toList(),
      workHistory: (d['workHistory'] as List<dynamic>? ?? [])
          .map((w) => WorkHistoryItem.fromMap(w as Map<String, dynamic>))
          .toList(),
      availability: AvailabilityPreferenceX.fromString(
          d['availability'] as String?),
      workHoursStart: (d['workHoursStart'] as num?)?.toInt() ?? 8,
      workHoursEnd: (d['workHoursEnd'] as num?)?.toInt() ?? 18,
      licenseNumber: d['licenseNumber'] as String?,
      backgroundCheckAcknowledged:
          d['backgroundCheckAcknowledged'] as bool? ?? false,
      isVerified: d['isVerified'] as bool? ?? false,
      isAvailableForHire: d['isAvailableForHire'] as bool? ?? false,
      onboardingComplete: d['onboardingComplete'] as bool? ?? false,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'caregiverType': caregiverType.name,
        if (bio != null && bio!.isNotEmpty) 'bio': bio,
        'yearsOfExperience': yearsOfExperience,
        'hourlyRate': hourlyRate,
        'dailyRate': dailyRate,
        'monthlyRate': monthlyRate,
        'certifications': certifications.map((c) => c.toMap()).toList(),
        'specializations': specializations,
        'languages': languages,
        'workHistory': workHistory.map((w) => w.toMap()).toList(),
        'availability': availability.firestoreValue,
        'workHoursStart': workHoursStart,
        'workHoursEnd': workHoursEnd,
        if (licenseNumber != null && licenseNumber!.isNotEmpty)
          'licenseNumber': licenseNumber,
        'backgroundCheckAcknowledged': backgroundCheckAcknowledged,
        'isVerified': isVerified,
        'isAvailableForHire': isAvailableForHire,
        'onboardingComplete': onboardingComplete,
        'createdAt': FieldValue.serverTimestamp(),
      };

  CaregiverProfileModel copyWith({
    String? name,
    String? photoUrl,
    CaregiverType? caregiverType,
    String? bio,
    int? yearsOfExperience,
    double? hourlyRate,
    double? dailyRate,
    double? monthlyRate,
    List<CertificationItem>? certifications,
    List<String>? specializations,
    List<String>? languages,
    List<WorkHistoryItem>? workHistory,
    AvailabilityPreference? availability,
    int? workHoursStart,
    int? workHoursEnd,
    String? licenseNumber,
    bool? backgroundCheckAcknowledged,
    bool? isVerified,
    bool? isAvailableForHire,
    bool? onboardingComplete,
  }) =>
      CaregiverProfileModel(
        uid: uid,
        name: name ?? this.name,
        photoUrl: photoUrl ?? this.photoUrl,
        caregiverType: caregiverType ?? this.caregiverType,
        bio: bio ?? this.bio,
        yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        dailyRate: dailyRate ?? this.dailyRate,
        monthlyRate: monthlyRate ?? this.monthlyRate,
        certifications: certifications ?? this.certifications,
        specializations: specializations ?? this.specializations,
        languages: languages ?? this.languages,
        workHistory: workHistory ?? this.workHistory,
        availability: availability ?? this.availability,
        workHoursStart: workHoursStart ?? this.workHoursStart,
        workHoursEnd: workHoursEnd ?? this.workHoursEnd,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        backgroundCheckAcknowledged:
            backgroundCheckAcknowledged ?? this.backgroundCheckAcknowledged,
        isVerified: isVerified ?? this.isVerified,
        isAvailableForHire: isAvailableForHire ?? this.isAvailableForHire,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        createdAt: createdAt,
      );

  static CaregiverType _parseType(String? v) =>
      CaregiverType.values.firstWhere(
        (t) => t.name == v,
        orElse: () => CaregiverType.family,
      );
}
