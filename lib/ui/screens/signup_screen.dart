import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;

  Future<void> _doSignup() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .signup(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
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
              Text('Criar Conta', style: SoloTextStyles.headingLarge),
              const SizedBox(height: 40),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 20),
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
                  onPressed: _loading ? null : _doSignup,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
