import 'package:cloud_firestore/cloud_firestore.dart';

/// Doctor specialty — fixed taxonomy used by the Discovery Hub filter chips.
/// Add new entries here AND extend the [DoctorSpecialtyX] mappings below.
enum DoctorSpecialty {
  general,
  cardiology,
  dermatology,
  endocrinology,
  gastroenterology,
  neurology,
  oncology,
  orthopedics,
  pediatrics,
  psychiatry,
  pulmonology,
  radiology,
  surgery,
  urology,
}

extension DoctorSpecialtyX on DoctorSpecialty {
  String get label => switch (this) {
        DoctorSpecialty.general          => 'General Practice',
        DoctorSpecialty.cardiology       => 'Cardiology',
        DoctorSpecialty.dermatology      => 'Dermatology',
        DoctorSpecialty.endocrinology    => 'Endocrinology',
        DoctorSpecialty.gastroenterology => 'Gastroenterology',
        DoctorSpecialty.neurology        => 'Neurology',
        DoctorSpecialty.oncology         => 'Oncology',
        DoctorSpecialty.orthopedics      => 'Orthopedics',
        DoctorSpecialty.pediatrics       => 'Pediatrics',
        DoctorSpecialty.psychiatry       => 'Psychiatry',
        DoctorSpecialty.pulmonology      => 'Pulmonology',
        DoctorSpecialty.radiology        => 'Radiology',
        DoctorSpecialty.surgery          => 'Surgery',
        DoctorSpecialty.urology          => 'Urology',
      };

  String get firestoreValue => switch (this) {
        DoctorSpecialty.general          => 'general',
        DoctorSpecialty.cardiology       => 'cardiology',
        DoctorSpecialty.dermatology      => 'dermatology',
        DoctorSpecialty.endocrinology    => 'endocrinology',
        DoctorSpecialty.gastroenterology => 'gastroenterology',
        DoctorSpecialty.neurology        => 'neurology',
        DoctorSpecialty.oncology         => 'oncology',
        DoctorSpecialty.orthopedics      => 'orthopedics',
        DoctorSpecialty.pediatrics       => 'pediatrics',
        DoctorSpecialty.psychiatry       => 'psychiatry',
        DoctorSpecialty.pulmonology      => 'pulmonology',
        DoctorSpecialty.radiology        => 'radiology',
        DoctorSpecialty.surgery          => 'surgery',
        DoctorSpecialty.urology          => 'urology',
      };

  static DoctorSpecialty fromString(String? v) => switch (v) {
        'cardiology'       => DoctorSpecialty.cardiology,
        'dermatology'      => DoctorSpecialty.dermatology,
        'endocrinology'    => DoctorSpecialty.endocrinology,
        'gastroenterology' => DoctorSpecialty.gastroenterology,
        'neurology'        => DoctorSpecialty.neurology,
        'oncology'         => DoctorSpecialty.oncology,
        'orthopedics'      => DoctorSpecialty.orthopedics,
        'pediatrics'       => DoctorSpecialty.pediatrics,
        'psychiatry'       => DoctorSpecialty.psychiatry,
        'pulmonology'      => DoctorSpecialty.pulmonology,
        'radiology'        => DoctorSpecialty.radiology,
        'surgery'          => DoctorSpecialty.surgery,
        'urology'          => DoctorSpecialty.urology,
        _                  => DoctorSpecialty.general,
      };
}

/// Mirrors `pro_doctors/{uid}` — the doctor's discoverable work profile.
///
/// Owner-writable, world-readable (per firestore.rules pro_doctors block).
/// Patients and managers browse this via the Discovery Hub. Doctors edit
/// their own document via the Work Profile screen.
class DoctorModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  // Clinical identity
  final DoctorSpecialty specialty;
  final List<String> qualifications;   // e.g. ['MBBS', 'MD - Cardiology']
  final String licenseNumber;          // medical council registration
  final int yearsOfExperience;
  final String? bio;

  // Practice details
  final String? hospitalAffiliation;
  final double consultationFee;        // single-source numeric currency
  final List<String> languages;        // ['English', 'Urdu', ...]

  // Discovery / status
  final double rating;                 // 0.0 – 5.0
  final int totalReviews;
  final bool isVerified;               // admin / KYC verified
  final bool isAvailable;              // accepting new appointments
  final bool onboardingComplete;       // gates dashboard access

  final DateTime createdAt;
  final DateTime? updatedAt;

  const DoctorModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.specialty,
    this.qualifications = const [],
    required this.licenseNumber,
    this.yearsOfExperience = 0,
    this.bio,
    this.hospitalAffiliation,
    this.consultationFee = 0,
    this.languages = const [],
    this.rating = 0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.onboardingComplete = false,
    required this.createdAt,
    this.updatedAt,
  });

  // ── Firestore ──────────────────────────────────────────────────────────────
  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DoctorModel(
      uid:                 doc.id,
      name:                d['name']                as String? ?? '',
      email:               d['email']               as String? ?? '',
      photoUrl:            d['photoUrl']            as String?,
      specialty:           DoctorSpecialtyX.fromString(d['specialty'] as String?),
      qualifications:      (d['qualifications'] as List?)?.cast<String>() ?? const [],
      licenseNumber:       d['licenseNumber']       as String? ?? '',
      yearsOfExperience:   (d['yearsOfExperience']  as num?)?.toInt() ?? 0,
      bio:                 d['bio']                 as String?,
      hospitalAffiliation: d['hospitalAffiliation'] as String?,
      consultationFee:     (d['consultationFee']    as num?)?.toDouble() ?? 0,
      languages:           (d['languages']      as List?)?.cast<String>() ?? const [],
      rating:              (d['rating']             as num?)?.toDouble() ?? 0,
      totalReviews:        (d['totalReviews']       as num?)?.toInt() ?? 0,
      isVerified:          d['isVerified']          as bool? ?? false,
      isAvailable:         d['isAvailable']         as bool? ?? true,
      onboardingComplete:  d['onboardingComplete']  as bool? ?? false,
      createdAt:           (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:           (d['updatedAt']  as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name':                name,
        'email':               email,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'specialty':           specialty.firestoreValue,
        'qualifications':      qualifications,
        'licenseNumber':       licenseNumber,
        'yearsOfExperience':   yearsOfExperience,
        if (bio != null) 'bio': bio,
        if (hospitalAffiliation != null) 'hospitalAffiliation': hospitalAffiliation,
        'consultationFee':     consultationFee,
        'languages':           languages,
        'rating':              rating,
        'totalReviews':        totalReviews,
        'isVerified':          isVerified,
        'isAvailable':         isAvailable,
        'onboardingComplete':  onboardingComplete,
        'createdAt':           Timestamp.fromDate(createdAt),
        'updatedAt':           FieldValue.serverTimestamp(),
      };

  // ── Helpers ────────────────────────────────────────────────────────────────
  DoctorModel copyWith({
    String? name,
    String? photoUrl,
    DoctorSpecialty? specialty,
    List<String>? qualifications,
    String? licenseNumber,
    int? yearsOfExperience,
    String? bio,
    String? hospitalAffiliation,
    double? consultationFee,
    List<String>? languages,
    double? rating,
    int? totalReviews,
    bool? isVerified,
    bool? isAvailable,
    bool? onboardingComplete,
  }) {
    return DoctorModel(
      uid:                 uid,
      name:                name                ?? this.name,
      email:               email,
      photoUrl:            photoUrl            ?? this.photoUrl,
      specialty:           specialty           ?? this.specialty,
      qualifications:      qualifications      ?? this.qualifications,
      licenseNumber:       licenseNumber       ?? this.licenseNumber,
      yearsOfExperience:   yearsOfExperience   ?? this.yearsOfExperience,
      bio:                 bio                 ?? this.bio,
      hospitalAffiliation: hospitalAffiliation ?? this.hospitalAffiliation,
      consultationFee:     consultationFee     ?? this.consultationFee,
      languages:           languages           ?? this.languages,
      rating:              rating              ?? this.rating,
      totalReviews:        totalReviews        ?? this.totalReviews,
      isVerified:          isVerified          ?? this.isVerified,
      isAvailable:         isAvailable         ?? this.isAvailable,
      onboardingComplete:  onboardingComplete  ?? this.onboardingComplete,
      createdAt:           createdAt,
      updatedAt:           DateTime.now(),
    );
  }

  /// Empty seed used by onboarding controllers before any field is set.
  factory DoctorModel.empty({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) =>
      DoctorModel(
        uid: uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        specialty: DoctorSpecialty.general,
        licenseNumber: '',
        createdAt: DateTime.now(),
      );
}
