# Smoke Test Manual — SoloForte v1.0.0

Executar em **dispositivo físico** (1× iOS + 1× Android API 33+) antes de submeter.

Marcar ✅ Pass / ❌ Fail / ⏭ N/A.

---

## Autenticação (5)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 1 | Login com credenciais válidas | | |
| 2 | Login com senha inválida → mensagem amigável | | |
| 3 | Cadastro com consentimento obrigatório | | |
| 4 | Logout limpa sessão e volta ao mapa público | | |
| 5 | Exclusão de conta (staging) funciona | | |

## Mapa e GPS (6)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 6 | Mapa privado abre sem lag perceptível | | |
| 7 | Permissão GPS solicitada e aceita | | |
| 8 | Pan/zoom funcionam; rotate desabilitado | | |
| 9 | Talhão selecionável por toque | | |
| 10 | Camadas de mapa alternam (satélite/terreno/padrão) | | |
| 11 | GPS negado → feedback visual sem crash | | |

## Ocorrências (6)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 12 | Armar modo ocorrências (toggle) | | |
| 13 | Tap no mapa armado abre dialog de criação | | |
| 14 | Tap sem modo armado NÃO cria ocorrência | | |
| 15 | Ocorrência salva offline (modo avião) | | |
| 16 | Pin aparece no mapa com cor correta | | |
| 17 | Tap no pin abre edição e salva alteração | | |

## Visitas (4)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 18 | Iniciar visita técnica | | |
| 19 | Ocorrência durante visita vincula session_id | | |
| 20 | Encerrar visita | | |
| 21 | Apenas uma sessão ativa por vez | | |

## Sync e offline (4)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 22 | Modo offline forçado pausa sync | | |
| 23 | Dados criados offline persistem após reiniciar app | | |
| 24 | Ao reconectar, sync silencioso reduz pendentes | | |
| 25 | Contador pendentes em Configurações coerente | | |

## Configurações e legal (3)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 26 | Política e Termos abrem no navegador | | |
| 27 | Limpar cache e limpar dados locais funcionam | | |
| 28 | Feedback envia (Supabase ou e-mail) | | |

## Módulos secundários (2)

| # | Cenário | iOS | Android |
|---|---------|-----|---------|
| 29 | Agenda: criar e editar evento | | |
| 30 | Clientes: listar e abrir detalhe | | |

---

## Critério de aprovação

**100% dos cenários aplicáveis = Pass** em ambas as plataformas.

Testador: _______________  
Data: _______________  
Build: _______________
