import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../clients/presentation/providers/clients_providers.dart';
import '../../domain/report_model.dart';
import '../providers/reports_providers.dart';

class ReportDetailScreen extends ConsumerWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  Future<void> _generateAndDownloadPdf(
    BuildContext context,
    Report report,
    String clientName,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Divider(),
              pw.Text(
                'Autor: ${report.author}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Gerado em: ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    report.title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Cliente: $clientName',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Tipo: ${report.typeDisplayName}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'Período: ${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(report.content, style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            if (report.images.isNotEmpty)
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: report.images.map((path) {
                  return pw.Container(
                    width: 200,
                    height: 200,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Center(child: pw.Text('Imagem (Placeholder)')),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 20),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_${report.title}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: SafeArea(
        child: reportAsync.when(
          data: (report) {
            if (report == null) {
              return const Center(child: Text('Relatório não encontrado'));
            }

            final clientAsync = ref.watch(
              clientDetailProvider(report.clientId),
            );

            return clientAsync.when(
              data: (client) {
                final clientName = client?.name ?? 'Cliente Desconhecido';
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Customizado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Detalhes',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.black,
                              size: 28,
                            ),
                            onPressed: () {
                              _generateAndDownloadPdf(
                                context,
                                report,
                                clientName,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Resto do conteúdo
                      // Title
                      Text(
                        report.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(label: Text(report.typeDisplayName)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cliente: $clientName',
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Período: ${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const Divider(height: 32),

                      // Body
                      Text(
                        report.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),

                      // Images
                      if (report.images.isNotEmpty) ...[
                        Text(
                          'Anexos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: report.images.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(report.images[index]),
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 200,
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Footer
                      const Divider(),
                      Text(
                        'Autor: ${report.author}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Criado em: ${dateFormat.format(report.createdAt)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Text('Erro ao carregar dados do cliente'),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro: $err')),
        ),
      ),
    );
  }
}
