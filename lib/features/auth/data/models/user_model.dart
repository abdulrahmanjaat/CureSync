import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? role; // 'patient' or 'caregiver'
  final String? photoUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
