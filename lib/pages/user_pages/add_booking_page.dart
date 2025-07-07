import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';

/// Pagina pentru adaugarea unei programari de vizionare
class AddBookingPage extends StatefulWidget {
  final String agentId;
  final String propertyId;

  const AddBookingPage({
    super.key,
    required this.agentId,
    required this.propertyId,
  });

  @override
  State<AddBookingPage> createState() => AddBookingPageState();
}

class AddBookingPageState extends State<AddBookingPage> {
  DateTime? selectedDate; // Data selectata
  TimeOfDay? selectedTime; // Ora selectata
  bool isSaving = false; // Flag pentru indicatorul de salvare
  String? errorMessage; // Mesaj de eroare
  String? successMessage; // Mesaj de succes

  /// Afiseaza picker pentru alegerea datei (nu permite trecutul)
  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // nu permite trecutul
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  /// Afiseaza picker pentru alegerea orei
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  /// Verifica daca exista deja o programare pentru aceeasi proprietate si utilizator
  Future<void> checkExistingBooking() async {
    // Combina data+ora si verificare trecut
    if (selectedDate == null || selectedTime == null) {
      setState(() => errorMessage = 'Alege mai intai data si ora');
      return;
    }
    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    if (dateTime.isBefore(DateTime.now())) {
      setState(() => errorMessage = 'Nu poti programa in trecut.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => errorMessage = 'Trebuie sa fii autentificat.');
      return;
    }

    final snap =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .where('properties', isEqualTo: widget.propertyId)
            .get();

    if (snap.docs.isNotEmpty) {
      setState(
        () =>
            errorMessage =
                'Exista deja o programare pentru aceasta proprietate.',
      );
    } else {
      saveBooking(dateTime);
    }
  }

  /// Salveaza programarea in Firestore
  Future<void> saveBooking(DateTime dateTime) async {
    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('bookings').add({
        'agentId': widget.agentId,
        'properties': widget.propertyId,
        'userId': user.uid,
        'date': Timestamp.fromDate(dateTime),
      });
      setState(() => successMessage = 'Vizionare programata cu succes!');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => errorMessage = 'Eroare la salvarea vizionarii.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      // Fara AppBar global
      body: LayoutBuilder(
        builder:
            (ctx, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child:
                      isWide
                          ? Row(
                            children: [buildFormContainer(), buildImagePane()],
                          )
                          : Column(
                            children: [buildImagePane(), buildFormContainer()],
                          ),
                ),
              ),
            ),
      ),
    );
  }

  /// Containerul formularului (jumatatea stanga/dreapta)
  Widget buildFormContainer() {
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sageata inapoi + titlu in container
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Programeaza o vizionare',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Banner eroare
              if (errorMessage != null) ...[
                ErrorBanner(
                  message: errorMessage!,
                  onDismiss: () => setState(() => errorMessage = null),
                ),
                const SizedBox(height: 16),
              ],

              // Banner succes
              if (successMessage != null) ...[
                ErrorBanner(
                  message: successMessage!,
                  messageType: MessageType.success,
                  onDismiss: () => setState(() => successMessage = null),
                ),
                const SizedBox(height: 16),
              ],

              // Buton Alege data
              ElevatedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  selectedDate == null
                      ? 'Alege data'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buton Alege ora
              ElevatedButton.icon(
                onPressed: pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  selectedTime == null
                      ? 'Alege ora'
                      : selectedTime!.format(context),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buton Programeaza
              FilledButton(
                onPressed: isSaving ? null : checkExistingBooking,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child:
                    isSaving
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Programeaza'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Containerul cu imagine (jumatatea opusa formularului)
  Widget buildImagePane() {
    return Expanded(
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
