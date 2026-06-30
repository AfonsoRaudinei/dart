import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/feedback_impact.dart';
import '../../domain/entities/feedback_module.dart';
import '../../domain/entities/feedback_type.dart';
import '../controllers/feedback_controller.dart';
import '../widgets/feedback_suggestions_chart.dart';
import '../widgets/feedback_stats_card.dart';

const _supportEmail = 'raudyneyb@icloud.com';
const _messageMaxLength = 500;
const _messageMinLength = 12;

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _messageController = TextEditingController();
  FeedbackType? _selectedType;
  FeedbackModule? _selectedModule;
  FeedbackImpact? _selectedImpact;
  final _formKey = GlobalKey<FormState>();
  int _messageLength = 0;

  static const _bugColor = Color(0xFFDC2626);
  static const _bugBackground = Color(0xFFFFEBEB);
  static const _suggestionColor = Color(0xFF92400E);
  static const _suggestionBackground = Color(0xFFFFF3CD);
  static const _praiseColor = Color(0xFF065F46);
  static const _praiseBackground = Color(0xFFD1FAE5);

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(
        () => _messageLength = _messageController.text.characters.length,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      ref
          .read(feedbackControllerProvider.notifier)
          .submitFeedback(
            type: _selectedType!,
            module: _selectedModule!,
            impact: _selectedImpact!,
            message: _messageController.text,
          );
    }
  }

  Future<void> _openSupportEmail() async {
    final subject = Uri.encodeComponent('Feedback SoloForte');
    final body = Uri.encodeComponent(_messageController.text.trim());
    final uri = Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body');
    final didLaunch = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!didLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o app de e-mail')),
      );
    }
  }

  Widget _buildStatsUnavailableBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF9A3412)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Não foi possível carregar estatísticas agora. Você ainda pode enviar feedback normalmente.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  kFabSafeArea + MediaQuery.of(context).padding.bottom + 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Feedback',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conte o que precisa melhorar, o que deu errado ou o que funcionou bem.',
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    const SizedBox(height: 32),

                    // Stats Section
                    const Text(
                      'Seus feedbacks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    statsAsync.when(
                      data: (stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stats.isUnavailable) ...[
                            _buildStatsUnavailableBanner(),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              FeedbackStatsCard(
                                label: 'Bug',
                                count: stats.bugCount,
                                icon: Icons.bug_report_outlined,
                                color: _bugColor,
                                backgroundColor: _bugBackground,
                                isSelected: _selectedType == FeedbackType.bug,
                                onTap: () => setState(
                                  () => _selectedType = FeedbackType.bug,
                                ),
                              ),
                              FeedbackStatsCard(
                                label: 'Sugestão',
                                count: stats.suggestionCount,
                                icon: Icons.lightbulb_outline,
                                color: _suggestionColor,
                                backgroundColor: _suggestionBackground,
                                isSelected:
                                    _selectedType == FeedbackType.suggestion,
                                onTap: () => setState(
                                  () => _selectedType = FeedbackType.suggestion,
                                ),
                              ),
                              FeedbackStatsCard(
                                label: 'Elogios',
                                count: stats.praiseCount,
                                icon: Icons.favorite_border,
                                color: _praiseColor,
                                backgroundColor: _praiseBackground,
                                isSelected:
                                    _selectedType == FeedbackType.praise,
                                onTap: () => setState(
                                  () => _selectedType = FeedbackType.praise,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 120, // Approximate height of cards
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsUnavailableBanner(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FeedbackStatsCard(
                                label: 'Bug',
                                count: 0,
                                icon: Icons.bug_report_outlined,
                                color: _bugColor,
                                backgroundColor: _bugBackground,
                                isSelected: _selectedType == FeedbackType.bug,
                                onTap: () => setState(
                                  () => _selectedType = FeedbackType.bug,
                                ),
                              ),
                              FeedbackStatsCard(
                                label: 'Sugestão',
                                count: 0,
                                icon: Icons.lightbulb_outline,
                                color: _suggestionColor,
                                backgroundColor: _suggestionBackground,
                                isSelected:
                                    _selectedType == FeedbackType.suggestion,
                                onTap: () => setState(
                                  () => _selectedType = FeedbackType.suggestion,
                                ),
                              ),
                              FeedbackStatsCard(
                                label: 'Elogios',
                                count: 0,
                                icon: Icons.favorite_border,
                                color: _praiseColor,
                                backgroundColor: _praiseBackground,
                                isSelected:
                                    _selectedType == FeedbackType.praise,
                                onTap: () => setState(
                                  () => _selectedType = FeedbackType.praise,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Toque em um cartão ou selecione abaixo o tipo do feedback.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 24),
                    statsAsync.when(
                      data: (stats) => FeedbackSuggestionsChart(
                        suggestionsByModule: stats.suggestionsByModule,
                        isUnavailable: stats.isUnavailable,
                      ),
                      loading: () => const SizedBox(
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      error: (_, __) => const FeedbackSuggestionsChart(
                        suggestionsByModule: {},
                        isUnavailable: true,
                      ),
                    ),

                    const SizedBox(height: 28),

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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Enviar Feedback',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _openSupportEmail,
                                  icon: const Icon(
                                    Icons.alternate_email,
                                    size: 18,
                                  ),
                                  label: const Text('E-mail'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F62FE),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Canal direto: $_supportEmail',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
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

                            const Text(
                              'Onde aconteceu?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildModuleDropdown(),

                            const SizedBox(height: 24),

                            const Text(
                              'Impacto',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildImpactDropdown(),

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
                              minLines: 5,
                              maxLines: 7,
                              maxLength: _messageMaxLength,
                              textInputAction: TextInputAction.newline,
                              decoration: InputDecoration(
                                hintText:
                                    'Ex.: encontrei erro ao salvar uma visita, gostaria de filtro por safra...',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F62FE),
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F7FA),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              validator: (value) {
                                final length =
                                    value?.trim().characters.length ?? 0;
                                if (length == 0) {
                                  return 'Por favor, escreva sua mensagem';
                                }
                                if (length < _messageMinLength) {
                                  return 'Descreva um pouco mais para eu entender melhor';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$_messageLength/$_messageMaxLength',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
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
                                  backgroundColor: const Color(0xFF0F62FE),
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
                                    color: Color(0xFFFF3B30),
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
    return DropdownButtonFormField<FeedbackType>(
      initialValue: _selectedType,
      hint: const Text('Selecione o tipo'),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down),
      decoration: _dropdownDecoration(),
      validator: (value) =>
          value == null ? 'Selecione o tipo de feedback' : null,
      items: FeedbackType.values.map((type) {
        IconData icon;
        Color color;
        switch (type) {
          case FeedbackType.bug:
            icon = Icons.bug_report_outlined;
            color = const Color(0xFFDC2626);
          case FeedbackType.suggestion:
            icon = Icons.lightbulb_outline;
            color = const Color(0xFF92400E);
          case FeedbackType.praise:
            icon = Icons.favorite_border;
            color = const Color(0xFF065F46);
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
    );
  }

  Widget _buildModuleDropdown() {
    return DropdownButtonFormField<FeedbackModule>(
      initialValue: _selectedModule,
      hint: const Text('Selecione o módulo'),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down),
      decoration: _dropdownDecoration(),
      validator: (value) => value == null ? 'Selecione o módulo' : null,
      items: FeedbackModule.values.map((module) {
        return DropdownMenuItem(
          value: module,
          child: Row(
            children: [
              Icon(
                _moduleIcon(module),
                color: const Color(0xFF0F62FE),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  module.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedModule = value;
        });
      },
    );
  }

  Widget _buildImpactDropdown() {
    return DropdownButtonFormField<FeedbackImpact>(
      initialValue: _selectedImpact,
      hint: const Text('Selecione o impacto'),
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down),
      decoration: _dropdownDecoration(),
      validator: (value) => value == null ? 'Selecione o impacto' : null,
      items: FeedbackImpact.values.map((impact) {
        final color = _impactColor(impact);
        return DropdownMenuItem(
          value: impact,
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: color, size: 20),
              const SizedBox(width: 12),
              Text(impact.label),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedImpact = value;
        });
      },
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F62FE), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF3B30)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
      ),
    );
  }

  IconData _moduleIcon(FeedbackModule module) {
    switch (module) {
      case FeedbackModule.agenda:
        return Icons.calendar_month_outlined;
      case FeedbackModule.map:
        return Icons.map_outlined;
      case FeedbackModule.visits:
        return Icons.route_outlined;
      case FeedbackModule.consulting:
        return Icons.groups_outlined;
      case FeedbackModule.drawing:
        return Icons.polyline_outlined;
      case FeedbackModule.weather:
        return Icons.cloud_outlined;
      case FeedbackModule.wallet:
        return Icons.account_balance_wallet_outlined;
      case FeedbackModule.marketing:
        return Icons.campaign_outlined;
      case FeedbackModule.plans:
        return Icons.workspace_premium_outlined;
      case FeedbackModule.settingsLogin:
        return Icons.settings_outlined;
      case FeedbackModule.other:
        return Icons.more_horiz;
    }
  }

  Color _impactColor(FeedbackImpact impact) {
    switch (impact) {
      case FeedbackImpact.low:
        return const Color(0xFF065F46);
      case FeedbackImpact.medium:
        return const Color(0xFF92400E);
      case FeedbackImpact.high:
        return const Color(0xFFDC2626);
      case FeedbackImpact.critical:
        return const Color(0xFF7F1D1D);
    }
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
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF34C759),
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
              'Seu feedback foi enviado com sucesso. Se precisar complementar, use $_supportEmail.',
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
                  side: const BorderSide(color: Color(0xFF0F62FE)),
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
                  _selectedModule = null;
                  _selectedImpact = null;
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
