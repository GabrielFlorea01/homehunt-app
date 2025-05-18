import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homehunt/pages/gallery_view.dart';
import 'package:http/http.dart' as http;
import 'package:homehunt/firebase/auth/auth_service.dart';
import 'package:homehunt/pages/login_page.dart';
import 'package:homehunt/pages/new_listing_page.dart';
import 'package:homehunt/pages/profile_page.dart';
import 'package:homehunt/pages/my_listings_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

/// Geocode a plain address into coordinates
Future<LatLng?> geocodeAddress(String address) async {
  final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
    'address': '$address, Romania',
    'key': 'AIzaSyA_61celkZcyTPfToDzE7u4KkhxLtq3xIo',
  });
  final resp = await http.get(url);
  if (resp.statusCode != 200) return null;
  final body = json.decode(resp.body) as Map<String, dynamic>;
  if (body['status'] != 'OK' || (body['results'] as List).isEmpty) return null;
  final loc =
      body['results'][0]['geometry']['location'] as Map<String, dynamic>;
  return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
}

/// Home page with filters and cards identical to MyListingsPage
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final StreamSubscription<QuerySnapshot> snapshot;
  User? user;
  bool isLoading = true;
  String? errorMessage;

  // Filters
  String transactionType = 'De vanzare';
  String propertyFilter = 'Tip de proprietate';
  String? roomFilter;
  String? locationFilter;
  double? minPrice;
  double? maxPrice;

  // Data
  List<Map<String, dynamic>> allListings = [];
  List<Map<String, dynamic>> filteredListings = [];
  List<String> favoriteIds = [];
  Map<String, bool> showPhone = {};
  Map<String, ScrollController> galleryControllers = {};

  @override
  void initState() {
    super.initState();
    loadUser();
    snapshot = FirebaseFirestore.instance
        .collection('properties')
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
  }

  @override
  void dispose() {
    snapshot.cancel();
    super.dispose();
  }

  void loadUser() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void applyFilters() {
    filteredListings =
        allListings.where((data) {
          // transaction
          if (transactionType == 'De vanzare' && data['type'] != 'De vanzare') {
            return false;
          }
          if (transactionType == 'De inchiriat' &&
              data['type'] != 'De inchiriat') {
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
                  'Birouri': 'Birou',
                }[propertyFilter]!;
            if (data['category'] != mapFilter) {
              return false;
            }
          }
          // rooms
          final apt = (data['apartmentDetails'] as Map?) ?? {};
          if (roomFilter != null &&
              roomFilter != 'Tip de proprietate' &&
              apt['rooms'].toString() != roomFilter) {
            return false;
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

  void promptLogin() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Login required'),
            content: const Text('You must be logged in to favorite.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }

  Future<void> signOut() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().signOut();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
            title: const Text('Sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  signOut();
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

  Widget buildMap(String address) {
    return FutureBuilder<LatLng?>(
      future: geocodeAddress(address),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            'Map error: ${snap.error}',
            style: const TextStyle(color: Colors.red),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final loc = snap.data;
        if (loc == null) return const Text('Nu se poate afisa harta');
        return SizedBox(
          height: 400,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: loc, zoom: 14),
            markers: {Marker(markerId: MarkerId(address), position: loc)},
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
        );
      },
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
      // AppBar
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
      // Drawer with full filter list
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
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
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 50),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Marketplace'),
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Favorite'),
                  onTap: () => Navigator.pop(context),
                  //TODO
                ),
                ListTile(
                  leading: const Icon(Icons.view_stream_rounded),
                  title: const Text('Anunturile mele'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyListingsPage()),
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
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: addListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Adauga anunt',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: confirmSignOut,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Deconectare'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),

      // Body: Filters + Listings
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                              buildDropdown(
                                value: transactionType,
                                items: const ['De vanzare', 'De inchiriat'],
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
                                  'Birouri',
                                ],
                                onChanged: (v) {
                                  propertyFilter = v!;
                                  applyFilters();
                                },
                              ),
                              const SizedBox(width: 8),
                              buildDropdown(
                                value: roomFilter ?? 'Nr. camere',
                                items: const [
                                  'Nr. camere',
                                  '1',
                                  '2',
                                  '3',
                                  '4+',
                                ],
                                onChanged: (v) {
                                  roomFilter = v == 'Nr. camere' ? null : v;
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
                          value: 'Cele mai noi',
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
                            if (t == 'Pret ↑') {
                              filteredListings.sort(
                                (a, b) => (a['price'] as num).compareTo(
                                  b['price'] as num,
                                ),
                              );
                            } else if (t == 'Pret ↓') {
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
                            setState(() {});
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
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Column(
                                    children:
                                        filteredListings.map((data) {
                                          final id = data['id'] as String;
                                          galleryControllers.putIfAbsent(
                                            id,
                                            () => ScrollController(),
                                          );

                                          // build full address
                                          final loc =
                                              (data['location'] as Map?) ?? {};
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

                                          final images = List<String>.from(
                                            data['images'] as List? ?? [],
                                          );

                                          return Card(
                                            margin: const EdgeInsets.symmetric(
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
                                                                  images.first,
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
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors.white,
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
                                                                ? Icons.favorite
                                                                : Icons
                                                                    .favorite_border,
                                                            color:
                                                                favoriteIds
                                                                        .contains(
                                                                          id,
                                                                        )
                                                                    ? Colors.red
                                                                    : Colors
                                                                        .grey,
                                                          ),
                                                          onPressed: () {
                                                            // TODO: Implement favorite toggle logic
                                                          },
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
                                                              Theme.of(context)
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
                                                          style:
                                                              const TextStyle(
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
                                                    data['title'] as String? ??
                                                        '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    '€ ${(data['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
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
                                                            Icons.location_on,
                                                            size: 16,
                                                            color: Colors.grey,
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
                                                    const SizedBox(height: 15),
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
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                    if (images.length > 1) ...[
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
                                                                    galleryControllers[id]!
                                                                            .offset -
                                                                        100,
                                                                    duration: const Duration(
                                                                      milliseconds:
                                                                          300,
                                                                    ),
                                                                    curve:
                                                                        Curves
                                                                            .easeInOut,
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
                                                                    (_, __) =>
                                                                        const SizedBox(
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
                                                                        borderRadius:
                                                                            BorderRadius.circular(
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
                                                                    galleryControllers[id]!
                                                                            .offset +
                                                                        100,
                                                                    duration: const Duration(
                                                                      milliseconds:
                                                                          300,
                                                                    ),
                                                                    curve:
                                                                        Curves
                                                                            .easeInOut,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 20),
                                                    buildMap(fullAddress),
                                                    const SizedBox(height: 20),
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
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                              child: Text(
                                                                name.isNotEmpty
                                                                    ? name[0]
                                                                        .toUpperCase()
                                                                    : 'A',
                                                                style: const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    name,
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  if (showPhone[id] ??
                                                                      false) ...[
                                                                    const SizedBox(
                                                                      height: 4,
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
                                                                Icons.phone,
                                                              ),
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                              onPressed:
                                                                  () =>
                                                                      togglePhone(
                                                                        id,
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
                            ),
                  ),
                ],
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
