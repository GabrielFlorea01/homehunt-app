import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp(String email, String password, String name, String userType) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw AuthException('Password too weak');
      } else if (e.code == 'email-already-in-use') {
        throw AuthException('Email already associated to an account');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Invalid email address provided');
      } else {
        throw AuthException('Sign up failed. Please try again');
      }
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('User not found with this email');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Wrong password provided');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Invalid email address provided');
      } else {
        throw AuthException('Login failed. Please try again');
      }
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('No user found with this email');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Invalid email address provided');
      } else {
        throw AuthException('Password reset failed. Please try again');
      }
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Error signing out. Please try again.');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
