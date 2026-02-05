import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // For calls/whatsapp
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../providers/clients_providers.dart';
import '../../../../../core/router/app_routes.dart';

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: clientAsync.when(
        data: (client) {
          if (client == null) {
            return const Center(child: Text("Cliente não encontrado"));
          }
          return Column(
            children: [
              // Custom Header (No AppBar)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          client.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Balance the back button for optical centering
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Photo & Basic Info
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                foregroundImage: client.photoPath != null
                                    ? NetworkImage(client.photoPath!)
                                    : null,
                                child: Text(
                                  client.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                client.city,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                client.state,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(
                              icon: Icons.phone,
                              label: 'Ligar',
                              onTap: () => _launchURL('tel:${client.phone}'),
                            ),
                            _ActionButton(
                              icon: Icons.chat, // WhatsApp
                              label: 'WhatsApp',
                              onTap: () {
                                // Simple whatsapp link for demo
                                _launchURL(
                                  'https://wa.me/55${client.phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                                );
                              },
                            ),
                            _ActionButton(
                              icon: Icons.report,
                              label: 'Relatórios',
                              onTap: () {
                                // Navigate to reports if needed, or show toast
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Funcionalidade de Relatórios em breve',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Counters
                        Row(
                          children: [
                            Expanded(
                              child: _CounterCard(
                                label: 'Relatórios',
                                count: '12',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _CounterCard(
                                label: 'Ocorrências',
                                count: '5',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Farms List
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fazendas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Adicionar Fazenda: Em breve',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add,
                                color: SoloForteColors.greenIOS,
                              ),
                              label: const Text(
                                'Nova',
                                style: TextStyle(
                                  color: SoloForteColors.greenIOS,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (client.farms.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50], // Very light gray
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.agriculture,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma fazenda cadastrada',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        else
                          ...client.farms.map(
                            (farm) => _FarmItem(
                              name: farm.name,
                              area: '${farm.totalAreaHa} ha',
                              onTap: () {
                                context.go(
                                  AppRoutes.farmDetail(client.id, farm.id),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erro: $err")),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // debugPrint('Could not launch $url');
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black, // Premium feel
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String label;
  final String count;

  const _CounterCard({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}

class _FarmItem extends StatelessWidget {
  final String name;
  final String area;
  final VoidCallback? onTap;

  const _FarmItem({required this.name, required this.area, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(area, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
