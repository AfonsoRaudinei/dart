import 'package:flutter/material.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/contracts/agenda_ai_recommendation_context.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_launcher_provider.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_recommendation_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_visit_writer_provider.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_analytics.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/agenda_ai/data/services/agenda_ai_service.dart';

Future<void> showAgendaAiSheet(BuildContext context) {
  return showSoloForteSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: false,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.none,
    builder: (_) => const _AgendaAiSheet(),
  );
}

class _AgendaAiSheet extends ConsumerStatefulWidget {
  const _AgendaAiSheet();

  @override
  ConsumerState<_AgendaAiSheet> createState() => _AgendaAiSheetState();
}

class _AgendaAiSheetState extends ConsumerState<_AgendaAiSheet> {
  final _service = AgendaAiService(Supabase.instance.client);
  final _chatController = TextEditingController();

  bool _loading = true;
  bool _creatingVisit = false;
  String? _error;

  List<Map<String, dynamic>> _recommendations = const [];
  final List<_ChatMsg> _chat = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations({String? chatMessage}) async {
    final stopwatch = Stopwatch()..start();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = await _buildPayload(chatMessage: chatMessage);

      final data = await _service.recommend(payload: payload);
      final recs = (data['recommendations'] as List<dynamic>? ?? [])
          .map(
            (e) => e is Map<String, dynamic>
                ? e
                : (e as Map).map((k, v) => MapEntry(k.toString(), v)),
          )
          .toList(growable: false);

      final aiMap = (data['ai'] is Map)
          ? (data['ai'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : null;

      setState(() {
        _recommendations = recs;
        if (aiMap != null &&
            aiMap['enabled'] == true &&
            aiMap['text'] is String) {
          _chat.add(_ChatMsg(text: aiMap['text'] as String, isUser: false));
        } else if (aiMap != null &&
            aiMap['reason'] is String &&
            chatMessage != null) {
          _chat.add(_ChatMsg(text: aiMap['reason'] as String, isUser: false));
        }
      });

      final userId = LocalSessionIdentity.resolveUserId();
      if (userId.isNotEmpty) {
        FeatureFlagAnalytics.trackAgendaAiRecommendationLoaded(
          userId: userId,
          recommendationCount: recs.length,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }
    } catch (e) {
      if (e is _AgendaAiUserMessageException) {
        setState(() {
          _error = e.message;
        });
        return;
      }
      if (e is StateError) {
        setState(() {
          _error = e.message;
        });
        return;
      }

      FeatureFlagAnalytics.trackAgendaAiError(
        errorType: 'recommendation_load_error',
        errorMessage: e.toString(),
      );
      setState(() {
        _error = 'Não foi possível carregar sugestões da IA.';
      });
    } finally {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _buildPayload({String? chatMessage}) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      throw const _AgendaAiUserMessageException(
        'Faça login novamente para usar o assistente IA.',
      );
    }

    final contextSnapshot = await ref
        .read(agendaAiRecommendationContextLookupProvider)
        .buildForUser(userId);

    final launchContext = ref.read(agendaAiLaunchContextProvider);

    final opportunities = contextSnapshot.opportunities
        .map(
          (item) => {
            'clientId': item.clientId,
            'clientName': item.clientName,
            'city': '',
            'location': null,
            'categoryId': item.categoryId,
            'categoryProgressPercent': item.categoryProgressPercent,
            'categoryAchievedValue': item.categoryAchievedValue,
            'lastVisitAt': item.lastVisitAt?.toUtc().toIso8601String(),
          },
        )
        .toList(growable: false);

    return {
      'consultantId': userId,
      'currentCity': launchContext?.city,
      'currentLocation': launchContext?.locationPayload,
      'targetCategoryId': contextSnapshot.targetCategoryId,
      'annualTargetValue': contextSnapshot.annualTargetValue,
      'annualAchievedValue': contextSnapshot.annualAchievedValue,
      'opportunities': opportunities,
      'policy': {
        'topN': 1,
        'prioritizeSameCity': true,
        'maxDistanceKm': 50,
        'cooldownDays': 7,
      },
      'useAiExplanation': true,
      if (chatMessage != null && chatMessage.trim().isNotEmpty)
        'chatMessage': chatMessage.trim(),
    };
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _loading) return;

    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isNotEmpty) {
      FeatureFlagAnalytics.trackAgendaAiChatAsked(
        userId: userId,
        messageLength: text.length,
      );
    }

    setState(() {
      _chat.add(_ChatMsg(text: text, isUser: true));
      _chatController.clear();
    });

    await _loadRecommendations(chatMessage: text);
  }

  Future<void> _createVisitFromRecommendation(Map<String, dynamic> rec) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Criar visita sugerida?'),
        content: Text(
          'Deseja criar uma visita para ${rec['clientName'] ?? 'Cliente'} agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _creatingVisit = true);

    try {
      final now = DateTime.now();
      final start = now.add(const Duration(hours: 1));
      final end = start.add(const Duration(hours: 1));

      await ref.read(agendaAiVisitWriterProvider).createSuggestedVisit(
        AgendaAiSuggestedVisitRequest(
          clientId: rec['clientId'] as String,
          clientName: rec['clientName'] as String? ?? 'Cliente',
          titulo: 'Visita sugerida IA • ${rec['clientName'] ?? 'Cliente'}',
          dataInicioPlanejada: start,
          dataFimPlanejada: end,
          currentUserId: LocalSessionIdentity.resolveUserId(),
        ),
      );

      if (!mounted) return;
      final userId = LocalSessionIdentity.resolveUserId();
      if (userId.isNotEmpty) {
        FeatureFlagAnalytics.trackAgendaAiVisitCreated(
          userId: userId,
          success: true,
          clientId: rec['clientId']?.toString(),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visita criada com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      final userId = LocalSessionIdentity.resolveUserId();
      if (userId.isNotEmpty) {
        FeatureFlagAnalytics.trackAgendaAiVisitCreated(
          userId: userId,
          success: false,
          clientId: rec['clientId']?.toString(),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao criar visita sugerida.')),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingVisit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.86;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF34C759)),
                SizedBox(width: 8),
                Text(
                  'Assistente IA • Agenda + Carteira',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const Text(
                        'Sugestão de visita',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_recommendations.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Sem sugestão elegível no momento.'),
                          ),
                        )
                      else
                        ..._recommendations.map(
                          (rec) => Card(
                            child: ListTile(
                              title: Text(
                                rec['clientName'] as String? ?? 'Cliente',
                              ),
                              subtitle: Text(rec['reason'] as String? ?? ''),
                              trailing: _creatingVisit
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.add_task),
                                      onPressed: () =>
                                          _createVisitFromRecommendation(rec),
                                    ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chat rápido',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_chat.isEmpty)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Pergunte algo sobre a sugestão e próximos passos.',
                                ),
                              )
                            else
                              ..._chat.map(
                                (m) => Align(
                                  alignment: m.isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: m.isUser
                                          ? const Color(0xFFE7F7EC)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(m.text),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatController,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Ex: qual abordagem usar nessa visita?',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF8E8E93),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFF2C2C2E),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _sendChat(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _sendChat,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Enviar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;

  _ChatMsg({required this.text, required this.isUser});
}

class _AgendaAiUserMessageException implements Exception {
  final String message;

  const _AgendaAiUserMessageException(this.message);
}
