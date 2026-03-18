import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/pos_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zjlklehusirpnrxonuam.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpqbGtsZWh1c2lycG5yeG9udWFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0NzQzNjUsImV4cCI6MjA4ODA1MDM2NX0.yFKohHuFtMMqwjAVHJfzO03R1d1v9rRW2cdEnTusdEU',
  );

  runApp(const TillPharmacy());
}

class TillPharmacy extends StatelessWidget {
  const TillPharmacy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Till Pharmacy',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return const PosScreen();
      },
    );
  }
}