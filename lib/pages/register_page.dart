import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:asset_guard/provider/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  List<String> role = <String>['Select Role', 'Storeman', 'Site Manager'];
  String selectedRole = 'Select Role';

  final _auth = AuthProvider();

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
              child: DropdownMenu<String>(
                initialSelection: selectedRole,
                expandedInsets: EdgeInsets.zero,
                onSelected: (String? value) {
                  setState(() {
                    selectedRole = value!;
                    role.remove('Select Role');
                  });
                },
                dropdownMenuEntries:
                    role.map<DropdownMenuEntry<String>>((String value) {
                  return DropdownMenuEntry<String>(value: value, label: value);
                }).toList(),
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
                  final bool isValid = EmailValidator.validate(_email.text);
                  String password = _password.text;
                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid email'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Password should be at least 6 characters'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    _signup();
                  }
                },
                child: const Text('Register'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 330,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('Already have an account?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _signup() async {
    final user = await _auth.createUser(
        _name.text, selectedRole, _email.text, _password.text);

    if (user != null) {
      log("User Created Succesfully");
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
