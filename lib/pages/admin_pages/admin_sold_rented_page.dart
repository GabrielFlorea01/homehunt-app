import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSoldRentedPage extends StatefulWidget {
  const AdminSoldRentedPage({Key? key}) : super(key: key);

  @override
  AdminSoldRentedPageState createState() => AdminSoldRentedPageState();
}

class AdminSoldRentedPageState extends State<AdminSoldRentedPage> {
  final propertiesRef = FirebaseFirestore.instance.collection('properties');
  String searchQuery = '';
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> toggleSold(String id, String currentType) async {
    final newType = currentType == 'De vanzare'
        ? 'Vandut'
        : currentType == 'De inchiriat'
            ? 'Inchiriat'
            : currentType;
    await propertiesRef.doc(id).update({'type': newType});
  }

  Widget buildListingsContainer() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cauta dupa titlu',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() {
                searchQuery = v.toLowerCase();
              }),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: propertiesRef
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Eroare: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs
                      .where((doc) {
                        final title = (doc['title'] as String? ?? '')
                            .toLowerCase();
                        return title.contains(searchQuery);
                      })
                      .toList();
                  if (docs.isEmpty) {
                    return const Center(child: Text('Niciun anunt gasit'));
                  }
                  return ListView.builder(
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
                              // text pe stanga
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
                              // preview imagine
                              if (images.isNotEmpty) ...[
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              ElevatedButton(
                                onPressed: () =>
                                    toggleSold(doc.id, type),
                                child: const Text('Aplica'),
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

  Widget buildImageSide() {
    return Expanded(
      flex: 2,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/homehuntlogin.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: isWide
          ? Row(
              children: [
                buildListingsContainer(),
                buildImageSide(),
              ],
            )
          : Column(
              children: [
                buildImageSide(),
                Expanded(child: buildListingsContainer()),
              ],
            ),
    );
  }
}
