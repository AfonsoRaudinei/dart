import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/domain/publicacao.dart';
import '../theme/soloforte_theme.dart';

// ════════════════════════════════════════════════════════════════════
// TELA DE EDIÇÃO DE PUBLICAÇÃO (ADR-007)
// ════════════════════════════════════════════════════════════════════

class PublicacaoEditorScreen extends StatefulWidget {
  final String publicacaoId;

  const PublicacaoEditorScreen({
    super.key,
    required this.publicacaoId,
  });

  @override
  State<PublicacaoEditorScreen> createState() =>
      _PublicacaoEditorScreenState();
}

class _PublicacaoEditorScreenState
    extends State<PublicacaoEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  bool _isLoading = true;

  Publicacao? _publicacao;

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
        backgroundColor: SoloForteColors.greenIOS,
      ),
    );

    context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: SoloForteColors.greenIOS,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Publicação'),
        backgroundColor: SoloForteColors.white,
        foregroundColor: SoloForteColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/map');
          },
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: SoloForteColors.greenIOS,
                fontWeight: SoloFontWeights.semibold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: SoloSpacing.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SoloForteColors.grayLight,
                borderRadius:
                    BorderRadius.circular(SoloRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: SoloForteColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID: ${widget.publicacaoId}',
                      style: SoloTextStyles.label.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Título
            Text(
              'Título',
              style: SoloTextStyles.label,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Título da publicação',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(SoloRadius.md),
                  borderSide: const BorderSide(
                    color: SoloForteColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(SoloRadius.md),
                  borderSide: const BorderSide(
                    color: SoloForteColors.greenIOS,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Descrição
            Text(
              'Descrição',
              style: SoloTextStyles.label,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Descrição da publicação',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(SoloRadius.md),
                  borderSide: const BorderSide(
                    color: SoloForteColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(SoloRadius.md),
                  borderSide: const BorderSide(
                    color: SoloForteColors.greenIOS,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fotos
            Text(
              'Fotos',
              style: SoloTextStyles.label,
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: SoloForteColors.grayLight,
                borderRadius:
                    BorderRadius.circular(SoloRadius.md),
                border: Border.all(
                  color: SoloForteColors.borderLight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color:
                          SoloForteColors.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adicionar fotos',
                      style: SoloTextStyles.label.copyWith(
                        color:
                            SoloForteColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
