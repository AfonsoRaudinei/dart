import 'dart:io';
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';

import '../models/register_dto.dart';
import '../services/auth_service.dart';
import '../utils/auth_validators.dart';
import '../widgets/profile_avatar_picker.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _role = 'produtor'; // Default value per spec
  File? _photo;
  bool _isLoading = false;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registered = false;
  String _registeredEmail = '';

  // Track validity for button state
  bool _isFormValid = false;

  // Debounce for double submit protection
  DateTime? _lastSubmitTime;

  @override
  void initState() {
    super.initState();
    // Listen to changes to update UI immediately
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_handlePasswordChange);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handlePasswordChange() {
    _passwordStrength = AuthValidators.evaluatePasswordStrength(
      _passwordController.text,
    );
    _validateForm();
  }

  void _validateForm() {
    // Quick validation check without triggering errors visually if not interacted
    // But for enable/disable button we check strict validity
    final isValid =
        AuthValidators.validateName(_nameController.text) == null &&
        AuthValidators.validateEmail(_emailController.text) == null &&
        AuthValidators.validatePhone(_phoneController.text) == null &&
        AuthValidators.validatePassword(_passwordController.text) == null &&
        _passwordController.text == _confirmPasswordController.text &&
        _passwordStrength != PasswordStrength.weak; // Enforce strength

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<void> _handleRegister() async {
    // 1. Debounce / Double submit protection
    final now = DateTime.now();
    if (_lastSubmitTime != null &&
        now.difference(_lastSubmitTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastSubmitTime = now;

    if (_isLoading) return;

    // 2. Local Validation
    if (!_formKey.currentState!.validate()) return;

    // 3. Consistency Checks
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('As senhas não coincidem');
      return;
    }

    if (_passwordStrength == PasswordStrength.weak) {
      _showError('A senha é muito fraca');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = RegisterDto(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(), // Enforce lowercase
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _role,
        photo: _photo,
      );

      final response = await ref.read(authServiceProvider.notifier).register(dto);
      if (response.session == null) {
        // email-confirm ativo — mostrar tela de confirmação
        if (!mounted) return;
        setState(() {
          _registered = true;
          _registeredEmail = dto.email;
        });
      } else {
        // sessão já ativa via signUp — não chamar login() novamente
        // SessionController detecta via onAuthStateChange automaticamente
        if (!mounted) return;
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        _showError(msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _registered
            ? _buildSuccessState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode:
                      AutovalidateMode.onUserInteraction, // Validation feedback
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 16),
                      Text(
                        'Criar Conta',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: PremiumTokens.textPrimaryLight,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha seus dados para começar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PremiumTokens.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      ProfileAvatarPicker(
                        onImageSelected: (file) =>
                            setState(() => _photo = file),
                      ),

                      const SizedBox(height: 32),

                      // Name
                      TextFormField(
                        key: const Key('register_name_field'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: AuthValidators.validateName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        key: const Key('register_email_field'),
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: AuthValidators.validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        key: const Key('register_phone_field'),
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: AuthValidators.validatePhone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Role
                      DropdownButtonFormField<String>(
                        key: const Key('register_role_field'),
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Usuário',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'produtor',
                            child: Text('Produtor'),
                          ),
                          DropdownMenuItem(
                            value: 'consultor',
                            child: Text('Consultor'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _role = value);
                        },
                        validator: (v) =>
                            v == null ? 'Selecione um tipo' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        key: const Key('register_password_field'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),

                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: AuthValidators.validatePassword,
                        textInputAction: TextInputAction.next,
                      ),

                      // Strength Indicator
                      ValueListenableBuilder(
                        valueListenable: _passwordController,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final strength =
                              AuthValidators.evaluatePasswordStrength(
                                value.text,
                              );

                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              left: 4,
                              right: 4,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildStrengthBar(0, strength)),
                                const SizedBox(width: 4),
                                Expanded(child: _buildStrengthBar(1, strength)),
                                const SizedBox(width: 4),
                                Expanded(child: _buildStrengthBar(2, strength)),
                                const SizedBox(width: 8),
                                Text(
                                  _getStrengthLabel(strength),
                                  style: TextStyle(
                                    color: _getStrengthColor(strength),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        key: const Key('register_confirm_password_field'),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),

                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme sua senha';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        key: const Key('register_submit_button'),
                        onPressed: (_isFormValid && !_isLoading)
                            ? _handleRegister
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumTokens.brandGreen,
                          disabledBackgroundColor: PremiumTokens.brandGreen
                              .withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
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
                            : Text(
                                'Criar Conta',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Já tem conta? ',
                            style: TextStyle(
                              color: PremiumTokens.textSecondaryLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: Text(
                              'Entrar',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: PremiumTokens.brandGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: Color(0xFF34C759),
          ),
          const SizedBox(height: 32),
          const Text(
            'Conta criada!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enviamos um link de confirmação para:\n$_registeredEmail\n\nAcesse seu e-mail, clique no link e volte para fazer login.\n\nVerifique também a pasta de spam.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text(
              'Ir para Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(int index, PasswordStrength strength) {
    Color color = Colors.grey[300]!;
    if (strength == PasswordStrength.weak) {
      if (index == 0) color = const Color(0xFFFF3B30);
    } else if (strength == PasswordStrength.medium) {
      if (index <= 1) color = const Color(0xFFFF9500);
    } else if (strength == PasswordStrength.strong) {
      color = const Color(0xFF34C759);
    }

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _getStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Fraca';
      case PasswordStrength.medium:
        return 'Média';
      case PasswordStrength.strong:
        return 'Forte';
    }
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return const Color(0xFFFF3B30);
      case PasswordStrength.medium:
        return const Color(0xFFFF9500);
      case PasswordStrength.strong:
        return const Color(0xFF34C759);
    }
  }
}
