import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../../domain/entities/feedback_type.dart';
import '../controllers/feedback_controller.dart';
import '../widgets/feedback_stats_card.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _messageController = TextEditingController();
  FeedbackType? _selectedType;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      ref
          .read(feedbackControllerProvider.notifier)
          .submitFeedback(
            type: _selectedType!,
            message: _messageController.text,
          );
    } else if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de feedback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch state
    final formState = ref.watch(feedbackControllerProvider);
    final statsAsync = ref.watch(feedbackStatsProvider);

    // Header Color (using Map-First consistency or white)
    const backgroundColor = Color(0xFFF5F7FA); // Light gray background

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: formState.isSuccess
            ? _buildSuccessView()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => context.go(AppRoutes.map),
                    ),
                    const SizedBox(height: 24),

                    // Header
                    Text('Feedback', style: SoloTextStyles.headingLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Ajude-nos a melhorar o SoloForte',
                      style: SoloTextStyles.body,
                    ),
                    const SizedBox(height: 32),

                    // Stats Section
                    const Text(
                      'Resumo de Feedbacks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    statsAsync.when(
                      data: (stats) => Row(
                        children: [
                          FeedbackStatsCard(
                            label: 'Bug',
                            count: stats.bugCount,
                            icon: Icons.bug_report_outlined,
                            color: SoloForteColors.textError,
                            backgroundColor: SoloForteColors.bgError,
                          ),
                          FeedbackStatsCard(
                            label: 'Sugestão',
                            count: stats.suggestionCount,
                            icon: Icons.lightbulb_outline,
                            color: SoloForteColors.textWarning,
                            backgroundColor: SoloForteColors.bgWarning,
                          ),
                          FeedbackStatsCard(
                            label: 'Elogios',
                            count: stats.praiseCount,
                            icon: Icons.favorite_border,
                            color: SoloForteColors.textSuccess,
                            backgroundColor: SoloForteColors.bgSuccess,
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 120, // Approximate height of cards
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      error: (_, __) => const SizedBox(
                        height: 120,
                        child: Center(child: Text('Erro ao carregar dados')),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enviar Feedback',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Type Selector
                            const Text(
                              'Tipo de Feedback',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTypeDropdown(),

                            const SizedBox(height: 24),

                            // Message Input
                            const Text(
                              'Sua mensagem',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _messageController,
                              maxLines: 5,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: 'Compartilhe sua experiência...',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F7FA),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, escreva sua mensagem';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: formState.isSubmitting
                                    ? null
                                    : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SoloForteColors.blueSamsung,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: formState.isSubmitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Enviar Feedback',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            if (formState.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  formState.errorMessage!,
                                  style: const TextStyle(
                                    color: SoloForteColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FeedbackType>(
          value: _selectedType,
          hint: const Text('Selecione o tipo'),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: FeedbackType.values.map((type) {
            IconData icon;
            Color color;
            switch (type) {
              case FeedbackType.bug:
                icon = Icons.bug_report_outlined;
                color = SoloForteColors.textError;
                break;
              case FeedbackType.suggestion:
                icon = Icons.lightbulb_outline;
                color = SoloForteColors.textWarning;
                break;
              case FeedbackType.praise:
                icon = Icons.favorite_border;
                color = SoloForteColors.textSuccess;
                break;
            }

            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Text(type.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value;
            });
          },
        ),
      ),
    );
  }

  // Phase 4: Success View
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SoloForteColors.bgSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: SoloForteColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Obrigado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seu feedback foi enviado com sucesso. Ele é muito importante para nós!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF86868B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  // Reset form to send another or go back
                  // Design suggests just being done, but let's allow going back or resetting
                  // For now, let's reset internal state to allow new submission or just go back
                  // But the user might want to leave.
                  // Let's offer "Back to Home"
                  context.go(AppRoutes.map);
                  // Ensure state is reset next time we visit
                  ref.read(feedbackControllerProvider.notifier).reset();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: SoloForteColors.blueSamsung),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Voltar ao Mapa'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(feedbackControllerProvider.notifier).reset();
                setState(() {
                  _selectedType = null;
                  _messageController.clear();
                });
              },
              child: const Text("Enviar outro feedback"),
            ),
          ],
        ),
      ),
    );
  }
}
