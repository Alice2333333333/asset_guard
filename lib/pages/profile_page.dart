import 'package:flutter/material.dart';

import 'package:asset_guard/provider/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: ListView(
          children: [
            const Text(
              'My Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 88, 61, 142),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: const Color.fromARGB(255, 144, 112, 207),
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const SizedBox(
                width: 100,
                height: 230,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                            'https://cdn-icons-png.flaticon.com/512/2716/2716808.png'),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Name: Alice',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Email: alice@example.com',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Role: System Tester',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Setting',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color.fromARGB(255, 88, 61, 142),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    'Change Email and Password',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    'Change Language',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
            ElevatedButton(
              onPressed: () async {
                await auth.signout();
                Navigator.pushNamed(context, '/');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                  ),
                );
              },
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
