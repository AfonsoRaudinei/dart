import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(_emailCtrl.text, _passCtrl.text);
      // Navigation is handled by router listening to state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoloForteColors.grayLight,
      body: Center(
        child: SingleChildScrollView(
          padding: SoloSpacing.paddingCard,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SoloForte Login', style: SoloTextStyles.headingLarge),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
