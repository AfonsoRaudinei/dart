import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';

// ════════════════════════════════════════════════════════════════════
// TELA DE EDIÇÃO DE PUBLICAÇÃO (ADR-007)
// ════════════════════════════════════════════════════════════════════

class PublicacaoEditorScreen extends StatefulWidget {
  final String publicacaoId;

  const PublicacaoEditorScreen({super.key, required this.publicacaoId});

  @override
  State<PublicacaoEditorScreen> createState() => _PublicacaoEditorScreenState();
}

class _PublicacaoEditorScreenState extends State<PublicacaoEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadPublicacao();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicacao() async {
    // TODO: carregar via repositório real
    setState(() => _isLoading = false);
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Publicação salva com sucesso!'),
        backgroundColor: PremiumTokens.brandGreen,
      ),
    );

    context.go('/map');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Publicação'),
        backgroundColor: Colors.white,
        foregroundColor: PremiumTokens.textPrimaryLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text(
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
                      style: const TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight).copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Título
            const Text('Título', style: TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight)),
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
            const Text('Descrição', style: TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight)),
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
            const Text('Fotos', style: TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight)),
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
                      style: const TextStyle(fontSize: 12, color: PremiumTokens.textSecondaryLight).copyWith(
                        color: PremiumTokens.textTertiaryLight,
                      ),
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
