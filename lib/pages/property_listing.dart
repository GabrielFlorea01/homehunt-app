import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyListing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String location;
  final int rooms;
  final int bathrooms;
  final double surface;
  final bool isForSale;
  final List<String> imageUrls;
  final String agentName;
  final String phoneNumber;
  final String propertyType;
  final DateTime createdAt;
  final String userId;

  PropertyListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.rooms,
    required this.bathrooms,
    required this.surface,
    required this.isForSale,
    required this.imageUrls,
    required this.agentName,
    required this.phoneNumber,
    required this.propertyType,
    required this.createdAt,
    required this.userId,
  });

  factory PropertyListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PropertyListing(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      rooms: data['rooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      surface: (data['surface'] ?? 0).toDouble(),
      isForSale: data['isForSale'] ?? true,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      agentName: data['agentName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      propertyType: data['propertyType'] ?? 'Apartamente',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'surface': surface,
      'isForSale': isForSale,
      'imageUrls': imageUrls,
      'agentName': agentName,
      'phoneNumber': phoneNumber,
      'propertyType': propertyType,
      'createdAt': createdAt,
      'userId': userId,
    };
  }
}