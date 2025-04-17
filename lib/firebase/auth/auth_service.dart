import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp(
    String email,
    String password,
    String name,
    String userType,
  ) async {
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

  Future<void> googleSignIn() async {
    try {
      if (!kIsWeb) {
        throw AuthException('Google Sign-In is only supported on web.');
      }
      final googleProvider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithPopup(googleProvider);

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('No user returned from Google Sign-In.');
      }
      // add to firebase daca e nou
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName ?? '',
          'userType': 'Te rog updateaza tipul de user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw AuthException('Google Sign-In failed. Please try again.');
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
      if (kIsWeb) {
        await _auth.signOut();
      }
    } catch (e) {
      throw AuthException('Error signing out. Please try again.');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}
