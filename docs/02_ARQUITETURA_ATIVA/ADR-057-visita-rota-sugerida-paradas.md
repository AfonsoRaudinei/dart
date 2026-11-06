# ADR-057 — Rota sugerida da visita (paradas)

**Data:** 05/11/2026  
**Status:** APROVADO  
**Módulos:** `visitas/`, `ui/` (host do mapa), `core/database`, `core/services/notification_service.dart`

## Contexto

Durante a visita ativa com talhão (`VisitSession.areaId`), o consultor precisa de uma
rota de paradas dentro do polígono — no espírito do Farmbox, com o nome
**Rota sugerida**. A ocorrência continua no bounded context `consultoria`. O mapa
não ganha sub-rota.

## Decisão

1. **Dono** — `visitas` gera e persiste a rota. O mapa só desenha.
2. **Geração** — Dart puro em `visitas/domain/visit_route_generator.dart`.
   Centróide do anel externo + Halton e grade no bbox, filtrados por
   `geoJsonContainsPoint`. Seleção pelo ponto mais distante, com separação
   mínima `lado_menor / (sqrt(N) + 1)`. N entre 3 e 12.
3. **Persistência local** — SQLite **v49** em `visit_sessions`:
   - `route_stops_json TEXT` — array `{index, lat, lng, status, occurrenceId?}`
   - `route_current_index INTEGER` — próxima parada pendente (1-based), null se
     não há rota ou a rota acabou
   Trocar fazenda ou talhão zera a rota. `saveRouteState` **não** altera
   `sync_status` nem `updated_at`. O payload do Supabase não inclui essas colunas.
4. **Mapa** — marcadores numerados em `lib/ui/components/map/visit_route_stop_markers.dart`
   (política 4A). Entrada no `VisitActiveCard`: **Rota sugerida** só com `areaId`.
   Chip **Parada X de N** + **Registrar ocorrência**.
5. **Ocorrência** — a UI abre o fluxo já existente `MapMarkSheet` no lat/lng da
   parada (`OccurrenceTalhaoPrefill` via o ponto). `visitas` não importa
   `consultoria`. Ao salvar, `completeCurrentStop` marca a parada `done`.
6. **Notificação** — local, em português, no momento em que a parada é concluída.
   Permanece na bandeja se o usuário bloquear a tela **depois**. Payload:
   `/map?modo=foco&lat=&lng=` (query já usada pelo mapa; sem sub-rota).
   `NotificationService.onDidReceiveNotificationResponse` entrega o payload;
   `main.dart` faz `go` só se o payload for esse foco.
7. **Primeiro plano** — `GeofenceController` avisa uma vez se o GPS chega a
   ~80 m da parada corrente **com o mapa aberto**. Não substitui a notificação
   de conclusão.

## Fase 2 — fora deste PR

Alerta de proximidade **com o telefone bloqueado e sem ação do usuário** exige
localização em background:

- iOS: `UIBackgroundModes` (`location`) + permissão **Always**
- Android: foreground service de localização

**Esta fase não adiciona Always nem `UIBackgroundModes`.** Sem isso, o sistema
não entrega posição com o app suspenso, então o aviso “você chegou na parada”
não dispara sozinho no bloqueio. O que a Fase 1 garante é a notificação da
**próxima** parada, publicada quando o consultor conclui a atual (app ainda
em execução) e visível depois do bloqueio. O toque abre o mapa no ponto.

## Consequências

- Bancos existentes sobem de v48 para v49 (ALTER idempotente).
- Sync de visita permanece o mesmo contrato remoto.
- Sem rota se o talhão não tiver polígono que caiba as N paradas.
