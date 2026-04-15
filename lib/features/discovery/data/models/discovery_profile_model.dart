import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a professional (doctor, caregiver, hospital, pharmacy) listed
/// in the Discovery Hub. Documents live in collection-group queries across
/// `pro_doctors`, `pro_caregivers`, `pro_hospitals`, and `pro_pharmacies`.
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
