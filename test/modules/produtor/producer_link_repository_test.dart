import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ProducerLinkRepository.createInvite error mapping', () {
    test('mapeia violação de RLS para orientação de sync/papel', () {
      final message = ProducerLinkRepository.mapCreateInviteError(
        const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );

      expect(message, contains('sincronizado'));
      expect(message, contains('consultor'));
    });

    test('mapeia FK ausente para cliente não sincronizado', () {
      final message = ProducerLinkRepository.mapCreateInviteError(
        const PostgrestException(
          message: 'insert or update on table violates foreign key constraint',
          code: '23503',
        ),
      );

      expect(message, contains('Sincronizar'));
    });
  });

  group('ProducerLinkRepository token helpers', () {
    test('normaliza token removendo espaços e padronizando caixa', () {
      expect(
        ProducerLinkRepository.normalizeToken(' sf-12ab  - 34cd '),
        'SF-12AB-34CD',
      );
    });

    test('hash é estável para variações de caixa e espaços', () {
      final a = ProducerLinkRepository.hashToken('SF-ABCD-1234-EF56');
      final b = ProducerLinkRepository.hashToken(' sf-abcd-1234-ef56 ');

      expect(a, b);
      expect(a, isNot(contains('ABCD')));
    });

    test('gera token no formato compartilhável', () {
      final token = ProducerLinkRepository.generateInviteToken(
        random: Random(7),
      );

      expect(
        token,
        matches(RegExp(r'^SF-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$')),
      );
    });
  });

  group('relatórios vinculados', () {
    test('usa relatorios_v2 como tabela remota do produtor', () {
      expect(ProducerLinkRepository.linkedReportsTable, 'relatorios_v2');
    });

    test('mapeia payload remoto de relatorios_v2', () {
      final report = ProducerLinkRepository.reportFromRemote({
        'id': 'report-1',
        'client_id': 'client-1',
        'titulo': 'Diagnóstico da safra',
        'created_at': '2026-06-12T10:00:00.000Z',
        'deleted_at': null,
      });

      expect(report.id, 'report-1');
      expect(report.title, 'Diagnóstico da safra');
      expect(report.farmName, 'Criado em 12/06/2026');
      expect(report.createdAt.toUtc(), DateTime.utc(2026, 6, 12, 10));
    });

    test('usa título técnico padrão quando titulo está vazio', () {
      final report = ProducerLinkRepository.reportFromRemote({
        'id': 'report-2',
        'client_id': 'client-1',
        'titulo': '   ',
        'created_at': '2026-06-12T10:00:00.000Z',
        'deleted_at': null,
      });

      expect(report.title, 'Relatório técnico');
    });
  });

  test('offline mantém o vínculo e a fazenda salva do produtor', () {
    final now = DateTime.utc(2026, 6, 1);
    final link = ProducerClientLink(
      id: 'link-1',
      consultorUserId: 'consultor-1',
      clientId: 'produtor-1',
      producerUserId: 'produtor-1',
      status: 'active',
      expiresAt: now.add(const Duration(days: 7)),
      usedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final client = ProducerLinkRepository.linkedClientFromLocalRows(
      link: link,
      clientRow: {
        'id': 'produtor-1',
        'nome': 'Sítio Boa Vista',
        'telefone': '62999990000',
        'cidade': 'Rio Verde',
        'uf': 'GO',
      },
      farmRows: [
        {
          'id': 'farm-1',
          'nome': 'Fazenda Norte',
          'municipio': 'Rio Verde',
          'uf': 'GO',
          'area_total': 120.5,
        },
      ],
      fieldRows: [
        {
          'id': 'field-1',
          'fazenda_id': 'farm-1',
          'nome': 'Talhão A',
          'area_produtiva': 40,
        },
      ],
    );

    expect(client.link.clientId, 'produtor-1');
    expect(client.name, 'Sítio Boa Vista');
    expect(client.farms, hasLength(1));
    expect(client.farms.single.name, 'Fazenda Norte');
    expect(client.farms.single.fields.single.name, 'Talhão A');
    expect(client.farms.single.fields.single.areaHa, 40);
  });
}
