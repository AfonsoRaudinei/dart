// ADR-032 — settings/presentation/screens/edit_profile_screen.dart
//
// Tela de edição do perfil do usuário.
// Aberta pela rota privada /settings/profile/edit.
//
// Campos somente leitura: email, role, data de cadastro
// Campos editáveis: fullName, phone, creaNumber
// Foto de perfil: fluxo existente em settings_repository.dart (não duplicado)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/user_role.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_provider.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => _profileStateScaffold(
        context,
        child: const CircularProgressIndicator(),
      ),
      error: (_, __) => _profileStateScaffold(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar o perfil.',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.invalidate(currentUserProfileProvider),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (profile) => profile == null
          ? _profileStateScaffold(
              context,
              child: const Text(
                'Usuário não autenticado.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _EditProfileForm(
              key: ValueKey('${profile.id}-${profile.updatedAt}'),
              initialProfile: profile,
            ),
    );
  }

  Scaffold _profileStateScaffold(
    BuildContext context, {
    required Widget child,
  }) {
    const bgColor = Color(0xFF1C1C1E);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ),
      body: Center(child: child),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({super.key, required this.initialProfile});

  final UserProfile initialProfile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  static const _inputFillColor = Colors.white;
  static const _inputTextColor = Color(0xFF1C1C1E);
  static const _inputBorderColor = Color(0xFFE5E5EA);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _creaCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(
      text: widget.initialProfile.fullName ?? '',
    );
    _phoneCtrl = TextEditingController(text: widget.initialProfile.phone ?? '');
    _creaCtrl = TextEditingController(
      text: widget.initialProfile.creaNumber ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _creaCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final original = widget.initialProfile;
    final oldFullName = (original.fullName ?? '').trim();
    final oldPhone = (original.phone ?? '').trim();
    final oldCrea = (original.creaNumber ?? '').trim();
    final newFullName = _fullNameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();
    final newCrea = _creaCtrl.text.trim();

    // Montar mapa de campos realmente alterados: {campo: valorAntigo}
    final changedFields = <String, String?>{};
    if (newFullName != oldFullName) {
      changedFields['fullName'] = original.fullName?.isNotEmpty == true
          ? original.fullName
          : null;
    }
    if (newPhone != oldPhone) {
      changedFields['phone'] = original.phone?.isNotEmpty == true
          ? original.phone
          : null;
    }
    if (newCrea != oldCrea) {
      changedFields['creaNumber'] = original.creaNumber?.isNotEmpty == true
          ? original.creaNumber
          : null;
    }

    // Nenhum campo mudou — fechar sem gravar
    if (changedFields.isEmpty) {
      if (mounted) context.go(AppRoutes.settings);
      return;
    }

    final updated = original.copyWith(
      fullName: newFullName.isEmpty ? null : newFullName,
      phone: newPhone.isEmpty ? null : newPhone,
      creaNumber: newCrea.isEmpty ? null : newCrea,
      clearFullName: newFullName.isEmpty,
      clearPhone: newPhone.isEmpty,
      clearCreaNumber: newCrea.isEmpty,
      updatedAt: DateTime.now(),
    );

    setState(() => _saving = true);

    try {
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.updateProfile(updated: updated, changedFields: changedFields);

      // Invalidar ambos os providers para forçar re-fetch
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(profileAuditTrailProvider);

      if (mounted) {
        HapticFeedback.lightImpact();
        context.go(AppRoutes.settings);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar perfil: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1C1C1E);
    const cardColor = Color(0xFF2C2C2E);
    const hintColor = Color(0xFF8E8E93);
    const amberColor = Color(0xFFF59E0B);
    final profile = widget.initialProfile;
    final role = profile.role.toUserRole();
    final canEditProfessionalId = role.isConsultor;

    final createdAtStr = DateFormat(
      'dd/MM/yyyy',
    ).format(profile.createdAt.toLocal());

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _saving ? null : () => context.go(AppRoutes.settings),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: amberColor,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: amberColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // ── Somente leitura ──────────────────────────────
            _sectionHeader('INFORMAÇÕES DA CONTA', hintColor),
            _card(cardColor, [
              _readonlyRow('E-mail', profile.email, hintColor),
              const Divider(height: 1, color: Color(0xFF3A3A3C)),
              _readonlyRow('Perfil', role.label, hintColor),
              const Divider(height: 1, color: Color(0xFF3A3A3C)),
              _readonlyRow('Cadastrado em', createdAtStr, hintColor),
            ]),

            // ── Editáveis ────────────────────────────────────
            _sectionHeader('DADOS EDITÁVEIS', hintColor),
            _card(cardColor, [
              _editableField(
                controller: _fullNameCtrl,
                label: 'Nome completo',
                hint: 'Seu nome',
                hintColor: hintColor,
                enabled: !_saving,
              ),
              const Divider(height: 1, color: Color(0xFF3A3A3C)),
              _editableField(
                controller: _phoneCtrl,
                label: 'Telefone',
                hint: '(00) 00000-0000',
                hintColor: hintColor,
                keyboardType: TextInputType.phone,
                enabled: !_saving,
              ),
              const Divider(height: 1, color: Color(0xFF3A3A3C)),
              if (canEditProfessionalId) ...[
                _editableField(
                  controller: _creaCtrl,
                  label: 'CREA / CFT',
                  hint: 'Número do registro',
                  hintColor: hintColor,
                  enabled: !_saving,
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    'Dados profissionais adicionais disponíveis apenas para consultor.',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _card(Color color, List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: children),
  );

  Widget _readonlyRow(String label, String value, Color hintColor) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: hintColor, fontSize: 14)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          ),
        ),
      ],
    ),
  );

  Widget _editableField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color hintColor,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: hintColor, fontSize: 14)),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: const TextStyle(color: _inputTextColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF636366),
                fontSize: 14,
              ),
              filled: true,
              fillColor: enabled
                  ? _inputFillColor
                  : _inputFillColor.withValues(alpha: 0.72),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _inputBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _inputBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF0A84FF),
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _inputBorderColor),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
