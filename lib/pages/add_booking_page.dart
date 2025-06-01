import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isSaving = false;
  String? errorMessage;

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> saveBooking() async {
    if (selectedDate == null || selectedTime == null) {
      setState(() {
        errorMessage = 'Te rog alege data si ora vizionarii';
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        errorMessage =
            'Trebuie sa fii autentificat pentru a programa o vizionare.';
      });
      return;
    }

    // Combinam data si ora intr-un singur DateTime
    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'agentId': widget.agentId,
        'properties': widget.propertyId,
        'userId': user.uid,
        'date': Timestamp.fromDate(dateTime),
        'feedback': 'pending',
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      
    } catch (e) {
      setState(() {
        errorMessage = 'A aparut o eroare la salvarea vizionarii.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programeaza o vizionare'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Afisam eventuale mesaje de eroare
            if (errorMessage != null) ...[
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],

            // 1) Buton de alegere data
            ElevatedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate == null
                    ? 'Alege data'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // 2) Buton de alegere ora
            ElevatedButton.icon(
              onPressed: pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedTime == null
                    ? 'Alege ora'
                    : selectedTime!.format(context),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            const Spacer(),

            // 3) Buton "Programeaza"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child:
                    isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Programeaza',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
