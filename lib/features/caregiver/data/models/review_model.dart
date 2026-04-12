import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String caregiverId;
  final String reviewerId; // UID of the patient / manager
  final String reviewerName;
  final int rating; // 1–5
  final String? comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.caregiverId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      caregiverId: d['caregiverId'] as String? ?? '',
      reviewerId: d['reviewerId'] as String? ?? '',
      reviewerName: d['reviewerName'] as String? ?? 'Anonymous',
      rating: (d['rating'] as num?)?.toInt().clamp(1, 5) ?? 5,
      comment: d['comment'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'caregiverId': caregiverId,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'rating': rating,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
