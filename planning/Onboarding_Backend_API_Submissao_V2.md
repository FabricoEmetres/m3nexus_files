# Onboarding Backend – Contexto do Projeto e Guia para Implementar a API de Submissão de Orçamento (v2)

Autor: Thúlio Silva

---

## 1) Sumário Executivo

Este documento orienta a pessoa de backend a implementar a nova API de submissão de orçamento por componente (v2), explicando o contexto, decisões já tomadas, requisitos funcionais e técnicos, padrões do projeto, contrato da API, mapeamento para a base de dados, validações, testes e próximos passos. Foco absoluto em persistência de dados. Integração com OneDrive/ficheiros será feita posteriormente.

---

## 2) Contexto do Projeto (o que é e como chegamos aqui)

- A aplicação realiza orçamentação por componente em duas frentes: Forge (produção/impressão 3D) e Post-Forge (acabamentos/materiais) e Admin (tem acesso a ambos).
- Avanços recentes (frontend + backend):
  - Autocomplete de Materiais (Post-Forge) implementado no PostForgeMaterialForm, replicando a UX do "neworder" (dropdown com animações, navegação por teclado, fechar em blur/scroll/clique fora, seleção com Enter/click).
  - Endpoint backend GET /api/get-existing-finishing-materials para alimentar o autocomplete (com auth e search opcional), e seed idempotente de materiais reais (tabela FinishingMaterial).
  - Ao selecionar um material, o formulário aplica valores sequencialmente (nome → marca → custo → link → descrição) com animação sutil; quando o material selecionado não possui um valor, o campo correspondente é esvaziado (evitando dados "fantasma").
  - Botão de abrir link (ícone FontAwesome arrow-up-right-from-square) no campo "Link de Compra".
- Próximo passo: nova API de submissão (v2) para persistir os dados do orçamento, de forma minimalista e alinhada ao modelo da BD.

---

## 3) O que Já Existe (para referência)

- Endpoint antigo: submit-component-budget (v1). Está desatualizado e segue lógica diferente. Deve ser usado apenas como referência de padrão (allowCors, autenticação, estrutura de resposta, estilo de código), não como base lógica.
- OneDrive: há endpoints e funções auxiliares, porém a integração será ignorada nesta fase da v2.
- Documentos de apoio (planejamento e DB):
  - 03_files/planning/Aplicacao_Nova_Api_Submisssao.md
  - 03_files/planning/documentacao_completa_impl_autocomplete_materiais_e_planeamento_api_submissao.md
  - 03_files/planning/Mapeamento_Dados_Submissao_Orcamento_Componente.md
  - 03_files/planning/Sistema_Orcamento_Componente_Implementacao_Final.md
  - 03_files/db/DataBaseDescription.txt

---

## 4) Problema a Resolver (v2)

- Precisamos de um novo endpoint POST /api/submit-component-budget-v2 que aceite um payload rico do frontend, mas PERSISTA apenas os campos que existem e fazem sentido no modelo atual da base de dados.
- Minimalismo: mesmo que o front envie 100 campos, só extraímos ~40 relevantes. O restante é ignorado.
- Status inicial do orçamento: deve ser o registro da tabela BudgetStatus cujo campo "order" = 0 (primeiro status da cadeia). Não selecionar por título.

---

## 5) Requisitos Funcionais (essência)

- Autenticação obrigatória (getAuthenticatedUserId). 401 se não autenticado.
- Persistir em ComponentBudget (e tabelas relacionadas) os dados mínimos: component_id, version, status inicial (order=0), cálculos finais, produção/curing quando aplicável, e comentários (internos/cliente).
- Registrar a mudança em BudgetStatusHistory (component_budget_id, status_id, user_id, timestamp).
- Mensagens em PT/EN de acordo com context.language (default EN).

---

## 6) Requisitos Não Funcionais e Padrões do Projeto

- Código de endpoint Next.js em 01_backend/src/pages/api/...
- Padrões:
  - allowCors(handler)
  - getAuthenticatedUserId(req)
  - pool do DB via '@/lib/db'
  - SQL parametrizado
  - Estrutura de resposta consistente: { success, message?, data?, errors? }
  - Tratamento de erros: 405 (método), 401 (auth), 400 (validação), 500 (exceção)
- Transação (BEGIN/COMMIT/ROLLBACK) para toda a submissão.
- Segurança e normalização de inputs: trim, null/undefined coerentes, validações numéricas (>0 quando aplicável).

---

## 7) Contrato Minimalista da API v2

- Método: POST
- Path: /api/submit-component-budget-v2
- Auth: obrigatória
- Content-Type: application/json

Payload esperado (apenas campos relevantes serão extraídos; demais são ignorados):
{
  "context": {
    "componentId": "uuid",        // OBRIGATÓRIO → ComponentBudget.component_id
    "version": 1,                  // OBRIGATÓRIO (>0)
    "userRole": "Forge" | "Post-Forge" | "Admin", // define submission_mode e validações
    "language": "pt" | "en"       // opcional; define idioma das mensagens (default EN)
  },
  "budgetCalculations": {
    "estimated_forge_days": 2.5,   // >0 (se houver coluna ou JSONB)
    "final_cost_per_piece": 12.34, // >0 (se houver coluna)
    "final_price_per_piece": 19.90,// >0 (há coluna)
    "estimated_prod_days": 4.0     // >0 (se houver coluna ou JSONB)
  },
  "forgeData": {
    "production": {
      "itemsPerTable": 20,                 // → items_per_table
      "printHoursPerTable": 8.5,           // → print_hours_per_table
      "volumePerTable": 1100.0,            // → volume_per_table
      "supportVolumePerTable": 75.0,       // → support_volume_per_table
      "timeEstimates": {
        "modelingHours": 1.0,              // → modeling_hours
        "slicingHours": 0.5,               // → slicing_hours
        "maintenanceHoursPerTable": 0.25   // → maintenance_hours_per_table
      }
    },
    "curing": {
      "isRequired": true,
      "machine": { "id": "uuid" },       // → curing_machine_id
      "hours": 3.0,                         // → curing_hours
      "itemsPerTable": 20                   // → curing_items_per_table
    },
    "comments": {
      "internal": "...",                   // → internal_notes
      "external": "..."                    // → client_notes
    }
  },
  "postForgeData": {
    "finishings": [
      {
        "finishingId": "uuid",
        "materials": [
          {
            "dynamicFields": {
              "unitConsumption": 0.5,       // >0
              "applicationHours": 1.25       // >0
            },
            "staticFields": {
              "name": "...",                // não vazio
              "supplierName": "...",         // não vazio
              "unitCost": 6.9,               // >0
              "purchaseLink": "https://..." | null,
              "description": "..." | null
            }
          }
        ]
      }
    ]
  }
}

Resposta (sucesso): { success: true, message, data: { budgetId, componentId, version, statusId } }
Resposta (erro de validação): { success: false, errors: [ { path, message }, ... ] }

---

## 8) Mapeamento para Base de Dados (resumo)

- Tabelas principais (ver DataBaseDescription.txt para detalhes):
  - ComponentBudget: registo principal do orçamento
    - Ex.: component_id, version, status_id, submitted_by_user_id, submission_mode
    - Produção: items_per_table, print_hours_per_table, volume_per_table, support_volume_per_table
    - Tempos: modeling_hours, slicing_hours, maintenance_hours_per_table
    - Curing: curing_machine_id, curing_hours, curing_items_per_table, curing_auto_filled (se aplicável)
    - Cálculos finais: final_price_per_piece, final_cost_per_piece (se existir), outros estimados
    - Notas: internal_notes, client_notes
  - BudgetStatus: id, title, description, order (usaremos order = 0 para o status inicial)
  - BudgetStatusHistory: component_budget_id, status_id, user_id, timestamp, notes
- Post-Forge: se o schema não possuir tabelas normalizadas (p.ex., ComponentBudgetFinishing/Material), usar JSONB de fallback (ex.: postforge_data_json) no próprio ComponentBudget.
- Forge extra (se faltar coluna): usar forge_data_json como fallback.

---

## 9) Validações Server-side

- context:
  - componentId: UUID válido; version: inteiro > 0
  - userRole: obrigatório; define submission_mode ('forge'|'post-forge'|'admin')
- budgetCalculations: números > 0 onde aplicável
- postForgeData (se fornecido): por material, unitConsumption>0, applicationHours>0, name e supplierName não vazios, unitCost>0
- forgeData (se fornecido): produção coerente; se curing.isRequired, machine.id e hours/itemsPerTable > 0
- Normalização: strings trim; undefined→null; ignorar campos desconhecidos
- Mensagens PT/EN segundo context.language

---

## 10) Fluxo de Persistência (Transação)

1. Verificar método=POST; autenticar (401 se falhar)
2. Validar payload minimalista; acumular erros com path (400 se existirem)
3. BEGIN
4. Selecionar status inicial: SELECT id FROM "BudgetStatus" WHERE "order" = 0 LIMIT 1;
5. INSERT em "ComponentBudget" com campos mapeados
6. INSERT em "BudgetStatusHistory" (component_budget_id, status_id, user_id)
7. COMMIT
8. Responder sucesso (budgetId, componentId, version, statusId); PT/EN

---

## 11) Estrutura do Código e Helpers

- Local do endpoint: 01_backend/src/pages/api/submit-component-budget-v2.js
- Padrões: allowCors(handler), getAuthenticatedUserId(req), import pool de '@/lib/db'
- Esqueleto exemplificativo (resumo):

```js
import pool from '@/lib/db';
import { allowCors } from '@/lib/cors';
import { getAuthenticatedUserId } from '@/lib/userAuth';

async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ success:false, error:'Method not allowed' });
  const userId = await getAuthenticatedUserId(req);
  if (!userId) return res.status(401).json({ success:false, error:'Authentication required' });
  const lang = req.body?.context?.language === 'pt' ? 'pt' : 'en';

  // 1) Extract & validate minimal payload (build errors[] with {path,message})
  // 2) If errors.length, return 400 with errors

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const status = await client.query('SELECT id FROM "BudgetStatus" WHERE "order" = 0 LIMIT 1');
    if (!status.rowCount) throw new Error('No initial budget status (order=0) configured');

    // 3) INSERT into ComponentBudget (mapped fields only)
    // 4) INSERT into BudgetStatusHistory

    await client.query('COMMIT');
    return res.status(200).json({ success:true, data:{ /* ids */ }, message: lang==='pt'? 'Orçamento submetido com sucesso.' : 'Budget submitted successfully.' });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('submit-component-budget-v2 error:', e);
    return res.status(500).json({ success:false, error: lang==='pt'? 'Erro interno ao submeter orçamento' : 'Internal server error while submitting budget' });
  } finally {
    client.release();
  }
}

export default allowCors(handler);
```

---

## 12) Testes (Unitários e Integração)

- Unit:
  - Validações por papel (Forge/Post-Forge/Admin)
  - Normalização de null/empty e trim
  - Seleção de status order=0
- Integração:
  - Sucesso mínimo (apenas cálculos + alguns campos de produção) → 200
  - Post-Forge com materiais faltando link/descrição (null/empty normalizado) → 200
  - Curing obrigatório sem dados → 400 (erros com paths)
  - Auth ausente → 401

---

## 13) Riscos e Mitigações

- Falta de colunas para alguns campos: usar JSONB de fallback até normalização.
- Divergência entre front e DB: validadores minimalistas garantem que só persiste o que o DB entende.
- Injeção SQL: consultas parametrizadas apenas.
- Regressões: testes unitários e integração cobrem casos positivos/negativos.

---

## 14) Roadmap Futuro (fora deste escopo)

- OneDrive: mover/associar ficheiros após criação do orçamento
- Idempotência: chave natural (componentId+version) e/ou hash do payload
- Auditoria de atualização de materiais: fluxo de propostas/approvals
- Normalização completa de postForgeData/forgeData (migrar JSONB → tabelas auxiliares, se for o caso)

---

## 15) Definition of Done (DoD)

- Endpoint POST /api/submit-component-budget-v2 criado
- Autenticação e validações conforme descrito
- Persistência transacional OK (ComponentBudget + BudgetStatusHistory)
- Status inicial por BudgetStatus.order = 0
- Respostas PT/EN consistentes
- Testes unitários e um de integração mínimo passando
- Sem dependências de OneDrive nesta fase

---

## 16) Referências

- DB: 03_files/db/DataBaseDescription.txt
- Planejamento: 
  - 03_files/planning/Aplicacao_Nova_Api_Submisssao.md
  - 03_files/planning/documentacao_completa_impl_autocomplete_materiais_e_planeamento_api_submissao.md
  - 03_files/planning/Mapeamento_Dados_Submissao_Orcamento_Componente.md
  - 03_files/planning/Sistema_Orcamento_Componente_Implementacao_Final.md

---

Thúlio Silva

