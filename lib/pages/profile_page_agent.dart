import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePageAgent extends StatefulWidget {
  const ProfilePageAgent({super.key});

  @override
  State<ProfilePageAgent> createState() => ProfilePageAgentState();
}

class ProfilePageAgentState extends State<ProfilePageAgent> {
  final user = FirebaseAuth.instance.currentUser;
  String? userType;
  String? errorMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserType();
  }

  Future<void> loadUserType() async {
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
    if (doc.exists) {
      setState(() {
        userType = doc.data()?['userType'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center),
        ),
      ),
    );
  }
}
