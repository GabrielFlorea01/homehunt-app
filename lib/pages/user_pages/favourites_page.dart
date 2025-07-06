import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/pages/gallery/gallery_view.dart';
import 'package:homehunt/pages/map/map.dart';
import 'package:intl/intl.dart';

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

  StreamSubscription<DocumentSnapshot>?
  userSub; // Abonament la documentul user-ului

  @override
  void initState() {
    super.initState();
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

                  // Afiseaza lista de carduri pentru fiecare proprietate favorita
                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            children:
                                docs.map((doc) {
                                  final data =
                                      doc.data()! as Map<String, dynamic>;
                                  data['id'] = doc.id;
                                  final images = List<String>.from(
                                    data['images'] as List? ?? [],
                                  );
                                  final loc =
                                      data['location']
                                          as Map<String, dynamic>? ??
                                      {};
                                  final fullAddress = [
                                        loc['street'] ?? '',
                                        loc['number'] ?? '',
                                        if ((loc['sector'] ?? '')
                                            .toString()
                                            .isNotEmpty)
                                          'Sector ${loc['sector']}',
                                        loc['city'] ?? '',
                                        loc['county'] ?? '',
                                      ]
                                      .where((s) => s.trim().isNotEmpty)
                                      .join(', ');

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ---- IMAGE STACK + BUTON DE UNFAVORITE ----
                                        Stack(
                                          children: [
                                            // Imaginea principala a proprietatii
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              child: AspectRatio(
                                                aspectRatio: 16 / 9,
                                                child:
                                                    images.isNotEmpty
                                                        ? Image.network(
                                                          images.first,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Container(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade300,
                                                              ),
                                                        )
                                                        : Container(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade300,
                                                        ),
                                              ),
                                            ),
                                            // Butonul de unfavorite (inima rosie)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.favorite,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    // Scoate imediat ID-ul din favoriteIds
                                                    final propId =
                                                        data['id'] as String;
                                                    try {
                                                      await usersRef
                                                          .doc(currentUser.uid)
                                                          .update({
                                                            'favoriteIds':
                                                                FieldValue.arrayRemove(
                                                                  [propId],
                                                                ),
                                                          });
                                                    } catch (e) {
                                                      // Daca nu exista campul, cream unul gol
                                                      await usersRef
                                                          .doc(currentUser.uid)
                                                          .set(
                                                            {'favoriteIds': []},
                                                            SetOptions(
                                                              merge: true,
                                                            ),
                                                          );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                            // Eticheta cu tipul tranzactiei ("De vanzare" sau "De inchiriat")
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  data['type'] as String? ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ---- DETAILS & EXPANSIONTILE ----
                                        ExpansionTile(
                                          tilePadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                          title: Text(
                                            data['title'] as String? ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '€ ${NumberFormat.decimalPattern('ro').format((data['price'] as num?) ?? 0)}',
                                          ),
                                          childrenPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                          children: [
                                            // Afiseaza adresa completa
                                            if (fullAddress.isNotEmpty)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      fullAddress,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 15),
                                            // Afiseaza chip-urile corespunzatoare categoriei
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: buildChips(data),
                                            ),
                                            // Afiseaza descrierea, daca exista
                                            if ((data['description'] as String?)
                                                    ?.isNotEmpty ??
                                                false) ...[
                                              const SizedBox(height: 20),
                                              Text(
                                                data['description'] as String,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                            // Daca exista mai multe imagini, afiseaza o galerie orizontala simplificata
                                            if (images.length > 1) ...[
                                              const SizedBox(height: 20),
                                              SizedBox(
                                                height: 150,
                                                child: Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.arrow_back_ios,
                                                      ),
                                                      onPressed: () {
                                                        // nu implementam scroll orizontal aici
                                                      },
                                                    ),
                                                    Expanded(
                                                      child: ListView.separated(
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        itemCount:
                                                            images.length,
                                                        separatorBuilder:
                                                            (_, __) =>
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                        itemBuilder:
                                                            (
                                                              _,
                                                              idx,
                                                            ) => GestureDetector(
                                                              onTap:
                                                                  () =>
                                                                      openGallery(
                                                                        context,
                                                                        images,
                                                                        idx,
                                                                      ),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                                child: Image.network(
                                                                  images[idx],
                                                                  width: 100,
                                                                  height: 100,
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                  errorBuilder:
                                                                      (
                                                                        _,
                                                                        __,
                                                                        ___,
                                                                      ) => Container(
                                                                        color:
                                                                            Colors.grey.shade300,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.arrow_forward_ios,
                                                      ),
                                                      onPressed: () {
                                                        // nu implementam scroll orizontal aici
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 20),
                                            // Afiseaza harta pentru adresa respectiva
                                            buildMapSection(fullAddress),
                                            const SizedBox(height: 20),
                                            // Afiseaza informatii despre agent
                                            FutureBuilder<DocumentSnapshot>(
                                              future:
                                                  FirebaseFirestore.instance
                                                      .collection('agents')
                                                      .doc(
                                                        data['agentId']
                                                            as String,
                                                      )
                                                      .get(),
                                              builder: (ctx, snapAgent) {
                                                final name =
                                                    data['agentName']
                                                        as String? ??
                                                    '';
                                                final phone =
                                                    snapAgent.hasData
                                                        ? (snapAgent.data!['phone']
                                                                as String? ??
                                                            '')
                                                        : '';
                                                return Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                      child: Text(
                                                        name.isNotEmpty
                                                            ? name[0]
                                                                .toUpperCase()
                                                            : 'A',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            name,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          if (snapAgent
                                                              .hasData) ...[
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              phone,
                                                              style:
                                                                  const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
