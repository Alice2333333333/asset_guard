import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider {
  final _auth = FirebaseAuth.instance;

  Future<User?> createUser(
      String name, String role, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      User? user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('user').doc(user.uid).set({
          'name': name,
          'role': role,
          'email': email,
        });
        log("User data saved in Firestore");
        return user;
      }
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
      log("User logged out");
    } catch (e) {
      log("Something went wrong");
    }
  }
}
