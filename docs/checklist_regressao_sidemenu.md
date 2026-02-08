# ⏱️ CHECKLIST DE REGRESSÃO FINAL — SideMenu Botão Voltar
**Tempo estimado:** 5 minutos  
**Data:** 08/02/2026  
**Objetivo:** Garantir que a correção do SideMenu não gerou efeito colateral.

---

## 📋 INSTRUÇÕES

Execute os testes na ordem. Marque ✅ se passou ou ❌ se falhou.

**Critério de aprovação:** Todos os itens devem passar (✅).  
**Se qualquer falhar:** Rollback imediato.

---

## 1️⃣ NAVEGAÇÃO BASE (1 min)

### Passo a Passo:
1. Abrir o app (deve cair automaticamente em `/dashboard`)
2. Verificar que o mapa está visível
3. Tocar no botão ☰ (SmartButton) para abrir o SideMenu
4. Observar o SideMenu

### Checklist:
- [ ] App abre em `/dashboard` sem erros
- [ ] Mapa está visível e funcional
- [ ] SideMenu abre normalmente
- [ ] **SideMenu NÃO mostra botão "Voltar"** (raiz do namespace)
- [ ] Título "SoloForte" está visível
- [ ] Itens do menu estão visíveis (Configurações, Relatórios, etc.)
- [ ] Console sem erros

**Status:** ☐ PASSOU / ☐ FALHOU

---

## 2️⃣ SUB-ROTA SIMPLES (1 min)

### Passo a Passo:
1. Navegar para `/consultoria/clientes` (via SideMenu → Clientes)
2. Abrir o SideMenu novamente (botão ☰)
3. Observar se o botão "Voltar ao Mapa" aparece
4. Tocar no botão "Voltar ao Mapa"
5. Verificar que voltou para `/dashboard`

### Checklist:
- [ ] Navegação para `/consultoria/clientes` funciona
- [ ] SideMenu abre normalmente
- [ ] **Botão "Voltar ao Mapa" APARECE** (sub-rota)
- [ ] Botão possui ícone de seta (←) e texto verde
- [ ] Ao tocar "Voltar", fecha o menu
- [ ] Navega corretamente para `/dashboard`
- [ ] Mapa volta a ser exibido

**Status:** ☐ PASSOU / ☐ FALHOU

---

## 3️⃣ SUB-ROTA PROFUNDA (1 min)

### Passo a Passo:
1. Navegar para `/consultoria/clientes` (via menu)
2. Tocar em um cliente qualquer (se houver dados)
   - **OU** simular navegando manualmente para uma rota profunda
3. Abrir o SideMenu
4. Verificar presença do botão "Voltar"
5. Tocar no botão
6. Confirmar retorno ao Dashboard

### Checklist:
- [ ] Navegação para sub-rota profunda funciona
- [ ] SideMenu abre normalmente
- [ ] **Botão "Voltar ao Mapa" APARECE**
- [ ] Ao tocar "Voltar", navega para `/dashboard`
- [ ] Nenhum erro de navegação

**Status:** ☐ PASSOU / ☐ FALHOU

---

## 4️⃣ HOT RESTART (R) (1 min)

### Passo a Passo:
1. Navegar para `/consultoria/relatorios` (via SideMenu → Relatórios)
2. Abrir o SideMenu → Botão "Voltar" deve aparecer
3. Fechar o SideMenu
4. **Pressionar `R` (Hot Restart)** no terminal Flutter
5. Aguardar reload completo
6. Abrir o SideMenu novamente
7. Verificar se o botão **AINDA APARECE**

### Checklist:
- [ ] Antes do restart: botão "Voltar" aparece
- [ ] Hot Restart completa sem erros
- [ ] App restaura para `/consultoria/relatorios` (ou última rota)
- [ ] SideMenu abre normalmente após restart
- [ ] **Botão "Voltar" AINDA APARECE** (determinístico!)
- [ ] Funcionalidade do botão continua normal
- [ ] Navegação geral continua funcional

**Status:** ☐ PASSOU / ☐ FALHOU

---

## 5️⃣ COLD START SIMULADO (1 min)

### Passo a Passo:
1. Navegar para `/settings` (via SideMenu → Configurações)
2. Abrir o SideMenu → Botão "Voltar" deve aparecer
3. **Fechar o app completamente** (matar o processo ou fechar emulador)
4. **Abrir o app novamente**
5. Se o app restaurar estado, deve voltar para `/settings`
6. Abrir o SideMenu
7. Verificar presença do botão
8. Navegar para `/dashboard` (pelo menu ou botão ☰)
9. Abrir SideMenu no Dashboard
10. Verificar que botão desaparece

### Checklist:
- [ ] App fecha e reabre sem problemas
- [ ] Estado é restaurado (ou inicia em `/dashboard`)
- [ ] Se em rota != `/dashboard`: botão "Voltar" **APARECE**
- [ ] Ao navegar para `/dashboard`: botão **NÃO APARECE**
- [ ] Comportamento permanece consistente
- [ ] Sem crashes ou erros

**Status:** ☐ PASSOU / ☐ FALHOU

---

## ✅ CRITÉRIO DE APROVAÇÃO FINAL

**Total de testes:** 5  
**Passaram:** _____ / 5  
**Falharam:** _____ / 5

### Decisão:
- [ ] ✅ **APROVADO** — Todos os 5 testes passaram (REGRESSÃO ZERO)
- [ ] ❌ **REPROVADO** — Algum teste falhou (ROLLBACK OBRIGATÓRIO)

---

## 🔒 VALIDAÇÃO ADICIONAL

### Testes Unitários
- [x] 20 testes unitários executados (`flutter test`)
- [x] Todos os testes passaram
- [x] Performance validada (< 10ms para 1000 chamadas)

### Análise Estática
- [x] `dart format` — OK
- [x] `dart analyze` — OK
- [x] Nenhum erro de lint

---

## 📝 NOTAS DO EXECUTOR

**Executado por:** _____________________  
**Data/Hora:** _____________________  
**Ambiente:** ☐ Android / ☐ iOS / ☐ Desktop  

**Observações:**
```
[Espaço para anotações de bugs encontrados, comportamentos inesperados, etc.]








```

---

## 🎯 RESULTADO ESPERADO

Se todos os testes passarem:
- ✅ SideMenu é **post-restart safe** (imune a hot restart e cold start)
- ✅ Botão "Voltar" é **100% determinístico** (baseado na rota)
- ✅ Baseline v1 está **inalterado** (nenhuma regressão)
- ✅ Navegação global funciona **perfeitamente**

---

**FIM DO CHECKLIST**
