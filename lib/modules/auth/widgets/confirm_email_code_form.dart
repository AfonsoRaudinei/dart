import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Formulário para confirmar o cadastro com o código de 6 dígitos do e-mail.
///
/// Não conhece navegação nem serviços: verificação e reenvio são injetados e
/// [onConfirmed] é chamado após a verificação bem-sucedida.
class ConfirmEmailCodeForm extends StatefulWidget {
  const ConfirmEmailCodeForm({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
    required this.onConfirmed,
    this.startWithResendCooldown = false,
  });

  static const int codeLength = 6;
  static const int resendCooldownSeconds = 60;
  static const int maxFailedAttempts = 5;
  static const int lockSeconds = 60;

  final String email;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onConfirmed;

  /// Inicia o cooldown de reenvio já ativo (e-mail acabou de ser enviado).
  final bool startWithResendCooldown;

  @override
  State<ConfirmEmailCodeForm> createState() => _ConfirmEmailCodeFormState();
}

class _ConfirmEmailCodeFormState extends State<ConfirmEmailCodeForm> {
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  Timer? _lockTimer;

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  int _lockRemaining = 0;
  int _failedAttempts = 0;
  String? _errorText;
  String? _successText;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    if (widget.startWithResendCooldown) {
      _startResendCooldown();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _lockTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  bool get _isCodeComplete =>
      _codeController.text.length == ConfirmEmailCodeForm.codeLength;

  bool get _isLocked => _lockRemaining > 0;

  bool get _canSubmit => _isCodeComplete && !_isVerifying && !_isLocked;

  bool get _canResend => !_isResending && !_isVerifying && _resendCooldown == 0;

  void _onCodeChanged() {
    if (mounted) setState(() {});
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendCooldown = ConfirmEmailCodeForm.resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown -= 1;
        if (_resendCooldown <= 0) {
          _resendCooldown = 0;
          timer.cancel();
        }
      });
    });
  }

  void _startLock() {
    _lockTimer?.cancel();
    _lockRemaining = ConfirmEmailCodeForm.lockSeconds;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockRemaining -= 1;
        if (_lockRemaining <= 0) {
          _lockRemaining = 0;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  String _messageFrom(Object error) =>
      error.toString().replaceAll('Exception: ', '');

  void _setError(String message) {
    _errorText = message;
    _successText = null;
  }

  void _setSuccess(String message) {
    _successText = message;
    _errorText = null;
  }

  Future<void> _handleVerify() async {
    if (!_canSubmit) return;
    setState(() {
      _isVerifying = true;
      _errorText = null;
      _successText = null;
    });
    try {
      await widget.onVerify(_codeController.text);
      if (!mounted) return;
      _failedAttempts = 0;
      widget.onConfirmed();
    } catch (e) {
      if (!mounted) return;
      _failedAttempts += 1;
      if (_failedAttempts >= ConfirmEmailCodeForm.maxFailedAttempts) {
        _startLock();
        _setError('Muitas tentativas incorretas. Aguarde 1 minuto.');
      } else {
        _setError(_messageFrom(e));
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    setState(() {
      _isResending = true;
      _errorText = null;
      _successText = null;
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      _startResendCooldown();
      _setSuccess('Novo código enviado. Verifique sua caixa de entrada.');
    } catch (e) {
      if (!mounted) return;
      _setError(_messageFrom(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.themeAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Digite o código de 6 dígitos enviado para ${widget.email}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.premiumTextSecondary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('confirm_code_field'),
          controller: _codeController,
          enabled: !_isVerifying,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(ConfirmEmailCodeForm.codeLength),
          ],
          decoration: const InputDecoration(
            labelText: 'Código',
            prefixIcon: Icon(Icons.pin_outlined),
            counterText: '',
          ),
          onSubmitted: (_) => _handleVerify(),
        ),
        if (_errorText != null || _successText != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorText ?? _successText!,
            key: const Key('confirm_code_feedback'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _errorText != null
                  ? PremiumTokens.alertError
                  : PremiumTokens.brandGreen,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('confirm_code_submit'),
          onPressed: _canSubmit ? _handleVerify : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            disabledBackgroundColor: accent.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isLocked ? 'Aguarde ${_lockRemaining}s' : 'Confirmar',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('confirm_code_resend'),
          onPressed: _canResend ? _handleResend : null,
          child: Text(
            _resendCooldown > 0
                ? 'Reenviar código (${_resendCooldown}s)'
                : 'Reenviar código',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
