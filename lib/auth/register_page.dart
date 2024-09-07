import 'dart:developer';

import 'package:asset_guard/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:asset_guard/auth/login_page.dart';
// import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sign Up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 202, 29, 29),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _email,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 330,
              child: ElevatedButton(
                onPressed: () {
                  // _signup();
                },
                child: const Text('Register'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 330,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (BuildContext context) {
                      return const LoginPage();
                    }),
                  );
                },
                child: const Text('Already have an account?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _signup() async {
  //   final user = await _auth.createUser(_email.text, _password.text);
  //   if (user != null) {
  //     log("User Created Succesfully");
  //     Navigator.of(context).push(
  //       MaterialPageRoute(builder: (BuildContext context) {
  //         return const LoginPage();
  //       }),
  //     );
  //   }
  // }
}
