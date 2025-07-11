import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDeleteListingsPage extends StatefulWidget {
  const AdminDeleteListingsPage({super.key});

  @override
  State<AdminDeleteListingsPage> createState() => AdminDeleteListingsPageState();
}

class AdminDeleteListingsPageState extends State<AdminDeleteListingsPage> {
  final CollectionReference propertiesRef = FirebaseFirestore.instance
      .collection('properties');

  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                        final title =
                            (doc['title'] as String? ?? '').toLowerCase();
                        return title.contains(searchQuery);
                      }).toList();
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
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // imagine + delete pe dreapta
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
                                              await propertiesRef
                                                  .doc(doc.id)
                                                  .delete();
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
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          if (isWide) {
            return Row(
              children: [
                Expanded(child: buildListingsContainer()),
                Expanded(child: buildImageSide()),
              ],
            );
          } else {
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
