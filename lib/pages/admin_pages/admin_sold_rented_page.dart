import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSoldRentedPage extends StatefulWidget {
  const AdminSoldRentedPage({super.key});

  @override
  AdminSoldRentedPageState createState() => AdminSoldRentedPageState();
}

class AdminSoldRentedPageState extends State<AdminSoldRentedPage> {
  // referinta la colectia de proprietati din Firestore
  final propertiesRef = FirebaseFirestore.instance.collection('properties');
  String searchQuery = ''; // textul cautat in campul de cautare
  final searchController = TextEditingController(); // controller pentru cautare

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // se marcheaza proprietatea ca vandut sau inchiriat in functie de tipul curent
  Future<void> toggleSoldRented(String id, String currentType) async {
    final newType =
        currentType == 'De vanzare'
            ? 'Vandut'
            : currentType == 'De inchiriat'
            ? 'Inchiriat'
            : currentType;
    await propertiesRef.doc(id).update({'type': newType});
  }

  // imaginea de fundal
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          if (isWide) {
            // pe ecrane mari afiseaza lista si imaginea in paralel
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
                  buildImageSide(height: 200),
                  buildListingsContainer(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // widget pentru afisarea si cautarea anunturilor
  Widget buildListingsContainer() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Marcheaza anunturile ca vandute/inchiriate',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          // cautare dupa titlu
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
          // lista anunturilor filtrate
          StreamBuilder<QuerySnapshot>(
            stream:
                propertiesRef
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(child: Text('Eroare: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs =
                  snap.data!.docs.where((doc) {
                    final title = (doc['title'] as String? ?? '').toLowerCase();
                    return title.contains(searchQuery);
                  }).toList();
              if (docs.isEmpty) {
                return const Center(child: Text('Niciun anunt gasit'));
              }
              // fiecare anunt in card cu imagine de referinta si buton de marcare
              return SizedBox(
                height: 400, // sau constraints.maxHeight * 0.6, după caz
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final data = doc.data()! as Map<String, dynamic>;
                    final images = List<String>.from(
                      data['images'] as List? ?? [],
                    );
                    final type = data['type'] as String? ?? '';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // titlul si tipul anuntului
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
                                  Text('Tip: $type'),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // imaginea anuntului daca exista
                            if (images.isNotEmpty) ...[
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: Colors.grey.shade300,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            // buton pentru a marca anuntul ca vandut/inchiriat
                            ElevatedButton(
                              onPressed: () => toggleSoldRented(doc.id, type),
                              child: const Text('Aplica'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
