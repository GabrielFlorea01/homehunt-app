import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:homehunt/pages/admin_pages/admin_add_agent_page.dart';

class AdminAgentsPage extends StatefulWidget {
  const AdminAgentsPage({super.key});

  @override
  AdminAgentsPageState createState() => AdminAgentsPageState();
}

class AdminAgentsPageState extends State<AdminAgentsPage> {
  // referinta la colectia agents din Firestore
  final agents = FirebaseFirestore.instance.collection('agents');

  // functie pentru deschiderea paginii de adaugare agent
  void openAddAgent() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminAddAgentPage()));
  }

  @override
  Widget build(BuildContext context) {
    // daca ecranul e suficient de lat
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          // pe ecrane mari formularul si imaginea
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
            // pe ecrane mici doar imaginea si formularul una sub alta
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [buildImagePane(height: 300), buildFormPane()],
              ),
            );
          }
        },
      ),
    );
  }

  // partea de formular pentru editarea agentilor
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
            // buton de inapoi, titlu si buton de adaugare agent
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: openAddAgent,
                  child: const Text('Adauga'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // lista agentilor din Firestore
            Expanded(
              child: Container(
                color: Colors.white,
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      agents.orderBy('createdAt', descending: true).snapshots(),
                  builder: (ctx, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Eroare la incarcarea agentilor: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Nu exista agenti'));
                    }
                    // afiseaza fiecare agent intr-un card editabil
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // camp editabil pentru nume
                                TextFormField(
                                  initialValue: data['name'] ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Nume',
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  onChanged:
                                      (val) =>
                                          doc.reference.update({'name': val}),
                                ),
                                const SizedBox(height: 12),
                                // camp editabil pentru email
                                TextFormField(
                                  initialValue: data['email'] ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged:
                                      (val) =>
                                          doc.reference.update({'email': val}),
                                ),
                                const SizedBox(height: 12),
                                // camp editabil pentru telefon (doar cifre)
                                TextFormField(
                                  initialValue: data['phone'] ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Telefon',
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  keyboardType: TextInputType.number,
                                  onChanged:
                                      (val) =>
                                          doc.reference.update({'phone': val}),
                                ),
                                const SizedBox(height: 12),
                                // buton pentru stergerea agentului
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'Sterge',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () async {
                                      // verifica daca agentul are proprietati asociate
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (ctx) => AlertDialog(
                                              title: const Text(
                                                'Sigur vrei sa stergi acest agent?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        ctx,
                                                      ).pop(false),
                                                  child: const Text('Nu'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        ctx,
                                                      ).pop(true),
                                                  child: const Text('Da'),
                                                ),
                                              ],
                                            ),
                                      );
                                      if (confirm != true) return;
                                      final propSnap =
                                          await FirebaseFirestore.instance
                                              .collection('properties')
                                              .where(
                                                'agentId',
                                                isEqualTo: doc.id,
                                              )
                                              .limit(1)
                                              .get();
                                      if (!mounted) return;
                                      if (propSnap.docs.isNotEmpty) {
                                        // daca are proprietati, afiseaza dialog de avertizare
                                        showDialog(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: const Text(
                                                  'Acest agent are cel putin un anunt asociat',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                        );
                                        return;
                                      }
                                      // daca nu are proprietati, sterge agentul
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

  // pane pentru afisare imagine in dreapta sau sus
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
