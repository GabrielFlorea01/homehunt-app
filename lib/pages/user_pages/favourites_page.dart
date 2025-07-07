import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/models/gallery/gallery_model.dart';
import 'package:homehunt/models/map/map_model.dart';
import 'package:homehunt/models/property_card/property_card_model.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  // Referinta catre colectia 'properties' din Firestore
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');
  // Referinta catre colectia 'users' din Firestore
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  User? user; // Referinta catre utilizatorul curent
  List<String> favoriteIds = []; // Lista de ID-uri de anunturi favorite
  bool isLoading = true; // Flag pentru loader
  final Map<String, ScrollController> galleryControllers = {}; // mini galeria din card

  StreamSubscription<DocumentSnapshot>?
  userSub; // Abonament la documentul user-ului

  @override
  void initState() {
    super.initState();
    for (var c in galleryControllers.values) {
      c.dispose();
    }
    loadFavorites(); // Incarca lista de favorite la initializare
  }

  @override
  void dispose() {
    userSub?.cancel(); // Opreste abonamentul daca exista
    super.dispose();
  }

  /// Incarca favoriteIds din documentul user-ului
  Future<void> loadFavorites() async {
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Daca nu exista user logat, opreste loader si returneaza
      setState(() => isLoading = false);
      return;
    }

    // Asculta modificari pe documentul user-ului
    userSub = usersRef
        .doc(user!.uid)
        .snapshots()
        .listen(
          (docSnap) {
            if (!mounted) return;
            final data = docSnap.data() as Map<String, dynamic>? ?? {};
            final favList = data['favoriteIds'] as List<dynamic>? ?? [];
            favoriteIds = favList.map((e) => e.toString()).toList();
            setState(() {
              isLoading = false; // Opreste loader dupa ce preia datele
            });
          },
          onError: (e) {
            if (!mounted) return;
            // Daca apare eroare, opreste loader
            setState(() {
              isLoading = false;
            });
          },
        );
  }

  /// Deschide galeria de imagini full-screen
  void openGallery(BuildContext ctx, List<String> imgs, int idx) {
    Navigator.of(ctx).push(
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

  /// Creaza o lista de Chip-uri in functie de categoria proprietatii
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
    // Daca este inca in curs de incarcare, afiseaza loader
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          // AppBar fara back-button (ramane implicit daca navigator are schema)
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Daca nu mai exista user logat, intoarce un widget gol (AuthGate va prelua situatia)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        // IconTheme pentru a face back-arrow implicit alb
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true, // Afiseaza back-arrow implicit
      ),
      body:
          favoriteIds.isEmpty
              // Daca nu exista favorite, afiseaza mesaj
              ? const Center(child: Text('Nu ai proprietati favorite'))
              : StreamBuilder<QuerySnapshot>(
                // Query Firestore: preia doar documentele a caror ID se afla in favoriteIds
                stream:
                    propertiesRef
                        .where(FieldPath.documentId, whereIn: favoriteIds)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    final err = snap.error;
                    // Daca eroarea este de permisiune
                    if (err is FirebaseException &&
                        err.code == 'permission-denied') {
                      return const Center(child: Text('Nu aveti permisiune'));
                    }
                    return Center(child: Text('Eroare: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Nu ai adaugat inca favorit'),
                    );
                  }

                  //lista de carduri pentru fiecare proprietate favorita
                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          children:
                              docs.map((doc) {
                                final data = doc.data()! as Map<String, dynamic>;
                                final id = doc.id;
                                data['id'] = id;
                                galleryControllers.putIfAbsent(id, () => ScrollController());
                                return PropertyCard(
                                  data: data,
                                  isFavorite: true,
                                  onToggleFavorite: (id) async {
                                    await usersRef.doc(user!.uid).update({
                                      'favoriteIds': FieldValue.arrayRemove([
                                        id,
                                      ]),
                                    });
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
    );
  }
}
