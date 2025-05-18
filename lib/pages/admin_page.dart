import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homehunt/firebase/auth/auth_service.dart';

/// Home page with filters and cards identical to MyListingsPage
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  late final StreamSubscription<QuerySnapshot> snapshot;
  User? user;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  @override
  void dispose() {
    snapshot.cancel();
    super.dispose();
  }

  void loadUser() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> signOut() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().signOut();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void confirmSignOut() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nu'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  signOut();
                },
                child: const Text('Da'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Image.asset('lib/images/logo.png', height: 80),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 17),
                ),
                onPressed: () {}, //TODO
                icon: const Icon(
                  Icons.real_estate_agent_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Modifica agenti',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      // Drawer with full filter list
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: confirmSignOut,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Deconectare'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
