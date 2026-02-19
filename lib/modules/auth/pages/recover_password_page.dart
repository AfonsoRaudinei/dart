import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../ui/theme/soloforte_theme.dart';
import '../services/auth_service.dart';

class RecoverPasswordPage extends ConsumerStatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  ConsumerState<RecoverPasswordPage> createState() =>
      _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends ConsumerState<RecoverPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authServiceProvider.notifier)
          .recoverPassword(_emailController.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar link: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoloForteColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: SoloForteColors.primary,
                  ),
                  label: const Text(
                    'VOLTAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SoloForteColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              _sent ? _buildSuccess() : _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Esqueceu sua senha?',
            style: SoloTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Digite seu e-mail e enviaremos um link para redefinir sua senha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: SoloForteColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: SoloForteColors.primary,
                size: 20,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe seu e-mail';
              if (!value.contains('@')) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRecover,
              style: ElevatedButton.styleFrom(
                backgroundColor: SoloForteColors.primary,
                disabledBackgroundColor: SoloForteColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SoloRadius.md),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enviar link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: SoloForteColors.success,
        ),
        const SizedBox(height: 24),
        Text(
          'E-mail enviado!',
          style: SoloTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Se o e-mail ${_emailController.text} estiver cadastrado, você receberá um link em alguns instantes.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: SoloForteColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: SoloForteColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SoloRadius.md),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Voltar para Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
