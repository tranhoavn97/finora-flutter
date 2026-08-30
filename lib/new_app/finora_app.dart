import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/services/auth_repository.dart';
import 'home_shell.dart';
import 'sign_in_screen.dart';
import 'theme.dart';

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Finora',
        debugShowCheckedModeBanner: false,
        theme: FinoraTheme.light,
        darkTheme: FinoraTheme.dark,
        themeMode: ThemeMode.system,
        home: StreamBuilder<User?>(
          stream: AuthRepository().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LaunchScreen();
            }
            final user = snapshot.data;
            return user == null ? const SignInScreen() : HomeShell(user: user);
          },
        ),
      );
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.bolt_rounded,
                  color: Color(0xFF10120F), size: 38),
            ),
            const SizedBox(height: 20),
            Text('FINORA', style: Theme.of(context).textTheme.headlineSmall),
          ]),
        ),
      );
}
