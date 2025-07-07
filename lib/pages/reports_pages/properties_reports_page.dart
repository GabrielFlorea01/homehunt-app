import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'reports_models/properies_model.dart';

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
    if (fromDate != null) ref = ref.startAt([Timestamp.fromDate(fromDate!)]);
    if (toDate != null) ref = ref.endAt([Timestamp.fromDate(toDate!)]);
    final snap = await ref.get();
    setState(() {
      properties = snap.docs.map((d) => PropertyModel.fromDoc(d)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800, maxHeight: maxHeight),
              child: Column(
                children: [
                  // back arrow + title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Proprietati',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // filtre
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: filterType,
                        items: const [
                          DropdownMenuItem(value: 'Toate', child: Text('Toate')),
                          DropdownMenuItem(value: 'Vandut', child: Text('Vandut')),
                          DropdownMenuItem(value: 'Inchiriat', child: Text('Inchiriat')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => filterType = v);
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
                          child: Text(fromDate == null ? 'De la' : DateFormat('dd/MM/yyyy').format(fromDate!)),
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
                            if (d != null) setState(() => toDate = d);
                          },
                          child: Text(toDate == null ? 'Pana la' : DateFormat('dd/MM/yyyy').format(toDate!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: applyFilter, child: const Text('Aplica')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // scrollable tabel
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
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
                            return DataRow(cells: [
                              DataCell(Text((index + 1).toString())),
                              DataCell(Text(p.title)),
                              DataCell(Text(p.type)),
                              DataCell(Text(NumberFormat.decimalPattern('ro').format(p.price))),
                              DataCell(Text(DateFormat('dd/MM/yyyy').format(p.createdAt))),
                            ]);
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // total
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
    );
  }
}