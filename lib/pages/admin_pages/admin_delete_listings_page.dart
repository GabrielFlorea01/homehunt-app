import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDeleteListingsPage extends StatefulWidget {
  const AdminDeleteListingsPage({super.key});

  @override
  State<AdminDeleteListingsPage> createState() =>
      AdminDeleteListingsPageState();
}

class AdminDeleteListingsPageState extends State<AdminDeleteListingsPage> {
  // referinta la colectia de proprietati din Firestore
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');

  String searchQuery = ''; // textul cautat in campul de cautare
  final TextEditingController searchController =
      TextEditingController(); // controller pentru campul de cautare

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> deletePropertyAndRemoveFromAgents(String propertyId) async {
    final agentsRef = FirebaseFirestore.instance.collection('agents');
    // toti agentii care au aceasta proprietate in lista lor
    final agentsWithProperty =
        await agentsRef.where('properties', arrayContains: propertyId).get();
    // se extrage id-ul proprietatii din lista fiecarui agent gasit
    for (final agent in agentsWithProperty.docs) {
      final List<dynamic> properties = agent['properties'] ?? [];
      properties.remove(propertyId);
      await agent.reference.update({'properties': properties});
    }
    // Sterge proprietatea din colectia de proprietati
    await propertiesRef.doc(propertyId).delete();
  }

  // widget pentru afisarea si cautarea anunturilor
  Widget buildListingsContainer() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // buton de inapoi si titlu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sterge anunturi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            // camp de cautare dupa titlu
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cauta dupa titlu',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) {
                setState(() {
                  searchQuery = v.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            // lista cu anunturile filtrate - stream Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    propertiesRef
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Eroare la gasirea anunturilor ${snap.error}',
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs =
                      snap.data!.docs.where((doc) {
                        final title =
                            (doc['title'] as String? ?? '').toLowerCase();
                        return title.contains(searchQuery);
                      }).toList();
                  if (docs.isEmpty) {
                    return const Center(child: Text('Niciun anunt gasit'));
                  }
                  // fiecare anunt intr-un card cu imagine sugestiva si buton de stergere
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final doc = docs[i];
                      final data = doc.data()! as Map<String, dynamic>;
                      final images = List<String>.from(
                        data['images'] as List? ?? [],
                      );
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // titlul anuntului
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] as String? ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // imagine si buton de stergere
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          images.isNotEmpty
                                              ? Image.network(
                                                images.first,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => Container(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                              )
                                              : Container(
                                                color: Colors.grey.shade300,
                                              ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Material(
                                        color: Colors.black45,
                                        shape: const CircleBorder(),
                                        child: IconButton(
                                          iconSize: 20,
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () async {
                                            // dialog pentru confirmare stergere anunt
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Confirma stergerea',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Anuleaza',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
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
                                              // sterge proprietatea si din lista agentilor asociati
                                              await deletePropertyAndRemoveFromAgents(
                                                doc.id,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // verific daca ecranul e suficient de lat
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          if (isWide) {
            // pe ecrane mari afiseaza lista si imaginea una langa alta
            return Row(
              children: [
                Expanded(child: buildListingsContainer()),
                Expanded(child: buildImageSide()),
              ],
            );
          } else {
            // pe ecrane mici imaginea sus si lista jos
            return SingleChildScrollView(
              child: Column(
                children: [
                  buildImageSide(height: 300),
                  buildListingsContainer(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Widget pentru afisarea imaginii de fundal
  Widget buildImageSide({double? height}) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/images/homehuntlogin.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
