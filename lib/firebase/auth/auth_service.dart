import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<void> signUp(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
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
      throw AuthException('Eroare neasteptata');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
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
      throw AuthException('Eroare neasteptata');
    }
  }

  Future<void> googleSignIn() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      final userCredential = await auth.signInWithPopup(googleProvider);
      final user = userCredential.user;

      if (user == null) {
        throw AuthException('Nu s-a returnat niciun user de la Google.');
      }

      final doc = await firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw AuthException('Logarea cu Google a esuat');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('User negasit cu acest email');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Adresa de email invalida');
      } else {
        throw AuthException('Introdu o adresa de email');
      }
    } catch (e) {
      throw AuthException('Eroare neasteptata');
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw AuthException('Eroare la sign out. Incearca din nou');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
