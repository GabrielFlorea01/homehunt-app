import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const _kGoogleMapsApiKey = 'AIzaSyA_61celkZcyTPfToDzE7u4KkhxLtq3xIo';

Future<LatLng?> geocodeAddress(String address) async {
  final query = '$address, Romania';
  final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
    'address': query,
    'key': _kGoogleMapsApiKey,
  });

  final response = await http.get(url);
  if (response.statusCode != 200) return null;

  final body = json.decode(response.body) as Map<String, dynamic>;
  if (body['status'] != 'OK' || (body['results'] as List).isEmpty) {
    return null;
  }

  final loc =
      (body['results'][0]['geometry']['location'] as Map<String, dynamic>);
  return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
}


class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});
  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Image.asset(
                'lib/images/logo.png',
                width: 220,
                height: 220,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  propertiesRef
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
                  return const Center(child: Text('Nu ai adaugat inca niciun anunt'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()! as Map<String, dynamic>;
                    final images = List<String>.from(data['images'] ?? []);
                    final title = data['title'] as String? ?? '';
                    final price = data['price'] as int? ?? 0;
                    final loc = data['location'] as Map<String, dynamic>?;

                    // Build la adresa full
                    String fullAddress = '';
                    if (loc != null) {
                      final parts = <String>[
                        loc['street'] ?? '',
                        loc['number'] ?? '',
                        if ((loc['sector'] ?? '').toString().isNotEmpty)
                          'Sector ${loc['sector']}',
                        loc['city'] ?? '',
                        loc['county'] ?? '',
                      ];
                      fullAddress = parts
                          .where((s) => s.trim().isNotEmpty)
                          .join(', ');
                    }

                    List<Widget> buildChips() {
                      switch (data['category'] as String? ?? '') {
                        case 'Apartament':
                          final apt =
                              data['apartmentDetails']
                                  as Map<String, dynamic>? ??
                              {};
                          return [
                            Chip(label: Text('${apt['rooms']} camere')),
                            Chip(label: Text('${apt['area']} mp')),
                            Chip(label: Text('Etaj ${apt['floor']}')),
                            Chip(label: Text('${apt['yearBuilt']}')),
                          ];
                        case 'Casa':
                          final house =
                              data['houseDetails'] as Map<String, dynamic>? ??
                              {};
                          return [
                            Chip(label: Text('${house['rooms']} camere')),
                            Chip(label: Text('${house['area']} mp utili')),
                            Chip(label: Text('${house['landArea']} mp teren')),
                            Chip(label: Text('${house['floors']} etaje')),
                            Chip(label: Text('${house['yearBuilt']}')),
                          ];
                        case 'Teren':
                          final land =
                              data['landDetails'] as Map<String, dynamic>? ??
                              {};
                          return [
                            Chip(label: Text(land['type'] ?? '')),
                            Chip(label: Text(land['classification'] ?? '')),
                            Chip(label: Text('${land['area']} mp')),
                          ];
                        case 'Spatiu comercial':
                          final com =
                              data['commercialDetails']
                                  as Map<String, dynamic>? ??
                              {};
                          return [
                            Chip(label: Text(com['type'] ?? '')),
                            Chip(label: Text('${com['area']} mp')),
                          ];
                        default:
                          return [];
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTileTheme(
                        minLeadingWidth: 0,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: SizedBox(
                            width: 80,
                            height: 80,
                            child:
                                images.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        images.first,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.photo,
                                        size: 40,
                                        color: Colors.white54,
                                      ),
                                    ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('€ $price'),
                          childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                            if ((data['description'] as String?)?.isNotEmpty ??
                                false) ...[
                              Text(
                                data['description']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (images.length > 1) ...[
                              SizedBox(
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(width: 8),
                                  itemBuilder:
                                      (_, idx) => ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          images[idx],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMapSection(String address) {
    return FutureBuilder<LatLng?>(
      future: geocodeAddress(address),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            'Eroare harta: ${snap.error}',
            style: const TextStyle(color: Colors.red),
          );
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
