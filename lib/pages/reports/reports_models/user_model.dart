import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
