import 'dart:developer';

import 'package:asset_guard/auth/register_page.dart';
import 'package:asset_guard/homepage.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    super.dispose();
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
            Image.network(
              'https://logos-world.net/wp-content/uploads/2022/07/Hilti-Logo.png',
              height: 150,
              width: 150,
            ),
            const Text(
              'Welcome to Asset Guard!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 202, 29, 29),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0),
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
                  _login();
                },
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 330,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (BuildContext context) {
                      return const RegisterPage();
                    }),
                  );
                },
                child: const Text('Create a new account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _login() async {
    final user = await _auth.loginUser(_email.text, _password.text);
    if (user != null) {
      log("User Logged In");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) {
          return const Homepage();
        }),
      );
    }
  }
}
