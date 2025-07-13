import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homehunt/pages/admin_pages/admin_agents_page.dart';
import 'package:homehunt/pages/admin_pages/admin_delete_listings_page.dart';
import 'package:homehunt/pages/admin_pages/admin_sold_rented_page.dart';
import 'package:homehunt/pages/admin_pages/reports_pages/rapoarte_page.dart';
import 'package:homehunt/pages/auth_pages/auth/auth_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  AdminPageState createState() => AdminPageState();
}

class AdminPageState extends State<AdminPage> {
  User? user; // utilizatorul curent autentificat
  String? errorMessage; // mesaj de eroare

  @override
  void initState() {
    super.initState();
    loadUser(); // utilizatorul la initializare
  }

  // utilizatorul curent din FirebaseAuth
  void loadUser() {
    if (!mounted) return;
    setState(() => user = FirebaseAuth.instance.currentUser);
  }

  Future<void> signOut() async {
    setState(() => errorMessage = null);
    try {
      await AuthService().signOut();
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message);
    } catch (_) {
      setState(() => errorMessage = 'Eroare la deconectare');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // drawer cu meniul de administrare
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // optiunile de meniu
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        // placeholder avatar cu initiala emailului
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        // spre pagina agentilor
                        ListTile(
                          leading: const Icon(Icons.group_rounded),
                          title: const Text('Agenti'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminAgentsPage(),
                              ),
                            );
                          },
                        ),
                        // spre pagina de rapoarte
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
                        // spre pagina de stergere anunturi
                        ListTile(
                          leading: const Icon(Icons.playlist_remove_rounded),
                          title: const Text('Sterge anunturi'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const AdminDeleteListingsPage(),
                              ),
                            );
                          },
                        ),
                        // spre pagina de anunturi vandute/inchiriate
                        ListTile(
                          leading: const Icon(Icons.playlist_add_check_circle),
                          title: const Text('Vandut/inchiriat'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const AdminSoldRentedPage(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
                // deconectare
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Sigur te deconectezi?'),
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
                    },
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
