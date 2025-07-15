import 'package:homehunt/models/error_widgets/error_banner.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditBookingPage extends StatefulWidget {
  final String bookingId; // id programare
  final DateTime initialDateTime; // data si ora initiala
  final String propertyName; // numele proprietatii

  const EditBookingPage({
    super.key,
    required this.bookingId,
    required this.initialDateTime,
    required this.propertyName,
  });

  @override
  State<EditBookingPage> createState() => EditBookingPageState();
}

class EditBookingPageState extends State<EditBookingPage> {
  late DateTime selectedDate; // data selectata
  late TimeOfDay selectedTime; // ora selectata
  // flag pentru a arata indicatorul de loading la salvare
  bool isSaving = false;
  String? errorMessage; // mesaj de eroare daca apare o problema
  String? successMessage; // mesaj de succes dupa salvare

  @override
  void initState() {
    super.initState();
    // initializare data si ora din widget
    selectedDate = widget.initialDateTime;
    selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  //date picker pentru alegerea unei date noi
  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: now, // nu se poate selecta o data din trecut
      lastDate: DateTime(now.year + 1), // maxim un an in viitor
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // time picker pentru alegerea unei ore noi
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  //se salveaza modificarile
  Future<void> saveEdit() async {
    final dateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    // data si ora curenta, fara secunde/milisecunde
    final now = DateTime.now();
    final nowTrimmed = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    if (dateTime.isBefore(nowTrimmed)) {
      setState(() => errorMessage = 'Nu te poti programa in trecut');
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });
    try {
      // se actualizeaza documentul
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'date': Timestamp.fromDate(dateTime)});
      setState(() => successMessage = 'Programare actualizata cu succes!');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => errorMessage = 'Eroare la actualizare');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            padding: const EdgeInsets.all(32),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editeaza programarea',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.propertyName,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // mesaj de eroare
                if (errorMessage != null) ...[
                  ErrorBanner(
                    message: errorMessage!,
                    onDismiss: () => setState(() => errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                ],
                // mesaj de succes
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
                  label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                  label: Text(selectedTime.format(context)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // buton pentru salvare
                FilledButton(
                  onPressed: isSaving ? null : saveEdit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Salveaza programarea'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
