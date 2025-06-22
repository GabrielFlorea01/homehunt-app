import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/pages/add_agent.dart';

class EditAgentsPage extends StatefulWidget {
  const EditAgentsPage({super.key});

  @override
  EditAgentsPageState createState() => EditAgentsPageState();
}

class EditAgentsPageState extends State<EditAgentsPage> {
  final agentsColl = FirebaseFirestore.instance.collection('agents');

  void openAddAgent() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddAgentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          if (isWide) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Row(
                children: [
                  Expanded(flex: 7, child: buildFormPane()),
                  Expanded(flex: 5, child: buildImagePane()),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildImagePane(height: 300),
                  buildFormPane(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildFormPane() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                      'Editeaza Agenti',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(onPressed: openAddAgent, child: const Text('Adauga')),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                color: Colors.white,
                child: StreamBuilder<QuerySnapshot>(
                  stream: agentsColl.orderBy('createdAt').snapshots(),
                  builder: (ctx, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Eroare: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Nu exista agenti.'));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data()! as Map<String, dynamic>;

                        return Card(
                          key: ValueKey(doc.id),
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  initialValue: data['name'] ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Nume',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  onChanged: (val) => doc.reference.update({'name': val}),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: data['email'] ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (val) => doc.reference.update({'email': val}),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: data['phone'] ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Telefon',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  onChanged: (val) => doc.reference.update({'phone': val}),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('Sterge', style: TextStyle(color: Colors.red)),
                                    onPressed: () async {
                                      final propSnap = await FirebaseFirestore.instance
                                          .collection('properties')
                                          .where('agentId', isEqualTo: doc.id)
                                          .limit(1)
                                          .get();

                                      if (!mounted) return;

                                      if (propSnap.docs.isNotEmpty) {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Acest agent are cel putin un anunt asociat'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(),
                                                child: const Text('OK'),
                                              )
                                            ],
                                          ),
                                        );
                                        return;
                                      }

                                      await doc.reference.delete();
                                    },
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
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImagePane({double? height}) {
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