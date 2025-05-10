import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Listings')),
        body: const Center(
          child: Text('You must be logged in to see your listings.'),
        ),
      );
    }

    return Scaffold(
        appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
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
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No properties yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data()! as Map<String, dynamic>;
                    final images = List<String>.from(data['images'] ?? []);
                    final title = data['title'] as String? ?? '';
                    final price = data['price'] as int? ?? 0;
                    final location = data['location'] as Map<String, dynamic>?;

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
                            if (location != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${location['city']}, ${location['county']}',
                                    style: const TextStyle(fontSize: 14),
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
                                data['description'],
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
                                  itemBuilder: (context, idx) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        images[idx],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
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
}