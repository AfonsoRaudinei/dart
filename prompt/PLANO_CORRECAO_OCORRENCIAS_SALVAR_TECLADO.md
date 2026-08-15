# Plano de correcao - Ocorrencias: salvar e erro oculto pelo teclado

Modo de revisao: AUDIT, somente leitura do codigo do app.

Bounded context principal: `consultoria/occurrences`.

Contextos tocados pela analise: `ui/map`, `core/router`, `consultoria`.

## Arquivos avaliados

- `AGENTS.md`
- `agentrevisor.md`
- `lib/modules/consultoria/AGENTS.md`
- `lib/ui/screens/map/handlers/map_first_query_handler.dart`
- `lib/ui/screens/private_map_screen.dart`
- `lib/ui/screens/map/widgets/map_build_orchestrator.dart`
- `lib/ui/screens/map/widgets/map_performance_hosts.dart`
- `lib/ui/components/map/map_bottom_sheet.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_models.dart`
- `lib/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart`
- `lib/modules/consultoria/occurrences/data/occurrence_repository.dart`
- `lib/modules/consultoria/occurrences/domain/occurrence.dart`
- `lib/core/database/migrations/database_migrations_v1_v23.dart`
- Testes existentes localizados por busca em `test/` relacionados a ocorrencias e `MapBottomSheet`.

## Limites da auditoria

- Nenhuma alteracao foi feita em `lib/`, `test/`, `tool/` ou arquivos de configuracao.
- Nao houve execucao em device fisico ou simulador com teclado real.
- Nao foi validado backend Supabase/RLS publicado.
- O erro runtime exato visto pelo usuario ainda nao foi capturado em log ou stack trace.
- A conclusao abaixo vem da leitura estatica dos fluxos de UI, callback assíncrono e persistencia local.

## Diagnostico

O bug de ocorrencias ainda nao parece totalmente corrigido. A persistencia local tem protecao para `user_id` no repository antes do insert, mas o fluxo de UI ainda tem tres fragilidades relevantes: coordenada ausente vira `0,0`, falhas assincronas de salvamento nao sao tratadas no formulario, e as mensagens de erro usam `SnackBar` enquanto o teclado e o bottom sheet competem pela area visivel.

### Achado 1 - formulario pode salvar com coordenada invalida quando falta pin real

Severidade: Alta

Categoria: Integridade de dados / fluxo Map-First

Localizacao:

- `lib/ui/components/map/map_bottom_sheet.dart:597-603`
- `lib/ui/components/map/map_bottom_sheet.dart:619-630`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_models.dart:100-106`

Evidencia curta:

- O formulario recebe `latitude` e `longitude` como `0` quando `creationLocation` esta nulo.
- O validador rejeita `(0,0)`.
- O erro exibido orienta tocar novamente no mapa.

Risco pratico:

O usuario pode preencher a ocorrencia inteira e, ao salvar, receber erro de ponto invalido. Se o teclado estiver aberto, esse erro pode nao ficar visivel. Em entradas por menu/rota ou por algum estado stale de sheet, o formulario fica aparentemente pronto para salvar, mas nao possui pin persistivel.

Direcao conceitual de correcao:

- Impedir a abertura do formulario de criacao quando nao houver `pendingOccurrenceLocation` valida.
- No fluxo `modo=ocorrencia`, manter apenas o modo armado e exigir toque no mapa antes de abrir o formulario.
- Se o produto decidir aceitar o centro atual do mapa como fallback, isso precisa ser uma decisao explicita e visivel ao usuario; nao deve acontecer silenciosamente.
- A mensagem de ausencia de pin deve ser persistente dentro do sheet ou banner do modo armado, nao somente `SnackBar`.

Validacao necessaria:

- Teste de widget cobrindo abertura por `modo=ocorrencia`/menu sem pin: nao deve chamar save nem mostrar formulario salvavel.
- Teste de widget cobrindo toque no mapa: deve abrir formulario com coordenada valida.
- Teste em device/simulador para confirmar a mensagem visivel com teclado aberto.

### Achado 2 - callback de confirmacao e `void`, mas o caller executa salvamento assincrono

Severidade: Media

Categoria: Concorrencia assincrona / UX de erro

Localizacao:

- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_models.dart:109`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart:334-378`
- `lib/ui/components/map/map_bottom_sheet.dart:616-656`
- `lib/modules/consultoria/occurrences/data/occurrence_repository.dart:47-72`

Evidencia curta:

- O tipo do callback de confirmacao e `void Function(...)`.
- O formulario chama `onConfirm` sem aguardar conclusao.
- O caller passa callback `async` e aguarda insert no repository.

Risco pratico:

Erros de banco, migracao, sessao local ou insert podem escapar sem tratamento deterministico no formulario. O botao tambem pode ser acionado repetidas vezes enquanto o salvamento esta em andamento, aumentando risco de duplicidade ou estado visual incoerente.

Direcao conceitual de correcao:

- Tornar o fluxo de confirmacao conceitualmente aguardavel pelo formulario.
- Introduzir estado de salvamento local no sheet: desabilitar botoes, evitar duplo toque e manter o formulario aberto ate sucesso real.
- Capturar falhas de salvamento no ponto mais proximo da UI e exibir erro persistente no proprio sheet.
- Dismissar foco/teclado antes de validar e salvar, para liberar area visual ao erro.

Validacao necessaria:

- Teste de widget/provider simulando falha no repository: formulario permanece aberto e mostra erro visivel.
- Teste de duplo toque em salvar: apenas uma tentativa de persistencia deve ocorrer.
- `flutter analyze` nos arquivos de ocorrencias e map.

### Achado 3 - erro usa SnackBar enquanto teclado e sheet aplicam insets em mais de um nivel

Severidade: Media

Categoria: Performance/UX funcional

Localizacao:

- `lib/ui/components/map/map_bottom_sheet.dart:355-361`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart:382-383`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart:714-724`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart:337-344`
- `lib/ui/components/map/map_bottom_sheet.dart:621-627`

Evidencia curta:

- O bottom sheet reduz altura usando `viewInsets.bottom`.
- O formulario tambem adiciona padding inferior com `keyboardHeight + 12`.
- Os erros principais aparecem via `SnackBar`.

Risco pratico:

Com teclado aberto, a area util pode ser reduzida duas vezes e o erro transitorio pode aparecer fora do foco visual do usuario. Isso bate com o relato: "o teclado por muitas vezes nao permite a visualizacao do erro".

Direcao conceitual de correcao:

- Definir um unico dono para ajuste de teclado: o container do sheet ou o conteudo interno, mas nao ambos de forma acumulada.
- Trocar validacoes criticas por erro inline persistente acima da barra de acoes ou junto ao campo/estado que bloqueou o salvamento.
- Ao detectar erro, rolar para a area afetada e manter o erro dentro da regiao visivel do sheet.
- Usar `SnackBar` apenas como feedback complementar, nao como unica explicacao de bloqueio.

Validacao necessaria:

- Teste/widget golden ou teste manual em simulador com teclado aberto.
- Verificar que erro de categoria/descricao e erro de pin ficam visiveis sem fechar o teclado.
- Verificar que a barra de acoes nao fica inacessivel em telas pequenas.

### Achado 4 - cobertura de teste nao cobre os cenarios que explicam o bug relatado

Severidade: Media

Categoria: Testabilidade

Localizacao:

- `test/modules/consultoria/occurrence_creation_sheet_prefill_test.dart`
- `test/ui/components/map/map_bottom_sheet_occurrence_host_test.dart`

Evidencia objetiva:

- Os testes existentes localizados cobrem prefill/draft e cenarios com `creationLocation` valida.
- Nao foi localizado teste focado em `creationLocation == null`, falha de repository, duplo toque em salvar ou erro visivel com teclado aberto.

Risco pratico:

Uma correcao parcial pode passar nos testes atuais e ainda manter o fluxo real quebrado no campo.

Direcao conceitual de correcao:

- Adicionar testes focados nos quatro riscos: sem pin, repository falhando, duplo toque e teclado aberto.
- Usar overrides de providers/repository para simular falha sem depender de Supabase real.
- Manter testes restritos a `consultoria/occurrences` e `ui/map`, sem mudar contratos globais.

Validacao necessaria:

- Rodar testes focados de ocorrencias e `MapBottomSheet`.
- Rodar `./tool/arch_check.sh`.
- Rodar `flutter analyze lib/` ou, no minimo, os paths tocados.

## Plano de execucao proposto

1. Reproduzir e registrar o caminho exato do bug.
   - Validar entrada pelo botao do mapa, pelo menu lateral `Nova Ocorrencia` e por `/map?modo=ocorrencia`.
   - Capturar se o formulario abriu com coordenada real ou com fallback `0,0`.
   - Capturar mensagem/stack quando o save falhar.

2. Corrigir o contrato conceitual do fluxo de criacao.
   - Formulario de criacao so deve existir com pin valido.
   - Ausencia de pin deve manter usuario no mapa em modo armado, com instrucao visivel para tocar no mapa.

3. Corrigir tratamento assincrono de salvamento.
   - O formulario deve aguardar conclusao do save.
   - Mostrar carregamento, bloquear duplo submit e capturar falhas.
   - Manter draft e formulario abertos quando houver erro.

4. Corrigir visibilidade de erro com teclado.
   - Tornar erros bloqueantes persistentes dentro do sheet.
   - Ajustar insets para evitar compensacao duplicada.
   - Garantir rolagem para erro/campo relevante.

5. Cobrir com testes focados.
   - Sem coordenada valida.
   - Falha simulada no repository.
   - Duplo toque no salvar.
   - Teclado aberto em tela pequena.
   - Sucesso preservando comportamento atual: salva, limpa draft e fecha sheet.

6. Validar gates.
   - `flutter analyze lib/modules/consultoria/occurrences lib/ui/components/map`
   - Testes focados de ocorrencias e `MapBottomSheet`.
   - `./tool/arch_check.sh`
   - Validacao manual em device/simulador com teclado aberto.

## Checklist de conclusao

- [x] `AGENTS.md` raiz lido.
- [x] `agentrevisor.md` lido.
- [x] `lib/modules/consultoria/AGENTS.md` lido.
- [x] Fluxo `/map?modo=ocorrencia` avaliado.
- [x] Fluxo de toque no mapa para abrir formulario avaliado.
- [x] Fluxo de submit do formulario avaliado.
- [x] Persistencia local de ocorrencias avaliada em leitura.
- [x] Risco de `user_id` no insert reavaliado: repository injeta `user_id` antes do insert.
- [x] Risco de coordenada invalida identificado.
- [x] Risco de erro assincrono sem tratamento no formulario identificado.
- [x] Risco de erro oculto pelo teclado identificado.
- [x] Plano de correcao criado sem alterar codigo do app.
- [ ] Stack trace/log real do erro capturado em device.
- [ ] Correcao implementada.
- [ ] Testes focados criados/atualizados.
- [ ] `flutter analyze` executado apos correcao.
- [ ] `./tool/arch_check.sh` executado apos correcao.
- [ ] Validacao manual com teclado aberto executada em device/simulador.

Nenhuma alteracao de codigo foi feita - apenas diagnostico e plano.

## Execucao da correcao - 2026-08-10

Bounded contexts alterados diretamente: `consultoria/occurrences` e `ui/map`.

Arquivos principais alterados:

- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_draft.dart`
- `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_submit.dart`
- `lib/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart`
- `lib/ui/components/map/map_bottom_sheet.dart`
- Testes focados de ocorrencias e mapa em `test/modules/consultoria/occurrences/` e `test/ui/components/map/`

Checklist de conclusao da execucao:

- [x] Formulario de ocorrencia nao fica salvavel quando nao ha pin valido.
- [x] Coordenada `(0,0)` continua rejeitada antes do submit.
- [x] `onConfirm` e aguardado pelo formulario.
- [x] Duplo toque em salvar e bloqueado por estado local de salvamento.
- [x] Erros de submit ficam inline no sheet e o teclado e fechado antes da validacao.
- [x] Rascunho e preservado no fechamento/remount sem escrita direta de provider durante `dispose`.
- [x] Testes focados de submit, rascunho e host do bottom sheet foram atualizados.
- [x] `flutter analyze lib/modules/consultoria/occurrences lib/ui/components/map` passou.
- [x] `flutter analyze lib/` passou.
- [x] `./tool/arch_check.sh` passou.
- [x] Testes focados de ocorrencias/mapa passaram.
- [ ] Validacao manual em device/simulador com teclado real nao executada nesta rodada.
- [ ] `flutter test` completo ainda falha fora do escopo, em `test/modules/agenda/use_cases/start_event_use_case_test.dart`.
