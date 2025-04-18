import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/pages/home_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? userType;
  String? errorMessage;
  bool isLoading = false;
  final validUserTypes = ['buyer', 'seller', 'agent'];

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

  Future<void> saveUserType() async {
    if (!validUserTypes.contains(userType)) {
      setState(() {
        errorMessage = 'Te rugam sa selectezi un tip de utilizator valid.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'userType': userType});
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Eroare la salvare. Incearca din nou.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profilul tau'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (errorMessage != null) ...[
                ErrorBanner(
                  message: errorMessage!,
                  onDismiss: () => setState(() => errorMessage = null),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Actualizeaza tipul de utilizator',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: validUserTypes.contains(userType) ? userType : null,
                decoration: const InputDecoration(
                  labelText: 'Tip utilizator',
                  border: OutlineInputBorder(),
                ),
                items:
                    validUserTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type == 'buyer'
                                  ? 'Cumparator'
                                  : type == 'seller'
                                  ? 'Vanzator'
                                  : 'Agent',
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    userType = value;
                  });
                },
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: isLoading ? null : saveUserType,
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Salveaza'),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Inapoi la Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
