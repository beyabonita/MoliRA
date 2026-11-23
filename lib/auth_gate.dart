import 'package:flutter/material.dart';
import 'login.dart';
import 'services/library_service.dart';
import 'student_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LibraryService.instance,
      builder: (context, _) {
        if (LibraryService.instance.currentUser != null) {
          return const StudentShell();
        }
        return const LoginScreen();
      },
    );
  }
}
