import 'package:cloud_firestore/cloud_firestore.dart';

enum CaregiverType { family, pro }

class CaregiverProfileModel {
  final String uid;
  final String name;
  final String? photoUrl;
  final CaregiverType caregiverType;
  final String? bio;
  final int yearsOfExperience;
  final double hourlyRate;
  final double dailyRate;
  final List<CertificationItem> certifications;
  final List<String> specializations;
  final int workHoursStart; // 0–23
  final int workHoursEnd; // 0–23
  final bool isVerified;
  final bool isAvailableForHire;
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
    this.certifications = const [],
    this.specializations = const [],
    this.workHoursStart = 8,
    this.workHoursEnd = 18,
    this.isVerified = false,
    this.isAvailableForHire = false,
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
      yearsOfExperience: d['yearsOfExperience'] as int? ?? 0,
      hourlyRate: (d['hourlyRate'] as num?)?.toDouble() ?? 0,
      dailyRate: (d['dailyRate'] as num?)?.toDouble() ?? 0,
      certifications: (d['certifications'] as List<dynamic>? ?? [])
          .map((c) => CertificationItem.fromMap(c as Map<String, dynamic>))
          .toList(),
      specializations: (d['specializations'] as List<dynamic>? ?? [])
          .map((s) => s.toString())
          .toList(),
      workHoursStart: d['workHoursStart'] as int? ?? 8,
      workHoursEnd: d['workHoursEnd'] as int? ?? 18,
      isVerified: d['isVerified'] as bool? ?? false,
      isAvailableForHire: d['isAvailableForHire'] as bool? ?? false,
      createdAt:
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'caregiverType': caregiverType.name,
        if (bio != null) 'bio': bio,
        'yearsOfExperience': yearsOfExperience,
        'hourlyRate': hourlyRate,
        'dailyRate': dailyRate,
        'certifications': certifications.map((c) => c.toMap()).toList(),
        'specializations': specializations,
        'workHoursStart': workHoursStart,
        'workHoursEnd': workHoursEnd,
        'isVerified': isVerified,
        'isAvailableForHire': isAvailableForHire,
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
    List<CertificationItem>? certifications,
    List<String>? specializations,
    int? workHoursStart,
    int? workHoursEnd,
    bool? isVerified,
    bool? isAvailableForHire,
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
        certifications: certifications ?? this.certifications,
        specializations: specializations ?? this.specializations,
        workHoursStart: workHoursStart ?? this.workHoursStart,
        workHoursEnd: workHoursEnd ?? this.workHoursEnd,
        isVerified: isVerified ?? this.isVerified,
        isAvailableForHire: isAvailableForHire ?? this.isAvailableForHire,
        createdAt: createdAt,
      );

  static CaregiverType _parseType(String? v) =>
      CaregiverType.values.firstWhere(
        (t) => t.name == v,
        orElse: () => CaregiverType.family,
      );
}

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
