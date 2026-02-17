import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/router/app_routes.dart';
import '../theme/soloforte_theme.dart';
import '../components/login/login_input_field.dart';
import '../components/login/gradient_button.dart';
import '../components/login/social_auth_button.dart';
import '../components/login/demo_mode_checkbox.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();

  bool _loading = false;
  bool _rememberMe = false;
  bool _isDemoMode = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 8) {
      return 'Senha deve ter no mínimo 8 caracteres';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isDemoMode) {
        // Modo Demo - credenciais fixas
        await ref
            .read(sessionControllerProvider.notifier)
            .login('demo@soloforte.com', 'demo1234');
      } else {
        // Login normal
        await ref
            .read(sessionControllerProvider.notifier)
            .login(_emailCtrl.text.trim(), _passCtrl.text);
      }

      if (mounted) {
        _showSuccessMessage('Login realizado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SoloForteColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: SoloRadius.radiusMd),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SoloForteColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: SoloRadius.radiusMd),
      ),
    );
  }

  void _handleSocialAuth(String provider) {
    _showErrorMessage('$provider Login em breve! Configure o OAuth primeiro.');
  }

  void _handleForgotPassword() {
    context.push(AppRoutes.recoverPassword);
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canPop();

    return Scaffold(
      backgroundColor: SoloForteColors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botão Voltar (se aplicável)
                  if (canGoBack)
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

                  const SizedBox(height: 20),

                  // Logo
                  Hero(
                    tag: 'app_logo',
                    child: Center(
                      child: Image.asset(
                        'assets/images/soloforte_logo.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: SoloForteGradients.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(SoloSpacing.md),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Título
                  Text(
                    'SoloForte Login',
                    textAlign: TextAlign.center,
                    style: SoloTextStyles.headingLarge,
                  ),

                  const SizedBox(height: 8),

                  // Slogan
                  const Text(
                    'Transforme complexidade\nem decisões simples',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.2,
                      color: SoloForteColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Ilustração placeholder
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(SoloSpacing.lg),
                    decoration: BoxDecoration(
                      color: SoloForteColors.accent.withValues(alpha: 0.3),
                      borderRadius: SoloRadius.radiusXl,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email Input
                  LoginInputField(
                    controller: _emailCtrl,
                    focusNode: _emailFocusNode,
                    label: 'Email',
                    hintText: 'seu@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    onSubmitted: (_) => _passFocusNode.requestFocus(),
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  LoginInputField(
                    controller: _passCtrl,
                    focusNode: _passFocusNode,
                    label: 'Senha',
                    hintText: 'Digite sua senha',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onSubmitted: (_) => _handleLogin(),
                  ),

                  const SizedBox(height: 16),

                  // Checkbox Lembrar-me
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          activeColor: SoloForteColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Lembrar-me',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: SoloForteColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botão Entrar
                  GradientButton(
                    text: 'ENTRAR',
                    onPressed: _loading ? null : _handleLogin,
                    isLoading: _loading,
                    height: 50,
                  ),

                  const SizedBox(height: 16),

                  // Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _handleForgotPassword,
                        child: const Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                            fontSize: 14,
                            color: SoloForteColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(color: SoloForteColors.border),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push(AppRoutes.register);
                        },
                        child: const Text(
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 14,
                            color: SoloForteColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider "ou"
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: SoloForteColors.border),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ou', style: SoloTextStyles.caption),
                      ),
                      const Expanded(
                        child: Divider(color: SoloForteColors.border),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botão Apple
                  SocialAuthButton(
                    text: 'Entrar com Apple',
                    icon: Icons.apple,
                    onPressed: () => _handleSocialAuth('Apple'),
                    borderColor: Colors.black,
                    iconColor: Colors.black,
                  ),

                  const SizedBox(height: 12),

                  // Botão Google
                  SocialAuthButton(
                    text: 'Entrar com Google',
                    icon: Icons.g_mobiledata,
                    onPressed: () => _handleSocialAuth('Google'),
                  ),

                  const SizedBox(height: 24),

                  // Modo Demo
                  Center(
                    child: DemoModeCheckbox(
                      value: _isDemoMode,
                      onChanged: (value) {
                        setState(() {
                          _isDemoMode = value ?? false;
                          if (_isDemoMode) {
                            _emailCtrl.text = 'demo@soloforte.com';
                            _passCtrl.text = 'demo1234';
                          } else {
                            _emailCtrl.clear();
                            _passCtrl.clear();
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
