import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserModel {
  final String id;
  final String email;
  final DateTime createdAt;

  UserModel({required this.id, required this.email, required this.createdAt});

  factory UserModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class UsersReportPage extends StatefulWidget {
  const UsersReportPage({super.key});

  @override
  UsersReportPageState createState() => UsersReportPageState();
}

class UsersReportPageState extends State<UsersReportPage> {
  DateTime? fromDate;
  DateTime? toDate;
  List<UserModel> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    final snap =
        await FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt')
            .get();
    setState(() {
      users =
          snap.docs
              .map((d) => UserModel.fromDoc(d))
              .where((u) => u.email != currentEmail)
              .toList();
    });
  }

  Future<void> applyFilter() async {
    final currentEmail = FirebaseAuth.instance.currentUser?.email;
    Query<Map<String, dynamic>> ref = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt');
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
      users =
          snap.docs
              .map((d) => UserModel.fromDoc(d))
              .where((u) => u.email != currentEmail)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 6,
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        'Utilizatori inregistrati',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // filtre
                  Row(
                    children: [
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
                            fromDate == null
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
                            if (d != null) setState(() => toDate = d);
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
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nr.')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Data creare')),
                        ],
                        rows: List.generate(users.length, (index) {
                          final u = users[index];
                          return DataRow(
                            cells: [
                              DataCell(Text((index + 1).toString())),
                              DataCell(Text(u.email)),
                              DataCell(
                                Text(
                                  DateFormat('dd/MM/yyyy').format(u.createdAt),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // total
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total utilizatori: ${users.length}',
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
