# 🧠 Skill — Auditoria de Escopo e Rotas (SoloForte)

## 🎯 Objetivo

Garantir que qualquer solicitação de implementação, correção ou ajuste:

- Respeite o módulo explicitamente autorizado
- Utilize apenas rotas oficiais do SoloForte
- Não altere estado global, navegação, tema ou outros módulos
- Não crie rotas novas
- Não duplique arquivos
- Não viole o contrato arquitetural Flutter (Dart)

Esta skill é estritamente analítica.
Ela NÃO implementa código.
Ela apenas valida e aponta inconsistências.

---

## 🗂️ Rotas Oficiais (Fonte de Verdade)

Considerar válidas apenas as seguintes rotas:

"/",
"/login",
"/login-dev",
"/demo-dock",
"/dashboard",
"/dashboard/:rest*",
"/dashboard/mapa-tecnico",
"/dashboard/clima-eventos",
"/consultoria",
"/consultoria/:rest*",
"/consultoria/comunicacao",
"/consultoria/comunicacao/chat",
"/consultoria/comunicacao/relatorios",
"/consultoria/comunicacao/galeria",
"/consultoria/comunicacao/historico",
"/consultoria/assistente-ia",
"/consultoria/clientes",
"/consultoria/agenda",
"/consultoria/performance",
"/consultoria/base-tecnica",
"/solo-cultivares",
"/solo-cultivares/:rest*",
"/gestao-agricola",
"/gestao-agricola/:rest*",
"/marketing",
"/marketing/:rest*"

Qualquer rota fora dessa lista → VIOLAÇÃO.

---

## 🔎 Quando Ativar

Ativar quando o prompt contiver termos como:

- implementar
- criar
- ajustar
- corrigir
- modificar
- adicionar funcionalidade
- alterar rota
- mexer no estado
- reorganizar navegação

---

## 📋 Etapas de Auditoria

### 1️⃣ Verificação de Escopo

- O módulo foi explicitamente declarado?
- As rotas estão dentro do módulo permitido?
- Existe risco de alteração em outro módulo?
- Há possibilidade de efeito colateral?

Se houver ambiguidade → solicitar confirmação antes de qualquer ação.

---

### 2️⃣ Verificação de Rotas

- A rota existe na lista oficial?
- Está criando sub-rota inexistente?
- Está utilizando rota paralela?
- Está quebrando contrato do Dashboard?

Se verdadeiro → marcar como VIOLAÇÃO DE ROTA.

---

### 3️⃣ Verificação Arquitetural Flutter (Dart)

Validar:

- Separação clara de responsabilidades
- Nenhuma alteração global indevida
- Nenhum AppBar adicionado
- Nenhuma duplicação de arquivo
- Nenhuma criação de rota paralela

---

### 4️⃣ Checklist de Efeito Colateral

Responder obrigatoriamente:

- Dashboard alterado?
- Outros módulos alterados?
- Navegação mudou?
- Tema alterado?
- Estado global alterado?

---

## 📦 Formato de Resposta Obrigatório

AUDITORIA DE ESCOPO — SOLOFORTE

Módulo analisado:
Rota(s) envolvida(s):

Resultado:
✔ Dentro do escopo
ou
🚨 Violação detectada

Detalhamento técnico:

Checklist Final:
Dashboard alterado?
Outros módulos alterados?
Navegação mudou?
Tema alterado?
Estado global alterado?

---

## 🚫 Restrições Absolutas

Esta skill:

- NÃO cria código
- NÃO executa alterações
- NÃO sugere melhorias fora do escopo
- NÃO expande funcionalidades
- NÃO interpreta intenção além do que está explícito

Se houver dúvida → interromper e solicitar confirmação.
