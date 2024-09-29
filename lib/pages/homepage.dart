import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:asset_guard/pages/login_page.dart';
import 'package:asset_guard/provider/auth_provider.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthProvider();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssetGuard'),
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.notifications),
              tooltip: 'Notification',
              onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () async {
              await auth.signout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
                  return const LoginPage();
                }),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Login successfully'),
      ),
    );
  }
}
