import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _userName;
  String? _userRole;
  String? _userEmail;

  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get userEmail => _userEmail;

  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> fetchUserDetails() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('user').doc(user.uid).get();

        _userEmail = user.email;
        _userName = userDoc['name'];
        _userRole = userDoc['role'];
        await saveUserDetails();
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> saveUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName ?? '');
    await prefs.setString('userRole', _userRole ?? '');
    await prefs.setString('userEmail', _userEmail ?? '');
  }

  Future<void> getUserDetailsFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName');
    _userRole = prefs.getString('userRole');
    _userEmail = prefs.getString('userEmail');
    notifyListeners();
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await fetchUserDetails();
      return cred.user;
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _userName = null;
      _userRole = null;
      _userEmail = null;
      notifyListeners();
      log("User logged out");
    } catch (e) {
      log("Something went wrong");
    }
  }
}
