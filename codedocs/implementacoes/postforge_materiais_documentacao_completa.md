# Sistema Post‑Forge – Gestão de Materiais: Autocomplete, Validação e Persistência v2

Autor: Thúlio Silva

---

## 🎯 Objetivo
Documentar, de forma abrangente, todas as alterações concebidas e implementadas para o sistema de gestão de materiais do Post‑Forge, cobrindo frontend e backend, decisões de design, validações, APIs e procedimentos de verificação. Este documento serve como referência de manutenção e onboarding técnico.

---

## 🧭 Visão Geral das Entregas
- Remoção de mocks e alinhamento do Post‑Forge com a fonte única de dados do orçamento do componente.
- Carregamento de catálogo de acabamentos (finishings) e mapeamento do componente via página de orçamento.
- Correções de submissão (Forge e Post‑Forge) e normalização de IDs/UUIDs no cliente.
- Materiais Post‑Forge:
  - Campo “Link de Compra” obrigatório (frontend e backend).
  - Criação automática de FinishingMaterial quando não há seleção do catálogo.
  - Checagem de unicidade case‑insensitive por (name, brand_name) ao criar.
  - Lógica “Smart Update”: UPDATE quando campos suplementares mudam; INSERT quando identidade (nome/marca) muda.
  - Autocomplete de nome do material e, agora, também de marca.
  - Pesquisa por marca também no dropdown de nome do material.
- Endpoint novo para listar marcas distintas de FinishingMaterial.
- SQLs de verificação rápida no pgAdmin para inspeção de dados persistidos.

---

## 🧩 Escopo técnico
- Frontend (React/Next.js):
  - Formulários de orçamento do componente (Forge e Post‑Forge)
  - UI e validações locais de materiais
  - Autocomplete (nome de material e marca)
  - Montagem do payload da submissão
- Backend (Next.js API Routes, PostgreSQL):
  - Endpoint de submissão de orçamento v2
  - Endpoints de catálogo auxiliar (materiais e marcas)
  - Transações SQL, consistência de snapshots e integridade referencial

---

## 🖥️ Frontend

### Páginas e Componentes alterados
- 00_frontend/src/app/component/[basecomponentId]/[version]/budget/page.js
- 00_frontend/src/components/forms/budgetforms/PostForgeBudgetForm.js
- 00_frontend/src/components/forms/budgetforms/PostForgeMaterialForm.js

### Carregamento de catálogo e mapeamento inicial (Post‑Forge)
- O PostForgeBudgetForm passa a preferir dados vindos da página (budgetData.finishings), com fallback para o endpoint legacy de catálogo caso necessário.
- Quando existir mapeamento de acabamentos do componente, a UI inicializa a lista com esse mapeamento e sequências; caso contrário, lista todo o catálogo por tipo.
- Persiste/recupera rascunho no localStorage.

### Validações (cliente)
- Forge
  - Compatibilidade de suporte: aceita tanto UUID quanto objeto { id } e normaliza antes de validar.
- Post‑Forge
  - Acabamento: se presente, precisa ser UUID.
  - Materiais:
    - Sempre exigir: nome, marca, consumo unitário (>0), custo unitário (>0), horas de aplicação (>0).
    - “Link de Compra”: obrigatório para TODOS os materiais (catálogo/não catálogo).
    - Para materiais novos (sem UUID de catálogo), validar também nome+marca (além do link) — necessária à criação.

### Payload enviado (cliente)
Para cada material:
- finishingMaterialId: UUID quando selecionado do catálogo; ausente para novos.
- materialName: nome do material (apoia o backend na criação).
- brandNameSnapshot: marca (supplierName na UI).
- purchaseLinkSnapshot: link (sempre obrigatório).
- unitCostSnapshot, currencySnapshot: custos/ISO currency (opcional para novos; backend usa defaults do catálogo quando existir).
- notes: descrição.

Isso permite ao backend decidir entre:
- Vincular a um material existente
- Atualizar material existente (campos suplementares)
- Criar novo material (quando identidade mudou ou não há seleção do catálogo)

### Autocomplete – Nome do material (melhorias)
- Endpoint: /api/get-existing-finishing-materials (pré‑existente)
- Agora o filtro local considera também a marca (brand_name) além do nome:
  - Digitar “UHU” mostra materiais cuja brand_name contenha “UHU”, mesmo que o nome não contenha.
- Comportamento UI: idêntico ao anterior (navegação por teclado, highlight, fechar ao clicar fora/scroll, etc.).

### Autocomplete – Marca do material (novo)
- Novo componente BrandNameSearchInput criado com a mesma base/UX do autocomplete de nome.
- Endpoint: /api/get-existing-finishing-brands (novo) – retorna apenas strings de marca.
- Pré‑carrega uma vez e filtra localmente conforme digitação.
- Seleção escreve diretamente no campo supplierName do material.

### Correções de UX/bug
- Limpeza de referência inexistente (currentFormRef) após submissão bem‑sucedida, substituído por resets independentes dos 2 forms (forgeFormRef, postForgeFormRef).
- Toasts mais informativos durante a validação do payload antes do POST.

---

## 🗄️ Backend

### Endpoint principal
- Arquivo: 01_backend/src/pages/api/submit-component-budget-v2.js
- Responsável por:
  - Validar método (POST) e autenticação
  - Validar contexto (componentId, userRole)
  - Iniciar transação
  - Inserir ComponentBudget (e campos de Forge se enviados)
  - Processar Post‑Forge (acabamentos + materiais)
  - Commit/rollback com logs estruturados

### Processamento Post‑Forge – Acabamentos
- Para cada finishing enviado, insere ComponentBudgetFinishing (com total_drying_hours, sequence_override, notes opcionais) e, na sequência, os materiais.

### Processamento Post‑Forge – Materiais
- Validações:
  - quantity > 0, application_hours > 0
  - purchase_link_snapshot obrigatório para TODOS os materiais
- Caminhos de execução:
  1) Sem UUID (novo material):
     - Exige materialName e brandNameSnapshot.
     - Busca case‑insensitive por (name, brand_name) na tabela FinishingMaterial.
     - Se encontrar, usa o existente; senão, cria (is_active=true), preenchendo: name, brand_name, description, default_unit_cost, currency, unit_of_measurement, purchase_link.
  2) Com UUID (material de catálogo selecionado):
     - Carrega a linha completa do catálogo.
     - “Smart Update”:
       - Se nome ou marca mudaram (identidade): cria NOVO material (INSERT) com os novos valores e usa o novo id.
       - Caso contrário: faz UPDATE apenas nos campos suplementares que mudaram (description, purchase_link, default_unit_cost, currency, unit_of_measurement).
     - Snapshots (unit_cost_snapshot, currency_snapshot) são garantidos a partir do registro vigente (ou do novo registro criado).
- Por fim, insere ComponentBudgetFinishingMaterial usando o id determinado e snapshots de custo/moeda + brand/purchase link/notes.

### Logs de suporte
- Logs por etapa: entrada, preview de INSERT, IDs gerados, contagens de acabamentos/materiais, e erros SQL específicos (códigos PG 23503, 23502, etc.).

---

## 🌐 Endpoints auxiliares

### GET /api/get-existing-finishing-materials (existente)
- Lista materiais de acabamento ativos com dados principais (id, name, brand_name, default_unit_cost, currency, unit_of_measurement, purchase_link, description), com ?search por nome (no front, filtramos local por nome+marca).

### GET /api/get-existing-finishing-brands (novo)
- Lista marcas distintas (strings) de FinishingMaterial.
- Correção SQL aplicada: DISTINCT dentro de sub‑query e ORDER BY no select externo para evitar o erro “for SELECT DISTINCT, ORDER BY expressions must appear in select list”.
- Protegido por autenticação, ordenado por LOWER(brand_name).

---

## 🔒 Segurança e Integridade
- Autenticação obrigatória em todos os endpoints de dados.
- SQL com parâmetros; sem concatenação de strings de input.
- Validações consistentes cliente/servidor: números positivos, UUIDs, e link de compra obrigatório para todos os materiais.
- Caso de criação: is_active=true por padrão em novos FinishingMaterial, para aparecerem nas listas futuras.
- “Smart Update” evita reescrever identidade inadvertidamente; quando a identidade muda, criamos um novo registro em vez de alterar o id existente.

---

## 🧪 Verificação e Testes (pgAdmin)
Consultas úteis (ajuste os UUIDs conforme necessário):

1) Verificar ComponentBudget:
```sql
SELECT id, component_id, submission_mode, is_active, support_material_id,
       items_per_table, print_min_per_table, g_per_table,
       modeling_min, slicing_min, maintenance_min_per_table,
       curing_machine_id, curing_min, curing_items_per_table,
       final_price_per_piece
FROM "ComponentBudget"
WHERE id = '<budgetId>'::uuid;
```

2) Contagens Post‑Forge:
```sql
WITH p AS (SELECT '<budgetId>'::uuid AS budget_id)
SELECT
  (SELECT COUNT(*) FROM "ComponentBudgetFinishing" cbf WHERE cbf.component_budget_id = (SELECT budget_id FROM p)) AS finishings_count,
  (SELECT COUNT(*) FROM "ComponentBudgetFinishingMaterial" cbfm
     JOIN "ComponentBudgetFinishing" cbf ON cbf.id = cbfm.component_budget_finishing_id
   WHERE cbf.component_budget_id = (SELECT budget_id FROM p)) AS materials_count;
```

3) Lista materiais por acabamento:
```sql
WITH p AS (SELECT '<budgetId>'::uuid AS budget_id)
SELECT cbf.id AS cbf_id, f.name AS finishing_name,
       fm.id AS finishing_material_id, fm.name AS material_name, fm.brand_name,
       cbfm.quantity, cbfm.application_hours,
       cbfm.unit_cost_snapshot, fm.default_unit_cost,
       cbfm.currency_snapshot, fm.currency,
       cbfm.purchase_link_snapshot
FROM "ComponentBudgetFinishingMaterial" cbfm
JOIN "ComponentBudgetFinishing" cbf ON cbf.id = cbfm.component_budget_finishing_id
JOIN "Finishing" f ON f.id = cbf.finishing_id
JOIN "FinishingMaterial" fm ON fm.id = cbfm.finishing_material_id
WHERE cbf.component_budget_id = (SELECT budget_id FROM p)
ORDER BY finishing_name, material_name;
```

4) Novos materiais criados (por nome/marca):
```sql
SELECT id, name, brand_name, purchase_link, default_unit_cost, currency, is_active
FROM "FinishingMaterial"
WHERE LOWER(name) = LOWER('<NOME>') AND LOWER(brand_name) = LOWER('<MARCA>');
```

---

## ⚙️ Operacional e Performance
- Pré‑carregamento e filtragem local para os dropdowns reduzem chamadas ao backend.
- Transações por submissão com COMMIT/ROLLBACK garantem consistência.
- Logs estruturados auxiliam troubleshooting e auditoria.
- Validação em camadas (UI + payload + servidor) minimiza round‑trips e erros de dados.

---

## 📌 Aprendizados e Notas Importantes
- Normalização de ID de suporte no Forge (string UUID vs objeto { id }) e impacto na validação do payload.
- A obrigatoriedade universal do “Link de Compra” elimina ambiguidade de origem do custo no tempo (melhor governança de catálogo).
- Estratégia de “Smart Update” assegura manutenção do histórico lógico: identidade diferente → novo registro; ajustes suplementares → update controlado.
- Cuidados com DISTINCT + ORDER BY no PostgreSQL: use sub‑query com ORDER BY fora.
- Autocomplete de marca aumenta consistência de dados e reduz variantes grafadas.

---

## 🚀 Próximos Passos (opcional)
- Validação de URL (http/https) no frontend para “Link de Compra”.
- Realçar a correspondência por marca no dropdown de materiais (p. ex., destacar a brand quando corresponder).
- Injetar, após criação, o novo material diretamente no store local/catálogo para seleção imediata (sem refresh).
- Paginação/consulta incremental de listas se o volume crescer muito.

---

FIM — Thúlio Silva

