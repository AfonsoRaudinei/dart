import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../ui/theme/soloforte_theme.dart';
import '../models/register_dto.dart';
import '../services/auth_service.dart';
import '../utils/auth_validators.dart';
import '../widgets/profile_avatar_picker.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  // For testing rebuilds
  static int buildCount = 0;

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

      await ref.read(authServiceProvider.notifier).register(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Verifique seu email.'),
            backgroundColor: SoloForteColors.success,
          ),
        );
        context.go(AppRoutes.login);
      }
    } catch (e) {
      // 4. Error Handling & State Reset
      if (mounted) {
        // Extract message usually from Supabase Exception
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('User already registered')) {
          msg = 'Email já cadastrado';
        }

        _showError('Erro ao criar conta: $msg');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SoloForteColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    RegisterPage.buildCount++;

    return Scaffold(
      backgroundColor: SoloForteColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode:
                AutovalidateMode.onUserInteraction, // Validation feedback
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Criar Conta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SoloForteColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preencha seus dados para começar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SoloForteColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                ProfileAvatarPicker(
                  onImageSelected: (file) => setState(() => _photo = file),
                ),

                const SizedBox(height: 30),

                // Name
                TextFormField(
                  key: const Key('register_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    prefixIcon: Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
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
                    filled: true,
                    fillColor: Colors.white,
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
                    filled: true,
                    fillColor: Colors.white,
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
                    filled: true,
                    fillColor: Colors.white,
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
                  validator: (v) => v == null ? 'Selecione um tipo' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  key: const Key('register_password_field'),
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: AuthValidators.validatePassword,
                  textInputAction: TextInputAction.next,
                ),

                // Strength Indicator
                ValueListenableBuilder(
                  valueListenable: _passwordController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    final strength = AuthValidators.evaluatePasswordStrength(
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
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
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
                    backgroundColor: SoloForteColors.primary,
                    disabledBackgroundColor: SoloForteColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : const Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem conta? ',
                      style: TextStyle(color: SoloForteColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: SoloForteColors.primary,
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

  Widget _buildStrengthBar(int index, PasswordStrength strength) {
    Color color = Colors.grey[300]!;
    if (strength == PasswordStrength.weak) {
      if (index == 0) color = SoloForteColors.error;
    } else if (strength == PasswordStrength.medium) {
      if (index <= 1) color = SoloForteColors.warning;
    } else if (strength == PasswordStrength.strong) {
      color = SoloForteColors.success;
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
        return SoloForteColors.error;
      case PasswordStrength.medium:
        return SoloForteColors.warning;
      case PasswordStrength.strong:
        return SoloForteColors.success;
    }
  }
}
