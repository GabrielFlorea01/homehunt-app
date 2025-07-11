import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String id;
  final String title;
  final String type; // 'Vandut' sau 'Inchiriat'
  final double price;
  final DateTime createdAt;

  PropertyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.createdAt,
  });

  factory PropertyModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return PropertyModel(
      id: doc.id,
      title: data['title'] as String,
      type: data['type'] as String,
      price: (data['price'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
