import 'package:flutter/material.dart';
import 'package:homehunt/pages/auth_pages/auth/auth_service.dart';
import 'package:homehunt/firebase/secrets/admin_key.dart';
import 'package:homehunt/pages/admin_pages/admin_page.dart';
import 'package:homehunt/pages/auth_pages/login_page.dart';
import 'package:homehunt/pages/user_pages/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder pentru a asculta schimbarile de autentificare
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        //indicator de incarcare cat timp conexiunea este in asteptare
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //inapoi la login daca e null
        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        //daca e admin - se preia cheia din secrets si o verifica
        if (user.uid == adminUUID) {
          // daca este admin se returneaza pagina de admin
          return const AdminPage();
        }

        // else user normal
        //user normal
        return const HomePage();
      },
    );
  }
}
