import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/data/map_repository.dart';
import 'package:soloforte_app/core/domain/publicacao.dart';
import 'package:soloforte_app/core/state/map_state.dart';

// ════════════════════════════════════════════════════════════════════
// TELA DE EDIÇÃO DE PUBLICAÇÃO (ADR-007)
// ════════════════════════════════════════════════════════════════════

class PublicacaoEditorScreen extends ConsumerStatefulWidget {
  final String publicacaoId;

  const PublicacaoEditorScreen({super.key, required this.publicacaoId});

  @override
  ConsumerState<PublicacaoEditorScreen> createState() =>
      _PublicacaoEditorScreenState();
}

class _PublicacaoEditorScreenState
    extends ConsumerState<PublicacaoEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late final MapRepository _repository;

  bool _isLoading = true;
  bool _isSaving = false;
  Publicacao? _publicacao;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _repository = ref.read(mapRepositoryProvider);
    _loadPublicacao();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicacao() async {
    try {
      final publicacao = await _repository.getPublicacaoById(
        widget.publicacaoId,
      );
      if (!mounted) return;

      if (publicacao == null) {
        setState(() {
          _errorMessage = 'Publicação não encontrada.';
          _isLoading = false;
        });
        return;
      }

      _titleController.text = publicacao.title ?? '';
      _descriptionController.text = publicacao.description ?? '';
      setState(() {
        _publicacao = publicacao;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar a publicação.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final publicacao = _publicacao;
    if (publicacao == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await _repository.updatePublicacao(
        publicacao.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        ),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicação salva com sucesso!'),
          backgroundColor: PremiumTokens.brandGreen,
        ),
      );

      context.go('/map');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a publicação.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: PremiumTokens.brandGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Publicação'),
          backgroundColor: Colors.white,
          foregroundColor: PremiumTokens.textPrimaryLight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.go('/map'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PremiumTokens.textSecondaryLight),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Publicação'),
        backgroundColor: Colors.white,
        foregroundColor: PremiumTokens.textPrimaryLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PremiumTokens.brandGreen,
                    ),
                  )
                : const Text(
                    'Salvar',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PremiumTokens.surfaceLight,
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: PremiumTokens.textTertiaryLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID: ${widget.publicacaoId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PremiumTokens.textSecondaryLight,
                      ).copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Título
            const Text(
              'Título',
              style: TextStyle(
                fontSize: 12,
                color: PremiumTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Título da publicação',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: PremiumTokens.hairlineLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: PremiumTokens.brandGreen,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Descrição
            const Text(
              'Descrição',
              style: TextStyle(
                fontSize: 12,
                color: PremiumTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Descrição da publicação',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: PremiumTokens.hairlineLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: PremiumTokens.brandGreen,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fotos
            const Text(
              'Fotos',
              style: TextStyle(
                fontSize: 12,
                color: PremiumTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: PremiumTokens.surfaceLight,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: PremiumTokens.hairlineLight),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: PremiumTokens.textTertiaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicionar fotos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: PremiumTokens.textSecondaryLight,
                      ).copyWith(color: PremiumTokens.textTertiaryLight),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kFabSafeArea),
          ],
        ),
      ),
    );
  }
}
