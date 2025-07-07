import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/models/gallery/gallery_model.dart';
import 'package:homehunt/models/property_card/property_card_model.dart';
import 'package:homehunt/pages/user_pages/edit_listing_page.dart';
import 'package:homehunt/models/map/map_model.dart';

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});
  @override
  State<MyListingsPage> createState() => MyListingsPageState();
}

class MyListingsPageState extends State<MyListingsPage> {
  final CollectionReference propertiesRef = FirebaseFirestore.instance.collection('properties');

  // A ScrollController for each card's horizontal gallery
  final Map<String, ScrollController> galleryControllers = {};
  // Track which cards have phone expanded
  final Map<String, bool> showPhone = {};

  @override
  void dispose() {
    for (var c in galleryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void openGallery(BuildContext c, List<String> imgs, int idx) {
    Navigator.of(c).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  '${idx + 1}/${imgs.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              body: GalleryView(images: imgs, initialIndex: idx),
            ),
      ),
    );
  }

  void togglePhone(String id) {
    showPhone[id] = !(showPhone[id] ?? false);
    setState(() {});
  }

  List<Widget> buildChips(Map<String, dynamic> data) {
    switch (data['category'] as String? ?? '') {
      case 'Garsoniera':
        final g = data['garsonieraDetails'] as Map<String, dynamic>? ?? {};
        return [
          const Chip(
            label: Text('1 camera'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${g['area'] ?? ''} mp'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('Etaj ${g['floor'] ?? ''}'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${g['yearBuilt'] ?? ''}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Apartament':
        final apt = data['apartmentDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text('${apt['rooms']} camere'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${apt['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('Etaj ${apt['floor']}'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${apt['yearBuilt']}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Casa':
        final c = data['houseDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text('${c['rooms']} camere'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${c['area']} mp utili'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${c['landArea']} mp teren'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${c['floors']} etaje'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${c['yearBuilt']}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Teren':
        final t = data['landDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text(t['classification'] ?? ''),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${t['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Spatiu comercial':
        final sc = data['commercialDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text('${sc['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: propertiesRef.where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (ctx, snap) {
            if (snap.hasError) {
              return Center(child: Text('Eroare: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text('Nu ai adaugat inca niciun anunt'),
              );
            }
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children:
                        docs.asMap().entries.map((entry) {
                          final data = entry.value.data()! as Map<String, dynamic>;
                          final id = entry.value.id;
                          data['id'] = id;
                          galleryControllers.putIfAbsent(id, () => ScrollController());
                          return PropertyCard(
                            data: data,
                            isFavorite: false,
                            onToggleFavorite: null, //nu am nevoie aici de favorite
                            onEdit: (id) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditListingPage(listingId: id),
                                ),
                              );
                            },
                            onDelete: (id) async {
                              await propertiesRef.doc(id).delete();
                            },
                            openGallery: openGallery,
                            buildMapSection: buildMapSection,
                            scrollController: galleryControllers[id],
                          );
                        }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
