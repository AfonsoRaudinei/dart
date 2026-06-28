# Homologacao iOS — Fase 5

Data: 2026-06-07
Build alvo: SoloForte `1.34.0+134`
IPA alvo: `build/ios/ipa/soloforte_app.ipa`
Status: PENDENTE DE DEVICE FISICO / TESTFLIGHT

## Resultado

A Fase 5 ainda nao pode ser considerada concluida.

Motivo: nao havia iPhone/iPad fisico disponivel para execucao da matriz minima.
O comando `flutter devices` detectou apenas macOS e Chrome. O `devicectl`
detectou um iPhone 16 chamado `Raudinei`, mas em estado `unavailable`.

## Evidencias locais ja coletadas

- `./tool/arch_check.sh`: Exit 0.
- `flutter analyze lib/`: sem issues.
- `flutter test`: 747 passed, 1 skip.
- `TARGETED_DEVICE_FAMILY`: `1,2` nas configuracoes principais de iPhoneOS.
- Simuladores disponiveis: iPhone 17 Pro, iPhone 17 Pro Max, iPhone 16e,
  iPad Pro, iPad mini, iPad Air e iPad A16.
- Device fisico: nao disponivel para teste no momento.

## Matriz minima obrigatoria

| Ambiente | Status | Evidencia |
|---|---:|---|
| iPhone pequeno fisico | PENDENTE | TestFlight/device fisico necessario |
| iPhone grande fisico | PENDENTE | TestFlight/device fisico necessario |
| iPad fisico | PENDENTE | TestFlight/device fisico necessario |
| Rede boa | PENDENTE | Testar no device fisico |
| Rede ruim | PENDENTE | Network Link Conditioner ou condicao real |
| Offline | PENDENTE | Airplane Mode/Wi-Fi desligado |
| Localizacao permitida | PENDENTE | Permitir When In Use |
| Localizacao negada | PENDENTE | Negar no prompt |
| Localizacao negada permanentemente | PENDENTE | Negar e bloquear em Settings |

## Fluxos obrigatorios

Cada fluxo deve ser executado em pelo menos iPhone pequeno, iPhone grande e iPad.
Marcar evidencia com screenshot, video curto ou log de crash ausente.

| Fluxo | iPhone pequeno | iPhone grande | iPad | Evidencia |
|---|---:|---:|---:|---|
| Cadastro/login/logout e isolamento entre usuarios | PENDENTE | PENDENTE | PENDENTE | |
| Reset de senha por `soloforte://` | PENDENTE | PENDENTE | PENDENTE | |
| Mapa inicial, tiles, layers, satelite e GPS | PENDENTE | PENDENTE | PENDENTE | |
| Criar cliente, fazenda, talhao e ocorrencia | PENDENTE | PENDENTE | PENDENTE | |
| Iniciar/finalizar visita | PENDENTE | PENDENTE | PENDENTE | |
| Gerar/exportar/compartilhar relatorio | PENDENTE | PENDENTE | PENDENTE | |
| Fotos por camera e galeria | PENDENTE | PENDENTE | PENDENTE | |
| Importacao KML/KMZ/GPX quando aplicavel | PENDENTE | PENDENTE | PENDENTE | |
| Notificacoes de agenda | PENDENTE | PENDENTE | PENDENTE | |
| Planos conforme Fase 3 | PENDENTE | PENDENTE | PENDENTE | |
| Exclusao de conta | PENDENTE | PENDENTE | PENDENTE | |
| VoiceOver | PENDENTE | PENDENTE | PENDENTE | |
| Dynamic Type | PENDENTE | PENDENTE | PENDENTE | |
| Contraste | PENDENTE | PENDENTE | PENDENTE | |

## Criterios de aceite

1. Nenhum crash durante os fluxos obrigatorios.
2. Login, sincronizacao e isolamento entre usuarios confirmados com duas contas.
3. Mapa carrega tiles padrao e satelite sem tela vazia permanente.
4. GPS funciona com permissao permitida e falha de forma compreensivel quando
   negado.
5. Offline nao corrompe dados locais e retoma sync quando a rede volta.
6. Relatorio exportado abre/compartilha corretamente.
7. Fotos de camera/galeria respeitam permissoes.
8. Planos iOS nao exibem preco, CTA ou checkout externo.
9. Exclusao de conta remove sessao e dados pessoais conforme politica.
10. Acessibilidade nao bloqueia fluxos principais.

## Procedimento recomendado

1. Subir `build/ios/ipa/soloforte_app.ipa` para TestFlight.
2. Instalar em:
   - iPhone pequeno.
   - iPhone grande.
   - iPad.
3. Executar a matriz em rede boa.
4. Repetir fluxos criticos em rede ruim e offline.
5. Repetir mapa/GPS com localizacao permitida, negada e negada permanentemente.
6. Coletar screenshots/videos e logs de crash do App Store Connect/TestFlight.
7. Assinar abaixo somente se todos os itens ficarem aprovados.

## Assinatura

Responsavel QA:

Data:

Build homologado:

Resultado final: APROVADO / REPROVADO
