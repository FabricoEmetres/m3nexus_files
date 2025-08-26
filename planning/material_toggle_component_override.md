# Implementação do Toggle de Materiais por Componente 3D (Enable/Disable) no Post‑Forge

## 1) Contexto e Motivação
- Problema: Precisamos controlar, por componente 3D, quais materiais elegíveis de um acabamento devem ser efetivamente considerados no orçamento. O catálogo global define os materiais “possíveis”, mas para um determinado componente, alguns materiais podem não ser aplicáveis.
- Objetivo: Permitir habilitar/desabilitar materiais por componente sem apagar do catálogo, mantendo governança e consistência.
- Requisitos complementares:
  - Materiais desativados devem permanecer visíveis, porém cinzas e sem expandir.
  - Devem ser excluídos de cálculos e submissões, mas continuam reordenáveis.
  - Numeração visual dos materiais deve ignorar os desativados (com “~” para os desativados).
  - Persistência: apenas estado enabled/disabled na tabela override e ordem física normal no DB.

## 2) Escopo
- Frontend (Next.js/React):
  - Toggle ON/OFF no header do accordion do material (à esquerda do grip).
  - Estados visuais e bloqueio de ações quando OFF (não abre; duplicar desabilitado; remover e drag continuam).
  - Numeração visual recalculada após qualquer alteração.
  - Filtro de materiais desativados nos cálculos e na submissão.
  - GET inicial: todos ativos por padrão, a menos que override (DB) diga o contrário.
- Backend (Next.js API Routes / PostgreSQL):
  - Persistir overrides por componente na nova tabela “Component_FinishingMaterialOverride”.
  - Endpoint para upsert de is_enabled (true/false).
  - GET painel inicial: opcionalmente refletir overrides para que o toggle já inicie no estado persistido (padrão ON).

## 3) Modelo de Dados
- Catálogo global:
  - Finishing, FinishingMaterial, Finishing_FinishingMaterial (elegibilidade global).
- Overrides por componente:
  - Tabela: Component_FinishingMaterialOverride
    - component_id (UUID, FK Component)
    - finishing_id (UUID, FK Finishing)
    - finishing_material_id (UUID, FK FinishingMaterial)
    - is_enabled BOOLEAN (NULL=herdar; FALSE=desativado; TRUE=explicitamente ativado)
    - notes TEXT
    - created_by UUID (opcional)
    - created_at, updated_at TIMESTAMPTZ
    - PK (component_id, finishing_id, finishing_material_id)
- Regra efetiva:
  - Elegíveis = Finishing_FinishingMaterial LEFT JOIN override (para o component_id atual), excluindo onde override.is_enabled = FALSE (ou seja, COALESCE(is_enabled, TRUE) = TRUE).
- Herança (opcional futuro):
  - ComponentBase_FinishingMaterialOverride com precedência Base < Componente.

## 4) APIs

### 4.1 Persistência de override
- POST /api/component-finishing-material-override
- Auth: obrigatório
- Body:
  - componentId: UUID (obrigatório)
  - finishingId: UUID (obrigatório)
  - finishingMaterialId: UUID (obrigatório)
  - isEnabled: boolean (obrigatório)
  - notes?: string (opcional)
- Validações:
  - Verificar que componentId existe e é acessível pelo usuário.
  - finishingId e finishingMaterialId válidos.
- Operação:
  - UPSERT:
    - INSERT (component_id, finishing_id, finishing_material_id, is_enabled, notes?)
    - ON CONFLICT → UPDATE is_enabled, notes?, updated_at
- Resposta:
  - 200 { success: true }
  - 400/401/500 conforme erro

Exemplo de SQL (conceito):
````javascript path=01_backend/src/pages/api/component-finishing-material-override.js mode=EXCERPT
await pool.query(`
  INSERT INTO "Component_FinishingMaterialOverride"
    (component_id, finishing_id, finishing_material_id, is_enabled, notes)
  VALUES ($1, $2, $3, $4, $5)
  ON CONFLICT (component_id, finishing_id, finishing_material_id)
  DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    notes = COALESCE(EXCLUDED.notes, "Component_FinishingMaterialOverride".notes),
    updated_at = CURRENT_TIMESTAMP
`, [componentId, finishingId, finishingMaterialId, isEnabled, notes || null]);
````

### 4.2 GET inicial (orçamento por componente)
- Endpoint já existente: /api/get-component-budget-data
- Ajustes (opcionais mas recomendados):
  - Incluir o estado efetivo do toggle por material ao construir cf.materials:
    - isEnabled = (override.is_enabled === false) ? false : true
  - Padrão: se não houver override para aquele material, iniciar isEnabled=true.
- Nota de negócio: “No GET inicial da página de orçamentação de componente todos os materiais devem estar ativos.” Isso já é atendido pela regra padrão (sem override → ON).

## 5) Frontend – UI/UX

### 5.1 PostForgeMaterialAccordion
- Toggle switch (à esquerda do grip):
  - type=checkbox; checked = material.isEnabled !== false
  - onChange: atualiza material.isEnabled e chama a API de override
  - Dicas de usabilidade: tooltip “Ativar/Desativar material”
- Estados quando OFF:
  - Accordion não abre (toggleAccordion retorna sem ação)
  - Se estiver aberto e mudar para OFF, fechar automaticamente
  - Visual cinza com opacidade reduzida
  - Botão de duplicar: desabilitado (sem clique)
  - Botão de remover: permanece disponível (caso o user queira remover um material OFF)
  - Drag handle: permanece ativo (pode reordenar mesmo OFF)
- Ícone de seta (abrir/fechar): sem ação útil quando OFF, mas pode permanecer visível para consistência

Trecho UI de header:
````javascript path=00_frontend/src/components/forms/budgetforms/PostForgeMaterialAccordion.js mode=EXCERPT
<label className="flex items-center gap-2 select-none">
  <input
    type="checkbox"
    checked={material.isEnabled !== false}
    onChange={(e) => {
      e.stopPropagation();
      const enabled = e.target.checked;
      onMaterialChange(finishingId, materialIndex, 'isEnabled', enabled);
      // call API to persist
      // axiosInstance.post('/api/component-finishing-material-override', { componentId, finishingId, finishingMaterialId: material.finishingMaterialId, isEnabled: enabled })
    }}
    className="toggle-checkbox"
    title={material.isEnabled !== false ? 'Desativar material' : 'Ativar material'}
  />
  <span className="text-xs text-gray-400">{material.isEnabled !== false ? 'ON' : 'OFF'}</span>
</label>
````

Botão de duplicar desativado quando OFF:
````javascript path=00_frontend/src/components/forms/budgetforms/PostForgeMaterialAccordion.js mode=EXCERPT
<div
  onClick={material.isEnabled === false ? undefined : handleDuplicateClick}
  className={`p-1 ${material.isEnabled === false ? 'text-gray-300 cursor-not-allowed' : 'text-gray-400 hover:text-gray-500 cursor-pointer'}`}
  title={material.isEnabled === false ? 'Duplicar indisponível para material desativado' : 'Duplicar material'}
  aria-disabled={material.isEnabled === false}
>
  <FontAwesomeIcon icon={faCopy} className="w-4 h-4" />
</div>
````

Fechamento automático e bloqueio de abertura:
````javascript path=00_frontend/src/components/forms/budgetforms/PostForgeMaterialAccordion.js mode=EXCERPT
useEffect(() => {
  if (material.isEnabled === false && isOpen) setIsOpen(false);
}, [material.isEnabled, isOpen]);

const toggleAccordion = () => {
  if (material.isEnabled === false) return;
  // existing toggle code
};
````

### 5.2 Numeração visual (ignora OFF)
- Em PostForgeMaterialsList:
  - Calcular displayIndex para cada material:
    - Se OFF => “~”
    - Se ON => número sequencial entre os ON
- Após reordenar, recalcular (automático no render)

Exemplo de cálculo:
````javascript path=00_frontend/src/components/forms/budgetforms/PostForgeMaterialsList.js mode=EXCERPT
const enabledIndexList = (() => {
  let counter = 0;
  return finishing.materials.map(m => (m.isEnabled === false ? null : ++counter));
})();

...

<PostForgeMaterialAccordion
  ...
  displayIndex={material.isEnabled === false ? '~' : enabledIndexList[materialIndex]}
/>
````

### 5.3 Exclusão de cálculos e submissão
- Sempre filtrar materials ON:
  - Em cálculos parciais e totais: .filter(m => m.isEnabled !== false)
  - Em submissão: não enviar OFF
- Campos dinâmicos continuam iniciando em zero (unitConsumption, applicationHours, totalDryingHours).

## 6) Fluxos de Persistência
- Componente 3D → Finishing → Material
- On toggle change:
  - Atualiza estado local
  - Chama API de override (upsert)
  - Não alterar ordem física no banco (drag continua atualizando ordem normal quando for submetido/guardado em sua lógica atual)
- GET inicial:
  - Carrega materiais (todos ON por padrão)
  - Se override existir (is_enabled=false), refletir OFF

## 7) Segurança e Boas Práticas
- API de override: autenticação obrigatória via getAuthenticatedUserId
- Autorização: validar acesso ao componentId
- SQL parametrizado; sem concatenar input
- Logs de auditoria (opcional): created_by/updated_by

## 8) Testes
- Unitários (frontend):
  - Toggle OFF → header cinza, acordeão não abre, botão duplicar desabilitado
  - Toggle ON → volta ao normal
  - Numeração visual: com [ON, OFF, ON] → [1, ~, 2]; após drag, recalcula
- Integração (backend):
  - POST override cria/atualiza registro
  - GET orçamento reflete OFF nos toggles (se optarmos por carregar)
- E2E manual:
  - Criar orçamento com 3 materiais
  - Desativar um material; recarregar; estado persistido
  - Submeter orçamento; OFF não enviado

## 9) Parâmetros e Contratos
- Override API body:
  - componentId: string UUID
  - finishingId: string UUID
  - finishingMaterialId: string UUID
  - isEnabled: boolean
  - notes?: string
- Frontend material shape (parcial):
  - {
    id: string,
    finishingMaterialId: string,
    name: string,
    supplierName: string,
    unitCost: number|null,
    currency: string|null,
    purchaseLink: string,
    description: string,
    unitConsumption: number,      // dinâmico (sempre inicia 0)
    applicationHours: number,     // dinâmico (sempre inicia 0)
    isEnabled: boolean,           // default true; pode vir do override
    ...
  }
- Visual:
  - displayIndex: '~' se OFF, senão 1..N para ON

## 10) Roadmap opcional
- Adicionar nível de override por component_base com herança/precedência
- VIEW com materiais “efetivamente elegíveis” para consumo consistente
- Rollback/Histórico com Budget-level snapshots não relacionado ao toggle