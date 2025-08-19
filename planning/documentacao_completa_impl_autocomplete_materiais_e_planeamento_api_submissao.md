# Documentação Completa – Autocomplete de Materiais (Post-Forge), Endpoint de Materiais de Acabamento e Planeamento da API de Submissão

Autor: Thúlio Silva

---

## 1. Visão Geral do Trabalho

Este documento consolida todo o trabalho realizado nesta jornada:
- Implementação do autocomplete de materiais de acabamento no formulário Post-Forge (PostForgeMaterialForm)
- Criação do endpoint backend GET /api/get-existing-finishing-materials para alimentar o autocomplete
- Seed de materiais reais na base de dados (FinishingMaterial) para testes
- Refinamentos de UX: dropdown com comportamento idêntico ao "neworder" (animações, teclado, fechar em foco externo e scroll), aplicação sequencial de valores com animação sutil ("pulinho")
- Botão de abrir link diretamente a partir do campo "Link de Compra"
- Planeamento detalhado da nova API de submissão de orçamento por componente (v2) com base na documentação existente

Objetivo: Documentar arquitetura, decisões, trade-offs, segurança, testes e próximos passos, tornando a manutenção futura simples e segura.

---

## 2. Contexto do Sistema

- Aplicação web com front-end Next.js/React, estilo consistente e utilitários (axiosInstance, animações globais, inputs customizados).
- Fluxo de orçamentação por componente dividido em duas grandes áreas de input:
  - Forge (produção/impressão, tempos, volumes, curing opcional)
  - Post-Forge (acabamentos, materiais, custos, tempos de aplicação)
- Repositório já possuía documentação extensa no diretório 03_files/planning (Mapeamento e Implementação Final), e endpoints de suporte (ex.: submit-component-budget, uploads OneDrive).

---

## 3. Implementações – Backend

### 3.1 Endpoint: GET /api/get-existing-finishing-materials

- Local: 01_backend/src/pages/api/get-existing-finishing-materials.js
- Autenticado via getAuthenticatedUserId (401 sem token)
- Método: GET (405 caso outro método)
- Query opcional: ?search= (filtra por LOWER(name) LIKE, parâmetros preparados)
- Resultado: Array ordenado por nome (case-insensitive) com:
  - id, name, brand_name, default_unit_cost, currency, unit_of_measurement, purchase_link, description
- Segurança e robustez:
  - SQL parametrizado; sem concatenar input cru
  - Filtragem simples e eficiente
  - Sem paginação por enquanto (preload + filtro local no front)

### 3.2 Seed de Dados (FinishingMaterial)

- Criado script SQL idempotente (usa NOT EXISTS) para inserir materiais reais, ex.:
  - Tintas (Robbialac, Dyrup), sprays (Rust-Oleum/Luxens), colas (Ceys, UHU, Rayt), resina epóxi, etc.
- Campos preenchidos: name, brand_name, default_unit_cost (valores plausíveis em EUR), currency='EUR', unit_of_measurement='unit', purchase_link, description
- Objetivo: Semear a base para validação realista da pesquisa/autopreenchimento

---

## 4. Implementações – Frontend

### 4.1 Autocomplete no PostForgeMaterialForm

- Componente alvo: 00_frontend/src/components/forms/budgetforms/PostForgeMaterialForm.js
- Criado componente interno MaterialNameSearchInput para encapsular a UX do dropdown de pesquisa de materiais, replicando fielmente o comportamento do "Cliente" em neworder:
  - Estado: isOpen, isClosing, isLoading, hasLoadedOnce, materials, filtered, selectedIndex
  - Preload on first open (GET /api/get-existing-finishing-materials)
  - Filtro local (normalizeText: lower + NFD/remoção de acentos + trim)
  - Navegação por teclado: ArrowUp/Down, Enter (seleciona), Escape (fecha)
  - Animações: dropdown-appear/disappear e option-appear com delays, consistentes com globals.css
  - Fechamento automático por:
    - clique fora (captura em document)
    - scroll em window/document (captura)
    - blur do input com pequeno delay (não interromper clique no item)
    - seleção por clique/Enter
- Seleção de material dispara aplicação sequencial de campos (ver 4.2) e fecha dropdown.

### 4.2 Aplicação Sequencial com Animação ("Pulinho")

- Ao selecionar um material do catálogo, os campos estáticos são preenchidos sequencialmente com pequenos delays (~120ms):
  - Ordem: name → supplierName → unitCost → purchaseLink → description
  - "Pulinho" sutil em cada campo aplicado, para feedback visual e clareza
- Regras de aplicação:
  - Se o valor do catálogo for null/undefined, aplica-se string vazia ("limpa" o campo) – evita "dados fantasma" ao trocar de material
  - Só "pula" se o valor realmente muda (comparação com valor atual, normalizando null/undefined→'')
  - Intensidade/duração do pulinho calibrada (escala ~1.035, ~0.32s), global .animate-bounce-once via <style jsx global>

### 4.3 Ajustes de Inputs/UX

- "Link de Compra":
  - Passou a ter padding-right para comportar botão de ação
  - Botão "abrir link" (ícone FontAwesome arrow-up-right-from-square) no mesmo estilo de posicionamento do botão da calculadora em TimeInput: absolute, right-1, centralizado verticalmente, hover sutil
  - Ao clicar, abre o link em nova aba (window.open com noopener/noreferrer)
  - Só é exibido quando há valor no campo
- Outros:
  - Seleção de texto em focus em campos numéricos (qualidade de vida)
  - Classes de animação reutilizadas do sistema para manter consistência

---

## 5. Decisões, Trade-offs e Boas Práticas

- Preload + filtro local: Evita chamadas excessivas ao backend e mantém UX responsivo; dataset de materiais de acabamento tende a ser limitado
- Atualizar catálogo automaticamente? Por segurança e auditabilidade, recomendado fluxo de proposta de atualização (review/approve) em vez de update direto do FinishingMaterial
- Null handling nas aplicações: Essencial para evitar inconsistência após troca de material; implementado com normalização de null/undefined
- Acessibilidade: Botões têm aria-label; navegação via teclado no dropdown; feedback visual discreto
- Segurança: Endpoints autenticados; SQL parametrizado; window.open com noopener/noreferrer
- Manutenção: Encapsular a lógica do dropdown de pesquisa num subcomponente deixou o formulário principal limpo e fácil de evoluir

---

## 6. Planeamento – Nova API de Submissão (v2)

### 6.1 Endpoint Proposto
- POST /api/submit-component-budget-v2
- Mantém submit-component-budget (v1) intacto; v2 recebe payload rico conforme documentação de mapeamento

### 6.2 Payload (resumo baseado no mapeamento)
- context: { basecomponentId, componentId, version, orderId?, userRole, submissionTimestamp, formType }
- forgeData: produção (itemsPerTable, printHoursPerTable, volumePerTable, supportVolumePerTable, timeEstimates), curing opcional (machine.id, hours, itemsPerTable), comentários, uploadedFiles + profileImage
- postForgeData: finishings[], cada finishing com materials[] (dynamicFields: unitConsumption, applicationHours; staticFields: name, unitCost, supplierName, purchaseLink?, description?) + metadados
- budgetCalculations: { estimated_forge_days, final_cost_per_piece, final_price_per_piece, estimated_prod_days }

### 6.3 Validação Server-side
- Gerais: context e budgetCalculations obrigatórios
- Por role (Forge/Post-Forge/Admin), validar requisitos e faixas (>0; strings não vazias)
- Normalizar nulls; trim strings; relatar erros por path (ex.: postForgeData.finishings[0].materials[1].staticFields.name)

### 6.4 Persistência
- Transação (BEGIN/COMMIT/ROLLBACK)
- ComponentBudget: inserir com campos principais (compat v1)
- Dados Forge/Post-Forge:
  - Se a base já possui tabelas normalizadas para budget data, inserir nelas
  - Alternativa pragmática: JSONB no ComponentBudget para v2 (até migração futura), minimizando impacto em schema
- Ficheiros/OneDrive: associar arquivos submetidos/"staging" ao budget recém criado; mover/organizar conforme padrões
- Auditoria: guardar submissionTimestamp, userId, role, campos críticos

### 6.5 Catálogo de Materiais
- Quando usuário edita campos após escolher material do catálogo:
  - Em vez de aplicar direto no FinishingMaterial, criar proposta (FinishingMaterialUpdateProposal) com status (pending/approved/rejected)
  - Admin aprova para evitar corrupção do catálogo

### 6.6 Resposta e Idempotência
- Responder com { success, budgetId, componentId, version, warnings? }
- Idempotência opcional via hash do payload/context para evitar duplo envio

### 6.7 Testes
- Unit: validadores de payload, conversões e normalizações
- Integração: inserção completa (com e sem curing; múltiplos materiais) e rollback em falhas

---

## 7. Componentes e Utilitários Envolvidos

- PostForgeMaterialForm: formulário de material (campos dinâmicos/estáticos)
- MaterialNameSearchInput (interno): dropdown com pesquisa e UX completa
- TimeInput: referência de estilo para botões auxiliares em inputs
- axiosInstance: cliente HTTP com baseURL configurável e cookies
- CSS global: keyframes dropdown-appear/disappear, option-appear, utilidades de animação

---

## 8. Segurança e Performance

- Segurança
  - Autenticação obrigatória nos endpoints
  - SQL parametrizado (sem injeção)
  - noopener/noreferrer ao abrir links externos
  - Preferência por propostas de atualização do catálogo (fluxo controlado)
- Performance
  - Preload de materiais + filtro local reduz latência
  - Renderizações otimizadas com estados locais e efeitos cuidadosamente limitados

---

## 9. Testes Funcionais Rápidos

- Backend
  - GET /api/get-existing-finishing-materials → 200 + lista; com ?search= filtra
- Frontend (PostForgeMaterialForm)
  - Digitar no "Nome do Material" abre dropdown; teclado (↓/↑/Enter/Escape)
  - Clique fora / scroll fecha dropdown
  - Selecionar item → fecha dropdown; aplica campos em sequência com pulinho; valores null limpam campos
  - Botão no "Link de Compra" abre o link em nova aba quando presente

---

## 10. Próximos Passos

- Implementar /api/submit-component-budget-v2 (skeleton → validações → persistência Forge/Post-Forge → ficheiros)
- Decidir formalmente o fluxo de atualização do catálogo (direto x proposta);
  - Recomendação: propostas com aprovação
- Se necessário, desenhar schema JSONB/transitório para postForgeData até normalização

---

## 11. Lições e Observações (além do escopo imediato)

- Reutilização de padrões de UX reduz custo cognitivo (ex.: replicar dropdown de Cliente em Materiais)
- Ter animações definidas globalmente acelera consistência visual
- Normalização de texto (accents/lower/trim) melhora muito a experiência de pesquisa em PT
- Manter endpoints pequenos e focados (ex.: get-existing-finishing-materials) simplifica testes e segurança
- O cuidado com null/empty no front evita problemas sérios depois (ex.: dados fantasma e sincronização com catálogo)
- Encapsular comportamentos (MaterialNameSearchInput) facilita reuso futuro (ex.: pesquisa de máquinas, fornecedores, etc.)

---

## 12. Assinatura

Thúlio Silva



---

## 13. Correção Importante – Seleção do Status Inicial (BudgetStatus)

- O status inicial do orçamento NÃO deve ser resolvido por título.
- Regra correta: selecionar o registo em "BudgetStatus" onde o campo "order" = 0 (primeiro da ordem de status)
- Racional: torna o fluxo independente de traduções de título e alinhado à ordenação canónica do workflow.
- Implementação sugerida:
  - SQL: `SELECT id FROM "BudgetStatus" WHERE "order" = 0 LIMIT 1;`
  - Falha controlada se não existir: retornar 500 com mensagem de configuração ausente.

---

## 14. Mapeamento de Dados para ComponentBudget (Detelhado)

O objetivo é persistir apenas o que a BD aceita hoje, de forma minimalista, mapeando campos críticos e usando JSONB como fallback quando necessário.

### 14.1 Campos principais
- component_id ← context.componentId
- submitted_by_user_id ← userId autenticado
- submission_mode ← derivado de context.userRole ("forge" | "post-forge" | "admin")
- status_id ← BudgetStatus."order" = 0
- final_price_per_piece ← budgetCalculations.final_price_per_piece
- internal_notes ← forgeData.comments.internal (opcional)
- client_notes ← forgeData.comments.external (opcional)
- description ← (opcional; pode receber concat de resumo do orçamento)

### 14.2 Produção (Forge)
- items_per_table ← forgeData.production.itemsPerTable
- print_hours_per_table ← forgeData.production.printHoursPerTable
- volume_per_table ← forgeData.production.volumePerTable
- support_volume_per_table ← forgeData.production.supportVolumePerTable
- modeling_hours ← forgeData.production.timeEstimates.modelingHours
- slicing_hours ← forgeData.production.timeEstimates.slicingHours
- maintenance_hours_per_table ← forgeData.production.timeEstimates.maintenanceHoursPerTable

### 14.3 Cura (Forge)
- curing_machine_id ← forgeData.curing.machine.id (quando isRequired)
- curing_hours ← forgeData.curing.hours
- curing_items_per_table ← forgeData.curing.itemsPerTable
- curing_auto_filled ← forgeData.curing.autoFilledFromMachine? boolean (se existir no payload; caso contrário, false)

### 14.4 Totais/valores
- total_value ← (opcional) se existir cálculo consolidado visado pela BD
- final_price_per_piece ← já mapeado (campo existente)
- Se fizer sentido guardar custo final por peça (final_cost_per_piece), usar JSONB fallback enquanto não existir coluna

### 14.5 Fallback JSONB
- forge_data_json (se necessário):
  - budgetCalculations.estimated_forge_days, estimated_prod_days, final_cost_per_piece
  - quaisquer subcampos de produção/curing não suportados nativamente
- postforge_data_json (se necessário):
  - finishings[]/materials[] com dynamicFields e staticFields
- Nota: o uso de JSONB mantém velocidade de entrega e não trava por dependência de migrações estruturais.

---

## 15. Validações por Papel – Matriz com Paths

### 15.1 Gerais
- context.componentId: uuid
- context.version: number > 0
- budgetCalculations.estimated_forge_days: number > 0
- budgetCalculations.final_cost_per_piece: number > 0
- budgetCalculations.final_price_per_piece: number > 0
- budgetCalculations.estimated_prod_days: number > 0

### 15.2 Forge
- forgeData.production.itemsPerTable: number > 0
- forgeData.production.printHoursPerTable: number > 0
- forgeData.production.volumePerTable: number >= 0
- forgeData.production.supportVolumePerTable: number >= 0
- forgeData.production.timeEstimates.modelingHours: number >= 0
- forgeData.production.timeEstimates.slicingHours: number >= 0
- forgeData.production.timeEstimates.maintenanceHoursPerTable: number >= 0

#### Cura (condicional)
- forgeData.curing.isRequired === true ⇒
  - forgeData.curing.machine.id: uuid
  - forgeData.curing.hours: number > 0
  - forgeData.curing.itemsPerTable: number > 0

### 15.3 Post-Forge
Para cada finishing.material:
- dynamicFields.unitConsumption: number > 0
- dynamicFields.applicationHours: number > 0
- staticFields.name: string.trim().length > 0
- staticFields.supplierName: string.trim().length > 0
- staticFields.unitCost: number > 0
- staticFields.purchaseLink: string | null (normalizado), opcional
- staticFields.description: string | null (normalizado), opcional

### 15.4 Normalização
- Strings: trim
- Nulls: undefined → null, strings vazias controladas para campos textuais opcionais
- Números: validar parse e faixas; rejeitar NaN

### 15.5 Autorização
- userRole = Forge ⇒ pode enviar forgeData
- userRole = Post-Forge ⇒ pode enviar postForgeData
- userRole = Admin ⇒ pode enviar ambos
- Nota: sempre podemos aceitar ambos e validar apenas a parte relevante ao papel, para reuso de UI multi-role

---

## 16. Fluxo de Transação – Passo a Passo Técnico

1) Autenticar (getAuthenticatedUserId), derivar language (pt/en)
2) Validar payload (geral + por role)
3) BEGIN
4) Query status inicial: `SELECT id FROM "BudgetStatus" WHERE "order" = 0 LIMIT 1` (erro 500 se não encontrado)
5) INSERT em "ComponentBudget" com campos mapeados
6) INSERT em "BudgetStatusHistory" (component_budget_id, status_id, user_id, notes=null)
7) COMMIT
8) Responder 200 { success: true, data: { budgetId, componentId, version, statusId }, message }

— ROLLBACK em qualquer falha de validação lógica após BEGIN (se ocorrer), ou exceções DB.

---

## 17. Tratamento de Erros e Mensagens (PT/EN)

- 405: Método não permitido / Method not allowed
- 401: Autenticação obrigatória / Authentication required
- 400: Erros de validação (lista de { path, message })
- 500: Erro interno ao submeter orçamento / Internal server error while submitting budget

Mensagens exemplificadas:
- PT: "Campo obrigatório em falta: budgetCalculations.final_price_per_piece"
- EN: "Missing required field: budgetCalculations.final_price_per_piece"

---
