import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../ui/theme/soloforte_theme.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  String _category = 'geral';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (AppConfig.hasSupabaseConfig &&
          Supabase.instance.client.auth.currentUser != null) {
        await Supabase.instance.client.from('feedback').insert({
          'user_id': Supabase.instance.client.auth.currentUser!.id,
          'category': _category,
          'message': _messageCtrl.text.trim(),
          'app_version': '1.0.0',
        });
      } else {
        final subject = Uri.encodeComponent('Feedback SoloForte — $_category');
        final body = Uri.encodeComponent(_messageCtrl.text.trim());
        final uri = Uri.parse(
          'mailto:${AppConfig.lgpdContactEmail}?subject=$subject&body=$body',
        );
        if (!await launchUrl(uri)) {
          throw Exception('Não foi possível abrir o cliente de e-mail.');
        }
      }

      if (mounted) {
        _messageCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback enviado. Obrigado!')),
        );
      }
    } catch (e) {
      appLog('Feedback error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Feedback', style: SoloTextStyles.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Conte sua experiência ou reporte um problema.',
                style: SoloTextStyles.label,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: const [
                  DropdownMenuItem(value: 'geral', child: Text('Geral')),
                  DropdownMenuItem(value: 'bug', child: Text('Bug / Erro')),
                  DropdownMenuItem(
                    value: 'sugestao',
                    child: Text('Sugestão'),
                  ),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'geral'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Mensagem',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Descreva com pelo menos 10 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
