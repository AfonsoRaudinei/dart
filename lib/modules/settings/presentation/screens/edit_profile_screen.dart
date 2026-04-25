// ADR-032 — settings/presentation/screens/edit_profile_screen.dart
//
// Tela de edição do perfil do usuário.
// Aberta via Navigator.push — SEM rota nova no GoRouter.
//
// Campos somente leitura: email, role, data de cadastro
// Campos editáveis: fullName, phone, creaNumber
// Foto de perfil: fluxo existente em settings_repository.dart (não duplicado)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/user_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile initialProfile;

  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
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
    _phoneCtrl = TextEditingController(
      text: widget.initialProfile.phone ?? '',
    );
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
    final newFullName = _fullNameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();
    final newCrea = _creaCtrl.text.trim();

    // Montar mapa de campos realmente alterados: {campo: valorAntigo}
    final changedFields = <String, String?>{};
    if (newFullName != (original.fullName ?? '')) {
      changedFields['fullName'] =
          original.fullName?.isNotEmpty == true ? original.fullName : null;
    }
    if (newPhone != (original.phone ?? '')) {
      changedFields['phone'] =
          original.phone?.isNotEmpty == true ? original.phone : null;
    }
    if (newCrea != (original.creaNumber ?? '')) {
      changedFields['creaNumber'] =
          original.creaNumber?.isNotEmpty == true ? original.creaNumber : null;
    }

    // Nenhum campo mudou — fechar sem gravar
    if (changedFields.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final updated = original.copyWith(
      fullName: newFullName.isEmpty ? null : newFullName,
      phone: newPhone.isEmpty ? null : newPhone,
      creaNumber: newCrea.isEmpty ? null : newCrea,
      updatedAt: DateTime.now(),
    );

    setState(() => _saving = true);

    try {
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.updateProfile(
        updated: updated,
        changedFields: changedFields,
      );

      // Invalidar ambos os providers para forçar re-fetch
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(profileAuditTrailProvider);

      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
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

    final createdAtStr = DateFormat('dd/MM/yyyy').format(
      profile.createdAt.toLocal(),
    );

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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
              _readonlyRow(
                'Perfil',
                profile.role?.isNotEmpty == true ? profile.role! : '—',
                hintColor,
              ),
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
              _editableField(
                controller: _creaCtrl,
                label: 'CREA / CFT',
                hint: 'Número do registro',
                hintColor: hintColor,
                enabled: !_saving,
              ),
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
              child: Text(
                label,
                style: TextStyle(
                  color: hintColor,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                ),
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
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: TextStyle(
                  color: hintColor,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF636366),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
}
