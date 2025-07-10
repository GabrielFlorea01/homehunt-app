import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// clasa pentru exceptii personalizate
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

//pentru gestionarea autentificarii
class AuthService {
  //pentru autentificare
  final FirebaseAuth auth = FirebaseAuth.instance;
  //pentru baza de date
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  //pentru schimbarile de stare ale autentificarii
  Stream<User?> get authStateChanges => auth.authStateChanges();

  //inregistrare utilizator nou
  Future<void> signUp(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      // creeaza utilizator cu email si parola
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // user-ul a fost creat cu succes
      if (userCredential.user != null) {
        // salveaza datele in colectie
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      // tratare erori specifice
      if (e.code == 'weak-password') {
        throw AuthException('Parola este prea slaba');
      } else if (e.code == 'email-already-in-use') {
        throw AuthException('Email deja asociat cu un cont');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Email invalid');
      } else {
        throw AuthException('Sign up esuat. Incearca din nou');
      }
    } catch (e) {
      // alte erori neasteptate
      throw AuthException('Eroare neasteptata');
    }
  }

  //logare utilizator existent
  Future<void> login(String email, String password) async {
    try {
      // cu email si parola
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      //tratare erori la logare
      if (e.code == 'user-not-found') {
        throw AuthException('User cu acest email nu exista');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Parola introdusa este gresita');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Adresa de email invalida');
      } else {
        throw AuthException('Login esuat. Incearca din nou');
      }
    } catch (e) {
      //alte erori neasteptate
      throw AuthException('Eroare neasteptata');
    }
  }

  //logare cu Google
  Future<void> googleSignIn() async {
    try {
      //provider pentru Google
      final googleProvider = GoogleAuthProvider();
      //selectarea contului Google
      googleProvider.setCustomParameters({'prompt': 'select_account'});
      // logare cu popup
      final userCredential = await auth.signInWithPopup(googleProvider);
      final user = userCredential.user;
      // daca nu s-a gasit user
      if (user == null) {
        throw AuthException('Contul Google nu a fost gasit');
      }
      // daca user exista deja
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        //nu exista salveaza datele user
        await firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // tratare erori la logarea cu Google
      throw AuthException('Logarea cu Google a esuat');
    }
  }

  //pentru resetarea parolei
  Future<void> forgotPassword(String email) async {
    try {
      //email de resetare parola
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // tratare erori specifice la resetare parola
      if (e.code == 'user-not-found') {
        throw AuthException('User negasit cu acest email');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Adresa de email invalida');
      } else {
        throw AuthException('Introdu o adresa de email');
      }
    } catch (e) {
      //alte erori neasteptate
      throw AuthException('Eroare neasteptata');
    }
  }

  // metoda pentru delogare
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      //tratare erori la delogare
      throw AuthException('Eroare la sign out. Incearca din nou');
    }
  }
}
