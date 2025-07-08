import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/pages/admin_pages/admin_listings_page.dart';
import 'package:homehunt/pages/auth_pages/auth/auth_service.dart';
import 'package:homehunt/pages/admin_pages/admin_sold_rented_page.dart';
import 'package:homehunt/pages/admin_pages/edit_agents_page.dart';
import 'package:homehunt/pages/reports_pages/rapoarte_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  User? user;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() {
    if (!mounted) return;
    setState(() => user = FirebaseAuth.instance.currentUser);
  }

  Future<void> signOut() async {
    setState(() => errorMessage = null);
    try {
      await AuthService().signOut();
      // redirectioneaza unde vrei tu
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (_) {
      setState(() => errorMessage = 'Eroare la deconectare');
    }
  }

  void confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sigur te deconectezi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nu')),
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
      // AppBar neschimbat
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
        ),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // partea scrollabila
                Expanded(
                  child: SingleChildScrollView(
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
                        const SizedBox(height: 50),
                        ListTile(
                          leading: const Icon(Icons.group_rounded),
                          title: const Text('Agenti'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditAgentsPage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.bar_chart_rounded),
                          title: const Text('Rapoarte'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RapoartePage(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.playlist_remove_rounded),
                          title: const Text('Sterge anunturi'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminListingsPage(),
                              ),
                            );
                          },
                        ),
                          ListTile(
                          leading: const Icon(Icons.playlist_add_check_circle),
                          title: const Text('Vandut/inchiriat'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminSoldRentedPage(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: confirmSignOut,
                    style: TextButton.styleFrom(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Deconectare'),
                  ),
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