import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Clasa de model pentru proprietati - pentru a fi folosit in tabel
class PropertyModel {
  final String id;
  final String title;
  final String type;
  final double price;
  final DateTime createdAt;

  PropertyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.price,
    required this.createdAt,
  });

  // Constructor din documentul Firestore
  // pentru a crea modelul de proprietate pe baza documentului din db
  // foloseste datele din document pentru a initializa campurile
  factory PropertyModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PropertyModel(
      id: doc.id,
      title: data['title'] as String,
      type: data['type'] as String,
      price: (data['price'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Pagina pentru raportul proprietatilor
class PropertiesReportPage extends StatefulWidget {
  const PropertiesReportPage({super.key});

  @override
  PropertiesReportPageState createState() => PropertiesReportPageState();
}

class PropertiesReportPageState extends State<PropertiesReportPage> {
  DateTime? fromDate;
  DateTime? toDate;
  String filterType = 'Toate';
  List<PropertyModel> properties = [];

  @override
  void initState() {
    super.initState();
    applyFilter();
  }

  Future<void> applyFilter() async {
    Query<Map<String, dynamic>> ref = FirebaseFirestore.instance
        .collection('properties')
        .orderBy('createdAt');
    if (filterType != 'Toate') ref = ref.where('type', isEqualTo: filterType);
    if (fromDate != null) {
      // inceputul zilei
      ref = ref.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(fromDate!.year, fromDate!.month, fromDate!.day, 0, 0, 0),
        ),
      );
    }
    if (toDate != null) {
      // sfarsitul zilei
      ref = ref.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(
          DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59, 999),
        ),
      );
    }
    final snap = await ref.get();
    setState(() {
      properties = snap.docs.map((d) => PropertyModel.fromDoc(d)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Proprietati',
                          style: TextStyle(
                            // butonul de inapoi si titlul paginii
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: filterType,
                          items: const [
                            DropdownMenuItem(
                              value: 'Toate',
                              child: Text('Toate'),
                            ),
                            DropdownMenuItem(
                              value: 'Vandut',
                              child: Text(
                                'Vandut',
                              ), //filtru pentru tipul de proprietate
                            ),
                            DropdownMenuItem(
                              value: 'Inchiriat',
                              child: Text('Inchiriat'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(
                                () => filterType = v,
                              ); // actualizeaza tipul de proprietate
                              applyFilter();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) setState(() => fromDate = d);
                            },
                            child: Text(
                              fromDate ==
                                      null // selectorul pentru data de inceput
                                  ? 'De la'
                                  : DateFormat('dd/MM/yyyy').format(fromDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setState(
                                  () => toDate = d,
                                ); // selectorul pentru data de sfarsit
                              }
                            },
                            child: Text(
                              toDate == null
                                  ? 'Pana la'
                                  : DateFormat('dd/MM/yyyy').format(toDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: applyFilter,
                          child: const Text('Aplica'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // tabelul cu proprietati
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nr.')),
                            DataColumn(label: Text('Titlu')),
                            DataColumn(label: Text('Tip')),
                            DataColumn(label: Text('Pret')),
                            DataColumn(label: Text('Data creare')),
                          ],
                          rows: List.generate(properties.length, (index) {
                            final p = properties[index];
                            return DataRow(
                              cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(Text(p.title)),
                                DataCell(Text(p.type)),
                                DataCell(
                                  Text(
                                    NumberFormat.decimalPattern(
                                      // formatarea pretului in format romanesc
                                      'ro',
                                    ).format(p.price),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(p.createdAt),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // afisarea numarului total de proprietati
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total proprietati: ${properties.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
