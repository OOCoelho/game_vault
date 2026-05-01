import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final user = await FirebaseService.signInWithGoogle();
    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao entrar. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b0e11),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(Icons.sports_esports,
                color: Colors.blueAccent, size: 72),
            const SizedBox(height: 16),
            const Text('GAMEVAULT',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4)),
            const SizedBox(height: 8),
            const Text('Sua biblioteca de jogos',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 60),

            // Botão Google
            _loading
                ? const CircularProgressIndicator(color: Colors.blueAccent)
                : GestureDetector(
                    onTap: _signIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1b2838),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 12),
                          Text('Entrar com Google',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

            const SizedBox(height: 80),

            // Atribuição RAWG (obrigatória pelos termos)
            const Text('Dados fornecidos por',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            const Text('RAWG.io',
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}