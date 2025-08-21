# Orçamentação de Componentes — Forge e Post‑Forge (v2)

Assunto: Documentação técnica completa, decisões, lições aprendidas e plano de evolução

Autor: Thúlio Silva

## Sumário executivo

Este documento consolida as decisões e implementações realizadas sobre a submissão do orçamento de componentes, com foco no fluxo Forge e, em seguida, preparando o terreno para Post‑Forge (acabamentos). Inclui:
- Alinhamento completo com o novo schema da base de dados (v2), sem fallbacks de nomes antigos
- Lógica de cura e sinalização de “curing_min_edited” (incluindo semântica de NULL)
- Ajustes do payload frontend → backend (Forge) e recomendações para Post‑Forge
- Atualizações de visão de auditoria (VW_ComponentBudget_Detail)
- Padrões, validações, segurança, performance e plano incremental de próximos passos

## Contexto e objetivos

- Consolidar a pipeline de orçamento do componente em duas fases: Forge (produção + cura + suporte) e Post‑Forge (acabamentos e materiais de acabamento)
- Padronizar nomenclaturas (minutos, gramas) e campos persistidos, eliminando divergências
- Tornar o fluxo Admin capaz de submeter “Forge” e “Post‑Forge” de forma simples e clara
- Garantir integridade, auditabilidade e fácil manutenção/observabilidade

## Estado atual (Forge)

### Frontend
- Página: component/[basecomponentId]/[version]/budget
- Para role Forge e Admin (atualmente), o formulário Forge é renderizado para submissões Forge
- Payload ajustado para novos nomes do schema:
  - production
    - itemsPerTable (int)
    - printMinPerTable (int)
    - gPerTable (decimal)
    - supportMaterial (uuid | null) — enviado como ID
    - supportGPerTable (decimal | null)
    - timeEstimates: modelingMin, slicingMin, maintenanceMinPerTable (int)
  - curing
    - isRequired (bool)
    - machine.id (uuid)
    - min (int)
    - itemsPerTable (int)
  - comments: internal, external (texto)

### Backend (API v2)
- Endpoint de submissão do orçamento (Forge e, futuramente, Post‑Forge)
- Sem fallbacks: apenas nomes do novo schema são aceitos
- Derivação e validação de campos (minutos/gramas inteiros vs decimais)
- Inserção em ComponentBudget com colunas novas:
  - support_material_id, support_g_per_table
  - items_per_table, print_min_per_table, g_per_table
  - modeling_min, slicing_min, maintenance_min_per_table
  - curing_machine_id, curing_min, curing_items_per_table, curing_min_edited
  - final_price_per_piece, submission_mode, is_active, notes

### Base de dados (novo schema)
- "ComponentBudget" com colunas renomeadas e semântica em minutos/gramas
- Tabelas de suporte a cura:
  - MachineCure
  - Material_MachineCure (cure_minutes recomendado por material x máquina)

## Lógica de cura e “curing_min_edited”

- Objetivo: marcar quando o operador alterou manualmente o tempo de cura em relação ao recomendado
- Regras:
  1. Se a cura não for aplicável ou não for preenchida, curing_min_edited = NULL
  2. Se houver valor e recomendação disponíveis:
     - TRUE quando curing_min (fornecido) != cure_minutes (recomendado)
     - FALSE quando iguais
- Implementação: consulta a Material_MachineCure para material do componente + máquina selecionada, pegando cure_minutes recomendado
- Inserção: quando NULL, a coluna é omitida do INSERT (fica NULL na BD)

## Remoção de fallbacks (compatibilidade)

- O backend não aceita mais nomes antigos (ex.: printHoursPerTable, volumePerTable, modelingHours, slicingHours, etc.)
- Frontend já envia novos nomes
- Impacto: integrações/clientes que enviavam nomes antigos precisam alinhar com o novo payload

## Materiais de suporte

- Frontend: supportMaterial agora envia o ID (uuid) diretamente: `supportMaterial: state.supportMaterial?.id || null`
- Backend: persiste support_material_id + support_g_per_table

## VW_ComponentBudget_Detail (auditoria)

- Atualizada para utilizar nomes novos:
  - support_g_per_table, print_min_per_table, g_per_table,
    modeling_min, slicing_min, maintenance_min_per_table,
    curing_min, curing_min_edited
- Flags de verificação:
  - has_production_fields com base em items_per_table, print_min_per_table, g_per_table
  - has_curing_fields com base em curing_machine_id, curing_min, curing_items_per_table
- Detectores de inconsistência atualizados a partir dos novos nomes

## Catálogo e orçamentação de acabamentos (Post‑Forge)

### Catálogo
- Finishing: define o acabamento (id, finishingtype_id, name, description, cost_per_unit, ativo)
- FinishingMaterial: define materiais (id, name, brand, default_unit_cost, currency, uom, purchase_link, ativo)

### Instâncias por orçamento
- ComponentBudgetFinishing: o acabamento aplicado no orçamento:
  - component_budget_id (FK), finishing_id (FK)
  - total_drying_hours (NUMERIC), sequence_override (ordem), notes
- ComponentBudgetFinishingMaterial: materiais usados naquele acabamento:
  - component_budget_finishing_id (FK), finishing_material_id (FK)
  - quantity (NUMERIC, > 0), quantity_uom
  - application_hours (NUMERIC, > 0)
  - Snapshots: unit_cost_snapshot, currency_snapshot, brand_name_snapshot, purchase_link_snapshot

### Estrutura de payload sugerida (Post‑Forge)

- postForgeData.finishings: [
  {
    finishingId: uuid,
    totalDryingHours: number,
    sequenceOverride?: number,
    notes?: string,
    materials: [
      {
        finishingMaterialId: uuid,
        quantity: number,
        quantityUom?: string,
        applicationHours: number,
        unitCostSnapshot?: number,
        currencySnapshot?: string,
        brandNameSnapshot?: string,
        purchaseLinkSnapshot?: string,
        notes?: string
      }
    ]
  }
]

## Design para role Admin (submissão “com um clique”)

- Objetivo: permitir que Admin submeta Forge e Post‑Forge ao mesmo tempo
- Frontend:
  - Mostrar ambos os formulários (Forge e Post‑Forge) para Admin (como já está)
  - O botão “Submeter” usa o formulário ativo (ref corrente) e monta o payload correspondente
- Backend:
  - Aceitar forgeData e postForgeData no mesmo POST (ou em POSTs separados, conforme estratégia de atomicidade)
  - Em transação: inserir/atualizar ComponentBudget (Forge) e tabelas de acabamentos (Post‑Forge)
  - Estratégia de idempotência simples: chaves de correlação por orçamento (ou limpeza e re‑inserção dos acabamentos na submissão)

## Validações recomendadas (Post‑Forge)

- finishingId existente e ativo
- Para cada material:
  - finishingMaterialId existente e ativo
  - quantity > 0 (CHECK na BD já cobre)
  - applicationHours > 0 (CHECK na BD já cobre)
- totalDryingHours >= 0
- sequenceOverride sem colisões dentro do mesmo orçamento (opcional)

## Plano de evolução (incremental)

1) Backend: implementar persistência de postForgeData.finishings
   - Endpoint v2 atual passa a processar postForgeData quando enviado
   - Transação: inserir ComponentBudgetFinishing e ComponentBudgetFinishingMaterial
   - Snapshots: se unitCostSnapshot/currencySnapshot não forem enviados, preencher a partir de FinishingMaterial.default_unit_cost/currency
   - Logs detalhados, retornando IDs criados

2) Frontend: atualizar PostForgeBudgetForm e PostForgeMaterialForm
   - UI para totalDryingHours, sequenceOverride e lista de materiais (quantity, applicationHours, UOM)
   - Montar payload sugerido
   - Validações de formulário (numéricos, obrigatórios, etc.)

4) Auditoria e relatórios
   - Expandir VW_ComponentBudget_Detail com agregações JSON de acabamentos e materiais (se removida, recriar)
   - Indicadores: finishings_count, materials_count; has_finishings, has_finishing_materials

5) Testes
   - Unitários backend: validações de payload, inserções e snapshots
   - Integração: submissão completa Forge e Post‑Forge, transação, rollback ao falhar
   - E2E leve: fluxo Admin com ambos os formulários

6) Observabilidade
   - Logs com IDs correlacionados por orçamento
   - Métricas de inserts/erros por tipo de submissão (Forge/Post‑Forge)

## Segurança

- Autenticação obrigatória (userId); rejeitar não autenticados
- Autorização por role: Forge pode submeter apenas Forge; Post‑Forge apenas pós; Admin ambos
- Validações robustas com mensagens claras (400) e uso consistente de SQL parametrizado (evita injeção)
- Controle de tamanho de payload (protege contra inputs excessivos)
- Snapshots somente para orçamentação; não atualizar catálogo ao submeter orçamentos

## Performance e robustez

- Consultas de recomendação de cura com índices adequados (material_id, machinecure_id)
- Inserts em lote por acabamento e materiais (dentro de transação)
- Reintentos controlados para conflitos ocasionais (opcional)
- Tratamento de erros granulares: 400 para validação, 500 para falhas internas

## Edge cases

- Cura marcada “requerida” sem dados completos → erro 400
- Sem opções de cura disponíveis → curing_min_edited = NULL; campos de cura podem ficar NULL
- Materiais duplicados no mesmo acabamento → somar quantidades ou permitir duplicados (definir regra de UX/negócio)
- “Submeter ambos” com um lado inválido → decidir se falha tudo (transação) ou permite parcial (recomendado: transação completa)

## Operacional

- Migrações: garantir que o schema v2 está aplicado antes do deploy
- Backups antes de alterações estruturais
- Flags de feature (opcional) para ativar Post‑Forge após testes
- Rollback: manter script reverso das mudanças críticas

## Exemplos de payload (referência)

### Forge
{
  "context": { "componentId": "...", "userRole": "Forge", "language": "pt" },
  "forgeData": {
    "production": {
      "itemsPerTable": 10,
      "printMinPerTable": 83,
      "gPerTable": 50000,
      "supportMaterial": "<uuid-material-suporte>",
      "supportGPerTable": 123,
      "timeEstimates": { "modelingMin": 83, "slicingMin": 83, "maintenanceMinPerTable": 83 }
    },
    "curing": { "isRequired": true, "machine": { "id": "<uuid-machinecure>" }, "min": 30, "itemsPerTable": 45 },
    "comments": { "internal": "...", "external": "..." }
  },
  "budgetCalculations": { "final_price_per_piece": 12.34 }
}

### Post‑Forge (acabamentos)
{
  "context": { "componentId": "...", "userRole": "Post-Forge", "language": "pt" },
  "postForgeData": {
    "finishings": [
      {
        "finishingId": "<uuid-finishing>",
        "totalDryingHours": 1.5,
        "sequenceOverride": 1,
        "notes": "camada base",
        "materials": [
          {
            "finishingMaterialId": "<uuid-material>",
            "quantity": 0.25,
            "quantityUom": "L",
            "applicationHours": 0.5,
            "unitCostSnapshot": 12.5,
            "currencySnapshot": "EUR",
            "brandNameSnapshot": "MarcaX"
          }
        ]
      }
    ]
  }
}

---
Assinado: Thúlio Silva

