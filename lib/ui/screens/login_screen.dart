import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/router/app_routes.dart';
import '../../modules/auth/utils/auth_validators.dart';
import '../../modules/marketing/presentation/widgets/ouro_map_background.dart';
import '../components/login/login_input_field.dart';
import '../components/login/gradient_button.dart';
import '../components/login/demo_mode_checkbox.dart';
import '../components/login/social_auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ⚠️ Demo mode — remover antes do release público
  static const _demoEmail = String.fromEnvironment(
    'DEMO_EMAIL',
    defaultValue: 'demo@soloforte.com',
  );
  static const _demoPassword = String.fromEnvironment(
    'DEMO_PASSWORD',
    defaultValue: 'demo1234',
  );

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passFocusNode = FocusNode();

  bool _loading = false;
  bool _socialLoading = false;
  bool _isDemoMode = false;

  // ── Rate limiting ──────────────────────────────────────────
  static const int _kMaxAttempts = 3;
  static const int _kCooldownSeconds = 30;
  int _failedAttempts = 0;
  Timer? _cooldownTimer;
  int _remainingCooldown = 0;

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
    _cooldownTimer?.cancel();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
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

  void _startCooldown() {
    setState(() => _remainingCooldown = _kCooldownSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingCooldown--;
        if (_remainingCooldown <= 0) {
          _remainingCooldown = 0;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    if (_remainingCooldown > 0) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (kDebugMode && _isDemoMode) {
        await ref
            .read(sessionControllerProvider.notifier)
            .login(_demoEmail, _demoPassword);
      } else {
        await ref
            .read(sessionControllerProvider.notifier)
            .login(_emailCtrl.text.trim().toLowerCase(), _passCtrl.text);
      }
      _failedAttempts = 0;
    } catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= _kMaxAttempts) {
        _startCooldown();
      }
      if (mounted) {
        _showErrorMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_loading || _socialLoading) return;
    setState(() => _socialLoading = true);
    try {
      await ref.read(sessionControllerProvider.notifier).loginWithGoogle();
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_loading || _socialLoading) return;
    setState(() => _socialLoading = true);
    try {
      await ref.read(sessionControllerProvider.notifier).loginWithApple();
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleForgotPassword() {
    context.push(AppRoutes.recoverPassword);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Mapa Ouro no fundo ──────────────────────
          const OuroMapBackground(),

          // ── Layer 2: Gradiente overlay (faz o mapa virar teaser) ─
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Layer 3: Badge "Pins Ouro" pulsante (teaser) ────
          Positioned(top: 60, right: 20, child: _OuroPinsTeaser()),

          // ── Botão Voltar → /public-map (glass iOS) ────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: RepaintBoundary(
              child: GestureDetector(
                onTap: () => context.go('/public-map'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.black.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: Formulário em caixa glass ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.80),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // Botão Voltar
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => context.go(AppRoutes.publicMap),
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  size: 16,
                                  color: PremiumTokens.brandGreen,
                                ),
                                label: const Text(
                                  'VOLTAR',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: PremiumTokens.brandGreen,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            // Logo
                            Hero(
                              tag: 'app_logo',
                              child: Center(
                                child: Image.asset(
                                  'assets/images/soloforte_logo.png',
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        gradient: PremiumTokens.brandGradient,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
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
                            const SizedBox(height: 12),

                            // Título
                            Text(
                              'Entrar',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    fontSize: 26,
                                  ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Transforme complexidade em decisões simples',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 24),

                            // Email Input
                            LoginInputField(
                              controller: _emailCtrl,
                              focusNode: _emailFocusNode,
                              label: 'Email',
                              hintText: 'seu@email.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: AuthValidators.validateEmail,
                              onSubmitted: (_) => _passFocusNode.requestFocus(),
                            ),
                            const SizedBox(height: 12),

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
                            const SizedBox(height: 12),

                            // Esqueceu a senha (sem Lembrar-me)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _handleForgotPassword,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: PremiumTokens.brandGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Botão Entrar
                            GradientButton(
                              text: _remainingCooldown > 0
                                  ? 'AGUARDE ${_remainingCooldown}s'
                                  : 'ENTRAR',
                              onPressed: _loading || _remainingCooldown > 0
                                  ? null
                                  : _handleLogin,
                              isLoading: _loading,
                              height: 50,
                            ),
                            const SizedBox(height: 12),

                            SocialAuthButton(
                              text: 'Continuar com Google',
                              icon: Icons.account_circle_outlined,
                              onPressed: _loading || _socialLoading
                                  ? () {}
                                  : _handleGoogleLogin,
                            ),
                            const SizedBox(height: 10),
                            SocialAuthButton(
                              text: 'Continuar com Apple',
                              icon: Icons.apple,
                              onPressed: _loading || _socialLoading
                                  ? () {}
                                  : _handleAppleLogin,
                            ),
                            const SizedBox(height: 12),

                            // Cadastrar
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    context.push(AppRoutes.register),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Não tem conta? ',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Cadastrar',
                                        style: TextStyle(
                                          color: PremiumTokens.brandGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Modo Demo — visível apenas em debug builds
                            if (kDebugMode)
                              Center(
                                child: DemoModeCheckbox(
                                  value: _isDemoMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDemoMode = value ?? false;
                                      if (_isDemoMode) {
                                        _emailCtrl.text = _demoEmail;
                                        _passCtrl.text = _demoPassword;
                                      } else {
                                        _emailCtrl.clear();
                                        _passCtrl.clear();
                                      }
                                    });
                                  },
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge animado de teaser "Pins Ouro ativos"
class _OuroPinsTeaser extends StatefulWidget {
  @override
  State<_OuroPinsTeaser> createState() => _OuroPinsTeaserState();
}

class _OuroPinsTeaserState extends State<_OuroPinsTeaser>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB800).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFB800).withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB800).withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFB800),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Cases Ouro no mapa',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
