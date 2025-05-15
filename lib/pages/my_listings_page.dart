import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// Cheia API pentru Google Maps
const _kGoogleMapsApiKey = 'AIzaSyA_61celkZcyTPfToDzE7u4KkhxLtq3xIo';

// Functie pentru a converti o adresa in coordonate geografice
Future<LatLng?> geocodeAddress(String address) async {
  // Adauga "Romania" la query pentru rezultate mai bune
  final query = '$address, Romania';
  final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
    'address': query,
    'key': _kGoogleMapsApiKey,
  });

  // Trimite cererea HTTP catre API-ul Google Maps
  final response = await http.get(url);
  if (response.statusCode != 200) return null;

  // Parseaza raspunsul JSON
  final body = json.decode(response.body) as Map<String, dynamic>;
  if (body['status'] != 'OK' || (body['results'] as List).isEmpty) {
    return null;
  }

  // Extrage coordonatele din raspuns
  final loc = (body['results'][0]['geometry']['location'] as Map<String, dynamic>);
  return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
}

// Pagina principala pentru anunturile utilizatorului
class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});
  @override
  State<MyListingsPage> createState() => MyListingsPageState();
}

// Starea pentru pagina de anunturi
class MyListingsPageState extends State<MyListingsPage> {
  // Utilizatorul curent autentificat
  final User? currentUser = FirebaseAuth.instance.currentUser;
  // Referinta la colectia de proprietati din Firestore
  final CollectionReference propertiesRef = FirebaseFirestore.instance.collection('properties');

  // Controller-e pentru scroll-urile orizontale cu imagini
  final Map<int, ScrollController> _scrollControllers = {};

  // Eliberam resursele la inchiderea paginii
  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Deschide galeria de imagini in fullscreen
  void _openGallery(BuildContext context, List<String> images, int initialIndex) {
    // Verificam daca lista de imagini contine elemente valide
    final validImages = images.where((url) => url.trim().isNotEmpty).toList();
    
    if (validImages.isEmpty) {
      // Afisam un mesaj daca nu exista imagini valide
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu exista imagini disponibile')),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text('${initialIndex + 1}/${validImages.length}', style: const TextStyle(color: Colors.white)),
            ),
            body: GalleryView(
              images: validImages,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          // Dezactivam butonul de revenire implicit
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: SizedBox(
              height: 80,
              child: Image.asset(
                'lib/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: StreamBuilder<QuerySnapshot>(
          // Obtinem proprietatile utilizatorului curent, ordonate dupa data crearii
          stream: propertiesRef
              .where('userId', isEqualTo: currentUser!.uid)
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
              return const Text('Nu ai adaugat inca niciun anunt');
            }

            // Folosim SingleChildScrollView pentru a face toata pagina scrollabila
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: List.generate(docs.length, (i) {
                      _scrollControllers[i] ??= ScrollController();

                      final data = docs[i].data()! as Map<String, dynamic>;
                      final images = List<String>.from(data['images'] ?? []);
                      final title = data['title'] as String? ?? '';
                      final price = data['price'] as int? ?? 0;
                      final loc = data['location'] as Map<String, dynamic>?;

                      // Construim adresa completa din componentele disponibile
                      String fullAddress = '';
                      if (loc != null) {
                        final parts = <String>[
                          loc['street'] ?? '',
                          loc['number'] ?? '',
                          if ((loc['sector'] ?? '').toString().isNotEmpty) 'Sector ${loc['sector']}',
                          loc['city'] ?? '',
                          loc['county'] ?? '',
                        ];
                        fullAddress = parts.where((s) => s.trim().isNotEmpty).join(', ');
                      }

                      // Construim chipurile pentru detaliile specifice fiecarui tip de proprietate
                      List<Widget> buildChips() {
                        switch (data['category'] as String? ?? '') {
                          case 'Apartament':
                            final apt = data['apartmentDetails'] as Map<String, dynamic>? ?? {};
                            return [
                              Chip(label: Text('${apt['rooms']} camere')),
                              Chip(label: Text('${apt['area']} mp')),
                              Chip(label: Text('Etaj ${apt['floor']}')),
                              Chip(label: Text('An constructie ${apt['yearBuilt']}')),
                            ];
                          case 'Casa':
                            final house = data['houseDetails'] as Map<String, dynamic>? ?? {};
                            return [
                              Chip(label: Text('${house['rooms']} camere')),
                              Chip(label: Text('${house['area']} mp utili')),
                              Chip(label: Text('${house['landArea']} mp teren')),
                              Chip(label: Text('${house['floors']} etaje')),
                              Chip(label: Text('${house['yearBuilt']}')),
                            ];
                          case 'Teren':
                            final land = data['landDetails'] as Map<String, dynamic>? ?? {};
                            return [
                              Chip(label: Text(land['type'] ?? '')),
                              Chip(label: Text(land['classification'] ?? '')),
                              Chip(label: Text('${land['area']} mp')),
                            ];
                          case 'Spatiu comercial':
                            final com = data['commercialDetails'] as Map<String, dynamic>? ?? {};
                            return [
                              Chip(label: Text(com['type'] ?? '')),
                              Chip(label: Text('${com['area']} mp')),
                            ];
                          default:
                            return [];
                        }
                      }

                      // Construim cardul pentru proprietate
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imaginea principala (preview)
                              if (images.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(images.first),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo,
                                    size: 60,
                                    color: Colors.white54,
                                  ),
                                ),
                              // Detaliile proprietatii
                              ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('€ $price'),
                                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                children: [
                                  if (fullAddress.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            fullAddress,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: buildChips(),
                                  ),
                                  const SizedBox(height: 8),
                                  if ((data['description'] as String?)?.isNotEmpty ?? false) ...[
                                    Text(
                                      data['description']!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (images.length > 1) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text(
                                        'Fotografii',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 110,
                                      child: Row(
                                        children: [
                                          // Buton de derulare la stanga
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back_ios),
                                            onPressed: () {
                                              _scrollControllers[i]?.animateTo(
                                                _scrollControllers[i]!.offset - 120,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          ),
                                          // Lista orizontala de imagini
                                          Expanded(
                                            child: ListView.separated(
                                              controller: _scrollControllers[i],
                                              scrollDirection: Axis.horizontal,
                                              itemCount: images.length,
                                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                                              itemBuilder: (_, idx) => GestureDetector(
                                                onTap: () => _openGallery(context, images, idx),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.network(
                                                    images[idx],
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      // Afisam un placeholder daca imaginea nu se incarca
                                                      return Container(
                                                        width: 100,
                                                        height: 100,
                                                        color: Colors.grey.shade300,
                                                        child: const Icon(Icons.broken_image, color: Colors.white70),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Buton de derulare la dreapta
                                          IconButton(
                                            icon: const Icon(Icons.arrow_forward_ios),
                                            onPressed: () {
                                              _scrollControllers[i]?.animateTo(
                                                _scrollControllers[i]!.offset + 120,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (fullAddress.isNotEmpty) ...[
                                    const SizedBox(height: 30),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        'Se afiseaza o locatie aproximativa. Adresa exacta este in descriere',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    buildMapSection(fullAddress),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }), 
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Construieste sectiunea hartii pentru o adresa data
  Widget buildMapSection(String address) {
    return FutureBuilder<LatLng?>(
      future: geocodeAddress(address),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Eroare harta: ${snap.error}', style: const TextStyle(color: Colors.red));
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final latLng = snap.data;
        if (latLng == null) {
          return const Text('Adresa nu a putut fi afisata pe harta');
        }
        return SizedBox(
          height: 400,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: latLng, zoom: 14),
            markers: {Marker(markerId: MarkerId(address), position: latLng)},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        );
      },
    );
  }
}

// Componenta pentru vizualizarea imaginilor in galerie fullscreen
class GalleryView extends StatefulWidget {
  final List<String> images; // Lista de URL-uri pentru imagini
  final int initialIndex;   // Indexul imaginii initiale de afisat

  const GalleryView({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zona principala cu imaginea curenta
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                clipBehavior: Clip.none,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Afisam un mesaj de eroare daca imaginea nu se incarca
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 64, color: Colors.white70),
                          const SizedBox(height: 16),
                          Text(
                            'Imaginea nu a putut fi incarcata',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        // Bara de navigare inferioara
        Container(
          color: Colors.black,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: _currentIndex < widget.images.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}