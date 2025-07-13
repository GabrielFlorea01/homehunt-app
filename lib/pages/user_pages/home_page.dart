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
  User? user; // userul curent
  bool isLoading = true; // stare pentru indicator de incarcare
  String? errorMessage; // mesaj de eroare daca exista

  // filtrele de sus pentru anunturi

  // tipul tranzactiei (vanzare/inchiriere) - default = 'Toate'
  String transactionType = 'Toate';
  // tipul proprietatii - default = 'Tip de proprietate'
  String propertyFilter = 'Tip de proprietate';
  String? roomFilter; // numarul de camere
  String? locationFilter; // localitatea
  double? minPrice; // pretul minim
  double? maxPrice; // pretul maxim
  String? titleFilter; // titlul anuntului
  // sortarea anunturilor - default = 'Cele mai noi'
  String selectedSort = 'Cele mai noi';

  // toate anunturile din baza de date
  List<Map<String, dynamic>> allListings = [];
  // anunturile filtrate in functie de criterii
  List<Map<String, dynamic>> filteredListings = [];
  // lista de favorite a userului
  List<String> favourites = [];
  // afiseaza/ascunde telefonul agentului pentru fiecare anunt
  Map<String, bool> showPhone = {};
  // controllere pentru galeria de imagini a fiecarui anunt
  Map<String, ScrollController> galleryControllers = {};

  // stream pentru ascultare modificari pentru proprietati si user
  StreamSubscription<QuerySnapshot>? snapshotProperties;
  StreamSubscription<DocumentSnapshot>? snapshotUserDoc;

  // referinte la colectiile din baza de date
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'users',
  );

  @override
  void initState() {
    super.initState();
    loadUserAndProperties(); // incarca userul curent si proprietatile din baza la initializare
  }

  // se elibereaza stream-urile la eliminarea widget-ului din arbore
  @override
  void dispose() {
    snapshotProperties?.cancel();
    snapshotUserDoc?.cancel();
    super.dispose();
  }

  // incarca userul curent si proprietatile din baza
  Future<void> loadUserAndProperties() async {
    setState(() => isLoading = true);

    // userul curent
    user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    // toate proprietatile pentru filtrare
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
            setState(() => errorMessage = 'Eroare la incarcarea anunturilor');
          },
        );

    // listener pe documentul userului pentru favorite
    snapshotUserDoc = usersRef.doc(user!.uid).snapshots().listen((docSnap) {
      if (!mounted) return;
      final data = docSnap.data() as Map<String, dynamic>? ?? {};
      final favList = data['favourites'] as List<dynamic>? ?? [];
      favourites = favList.map((e) => e.toString()).toList();
      setState(() {});
    });
    setState(() => isLoading = false);
  }

  // adauga sau scoate din favorite in firestore
  Future<void> toggleFavorite(String propertyId) async {
    if (user == null) return;

    final property = allListings.firstWhere(
      (p) => p['id'] == propertyId,
      orElse: () => {},
    );

    // daca proprietatea este vanduta nu se poate adauga la favorite
    if (property['type'] == 'Vandut') {
      setState(() {
        errorMessage = 'Nu poti adauga la favorite un anunt vandut';
      });
      return;
    }

    final userDoc = usersRef.doc(user!.uid);

    try {
      if (favourites.contains(propertyId)) {
        // daca exista deja scoatem
        await userDoc.update({
          'favourites': FieldValue.arrayRemove([propertyId]),
        });
        favourites.remove(propertyId);
      } else {
        // else adaugam
        await userDoc.update({
          'favourites': FieldValue.arrayUnion([propertyId]),
        });
        favourites.add(propertyId);
      }
      if (mounted) setState(() {});
    } catch (e) {
      // daca nu exista campul favourites il cream
      try {
        await userDoc.set({
          'favourites': [propertyId],
        }, SetOptions(merge: true));
        favourites = [propertyId];
        if (mounted) setState(() {});
      } catch (_) {
        if (mounted) {
          setState(() => errorMessage = 'Eroare la actualizarea favorite');
        }
      }
    }
  }

  // logout user
  Future<void> signOut() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // se apeleaza metoda de sign-out din AuthService
      await AuthService().signOut();
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (e) {
      setState(() => errorMessage = 'Eroare la sign-out');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // aplica filtrele pe lista de anunturi
  void applyFilters() {
    filteredListings =
        allListings.where((data) {
          // tranzactie
          if (transactionType != 'Toate' && data['type'] != transactionType) {
            return false;
          }
          // tip proprietate
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
          // filtrul pentru titlu
          final title = (data['title'] as String? ?? '').toLowerCase();
          if (titleFilter?.isNotEmpty == true &&
              !title.contains(titleFilter!.toLowerCase())) {
            return false;
          }
          // filtrul pentru camere
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
          //filtrul pentru locatie
          if (locationFilter?.isNotEmpty == true) {
            final loc = (data['location'] as Map?) ?? {};
            // se constuieste adresa formatata pentru filtrare
            // se verifica daca adresa contine textul din filtru
            final fullAddress =
                [
                  loc['street'] ?? '',
                  loc['number'] ?? '',
                  if ((loc['sector'] ?? '').toString().isNotEmpty)
                    'Sector ${loc['sector']}',
                  loc['city'] ?? '',
                  loc['county'] ?? '',
                ].where((s) => s.trim().isNotEmpty).join(', ').toLowerCase();
            if (!fullAddress.contains(locationFilter!.toLowerCase())) {
              return false;
            }
          }
          // filtru pentru pret
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

  // afiseaza/ascunde telefonul agentului
  void togglePhone(String id) {
    showPhone[id] = !(showPhone[id] ?? false);
    setState(() {});
  }

  // da dismiss la mesajul de eroare
  void clearError() => setState(() => errorMessage = null);

  // navigare catre pagina de adaugare a unui anunt nou
  void addListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewListingPage()),
    );
  }

  // navigare catre pagina de profil a userului
  void profilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  // casuta de dialog pentru confirmare logout
  void confirmSignOut() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Te deconectezi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nu'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await signOut();
                },
                child: const Text('Sigur'),
              ),
            ],
          ),
    );
  }

  // deschide galeria de imagini la apasare
  void openGallery(BuildContext ctx, List<String> imgs, int idx) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: GalleryView(images: imgs, initialIndex: idx),
            ),
      ),
    );
  }

  // lista de chips cu detalii in functie de tipul proprietatii
  List<Widget> buildChips(Map<String, dynamic> data) {
    // se verifica tipul proprietatii si se returneaza chips in functie de tip
    switch (data['category'] as String? ?? '') {
      // Apartament chips
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
      // Garsoniera chips
      case 'Garsoniera':
        final gars = (data['garsonieraDetails'] as Map?) ?? {};
        return [
          Chip(label: Text('1 camera'), visualDensity: VisualDensity.compact),
          Chip(
            label: Text('${gars['area']} mp'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('Etaj ${gars['floor']}'),
            visualDensity: VisualDensity.compact,
          ),
          Chip(
            label: Text('An ${gars['yearBuilt']}'),
            visualDensity: VisualDensity.compact,
          ),
        ];
      // Casa chips
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
      // Teren chips
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
      // Spatiu comercial chips
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

  // UI-ul paginii principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // app bar cu logo si butoane catre profil si adaugare anunt
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
                onPressed: profilePage,
                icon: const Icon(Icons.person, color: Colors.white, size: 20),
                label: const Text(
                  'Profil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      // Meniul lateral cu optiuni de filtrare si navigare catre alte pagini + adaugare anunt
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
                        //se extrage prima litera din email pentru avatar
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      // marketplace, favorite, anunturile mele, vizionari
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
                      // butoane pentru filtrare rapida
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
              // buton pentru adaugare anunt nou
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
              // buton deconectare
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

      // Body-ul paginii: filtrele si lista de anunturi
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  children: [
                    // filtrele de sus
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

                    // rezultate returnate  si sortare
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

                    // lista de anunturi
                    Expanded(
                      child:
                          filteredListings.isEmpty
                              ? const Center(child: Text('Nu exista anunturi'))
                              : SingleChildScrollView(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 600,
                                    ),
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

                                            // adresa completa pentru afisare se concateneaza
                                            final loc =
                                                (data['location'] as Map?) ??
                                                {};
                                            final fullAddressess = [
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
                                                    // cardul cu imaginea, detalii si butoane
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
                                                        // butonul de favorite
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
                                                                favourites
                                                                        .contains(
                                                                          id,
                                                                        )
                                                                    ? Icons
                                                                        .favorite
                                                                    : Icons
                                                                        .favorite_border,
                                                                color:
                                                                    favourites
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

                                                    // detalii si ExpansionTile
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
                                                        if (fullAddressess
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
                                                                  fullAddressess,
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
                                                          fullAddressess,
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
                                                                  'eroare detalii agent',
                                                                );
                                                              }
                                                              if (!snapAgent
                                                                      .hasData ||
                                                                  !snapAgent
                                                                      .data!
                                                                      .exists) {
                                                                // agentul a fost sters sau nu exista
                                                                return const Text(
                                                                  'agent inexistent',
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
                                                              final email =
                                                                  agentDoc.get(
                                                                        'email',
                                                                      )
                                                                      as String;
                                                              // returneaza detalii agent + buton telefon + vizionare
                                                              return Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .stretch,
                                                                children: [
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
                                                                            Text(
                                                                              email,
                                                                            ),
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
                                                                        'programeaza o vizionare',
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
                                                          // daca nu avem user logat, afisam doar nume agent si buton
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
                                                                    'programeaza o vizionare',
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

  // dropdown custom pentru filtre
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

  // textfield custom pentru filtre
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
