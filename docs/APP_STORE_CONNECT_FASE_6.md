# App Store Connect — Fase 6

Data: 2026-06-08
App: SoloForte
Bundle ID: `com.soloforte.soloforteApp`
Versao App Store: `1.34.0`
Build alvo: `1.34.0+134`
Status: PENDENTE DE ACESSO AO APP STORE CONNECT / BUILD PROCESSADO

## Resultado

A Fase 6 ainda nao pode ser considerada concluida.

Motivos:

1. O IPA ainda precisa ser enviado e processado no App Store Connect/TestFlight.
2. Nao ha sessao/API key do App Store Connect disponivel neste ambiente.
3. A Fase 5 ainda esta pendente de homologacao em device fisico.
4. URL publica de suporte e politica de privacidade ainda precisam ser
   confirmadas antes do envio.

## Criar versao iOS

Preencher no App Store Connect:

| Campo | Valor |
|---|---|
| Nome | SoloForte |
| Bundle ID | `com.soloforte.soloforteApp` |
| Versao | `1.34.0` |
| Build | selecionar build processado `134` |
| SKU | definir internamente, por exemplo `soloforte-ios` |
| Categoria primaria | Negocios |
| Categoria secundaria | Produtividade |

Observacao: confirmar primeiro se o build `134` e superior ao ultimo build ja
enviado para este bundle/versionamento.

## Metadata proposta

### Subtitulo

```text
Gestao agricola de campo
```

Limite: 25/30 caracteres.

### Keywords

```text
agronomia,agricultura,fazenda,talhao,mapa,gps,visita,relatorio,ocorrencia,clima,campo
```

Limite: 89/100 caracteres.

### Descricao

```text
SoloForte e um aplicativo mobile para gestao agricola de campo, pensado para profissionais que precisam registrar clientes, fazendas, talhoes, visitas, ocorrencias e relatorios a partir do mapa.

Com uma experiencia Map-First, o app ajuda a organizar dados de campo por localizacao, acompanhar atividades em propriedades rurais, visualizar camadas de mapa, registrar pontos de interesse e gerar relatorios para atendimento tecnico.

Principais recursos:
- Mapa com GPS, camadas e visualizacao por propriedade.
- Cadastro de clientes, fazendas e talhoes.
- Registro de ocorrencias georreferenciadas.
- Agenda e controle de visitas de campo.
- Relatorios com dados, fotos e evidencias.
- Importacao de arquivos geograficos quando aplicavel.
- Sincronizacao segura da conta e dados autorizados.

O SoloForte foi criado para apoiar rotinas de agronomia, consultoria agricola e gestao operacional em campo.
```

### Texto promocional

```text
Organize visitas, talhoes, ocorrencias e relatorios direto do mapa.
```

### Novidades da versao

```text
Preparacao para distribuicao iOS, ajustes de privacidade, compatibilidade com App Store Connect e melhorias no fluxo de planos para iOS.
```

## URLs obrigatorias

Preencher antes do envio:

| Campo | Status |
|---|---|
| URL de suporte | PENDENTE |
| URL da politica de privacidade | PENDENTE |
| URL de escolhas de privacidade | OPCIONAL, recomendada se houver pagina de exclusao/privacidade |

Requisito: URLs HTTPS permanentes e publicas.

## Screenshots

Usar dados reais autorizados ou conta demo com dados realistas. Nao usar dados
de clientes reais sem autorizacao.

Sequencia recomendada:

1. Mapa inicial com talhoes e GPS.
2. Detalhe de fazenda/talhao.
3. Criacao ou detalhe de ocorrencia.
4. Agenda/visita de campo.
5. Relatorio gerado/exportado.
6. Tela de planos iOS apenas se mostrar status de plano, sem preco, CTA ou
   checkout externo.

Obrigatorio antes de publicar:

- Capturas em iPhone grande.
- Capturas em iPhone pequeno se a UI nao escalar bem a partir do tamanho maior.
- Capturas em iPad, pois o projeto inclui `TARGETED_DEVICE_FAMILY = 1,2`.

## Conta demo

Preencher no App Review:

```text
Usuario: PENDENTE
Senha: PENDENTE
2FA: desativado
Dados demo: clientes, fazendas, talhoes, visitas, ocorrencias e relatorios pre-carregados.
```

Requisitos da conta demo:

1. Login funcional no build de producao.
2. Sem 2FA.
3. Dados de campo suficientes para revisar mapa, clientes, visitas, ocorrencias
   e relatorios.
4. Plano ativo ou estado de plano coerente com a Fase 3.
5. Permitir exclusao de conta ou explicar ao revisor se a conta demo sera
   restaurada apos review.

## Notas ao revisor

```text
O SoloForte usa uma experiencia Map-First para agronomia de campo. A tela principal e o mapa privado, onde o usuario acessa clientes, fazendas, talhoes, visitas, ocorrencias e relatorios.

Para revisar o app:
1. Entrar com a conta demo informada.
2. Permitir localizacao "Durante o uso" para testar GPS e recursos de mapa.
3. Abrir o menu do mapa para acessar clientes, agenda, relatorios e configuracoes.
4. Validar o fluxo de cliente/fazenda/talhao, registro de ocorrencia, visita e geracao de relatorio.
5. Em iOS, o modulo de planos nao inicia checkout externo e nao vende planos digitais pelo app. Ele exibe apenas o status do plano associado a conta.
6. A exclusao de conta esta disponivel em Configuracoes > Sessao > Excluir minha conta.

O app nao usa tracking de localizacao em background. A permissao de localizacao e usada para posicionar ocorrencias, talhoes, rotas de visita e GPS no mapa enquanto o app esta em uso.
```

## Export Compliance

Estado local:

- `ITSAppUsesNonExemptEncryption=false` em `Info.plist`.

Resposta operacional esperada no App Store Connect:

- Declarar uso de criptografia conforme o formulario da Apple.
- Se o app usa apenas criptografia padrao do sistema/HTTPS e nao usa
  criptografia proprietaria, manter coerente com `ITSAppUsesNonExemptEncryption=false`.

## App Privacy

Usar como base:

- `docs/APP_STORE_PRIVACY_DECLARATIONS.md`

Conferir no App Store Connect:

1. Localizacao precisa.
2. Identificadores de usuario/conta.
3. Dados de contato se coletados.
4. Conteudo do usuario.
5. Fotos/imagens.
6. Diagnosticos se coletados.
7. Dados de uso se coletados.
8. Terceiros: Supabase, mapas/tiles, clima, Mercado Pago para canais nao iOS,
   WebView/URL externa, notificacoes e analytics se existirem.

## Checklist de submissao

```text
[ ] App iOS 1.34.0 criado no App Store Connect
[ ] Build 134 enviado e processado
[ ] Build 134 selecionado na versao
[ ] Nome SoloForte confirmado
[ ] Bundle com.soloforte.soloforteApp confirmado
[ ] Categoria primaria definida
[ ] Subtitulo preenchido
[ ] Descricao preenchida
[ ] Keywords preenchidas
[ ] URL de suporte preenchida
[ ] URL de politica de privacidade preenchida
[ ] Screenshots iPhone grande anexados
[ ] Screenshots iPhone pequeno revisados/anexados se necessario
[ ] Screenshots iPad anexados
[ ] Conta demo funcional preenchida
[ ] Notas ao revisor preenchidas
[ ] Export Compliance preenchido
[ ] App Privacy preenchido
[ ] Fase 5 homologada em device fisico
[ ] Nenhum warning ITMS pendente
[ ] Enviado para App Review
```

## Bloqueadores

1. Upload/processamento do build no App Store Connect.
2. Homologacao fisica da Fase 5.
3. URLs publicas de suporte e politica de privacidade.
4. Conta demo funcional com dados pre-carregados.
