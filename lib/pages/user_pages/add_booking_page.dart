import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/models/error_widgets/error_banner.dart';

class AddBookingPage extends StatefulWidget {
  final String agentId; // id-ul agentului
  final String propertyId; // id-ul proprietatii

  const AddBookingPage({
    super.key,
    required this.agentId,
    required this.propertyId,
  });

  @override
  State<AddBookingPage> createState() => AddBookingPageState();
}

class AddBookingPageState extends State<AddBookingPage> {
  DateTime? selectedDate; // data selectata
  TimeOfDay? selectedTime; // ora selectata
  // flag pentru a arata indicatorul de loading la salvare
  bool isSaving = false;
  String? errorMessage; // mesaj de eroare
  String? successMessage; // mesaj de succes

  // date picker pentru alegerea datei
  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // nu se poate selecta o data din trecut
      lastDate: DateTime(now.year + 1), // maxim un an in viitor
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // afiseaza un time picker pentru alegerea orei
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0), // ora default
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  // verifica daca exista deja o programare
  Future<void> checkExistingBooking() async {
    if (selectedDate == null || selectedTime == null) {
      setState(() => errorMessage = 'Alege data si ora!');
      return;
    }

    // verific data si ora
    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    if (dateTime.isBefore(DateTime.now())) {
      setState(() => errorMessage = 'Nu poti programa o vizionare in trecut!');
      return;
    }

    // extrage userul curent si daca e autentificat
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => errorMessage = 'User neautentificat');
      return;
    }

    // daca exista deja o programare pentru user si proprietate, afiseaza mesaj de eroare
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
                'Ai deja o vizionare programata pe ${dateTime.toLocal()}!',
      );
    } else {
      saveBooking(dateTime);
    }
  }

  // salvez programarea
  Future<void> saveBooking(DateTime dateTime) async {
    setState(() {
      isSaving = true; // porneste indicatorul de loading
      errorMessage = null; // reseteaza mesajele de eroare
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
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => errorMessage = 'Eroare la salvare');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
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

  // widget/container cu formularul
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
              // afiseaza banner de eroare
              if (errorMessage != null) ...[
                ErrorBanner(
                  message: errorMessage!,
                  onDismiss: () => setState(() => errorMessage = null),
                ),
                const SizedBox(height: 16),
              ],
              // afiseaza banner de succes
              if (successMessage != null) ...[
                ErrorBanner(
                  message: successMessage!,
                  messageType: MessageType.success,
                  onDismiss: () => setState(() => successMessage = null),
                ),
                const SizedBox(height: 16),
              ],
              // buton pentru alegerea datei
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
              // buton pentru alegerea orei
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
              // butonul de programare
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
                        : const Text('Programeaza-te'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // widget cu imaginea
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
