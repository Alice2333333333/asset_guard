import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:asset_guard/constants/firebase_constant.dart';

enum AuthAction {
  login,
  register,
}

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  userNotFound,
  wrongPassword,
  weakPassword,
  emailAlreadyInUsed,
  registerError,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;

  AuthStatus _status = AuthStatus.uninitialized;
  AuthAction _action = AuthAction.login;

  AuthStatus get status => _status;
  AuthAction get action => _action;

  set action(AuthAction newAction) {
    _action = newAction;
    notifyListeners();
  }

  AuthProvider({
    required this.firebaseAuth,
    required this.firebaseFirestore,
  });

  String getCurrentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  Future<bool> handleRegister(
    String? role,
    String name,
    String email,
    String password,
  ) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      User? firebaseUser =
          (await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ))
              .user;

      if (firebaseUser != null) {
        final addData = {
          FirebaseConstant.id: firebaseUser.uid,
          FirebaseConstant.name: name,
          FirebaseConstant.role: role,
        };

        firebaseFirestore
            .collection(FirebaseConstant.pathUserCollection)
            .doc(firebaseUser.uid)
            .set(addData);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.registerError;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _status = AuthStatus.weakPassword;
      } else if (e.code == 'email-already-in-use') {
        _status = AuthStatus.emailAlreadyInUsed;
      } else {
        _status = AuthStatus.registerError;
      }
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _status = AuthStatus.registerError;
      notifyListeners();
      return false;
    }
  }

  Future<bool> handleLogin(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      User? firebaseUser =
          (await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      ))
              .user;
      if (firebaseUser != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.authenticateError;
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _status = AuthStatus.userNotFound;
      } else if (e.code == 'wrong-password') {
        _status = AuthStatus.wrongPassword;
      } else {
        _status = AuthStatus.authenticateError;
      }
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _status = AuthStatus.authenticateError;
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignOut() async {
    _status = AuthStatus.uninitialized;
    _action = AuthAction.login;
    notifyListeners();
    await firebaseAuth.signOut();
  }
}
