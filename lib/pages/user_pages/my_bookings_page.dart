import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/pages/user_pages/edit_booking_page.dart';
import 'package:intl/intl.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';

/// Pagina pentru vizualizarea si editarea programarilor
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => MyBookingsPageState();
}

class MyBookingsPageState extends State<MyBookingsPage> {
  User? user;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Preluam user-ul curent de la FirebaseAuth
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'Eroare la stergerea vizionarii');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    // Daca user-ul nu este logat, afisam un mesaj simplu
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vizionarile mele')),
        body: const Center(child: Text('Trebuie sa fii autentificat.')),
      );
    }

    // Layout 50/50 pe ecrane late, Column pe ecrane inguste
    return Scaffold(
      body:
          isWide
              ? Row(children: [buildListPane(), buildImagePane()])
              : Column(children: [buildImagePane(), buildListPane()]),
    );
  }

  /// Pane-ul cu lista de programari si butonul de inapoi interior
  Widget buildListPane() {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          // Stil container alb cu colturi rotunjite
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rand cu sageata de intoarcere si titlu
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Vizionarile mele',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (errorMessage != null) ...[
                ErrorBanner(
                  message: errorMessage!,
                  messageType: MessageType.error,
                  onDismiss: () => setState(() => errorMessage = null),
                ),
                const SizedBox(height: 16),
              ],

              // Flux de date din Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('bookings')
                          .where('userId', isEqualTo: user!.uid)
                          .orderBy('date')
                          .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      // Afisam eroarea
                      return Center(child: Text('Eroare: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      // Indicator de incarcare
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snap.data!.docs;
                    if (docs.isEmpty) {
                      // Nu exista programari
                      return const Center(
                        child: Text('Nu ai vizionari inregistrate'),
                      );
                    }

                    // ListView pentru fiecare booking
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final data = docs[i].data()! as Map<String, dynamic>;
                        final bookingId = docs[i].id;
                        final ts = data['date'] as Timestamp;
                        final dt = ts.toDate();
                        final formatted = DateFormat(
                          'dd/MM/yyyy – HH:mm',
                        ).format(dt);

                        // Preluam ID-ul proprietatii
                        final propertyId = data['properties'] as String;

                        // FutureBuilder pentru a lua numele proprietatii
                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .get(),
                          builder: (context, propSnap) {
                            String propertyName = 'Proprietate';
                            if (propSnap.hasData && propSnap.data!.exists) {
                              final propData =
                                  propSnap.data!.data() as Map<String, dynamic>;
                              propertyName = propData['title'] ?? propertyName;
                            }

                            // ListTile care afiseaza data, numele proprietatii si buton edit
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tileColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              title: Text(
                                formatted,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(propertyName),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blueAccent,
                                    onPressed: () {
                                      // Navigam la pagina de editare, trimitand si numele proprietatii
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => EditBookingPage(
                                                bookingId: bookingId,
                                                initialDateTime: dt,
                                                propertyName: propertyName,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.redAccent,
                                    onPressed: () => deleteBooking(bookingId),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pane-ul cu imaginea decorativa
  Widget buildImagePane() {
    return Expanded(
      flex: 1,
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
}