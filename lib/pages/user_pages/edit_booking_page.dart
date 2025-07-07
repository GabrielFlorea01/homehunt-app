import 'package:homehunt/models/error_widgets/error_banner.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditBookingPage extends StatefulWidget {
  final String bookingId;
  final DateTime initialDateTime;
  final String propertyName;

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
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    // Initializam cu datele primite
    selectedDate = widget.initialDateTime;
    selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  /// Afiseaza picker pentru data noua
  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  /// Afiseaza picker pentru ora noua
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  /// Salveaza modificarile in Firestore
  Future<void> saveEdit() async {
    // Combinam data+ora
    final dt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    // Nu permitem trecutul
    if (dt.isBefore(DateTime.now())) {
      setState(() => errorMessage = 'Nu poti programa in trecut.');
      return;
    }
    setState(() {
      isSaving = true;
      errorMessage = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'date': Timestamp.fromDate(dt)});
      setState(() => successMessage = 'Programare actualizata cu succes!');
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => errorMessage = 'Eroare la actualizare.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              // Rand cu sageata si titlul + numele proprietatii
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
                        'Editeaza programare',
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

              // Buton data
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

              // Buton ora
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

              // Buton salvare
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
                        : const Text('Salveaza'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
