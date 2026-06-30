import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_routes.dart';
import '../models/publicacao_tema.dart';
import '../providers/publicacao_providers.dart';
import '../use_cases/create_publicacao_use_case.dart';
import '../../../../core/constants/layout_constants.dart';

/// Tela de Criação de Publicação Técnica — PASSO 4
///
/// Rota: [AppRoutes.publicacaoNova] (/consultoria/publicacoes/nova)
///
/// Formulário de criação com validação.
/// Navegação: sem AppBar. SmartButton global cuida do retorno.
class PublicacaoFormScreen extends ConsumerStatefulWidget {
  const PublicacaoFormScreen({super.key});

  @override
  ConsumerState<PublicacaoFormScreen> createState() =>
      _PublicacaoFormScreenState();
}

class _PublicacaoFormScreenState extends ConsumerState<PublicacaoFormScreen> {
  final _tituloController = TextEditingController();
  final _conteudoController = TextEditingController();
  final _safraController = TextEditingController();

  PublicacaoTema? _selectedTema;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    _safraController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _tituloController.text.trim().isNotEmpty &&
      _conteudoController.text.trim().isNotEmpty &&
      _selectedTema != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildForm(),
            _buildPublishButton(),
            const SliverToBoxAdapter(child: SizedBox(height: kFabSafeArea)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Text(
          'Nova Publicação',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo Tema
            const Text(
              'Tema',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TemaChip(
                  label: 'Praga',
                  tema: PublicacaoTema.praga,
                  selected: _selectedTema == PublicacaoTema.praga,
                  onTap: () =>
                      setState(() => _selectedTema = PublicacaoTema.praga),
                ),
                _TemaChip(
                  label: 'Doença',
                  tema: PublicacaoTema.doenca,
                  selected: _selectedTema == PublicacaoTema.doenca,
                  onTap: () =>
                      setState(() => _selectedTema = PublicacaoTema.doenca),
                ),
                _TemaChip(
                  label: 'Solo',
                  tema: PublicacaoTema.solo,
                  selected: _selectedTema == PublicacaoTema.solo,
                  onTap: () =>
                      setState(() => _selectedTema = PublicacaoTema.solo),
                ),
                _TemaChip(
                  label: 'Fenologia',
                  tema: PublicacaoTema.fenologia,
                  selected: _selectedTema == PublicacaoTema.fenologia,
                  onTap: () =>
                      setState(() => _selectedTema = PublicacaoTema.fenologia),
                ),
                _TemaChip(
                  label: 'Recomendação',
                  tema: PublicacaoTema.recomendacao,
                  selected: _selectedTema == PublicacaoTema.recomendacao,
                  onTap: () => setState(
                    () => _selectedTema = PublicacaoTema.recomendacao,
                  ),
                ),
                _TemaChip(
                  label: 'Outro',
                  tema: PublicacaoTema.outro,
                  selected: _selectedTema == PublicacaoTema.outro,
                  onTap: () =>
                      setState(() => _selectedTema = PublicacaoTema.outro),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo Título
            const Text(
              'Título',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                hintText: 'Ex: Alerta de percevejo-marrom na safra 24/25',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A56DB),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Campo Conteúdo
            const Text(
              'Conteúdo técnico',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _conteudoController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Descreva as observações, recomendações ou alertas técnicos...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A56DB),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Campo Safra (opcional)
            const Text(
              'Safra (opcional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _safraController,
              decoration: InputDecoration(
                hintText: 'Ex: 2024-2025',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A56DB),
                    width: 2,
                  ),
                ),
              ),
            ),

            // Mensagem de erro
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: FilledButton(
          onPressed: (_isValid && !_isSubmitting) ? _publish : null,
          style: FilledButton.styleFrom(
            backgroundColor: (_isValid && !_isSubmitting)
                ? const Color(0xFF1A56DB)
                : const Color(0xFFD1D5DB),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'PUBLICAR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (!_isValid || _isSubmitting) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authorId = Supabase.instance.client.auth.currentUser?.id ?? '';

      if (authorId.isEmpty) {
        throw Exception('Usuário não autenticado');
      }

      final input = CreatePublicacaoInput(
        authorId: authorId,
        tema: _selectedTema!,
        titulo: _tituloController.text.trim(),
        conteudo: _conteudoController.text.trim(),
        visibility: PublicacaoVisibility.publica,
        safra: _safraController.text.trim().isNotEmpty
            ? _safraController.text.trim()
            : null,
      );

      await ref.read(createPublicacaoProvider(input).future);
      if (!mounted) return; // ← Guard obrigatório antes de usar ref
      ref.invalidate(publicacoesListProvider);

      if (mounted) {
        context.go('/consultoria/publicacoes');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicação criada com sucesso!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Erro ao publicar. Tente novamente.';
        });
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════════════
// COMPONENTES PRIVADOS
// ════════════════════════════════════════════════════════════════════════

class _TemaChip extends StatelessWidget {
  const _TemaChip({
    required this.label,
    required this.tema,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PublicacaoTema tema;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A56DB) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF1A56DB) : const Color(0xFFD1D5DB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}
