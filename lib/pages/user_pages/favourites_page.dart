import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/models/gallery/gallery_model.dart';
import 'package:homehunt/models/map/map_model.dart';
import 'package:intl/intl.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => FavoritesPageState();
}

class FavoritesPageState extends State<FavoritesPage> {
  // referinta catre colectia 'properties'
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');
  // referinta catre colectia 'users'
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  User? user; // user curent
  List<String> favoriteIds = []; // lista de id-uri favorite
  bool isLoading = true; // loader pentru date

  StreamSubscription<DocumentSnapshot>?
  userSub; // subscriptie la documentul userului

  // controllere pentru galeria de imagini
  Map<String, ScrollController> galleryControllers = {};

  @override
  void initState() {
    super.initState();
    loadFavorites(); // incarca cele favorite la pornire
  }

  @override
  void dispose() {
    userSub?.cancel(); // opreste subscriptia daca exista
    super.dispose();
  }

  /// incarca proprietatile favoritele userului
  Future<void> loadFavorites() async {
    user = FirebaseAuth.instance.currentUser; // userul curent
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    //verifica/asculta modificarile pe documentul userului
    userSub = usersRef
        .doc(user!.uid)
        .snapshots()
        .listen(
          (docSnap) {
            if (!mounted) return;
            final data = docSnap.data() as Map<String, dynamic>? ?? {};
            final favList = data['favourites'] as List<dynamic>? ?? [];
            favoriteIds = favList.map((e) => e.toString()).toList();
            setState(() {
              isLoading = false;
            });
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
          },
        );
  }

  /// galeria de imagini
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

  /// lista de chips in functie de categorie in interiorul card-ului
  List<Widget> buildChips(Map<String, dynamic> data) {
    switch (data['category'] as String? ?? '') {
      case 'Garsoniera':
        final garsoniera =
            data['garsonieraDetails'] as Map<String, dynamic>? ?? {};
        return [
          const Chip(
            label: Text('1 camera'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${garsoniera['area'] ?? ''} mp'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('Etaj ${garsoniera['floor'] ?? ''}'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${garsoniera['yearBuilt'] ?? ''}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Apartament':
        final apartament =
            data['apartmentDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text('${apartament['rooms']} camere'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${apartament['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('Etaj ${apartament['floor']}'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${apartament['yearBuilt']}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Casa':
        final casa = data['houseDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text('${casa['rooms']} camere'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${casa['area']} mp utili'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${casa['landArea']} mp teren'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${casa['floors']} etaje'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${casa['yearBuilt']}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Teren':
        final teren = data['landDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text(teren['classification'] ?? ''),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('${teren['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      case 'Spatiu comercial':
        final spatiuComercial =
            data['commercialDetails'] as Map<String, dynamic>? ?? {};
        return [
          Chip(
            label: Text('${spatiuComercial['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // daca starea e loading
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // user nu e logat, widget gol
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    // widget/form
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
      ),
      body:
          favoriteIds.isEmpty
              // daca nu exista favorite
              ? const Center(child: Text('Nu ai adaugat proprietati favorite'))
              // daca exista favorite
              // lista de proprietati favorite
              : StreamBuilder<QuerySnapshot>(
                stream:
                    propertiesRef
                        .where(FieldPath.documentId, whereIn: favoriteIds)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    final err = snap.error;
                    if (err is FirebaseException &&
                        err.code == 'permission-denied') {
                      return const Center(
                        child: Text('Nu s-au putut incarca favoritele'),
                      );
                    }
                    return Center(child: Text('Eroare: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Nu ai adaugat proprietati favorite'),
                    );
                  }
                  // lista de carduri pentru fiecare proprietate favorita
                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children:
                              // initializare si extragere date din documente pentru afisare
                              docs.map((doc) {
                                final data =
                                    doc.data()! as Map<String, dynamic>;
                                data['id'] = doc.id;
                                final id = data['id'] as String;
                                final images = List<String>.from(
                                  data['images'] as List? ?? [],
                                );
                                final loc =
                                    data['location'] as Map<String, dynamic>? ??
                                    {};
                                galleryControllers.putIfAbsent(
                                  id,
                                  () => ScrollController(),
                                );
                                final fullAddress = [
                                  loc['street'] ?? '',
                                  loc['number'] ?? '',
                                  if ((loc['sector'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    'Sector ${loc['sector']}',
                                  loc['city'] ?? '',
                                  loc['county'] ?? '',
                                ].where((s) => s.trim().isNotEmpty).join(', ');

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
                                      // imagine si buton unfavorite
                                      Stack(
                                        children: [
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
                                          // buton unfavorite (inima)
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
                                                  final propId =
                                                      data['id'] as String;
                                                  try {
                                                    await usersRef
                                                        .doc(currentUser.uid)
                                                        .update({
                                                          'favourites':
                                                              FieldValue.arrayRemove(
                                                                [propId],
                                                              ),
                                                        });
                                                  } catch (e) {
                                                    await usersRef
                                                        .doc(currentUser.uid)
                                                        .set(
                                                          {'favourites': []},
                                                          SetOptions(
                                                            merge: true,
                                                          ),
                                                        );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),

                                          // chip tip tranzactie
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

                                      // detaliile din card
                                      ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(
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
                                          // adresa
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
                                                  child: SelectableText(
                                                    fullAddress,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 15),
                                          // chips detalii
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: buildChips(data),
                                          ),
                                          // descriere
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
                                          // galerie mica imagini
                                          if (images.length > 1) ...[
                                            const SizedBox(height: 20),
                                            SizedBox(
                                              height: 120,
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.arrow_back_ios,
                                                    ),
                                                    onPressed:
                                                        () => galleryControllers[id]!.animateTo(
                                                          (galleryControllers[id]!
                                                                      .offset -
                                                                  100)
                                                              .clamp(
                                                                0.0,
                                                                galleryControllers[id]!
                                                                    .position
                                                                    .maxScrollExtent,
                                                              ),
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                        ),
                                                  ),
                                                  Expanded(
                                                    child: ListView.separated(
                                                      controller:
                                                          galleryControllers[id],
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount: images.length,
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
                                                                width: 120,
                                                                height: 80,
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
                                                                          Colors
                                                                              .grey
                                                                              .shade300,
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
                                                    onPressed:
                                                        () => galleryControllers[id]!.animateTo(
                                                          (galleryControllers[id]!
                                                                      .offset +
                                                                  100)
                                                              .clamp(
                                                                0.0,
                                                                galleryControllers[id]!
                                                                    .position
                                                                    .maxScrollExtent,
                                                              ),
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 20),
                                          // harta
                                          buildMapSection(fullAddress),
                                          const SizedBox(height: 20),
                                          // detalii agent
                                          FutureBuilder<DocumentSnapshot>(
                                            future:
                                                FirebaseFirestore.instance
                                                    .collection('agents')
                                                    .doc(
                                                      data['agentId'] as String,
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
                                              final email =
                                                  snapAgent.hasData
                                                      ? (snapAgent.data!['email']
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
                                                          ? (name[0] + name[1])
                                                              .toUpperCase()
                                                          : 'A',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
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
                                                        const SizedBox(
                                                          height: 5,
                                                        ),
                                                        SelectableText(email),
                                                        SelectableText(phone),
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
