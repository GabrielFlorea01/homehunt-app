import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => MyBookingsPageState();
}

class MyBookingsPageState extends State<MyBookingsPage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    // Daca utilizatorul nu este logat, afisam un mesaj
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vizionarile mele'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(
          child: Text('Trebuie sa fii autentificat ca sa vezi vizionarile.'),
        ),
      );
    }

    // Interogare Firestore: unde userId == uid si sortare dupa campul date
    final bookingsQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('date', descending: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizionarile mele'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Nu ai nicio vizionare programata.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final Timestamp ts = data['date'] as Timestamp;
              final dt = ts.toDate();
              final formattedDate = DateFormat('dd/MM/yyyy – HH:mm').format(dt);
              final feedback = data['feedback'] as String? ?? 'pending';

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Feedback: $feedback'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  onPressed: () async {
                    // Stergere booking (optional)
                    final docId = docs[index].id;
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(docId)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
