import 'package:asset_guard/pages/asset_page.dart';
import 'package:asset_guard/pages/homepage.dart';
import 'package:asset_guard/pages/login_page.dart';
import 'package:asset_guard/pages/notification_page.dart';
import 'package:asset_guard/pages/profile_page.dart';
import 'package:asset_guard/pages/register_page.dart';
import 'package:asset_guard/provider/auth_provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/homepage': (context) => const Homepage(),
        '/profile': (context) => ProfilePage(),
        '/notification': (context) => const NotificationPage(),
        '/asset': (context) => const AssetPage(),
      },
    );
  }
}
