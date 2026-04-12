import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review_model.dart';

class ReviewRepository {
  final FirebaseFirestore _db;

  ReviewRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference _reviewsRef(String caregiverId) => _db
      .collection('pro_caregivers')
      .doc(caregiverId)
      .collection('reviews');

  DocumentReference _caregiverRef(String caregiverId) =>
      _db.collection('pro_caregivers').doc(caregiverId);

  Stream<List<ReviewModel>> reviewsStream(String caregiverId) {
    return _reviewsRef(caregiverId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map(ReviewModel.fromFirestore).toList());
  }

  /// Adds a review and atomically updates avgRating + reviewCount on the
  /// caregiver's pro_caregivers document.
  Future<void> addReview(ReviewModel review) async {
    final caregiverRef = _caregiverRef(review.caregiverId);
    final reviewRef = _reviewsRef(review.caregiverId).doc();

    await _db.runTransaction((txn) async {
      final snap = await txn.get(caregiverRef);
      final d = snap.data() as Map<String, dynamic>? ?? {};

      final currentCount = (d['reviewCount'] as num?)?.toInt() ?? 0;
      final currentAvg = (d['avgRating'] as num?)?.toDouble() ?? 0.0;

      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + review.rating) / newCount;

      txn.set(reviewRef, review.toFirestore());
      txn.set(
        caregiverRef,
        {
          'reviewCount': newCount,
          'avgRating': double.parse(newAvg.toStringAsFixed(1)),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Updates successRate on the discovery hub document.
  /// Call after a deal is accepted or rejected.
  /// [completedJobs] = total accepted deals, [totalRequests] = all requests.
  Future<void> updateSuccessRate({
    required String caregiverId,
    required int completedJobs,
    required int totalRequests,
  }) async {
    final rate = totalRequests > 0
        ? double.parse(
            ((completedJobs / totalRequests) * 100).toStringAsFixed(1))
        : 0.0;

    await _caregiverRef(caregiverId).set(
      {'successRate': rate},
      SetOptions(merge: true),
    );
  }
}
