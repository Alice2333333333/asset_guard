import 'dart:developer';

import 'package:asset_guard/pages/loading_view.dart';
import 'package:asset_guard/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:asset_guard/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.status) {
      case AuthStatus.authenticateError:
        Fluttertoast.showToast(msg: "Sign in fail");
        break;
      case AuthStatus.authenticated:
        Fluttertoast.showToast(msg: "Sign in success");
        break;
      case AuthStatus.userNotFound:
        Fluttertoast.showToast(msg: "User not found");
        break;
      case AuthStatus.wrongPassword:
        Fluttertoast.showToast(msg: "Wrong password");
        break;
      case AuthStatus.weakPassword:
        Fluttertoast.showToast(msg: "Weak password");
        break;
      case AuthStatus.emailAlreadyInUsed:
        Fluttertoast.showToast(msg: "Email already in used");
        break;
      case AuthStatus.registerError:
        Fluttertoast.showToast(msg: "Sign up fail");
        break;
      default:
        break;
    }
    return Stack(
      children: [
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(30.0),
            children: [
              Scaffold(
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
                            // _login();
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
                              MaterialPageRoute(
                                  builder: (BuildContext context) {
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
              )
            ],
          ),
        ),
        Positioned(
          child: authProvider.status == AuthStatus.authenticating
              ? const LoadingView()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Text _buildHeader(BuildContext context, AuthProvider authProvider) {
  //   final l = FirebaseUILocalizations.labelsOf(context);

  //   late String hint;
  //   late String actionText;

  //   if (authProvider.action == AuthAction.signIn) {
  //     hint = l.registerHintText;
  //     actionText = l.registerText;
  //   } else if (authProvider.action == AuthAction.signUp) {
  //     hint = l.signInHintText;
  //     actionText = l.signInText;
  //   }

//     TextStyle? hintStyle;
//     late Color registerTextColor;

//     final theme = Theme.of(context);
//     hintStyle = theme.textTheme.bodySmall;
//     registerTextColor = theme.colorScheme.primary;

//     return Text.rich(
//       TextSpan(
//         children: [
//           TextSpan(
//             text: '$hint ',
//             style: hintStyle,
//           ),
//           TextSpan(
//             text: actionText,
//             style: theme.textTheme.labelLarge?.copyWith(
//               color: registerTextColor,
//             ),
//             mouseCursor: SystemMouseCursors.click,
//             recognizer: TapGestureRecognizer()
//               ..onTap = () => _handleDifferentAuthAction(authProvider),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleDifferentAuthAction(AuthProvider authProvider) {
//     FocusManager.instance.primaryFocus?.unfocus();
//     if (authProvider.action == AuthAction.signIn) {
//       authProvider.action = AuthAction.signUp;
//     } else {
//       authProvider.action = AuthAction.signIn;
//     }
//   }

//   String _choosePageTitle(AuthProvider authProvider) {
//     if (authProvider.action == AuthAction.signIn) {
//       return AppConstants.signInTitle;
//     } else if (authProvider.action == AuthAction.signUp) {
//       return AppConstants.registerTitle;
//     }
//     return "";
//   }
}
