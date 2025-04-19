import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:homehunt/firebase/auth/auth_service.dart';
import 'package:homehunt/pages/login_page.dart';
import 'package:homehunt/error_widgets/error_banner.dart';
import 'package:homehunt/pages/new_listing_page.dart';
import 'package:homehunt/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  User? user;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    setState(() => isLoading = true);
    user = FirebaseAuth.instance.currentUser;
    setState(() => isLoading = false);
  }

  Future<void> signOut() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() => errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void clearError() {
    setState(() {
      errorMessage = null;
    });
  }

  Future<void> showSignOutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Te vei deconecta de la contul tau'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Renunta'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                signOut();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  void addNewListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNewListingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          title: Center(
            child: Padding(padding: const EdgeInsets.only(top: 15),
            child: Image.asset('lib/images/logo.png', width: 220, height: 220),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 30, top: 15),
              child: TextButton.icon(
                onPressed: addNewListing,
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'Anunt',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        backgroundColor: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user?.email?.isNotEmpty == true
                    ? user!.email![0].toUpperCase()
                    : 'U',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Marketplace'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorite'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.addchart_rounded),
              title: const Text('Anunturile mele'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),

            const Spacer(),

            // Adauga anunt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addNewListing,
                style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                ),
                child: const Text('Adauga anunt', style: TextStyle(
                  fontSize: 18,
                ),
                ),
              ),
              ),
            ),
            const SizedBox(height: 50),
            //signout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: showSignOutConfirmationDialog,
                  style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Deconectare'),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null)
                        ErrorBanner(
                          message: errorMessage!,
                          onDismiss: clearError,
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
