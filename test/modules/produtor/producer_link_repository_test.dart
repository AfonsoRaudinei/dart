import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/producer_invite_dialog.dart';
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
        ProducerLinkRepository.normalizeToken(' sf-abcd  - 1234 - ef56 '),
        'SF-ABCD-1234-EF56',
      );
    });

    test('extrai token da mensagem completa do WhatsApp', () {
      final message = ProducerInviteDialog.shareMessage(
        clientName: 'Jonathan',
        token: 'SF-ABCD-1234-EF56',
      );

      expect(
        ProducerLinkRepository.normalizeToken(message),
        'SF-ABCD-1234-EF56',
      );
    });

    test('texto sem código SF rejeita com orientação clara', () {
      expect(
        () => ProducerLinkRepository.normalizeToken('cole o token aqui'),
        throwsFormatException,
      );
    });

    test('hash é estável para variações de caixa e espaços', () {
      final a = ProducerLinkRepository.hashToken('SF-ABCD-1234-EF56');
      final b = ProducerLinkRepository.hashToken(' sf-abcd-1234-ef56 ');

      expect(a, b);
      expect(a, isNot(contains('ABCD')));
    });

    test('linha retornada pelo RPC pode vir em lista', () {
      final map = ProducerLinkRepository.linkRowFromRpc([
        {'id': 'link-1', 'status': 'active'},
      ]);

      expect(map, isNotNull);
      expect(map!['id'], 'link-1');
    });

    test('mapeia erro de papel produtor na aceitação', () {
      final message = ProducerLinkRepository.mapAcceptTokenError(
        const PostgrestException(
          message: 'producer_role_required',
          code: 'P0001',
        ),
      );

      expect(message, contains('produtor'));
    });

    test('vínculo antigo sem colunas de escopo libera tudo', () {
      final link = ProducerClientLink.fromRemote({
        'id': 'link-1',
        'consultor_user_id': 'consultor-1',
        'client_id': 'client-1',
        'producer_user_id': 'produtor-1',
        'status': 'active',
        'expires_at': '2026-12-01T00:00:00.000Z',
        'used_at': null,
        'created_at': '2026-11-01T00:00:00.000Z',
        'updated_at': '2026-11-01T00:00:00.000Z',
      });

      expect(link.share.farms, isTrue);
      expect(link.share.fields, isTrue);
      expect(link.share.occurrences, isTrue);
      expect(link.share.reports, isTrue);
    });

    test('escopo falso no remoto permanece falso', () {
      final link = ProducerClientLink.fromRemote({
        'id': 'link-1',
        'consultor_user_id': 'consultor-1',
        'client_id': 'client-1',
        'producer_user_id': null,
        'status': 'pending',
        'expires_at': '2026-12-01T00:00:00.000Z',
        'used_at': null,
        'created_at': '2026-11-01T00:00:00.000Z',
        'updated_at': '2026-11-01T00:00:00.000Z',
        'share_farms': false,
        'share_fields': true,
        'share_occurrences': false,
        'share_reports': true,
      });

      expect(link.share.farms, isFalse);
      expect(link.share.fields, isTrue);
      expect(link.share.occurrences, isFalse);
      expect(link.share.reports, isTrue);
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
          'bordadura_geo':
              '{"type":"Polygon","coordinates":[[[-48.0,-10.0],[-48.0,-10.1],[-47.9,-10.1],[-48.0,-10.0]]]}',
        },
      ],
    );

    expect(client.link.clientId, 'produtor-1');
    expect(client.name, 'Sítio Boa Vista');
    expect(client.farms, hasLength(1));
    expect(client.farms.single.name, 'Fazenda Norte');
    expect(client.farms.single.fields.single.name, 'Talhão A');
    expect(client.farms.single.fields.single.areaHa, 40);
    expect(client.farms.single.fields.single.hasGeometry, isTrue);
  });

  test('ocorrência remota usa a descrição e, sem ela, a categoria', () {
    final withDescription = ProducerLinkRepository.occurrenceFromRemote({
      'id': 'occ-1',
      'description': 'Ferrugem na bordadura',
      'category': 'doenca',
      'created_at': '2026-06-12T10:00:00.000Z',
      'latitude': -10.5,
      'longitude': -48.2,
    });

    expect(withDescription, isNotNull);
    expect(withDescription!.title, 'Ferrugem na bordadura');
    expect(withDescription.hasLocation, isTrue);

    final categoryOnly = ProducerLinkRepository.occurrenceTitle({
      'description': '   ',
      'category': 'area_visitada',
    });
    expect(categoryOnly, 'Área visitada');
  });

  test('leitura de vínculo ativo não corta pelo vencimento do token', () {
    final source = File(
      'lib/modules/produtor/data/producer_link_repository.dart',
    ).readAsStringSync();

    expect(source, isNot(contains(".gt('expires_at'")));
    expect(source, isNot(contains('expiresAt.toUtc().isAfter')));
    expect(source, contains("eq('status', 'active')"));
  });

  test('vínculo ativo antigo continua na leitura mesmo com token vencido', () {
    final expired = DateTime.utc(2020, 1, 1);
    final link = ProducerClientLink(
      id: 'link-old',
      consultorUserId: 'consultor-1',
      clientId: 'client-1',
      producerUserId: 'produtor-1',
      status: 'active',
      expiresAt: expired,
      usedAt: expired,
      createdAt: expired,
      updatedAt: expired,
    );

    final client = ProducerLinkRepository.linkedClientFromLocalRows(
      link: link,
      clientRow: {'nome': 'Jonathan'},
    );

    expect(client.link.status, 'active');
    expect(client.link.expiresAt.isBefore(DateTime.utc(2026, 1, 1)), isTrue);
  });
}
