# Aplicação da Nova API de Submissão de Orçamento por Componente (v2)

Autor: Thúlio Silva

---

## 1) Objetivo e Visão Geral

Este documento, extremamente detalhado, consolida o plano de ação para a implementação da nova API de submissão de orçamento por componente (v2). O foco desta fase é exclusivamente a persistência de dados coerente com o modelo atual da base, adiando qualquer integração com ficheiros/OneDrive. O documento incorpora todas as decisões técnicas e de produto estabelecidas durante o desenvolvimento do Autocomplete de Materiais (Post-Forge) e as diretrizes das pastas de planning e DB.

Princípios-chaves:
- Minimalismo: a API aceita apenas os campos necessários para persistir no modelo de BD atual; tudo o que for excedente no payload do frontend é ignorado.
- Consistência: seguir exatamente os padrões de endpoints do projeto (allowCors, autenticação, mensagens PT/EN, estrutura de resposta, transações, SQL parametrizado).
- Robustez: validações server-side focadas, normalização de null/undefined, e mensagens de erro claras com path do campo.
- Evolução segura: quando o schema não suportar algo, usar JSONB como fallback, sem bloquear a entrega; normalizações futuras poderão migrar esses dados.

---

## 2) Escopo e Limitações

Incluído:
- Endpoint POST /api/submit-component-budget-v2 (v2)
- Autenticação obrigatória, validações server-side, transações e persistência mínima
- Definição do status inicial pelo primeiro estado da ordem (BudgetStatus.order = 0)
- Mensagens de resposta PT/EN, coerentes com context.language (default EN)

Excluído nesta fase:
- Integração com OneDrive/ficheiros (será endereçada posteriormente)
- Atualização automática do catálogo FinishingMaterial (edições no front não escrevem no catálogo nesta fase)

---

## 3) Referenciais e Alinhamento com o Modelo de Dados

- Fonte de verdade: 03_files/db/DataBaseDescription.txt
- Planeamentos correlatos:
  - 03_files/planning/Mapeamento_Dados_Submissao_Orcamento_Componente.md (mapa de onde o front guarda os dados; usar para extrair apenas o necessário)
  - 03_files/planning/Sistema_Orcamento_Componente_Implementacao_Final.md (contexto de implementação)
  - 03_files/planning/documentacao_completa_impl_autocomplete_materiais_e_planeamento_api_submissao.md (lições e padrões do autocomplete)
- A API v2 deve ignorar dados supérfluos e extrair apenas o subconjunto que tem destino na BD.

---

## 4) Contrato da API v2 (Minimalista e Preciso)

- Método: POST
- Path: /api/submit-component-budget-v2
- Auth: obrigatória (getAuthenticatedUserId)
- Content-Type: application/json

Payload aceito (comentários indicam o que será consumido):
{
  "context": {
    "componentId": "uuid",        // OBRIGATÓRIO → ComponentBudget.component_id
    "version": 1,                  // OBRIGATÓRIO (>0) → ComponentBudget.version (se aplicável)
    "userRole": "Forge" | "Post-Forge" | "Admin", // influencia validações e submission_mode
    "language": "pt" | "en"       // opcional; define idioma das mensagens
  },
  "budgetCalculations": {          // campos calculados finais
    "estimated_forge_days": 2.5,   // >0 (se houver coluna ou JSONB)
    "final_cost_per_piece": 12.34, // >0 → ComponentBudget.final_cost_per_piece (se existir)
    "final_price_per_piece": 19.90,// >0 → ComponentBudget.final_price_per_piece
    "estimated_prod_days": 4.0     // >0 (se houver coluna ou JSONB)
  },
  "forgeData": {                   // opcional, mas validado se o papel exigir
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
      "machine": { "id": "uuid" },       // → curing_machine_id (se isRequired)
      "hours": 3.0,                         // → curing_hours
      "itemsPerTable": 20                   // → curing_items_per_table
    },
    "comments": {
      "internal": "...",                   // → ComponentBudget.internal_notes
      "external": "..."                    // → ComponentBudget.client_notes
    }
  },
  "postForgeData": {               // opcional, mas validado se o papel exigir
    "finishings": [
      {
        "finishingId": "uuid",           // se existir relacionamento específico
        "materials": [
          {
            "dynamicFields": {
              "unitConsumption": 0.5,     // >0
              "applicationHours": 1.25     // >0
            },
            "staticFields": {
              "name": "...",             // não vazio
              "supplierName": "...",      // não vazio
              "unitCost": 6.9,            // >0
              "purchaseLink": "https://..." | null,
              "description": "..." | null
            }
          }
        ]
      }
    ]
  }
}

Resposta (sucesso):
{
  "success": true,
  "message": "Orçamento submetido com sucesso.",
  "data": { "budgetId": "uuid", "componentId": "uuid", "version": 1, "statusId": "uuid" }
}

Resposta (erro validação):
{
  "success": false,
  "errors": [ { "path": "context.componentId", "message": "Campo obrigatório em falta" }, ... ]
}

---

## 5) Seleção do Status Inicial

- Regra: apanhar o primeiro status da ordem, isto é, registro de "BudgetStatus" onde o campo "order" = 0.
- Query típica: SELECT id FROM "BudgetStatus" WHERE "order" = 0 LIMIT 1;
- Se não existir, abortar com 500 (configuração inválida no ambiente).

---

## 6) Validações Server-side (por papel e coerência)

Geral:
- Auth obrigatória; language = context.language ?? 'en'.
- componentId (uuid), version (>0), budgetCalculations.* (>0) segundo colunas.

Post-Forge (se fornecido ou se o papel exigir dados de pós-acabamento):
- Para cada material: unitConsumption > 0, applicationHours > 0, name e supplierName não vazios, unitCost > 0.
- purchaseLink e description: normalizar para string ou null.

Forge (se fornecido ou se o papel exigir dados de produção):
- production.* coerentes (>=0 ou >0 conforme o caso)
- Se curing.isRequired: machine.id válido, hours > 0 e itemsPerTable > 0

Normalizações:
- Strings: trim.
- undefined → null.
- Campos desconhecidos: ignorar.

Mensagens PT/EN:
- Definidas por tabela simples de traduções no handler; PT prioritário quando solicitado.

---

## 7) Persistência (Transação e Mapeamento)

Estratégia:
- Iniciar transação (BEGIN).
- Obter status_id do "BudgetStatus" com order=0.
- Insert em "ComponentBudget" com o mínimo necessário:
  - component_id, version, status_id
  - submitted_by_user_id (user autenticado)
  - submission_mode: 'forge' | 'post-forge' | 'admin' (derivado de context.userRole)
  - final_price_per_piece, final_cost_per_piece (se colunas existirem); estimated_* se existirem
  - production mapeado para: items_per_table, print_hours_per_table, volume_per_table, support_volume_per_table
  - timeEstimates mapeado para: modeling_hours, slicing_hours, maintenance_hours_per_table
  - curing mapeado para: curing_machine_id, curing_hours, curing_items_per_table (e opcional curing_auto_filled=false)
  - comments → internal_notes, client_notes
- Caso algum sub-bloco não tenha colunas normalizadas disponíveis:
  - Guardar em JSONB de fallback (ex.: forge_data_json, postforge_data_json) no próprio registo, se disponíveis
- Inserir em "BudgetStatusHistory" (component_budget_id, status_id, user_id, timestamp)
- COMMIT.

Erros:
- ROLLBACK e resposta 400 para validação; 500 para exceções.

---

## 8) Estrutura de Erros e Respostas

- success: boolean
- message: string (curta)
- data: { ids, statusId }
- errors: lista com objetos { path, message }
- HTTP: 200 (sucesso), 400 (validação), 401 (auth), 405 (método), 500 (erro interno)

---

## 9) Segurança e Qualidade

- SQL parametrizado (nunca concatenar input direto)
- Autenticação obrigatória; checagem de permissões por papel se necessário
- Normalização de null/empty; evitar vazar dados sensíveis em mensagens
- Estrutura consistente com demais APIs; logging mínimo e útil

---

## 10) Testes Recomendados

Unitários:
- Validações por papel (Forge/Post-Forge/Admin)
- Normalização (null/undefined → null; strings trim)
- Seleção do status order=0

Integração:
- Submissão minimal válida (apenas cálculos + alguns campos de produção)
- Fluxo com curing obrigatório
- Fluxo com materiais sem link/descrição (aplicar null/coerência)
- Erros de validação com paths corretos

---

## 11) Passos de Implementação (Check-list Técnico)

1. Criar 01_backend/src/pages/api/submit-component-budget-v2.js com allowCors.
2. Validar método=POST; autenticar via getAuthenticatedUserId.
3. Extrair context, budgetCalculations, forgeData, postForgeData; filtrar apenas campos persistíveis.
4. Validar conforme regras acima; acumular erros com path e idioma.
5. BEGIN; SELECT status_id (BudgetStatus.order=0).
6. INSERT em ComponentBudget com os campos mapeados.
7. INSERT em BudgetStatusHistory (component_budget_id, status_id, user_id).
8. COMMIT; responder sucesso com ids e status.
9. ROLLBACK + 400/500 em erros; mensagens PT/EN.

---

## 12) Notas Operacionais e Próximos Passos

- Nesta fase, ignorar totalmente OneDrive/ficheiros.
- Em versão futura, adicionar idempotência (ex.: lock por componentId+version, ou hash do payload) e auditoria detalhada.
- Avaliar necessidade de normalização definitiva de postForgeData e forgeData (migrar do JSONB para tabelas auxiliares), conforme roadmap.

---

Thúlio Silva



Plano confirmado e documentação criada
Ajuste aplicado: o status inicial do orçamento será obtido em BudgetStatus pelo campo order = 0 (primeiro status), não por nome.
Mantemos OneDrive fora do escopo.
A API v2 receberá e persistirá apenas os campos coerentes com o schema atual; o resto será ignorado. Onde faltar estrutura normalizada, podemos usar JSONB como fallback para não bloquear a entrega.
Documentos criados/atualizados
Documento “grande e completo” do planejamento e histórico já estava criado e revisado:
03_files/planning/documentacao_completa_impl_autocomplete_materiais_e_planeamento_api_submissao.md
Novo documento de aplicação da nova API, com foco na implementação, extremamente detalhado:
03_files/planning/Aplicacao_Nova_Api_Submisssao.md
Assinado: Thúlio Silva
Este documento cobre:

Escopo, princípios e exclusões
Contrato minimalista do endpoint POST /api/submit-component-budget-v2
Seleção do status inicial por BudgetStatus.order = 0
Validações por papel (Forge/Post-Forge/Admin)
Persistência transacional no ComponentBudget, BudgetStatusHistory e uso de JSONB como fallback
Estrutura de erros e mensagens PT/EN
Checklist técnico de implementação
Testes unitários e de integração recomendados