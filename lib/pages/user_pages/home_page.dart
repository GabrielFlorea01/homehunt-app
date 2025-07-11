import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';
import 'package:homehunt/models/gallery/gallery_model.dart';
import 'package:homehunt/models/map/map_model.dart';
import 'package:homehunt/pages/user_pages/add_booking_page.dart';
import 'package:homehunt/pages/user_pages/favourites_page.dart';
import 'package:homehunt/pages/user_pages/my_bookings_page.dart';
import 'package:homehunt/pages/auth_pages/auth/auth_service.dart';
import 'package:homehunt/pages/user_pages/new_listing_page.dart';
import 'package:homehunt/pages/user_pages/profile_page.dart';
import 'package:homehunt/pages/user_pages/my_listings_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  StreamSubscription<QuerySnapshot>? snapshotProperties;
  StreamSubscription<DocumentSnapshot>? snapshotUserDoc;

  User? user;
  bool isLoading = true;
  String? errorMessage;

  // Filters
  String transactionType = 'Toate';
  String propertyFilter = 'Tip de proprietate';
  String? roomFilter;
  String? locationFilter;
  double? minPrice;
  double? maxPrice;
  String? titleFilter;
  String selectedSort = 'Cele mai noi';

  // Data
  List<Map<String, dynamic>> allListings = [];
  List<Map<String, dynamic>> filteredListings = [];
  List<String> favoriteIds = []; // lista de favorites a user-ului
  Map<String, bool> showPhone = {};
  Map<String, ScrollController> galleryControllers = {};

  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  @override
  void initState() {
    super.initState();
    loadUserAndProperties();
  }

  @override
  void dispose() {
    snapshotProperties?.cancel();
    snapshotUserDoc?.cancel();
    super.dispose();
  }

  Future<void> loadUserAndProperties() async {
    setState(() => isLoading = true);

    // 1) user-ul curent
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // daca user e null, nu afisam nimic
      setState(() => isLoading = false);
      return;
    }

    // 2)  proprietatile (lista completa, pentru filtrare)
    snapshotProperties = propertiesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            allListings =
                snap.docs.map((d) {
                  final m = Map<String, dynamic>.from(d.data() as Map);
                  m['id'] = d.id;
                  return m;
                }).toList();
            applyFilters();
          },
          onError: (e) {
            if (!mounted) return;
            setState(() => errorMessage = 'Eroare la incărcarea anunyurilor');
          },
        );

    // 3) ascultăm documentul user-ului pentru a prelua array-ul de favoriteIds
    snapshotUserDoc = usersRef.doc(user!.uid).snapshots().listen((docSnap) {
      if (!mounted) return;
      final data = docSnap.data() as Map<String, dynamic>? ?? {};
      final favList = data['favoriteIds'] as List<dynamic>? ?? [];
      favoriteIds = favList.map((e) => e.toString()).toList();
      // nu afectează lista allListings, dar va forța rebuild pentru a actualiza iconițele inimioară
      setState(() {});
    });

    // 4) terminăm loading
    setState(() => isLoading = false);
  }

  /// Toggle între adăugare/scoatere din favorites în Firestore
  Future<void> toggleFavorite(String propertyId) async {
    if (user == null) return;

    final property = allListings.firstWhere(
      (p) => p['id'] == propertyId,
      orElse: () => {},
    );

    if(property['type'] == 'Vandut') {
      setState(() {
        errorMessage = 'Nu poti adauga la favorite un anunt vandut';
      });
      return;
    }

    final userDoc = usersRef.doc(user!.uid);

    try {
      if (favoriteIds.contains(propertyId)) {
        // daca exista deja, scoatem:
        await userDoc.update({
          'favoriteIds': FieldValue.arrayRemove([propertyId]),
        });
        // actualizăm local:
        favoriteIds.remove(propertyId);
      } else {
        // altfel adăugăm:
        await userDoc.update({
          'favoriteIds': FieldValue.arrayUnion([propertyId]),
        });
        favoriteIds.add(propertyId);
      }
      if (mounted) setState(() {});
    } catch (e) {
      // dacă nu există câmpul favoriteIds, putem crea
      try {
        await userDoc.set({
          'favoriteIds': [propertyId],
        }, SetOptions(merge: true));
        favoriteIds = [propertyId];
        if (mounted) setState(() {});
      } catch (_) {
        // eroare generică
        if (mounted) {
          setState(() => errorMessage = 'Eroare la actualizarea favorite');
        }
      }
    }
  }

  Future<void> signOut() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().signOut();
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (e) {
      setState(() => errorMessage = 'Eroare la sign-out');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    filteredListings =
        allListings.where((data) {
          // transaction
          if (transactionType != 'Toate' && data['type'] != transactionType) {
            return false;
          }
          // category mapping
          if (propertyFilter != 'Tip de proprietate') {
            final mapFilter =
                {
                  'Apartamente': 'Apartament',
                  'Garsoniere': 'Garsoniera',
                  'Case': 'Casa',
                  'Teren': 'Teren',
                  'Spatii comerciale': 'Spatiu comercial',
                }[propertyFilter]!;
            if (data['category'] != mapFilter) {
              return false;
            }
          }
          //titlu
          final title = (data['title'] as String? ?? '').toLowerCase();
          if (titleFilter?.isNotEmpty == true &&
              !title.contains(titleFilter!.toLowerCase())) {
            return false;
          }
          // rooms
          if (roomFilter?.isNotEmpty == true) {
            final cat = data['category'] as String? ?? '';
            String actualRooms;

            if (cat == 'Garsoniera') {
              actualRooms = '1';
            } else if (cat == 'Apartament') {
              actualRooms =
                  ((data['apartmentDetails'] as Map?)?['rooms'] ?? '')
                      .toString();
            } else if (cat == 'Casa') {
              actualRooms =
                  ((data['houseDetails'] as Map?)?['rooms'] ?? '').toString();
            } else {
              actualRooms = '';
            }

            if (actualRooms != roomFilter) {
              return false;
            }
          }
          // location substring
          if (locationFilter?.isNotEmpty == true) {
            final loc = (data['location'] as Map?) ?? {};
            final fullAddr =
                [
                  loc['street'] ?? '',
                  loc['number'] ?? '',
                  if ((loc['sector'] ?? '').toString().isNotEmpty)
                    'Sector ${loc['sector']}',
                  loc['city'] ?? '',
                  loc['county'] ?? '',
                ].where((s) => s.trim().isNotEmpty).join(', ').toLowerCase();
            if (!fullAddr.contains(locationFilter!.toLowerCase())) {
              return false;
            }
          }
          // price
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          if (minPrice != null && price < minPrice!) {
            return false;
          }
          if (maxPrice != null && price > maxPrice!) {
            return false;
          }
          return true;
        }).toList();
    setState(() {});
  }

  void togglePhone(String id) {
    showPhone[id] = !(showPhone[id] ?? false);
    setState(() {});
  }

  void clearError() => setState(() => errorMessage = null);

  void addListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewListingPage()),
    );
  }

  void myProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void confirmSignOut() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sigur te deconectezi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await signOut();
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

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

  List<Widget> buildChips(Map<String, dynamic> data) {
    switch (data['category'] as String? ?? '') {
      case 'Apartament':
        final apt = (data['apartmentDetails'] as Map?) ?? {};
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
      case 'Garsoniera':
        final g = (data['garsonieraDetails'] as Map?) ?? {};
        return [
          Chip(label: Text('1 cameră'), visualDensity: VisualDensity.compact),
          Chip(
            label: Text('${g['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('Etaj ${g['floor']}'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${g['yearBuilt']}'),
            visualDensity: VisualDensity.compact,
          ),
        ];

      case 'Casa':
        final c = (data['houseDetails'] as Map?) ?? {};
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
        final t = (data['landDetails'] as Map?) ?? {};
        return [
          Chip(
            label: Text(t['type'] ?? ''),
            visualDensity: VisualDensity.compact,
          ),
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
        final sc = (data['commercialDetails'] as Map?) ?? {};
        return [
          Chip(
            label: Text(sc['type'] ?? ''),
            visualDensity: VisualDensity.compact,
          ),
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Image.asset('lib/images/logo.png', height: 80),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 17),
                ),
                onPressed: addListing,
                icon: const Icon(
                  Icons.add_box_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Anunt',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15, right: 16),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  alignment: Alignment.center,
                  textStyle: const TextStyle(fontSize: 17),
                ),
                onPressed: myProfilePage,
                icon: const Icon(Icons.person, color: Colors.white, size: 20),
                label: const Text(
                  'Contul meu',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),

      // Drawer
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 30),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Marketplace'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite),
                        title: const Text('Favorite'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FavoritesPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.list_rounded),
                        title: const Text('Anunturile mele'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyListingsPage(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: const Text('Vizionari'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyBookingsPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      // quick filters
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De vanzare';
                            propertyFilter = 'Apartamente';
                            applyFilters();
                          },
                          child: const Text('Apartamente de vanzare'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De inchiriat';
                            propertyFilter = 'Apartamente';
                            applyFilters();
                          },
                          child: const Text('Apartamente de inchiriat'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De vanzare';
                            propertyFilter = 'Case';
                            applyFilters();
                          },
                          child: const Text('Case de vanzare'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De inchiriat';
                            propertyFilter = 'Case';
                            applyFilters();
                          },
                          child: const Text('Case de inchiriat'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De vanzare';
                            propertyFilter = 'Garsoniere';
                            applyFilters();
                          },
                          child: const Text('Garsoniere de vanzare'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De inchiriat';
                            propertyFilter = 'Garsoniere';
                            applyFilters();
                          },
                          child: const Text('Garsoniere de inchiriat'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De vanzare';
                            propertyFilter = 'Teren';
                            applyFilters();
                          },
                          child: const Text('Terenuri de vanzare'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De inchiriat';
                            propertyFilter = 'Spatii comerciale';
                            applyFilters();
                          },
                          child: const Text('Spatii comerciale de inchiriat'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            transactionType = 'De vanzare';
                            propertyFilter = 'Spatii comerciale';
                            applyFilters();
                          },
                          child: const Text('Spatii comerciale de vanzare'),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: addListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Adauga anunt nou',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton(
                  onPressed: confirmSignOut,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Deconectare'),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // Body: filtre + listings
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  children: [
                    // Top filters
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          if (errorMessage != null) ...[
                            ErrorBanner(
                              message: errorMessage!,
                              onDismiss: clearError,
                            ),
                            const SizedBox(height: 8),
                          ],
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                buildTextField(
                                  hint: 'Titlu',
                                  width: 150,
                                  height: 51,
                                  onChanged: (v) {
                                    titleFilter = v;
                                    applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildDropdown(
                                  value: transactionType,
                                  items: const [
                                    'Toate',
                                    'De vanzare',
                                    'De inchiriat',
                                  ],
                                  onChanged: (v) {
                                    transactionType = v!;
                                    applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildTextField(
                                  hint: 'Localitate',
                                  width: 150,
                                  height: 51,
                                  onChanged: (v) {
                                    locationFilter = v;
                                    applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildDropdown(
                                  value: propertyFilter,
                                  items: const [
                                    'Tip de proprietate',
                                    'Apartamente',
                                    'Garsoniere',
                                    'Case',
                                    'Teren',
                                    'Spatii comerciale',
                                  ],
                                  onChanged: (v) {
                                    propertyFilter = v!;
                                    applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildTextField(
                                  hint: 'Camere',
                                  width: 150,
                                  height: 51,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (v) {
                                    roomFilter = v.isEmpty ? null : v;
                                    applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),
                                buildDropdown(
                                  value: 'Pret',
                                  items: const [
                                    'Pret',
                                    '< 50.000',
                                    '50.000 - 100.000',
                                    '100.000 - 200.000',
                                    '> 200.000',
                                  ],
                                  onChanged: (v) {
                                    if (v == '< 50.000') {
                                      minPrice = 0;
                                      maxPrice = 50000;
                                    } else if (v == '50.000 - 100.000') {
                                      minPrice = 50000;
                                      maxPrice = 100000;
                                    } else if (v == '100.000 - 200.000') {
                                      minPrice = 100000;
                                      maxPrice = 200000;
                                    } else if (v == '> 200.000') {
                                      minPrice = 200000;
                                      maxPrice = null;
                                    } else {
                                      minPrice = maxPrice = null;
                                    }
                                    applyFilters();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Results count & sort
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'S-au gasit ${filteredListings.length} rezultate',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: selectedSort,
                            items:
                                const ['Cele mai noi', 'Pret ↑', 'Pret ↓']
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (t) {
                              if (t == null) return;
                              setState(() {
                                selectedSort = t;
                                if (selectedSort == 'Pret ↑') {
                                  filteredListings.sort(
                                    (a, b) => (a['price'] as num).compareTo(
                                      b['price'] as num,
                                    ),
                                  );
                                } else if (selectedSort == 'Pret ↓') {
                                  filteredListings.sort(
                                    (a, b) => (b['price'] as num).compareTo(
                                      a['price'] as num,
                                    ),
                                  );
                                } else {
                                  filteredListings.sort(
                                    (a, b) => (b['createdAt'] as Timestamp)
                                        .compareTo(a['createdAt'] as Timestamp),
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Listings
                    Expanded(
                      child:
                          filteredListings.isEmpty
                              ? const Center(child: Text('Nu exista anunturi'))
                              : SingleChildScrollView(
                                child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 600),
                                    child: Column(
                                      children:
                                          filteredListings.map((data) {
                                            final id = data['id'] as String;
                                            final agentId =
                                                data['agentId'] as String;
                                            galleryControllers.putIfAbsent(
                                              id,
                                              () => ScrollController(),
                                            );

                                            // build full address
                                            final loc =
                                                (data['location'] as Map?) ??
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
                                                .where(
                                                  (s) => s.trim().isNotEmpty,
                                                )
                                                .join(', ');

                                            final images = List<String>.from(
                                              data['images'] as List? ?? [],
                                            );

                                            return ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 700,
                                              ),
                                              child: Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Image + favorite + tag
                                                    Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              const BorderRadius.vertical(
                                                                top:
                                                                    Radius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                          child: AspectRatio(
                                                            aspectRatio: 16 / 9,
                                                            child:
                                                                images.isNotEmpty
                                                                    ? Image.network(
                                                                      images
                                                                          .first,
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
                                                                    )
                                                                    : Container(
                                                                      color:
                                                                          Colors
                                                                              .grey
                                                                              .shade300,
                                                                    ),
                                                          ),
                                                        ),
                                                        // Butonul de Favorite (inima)
                                                        Positioned(
                                                          top: 8,
                                                          right: 8,
                                                          child: Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                ),
                                                            child: IconButton(
                                                              icon: Icon(
                                                                favoriteIds
                                                                        .contains(
                                                                          id,
                                                                        )
                                                                    ? Icons
                                                                        .favorite
                                                                    : Icons
                                                                        .favorite_border,
                                                                color:
                                                                    favoriteIds
                                                                            .contains(
                                                                              id,
                                                                            )
                                                                        ? Colors
                                                                            .red
                                                                        : Colors
                                                                            .grey,
                                                              ),
                                                              onPressed:
                                                                  () =>
                                                                      toggleFavorite(
                                                                        id,
                                                                      ),
                                                            ),
                                                          ),
                                                        ),
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
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              data['type']
                                                                      as String? ??
                                                                  '',
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Details & ExpansionTile
                                                    ExpansionTile(
                                                      tilePadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      title: Text(
                                                        data['title']
                                                                as String? ??
                                                            '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                                        if (fullAddress
                                                            .isNotEmpty) ...[
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .location_on,
                                                                size: 16,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  fullAddress,
                                                                  style:
                                                                      const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        const SizedBox(
                                                          height: 15,
                                                        ),
                                                        Wrap(
                                                          spacing: 8,
                                                          runSpacing: 4,
                                                          children: buildChips(
                                                            data,
                                                          ),
                                                        ),
                                                        if ((data['description']
                                                                    as String?)
                                                                ?.isNotEmpty ??
                                                            false) ...[
                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          Text(
                                                            data['description']
                                                                as String,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                        ],
                                                        if (images
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          SizedBox(
                                                            height: 150,
                                                            child: Row(
                                                              children: [
                                                                IconButton(
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .arrow_back_ios,
                                                                  ),
                                                                  onPressed:
                                                                      () => galleryControllers[id]!.animateTo(
                                                                        galleryControllers[id]!.offset -
                                                                            100,
                                                                        duration: const Duration(
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
                                                                    itemCount:
                                                                        images
                                                                            .length,
                                                                    separatorBuilder:
                                                                        (
                                                                          _,
                                                                          __,
                                                                        ) => const SizedBox(
                                                                          width:
                                                                              8,
                                                                        ),
                                                                    itemBuilder:
                                                                        (
                                                                          _,
                                                                          idx,
                                                                        ) => GestureDetector(
                                                                          onTap:
                                                                              () => openGallery(
                                                                                context,
                                                                                images,
                                                                                idx,
                                                                              ),
                                                                          child: ClipRRect(
                                                                            borderRadius: BorderRadius.circular(
                                                                              6,
                                                                            ),
                                                                            child: Image.network(
                                                                              images[idx],
                                                                              width:
                                                                                  100,
                                                                              height:
                                                                                  100,
                                                                              fit:
                                                                                  BoxFit.cover,
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
                                                                    Icons
                                                                        .arrow_forward_ios,
                                                                  ),
                                                                  onPressed:
                                                                      () => galleryControllers[id]!.animateTo(
                                                                        galleryControllers[id]!.offset +
                                                                            100,
                                                                        duration: const Duration(
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
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        buildMapSection(
                                                          fullAddress,
                                                        ),
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        // agentii din card
                                                        if (user != null) ...[
                                                          FutureBuilder<
                                                            DocumentSnapshot
                                                          >(
                                                            future:
                                                                FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'agents',
                                                                    )
                                                                    .doc(
                                                                      data['agentId']
                                                                          as String,
                                                                    )
                                                                    .get(),
                                                            builder: (
                                                              ctx,
                                                              snapAgent,
                                                            ) {
                                                              if (snapAgent
                                                                  .hasError) {
                                                                return const Text(
                                                                  'Eroare detalii agent',
                                                                );
                                                              }
                                                              if (!snapAgent
                                                                      .hasData ||
                                                                  !snapAgent
                                                                      .data!
                                                                      .exists) {
                                                                // agentul a fost sters sau nu exista
                                                                return const Text(
                                                                  'Agent inexistent',
                                                                );
                                                              }
                                                              final agentDoc =
                                                                  snapAgent
                                                                      .data!;
                                                              final name =
                                                                  agentDoc.get(
                                                                        'name',
                                                                      )
                                                                      as String;
                                                              final phone =
                                                                  agentDoc.get(
                                                                        'phone',
                                                                      )
                                                                      as String;
                                                              final email = agentDoc.get('email') as String;
                                                              // Înlocuim return-ul simplu cu un Column
                                                              return Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .stretch,
                                                                children: [
                                                                  // —–––––––––––– Rândul cu avatar, nume și buton telefon ––––––––––––
                                                                  Row(
                                                                    children: [
                                                                      CircleAvatar(
                                                                        radius:
                                                                            20,
                                                                        backgroundColor:
                                                                            Theme.of(
                                                                              context,
                                                                            ).colorScheme.primary,
                                                                        child: Text(
                                                                          name.isNotEmpty
                                                                              ? name[0].toUpperCase()
                                                                              : 'A',
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      Expanded(
                                                                        child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              name,
                                                                              style: const TextStyle(
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                            Text(email),
                                                                            if (showPhone[id] ??
                                                                                false) ...[
                                                                              const SizedBox(
                                                                                height:
                                                                                    4,
                                                                              ),
                                                                              Text(
                                                                                phone,
                                                                                style: const TextStyle(
                                                                                  color:
                                                                                      Colors.grey,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(
                                                                          Icons
                                                                              .phone,
                                                                        ),
                                                                        color:
                                                                            Theme.of(
                                                                              context,
                                                                            ).colorScheme.primary,
                                                                        onPressed:
                                                                            () => togglePhone(
                                                                              id,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),

                                                                  const SizedBox(
                                                                    height: 7,
                                                                  ),

                                                                  // —–––––––––––– Textul „sau” centrat ––––––––––––
                                                                  const Center(
                                                                    child: Text(
                                                                      'sau',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontStyle:
                                                                            FontStyle.italic,
                                                                        color:
                                                                            Colors.grey,
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  const SizedBox(
                                                                    height: 12,
                                                                  ),

                                                                  // —–––––––––––– Butonul „Programează o vizionare” ––––––––––––
                                                                  Center(
                                                                    child: ElevatedButton(
                                                                      onPressed: () {
                                                                        Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder:
                                                                                (_) => AddBookingPage(
                                                                                  agentId:
                                                                                      agentId,
                                                                                  propertyId:
                                                                                      id,
                                                                                ),
                                                                          ),
                                                                        );
                                                                      },
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Theme.of(
                                                                              context,
                                                                            ).colorScheme.primary,
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              24,
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                        shape: RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                8,
                                                                              ),
                                                                        ),
                                                                      ),
                                                                      child: const Text(
                                                                        'Programeaza o vizionare',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),
                                                        ] else ...[
                                                          // Dacă nu avem user logat, afișăm tot „nume agent + sau + buton”
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              Text(
                                                                data['agentName']
                                                                        as String? ??
                                                                    '',
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 7,
                                                              ),
                                                              //sau text
                                                              const Center(
                                                                child: Text(
                                                                  'sau',
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              ),

                                                              const SizedBox(
                                                                height: 12,
                                                              ),

                                                              Center(
                                                                child: ElevatedButton(
                                                                  onPressed: () {
                                                                    Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (
                                                                              _,
                                                                            ) =>
                                                                                const FavoritesPage(),
                                                                      ),
                                                                    );
                                                                  },
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Theme.of(
                                                                          context,
                                                                        ).colorScheme.primary,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          24,
                                                                      vertical:
                                                                          12,
                                                                    ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  child: const Text(
                                                                    'Programeaza o vizionare',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        items:
            items
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
      ),
    );
  }

  
  Widget buildTextField({
    required String hint,
    required double width,
    required double height,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
