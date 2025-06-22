import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homehunt/firebase/secrets/api_key.dart';
import 'package:homehunt/pages/gallery_view.dart';
import 'package:homehunt/pages/edit_listing_page.dart';
import 'package:http/http.dart' as http;

/// Geocode a plain address into coordinates
Future<LatLng?> geocodeAddress(String address) async {
  final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
    'address': '$address, Romania',
    'key': googleMapsApiKey,
  });
  final resp = await http.get(url);
  if (resp.statusCode != 200) return null;
  final body = json.decode(resp.body) as Map<String, dynamic>;
  if (body['status'] != 'OK' || (body['results'] as List).isEmpty) {
    return null;
  }
  final loc =
      body['results'][0]['geometry']['location'] as Map<String, dynamic>;
  return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
}

class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});
  @override
  State<MyListingsPage> createState() => MyListingsPageState();
}

class MyListingsPageState extends State<MyListingsPage> {
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');

  // A ScrollController for each card's horizontal gallery
  final Map<int, ScrollController> scrollControllers = {};

  // Track which cards have phone expanded
  final Map<String, bool> showPhone = {};

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

  Widget buildMapSection(String address) {
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
        if (loc == null) return const Text('Cannot display map');
        return SizedBox(
          height: 200,
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
          stream:
              propertiesRef
                  .where(
                    'userId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
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
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Column(
                      children:
                          docs.asMap().entries.map((entry) {
                            final i = entry.key;
                            final doc = entry.value;
                            scrollControllers[i] ??= ScrollController();

                            final data = doc.data()! as Map<String, dynamic>;
                            data['id'] = doc.id;
                            final images = List<String>.from(
                              data['images'] as List? ?? [],
                            );
                            final loc =
                                data['location'] as Map<String, dynamic>? ?? {};
                            final fullAddress = [
                              loc['street'] ?? '',
                              loc['number'] ?? '',
                              if ((loc['sector'] ?? '').toString().isNotEmpty)
                                'Sector ${loc['sector']}',
                              loc['city'] ?? '',
                              loc['county'] ?? '',
                            ].where((s) => s.trim().isNotEmpty).join(', ');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                                        (_, __, ___) =>
                                                            Container(
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade300,
                                                            ),
                                                  )
                                                  : Container(
                                                    color: Colors.grey.shade300,
                                                  ),
                                        ),
                                      ),
                                      // EDIT & DELETE buttons
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Row(
                                          children: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white70,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Colors.black87,
                                              ),
                                              label: const Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => EditListingPage(
                                                          listingId:
                                                              data['id']
                                                                  as String,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 4),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white70,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                              ),
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: Colors.redAccent,
                                              ),
                                              label: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                              onPressed: () async {
                                                final ok = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (ctx) => AlertDialog(
                                                        title: const Text(
                                                          'Confirma stergerea',
                                                        ),
                                                        content: const Text(
                                                          'Sigur vrei sa stergi acest anunt?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      false,
                                                                    ),
                                                            child: const Text(
                                                              'Anuleaza',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      true,
                                                                    ),
                                                            child: const Text(
                                                              'Sterge',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (ok == true) {
                                                  await propertiesRef
                                                      .doc(data['id'] as String)
                                                      .delete();
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ---- DETALII & EXPANSIONTILE ----
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
                                      '€ ${(data['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                    ),
                                    childrenPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    children: [
                                      if (fullAddress.isNotEmpty)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
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
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: buildChips(data),
                                      ),
                                      if ((data['description'] as String?)
                                              ?.isNotEmpty ??
                                          false) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          data['description'] as String,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                      if (images.length > 1) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 100,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_back_ios,
                                                ),
                                                onPressed: () {
                                                  final c =
                                                      scrollControllers[i]!;
                                                  final newOffset =
                                                      (c.offset - 100).clamp(
                                                        0.0,
                                                        c
                                                            .position
                                                            .maxScrollExtent,
                                                      );
                                                  c.animateTo(
                                                    newOffset,
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                                },
                                              ),
                                              Expanded(
                                                child: ListView.separated(
                                                  controller:
                                                      scrollControllers[i]!,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: images.length,
                                                  separatorBuilder:
                                                      (_, __) => const SizedBox(
                                                        width: 8,
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
                                                            width: 100,
                                                            height: 100,
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
                                                  final c =
                                                      scrollControllers[i]!;
                                                  final newOffset =
                                                      (c.offset + 100).clamp(
                                                        0.0,
                                                        c.position.maxScrollExtent,
                                                      );
                                                  c.animateTo(
                                                    newOffset,
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      buildMapSection(fullAddress),
                                      const SizedBox(height: 8),

                                      // Agent row cu toggle telefon
                                      FutureBuilder<DocumentSnapshot>(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('agents')
                                                .doc(data['agentId'] as String)
                                                .get(),
                                        builder: (ctx, snapAgent) {
                                          final name =
                                              data['agentName'] as String? ??
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
                                                      ? name[0].toUpperCase()
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
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (showPhone[data['id']] ??
                                                        false) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        phone,
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.phone),
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                onPressed:
                                                    () => togglePhone(
                                                      data['id'] as String,
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
            );
          },
        ),
      ),
    );
  }
}
